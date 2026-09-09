#!/usr/bin/env python3
# Copyright 2025-2026 School of Integrated Circuits, Peking University
# SPDX-License-Identifier: Apache-2.0
#
"""Run DCO register, clock/divider, and extracted SoC clock-branch checks."""
from pathlib import Path
import argparse,subprocess,json,time,sys,hashlib,os
HERE=Path(__file__).resolve().parent
p=argparse.ArgumentParser();p.add_argument('--rtl',type=Path,default=HERE.parent);p.add_argument('--out',type=Path,default=HERE.parent/'build/dco');p.add_argument('--only',default='regs,clock,top,axi');p.add_argument('--seed',type=int,default=97282);a=p.parse_args()
root=a.rtl.resolve();out=a.out.resolve();out.mkdir(parents=True,exist_ok=True)
selected=set(a.only.split(','));assert selected <= {'regs','clock','top','axi','lint'} and selected
rtl=root;tests=rtl/'soc_axi/clk/tb';rows=[];manifest=[]
def run(name,cmd,kind='test',timeout=240):
 start=time.time()
 try:q=subprocess.run([str(x) for x in cmd],cwd=out,capture_output=True,text=True,timeout=timeout);rc=q.returncode;txt=q.stdout+q.stderr
 except subprocess.TimeoutExpired as e:rc=124;txt=str(e.stdout)+str(e.stderr)+'\nTIMEOUT'
 (out/(name+'.log')).write_text(txt)
 rows.append(dict(name=name,kind=kind,command=[str(x) for x in cmd],exit_code=rc,seconds=round(time.time()-start,2),log=name+'.log'))
 (out/'results.json').write_text(json.dumps(rows,indent=2)+'\n')
 print(name,rc,flush=True)
 if rc and kind=='test':print('\n'.join(txt.splitlines()[-12:]),flush=True)
 return rc

def sim(name,top,files,defs=()):
 mdir=out/('obj_'+name)
 for f in files:
  f=Path(f)
  if f.exists():manifest.append(dict(path=str(f),sha256=hashlib.sha256(f.read_bytes()).hexdigest()))
 cmd=['verilator','--binary','--timing','--assert','-j','4','-Wno-fatal','--timescale','1ns/1ps','--top-module',top,'--Mdir',mdir,'+incdir+'+str(rtl/'include'),*defs,*files]
 if run(name+'_build',cmd)==0:run(name+'_run',[mdir/('V'+top),'+verilator+seed+'+str(a.seed)],timeout=30)

if 'regs' in selected:
 for label,rel in [('rtl','soc_axi/clk/dco_regs.sv')]:
  sim('regs_'+label,'dco_regs_tb',[root/rel,tests/'dco_regs_tb.sv'])
if 'clock' in selected:
 # DCO.v is the behavioural release model: dividers are real RTL, the ring oscillator is a placeholder.
 sim('dco_dividers','dco_clock_tb',[rtl/'tech_specific/DCO.v',tests/'dco_clock_tb.sv'])
if 'top' in selected:
 for label,rel in [('rtl','soc_noc.sv')]:
  s=(root/rel).read_text();start=s.index('`ifdef SIM\n  assign clk = sys_clk_i;');end=s.index('\n`endif',start)+len('\n`endif');block=s[start:end]
  tb='''`timescale 1ns/1ps
`default_nettype none
module soc_dco_clock_slice(
 input logic sys_clk_i,ext_clk_i,rstn_i,sys_dco_en_i,sys_clk_sel_i,
 input logic[5:0] sys_dco_cc_sel,sys_dco_fc_sel,
 input logic[2:0] sys_dco_div_sel,
 input logic[1:0] sys_dco_freq_sel,
`ifndef FPGA
 output logic sys_dco_clk_o,
`endif
 output logic observed_clk);
 logic clk;
'''+block+'''
 assign observed_clk=clk;
endmodule
module soc_dco_clock_tb;
 logic sys_clk_i=0,ext_clk_i=0,rstn_i=0,sys_dco_en_i=0,sys_clk_sel_i=1;
 logic[5:0] sys_dco_cc_sel=63,sys_dco_fc_sel=63;
 logic[2:0] sys_dco_div_sel=4;
 logic[1:0] sys_dco_freq_sel=3;
 wire observed_clk;
`ifndef FPGA
 wire sys_dco_clk_o;
`endif
 always #5 sys_clk_i=~sys_clk_i;
 always #7 ext_clk_i=~ext_clk_i;
 soc_dco_clock_slice dut(.*);
 initial begin
   for(int f=0;f<4;f++)begin
     int ratio;time t;
     @(negedge ext_clk_i);rstn_i=0;sys_dco_freq_sel=2'(f);
     repeat(3)@(negedge ext_clk_i);rstn_i=1;repeat(40)@(posedge ext_clk_i);
`ifdef SIM
     ratio=10;
`elsif FPGA
     ratio=10; // Only validates wiring through the stand-in PLL interface.
`else
     ratio=14*(f==1 ? 2:f==3 ? 4:1);
`endif
     repeat(8)begin
       @(posedge observed_clk);t=$time;
`ifndef FPGA
       #1;if(sys_dco_clk_o!==1)$fatal(1,"observation clock not driven high");
`endif
       @(posedge observed_clk);if($time-t!=ratio)$fatal(1,"wrong SoC clock period");
       @(negedge observed_clk);
`ifndef FPGA
       #1;if(sys_dco_clk_o!==0)$fatal(1,"observation clock not driven low");
`endif
     end
   end
   $display("[PASS] actual SoC clock branch: four FREQ settings, period and output routing");$finish;
 end
 initial begin #100000;$fatal(1,"clock branch timeout");end
endmodule
`default_nettype wire
'''
  path=out/(label+'_clock_slice.sv');path.write_text(tb)
  manifest.append(dict(path=str(root/rel),sha256=hashlib.sha256(s.encode()).hexdigest(),extracted_block=block))
  # The FPGA branch instantiates the tool-generated clocking wrapper `clk_div`; a pass-through stub stands in for it.
  for mode,defs,extra in [('asic',[],[]),('sim',['+define+SIM'],[]),('fpga',['+define+FPGA'],[HERE/'fpga_clk_div_stub.sv'])]:
   sim('top_'+label+'_'+mode,'soc_dco_clock_tb',[rtl/'tech_specific/DCO.v',*extra,path],defs)
if 'axi' in selected:
 for q in (0,1):
  for r in (0,1):
   sim(f'axi_dco_q{q}_r{r}','dco_axi_tb',[rtl/'misc_common/cf_math_pkg.sv',rtl/'soc_axi/axi_bus/axi_pkg.sv',rtl/'soc_axi/bus_converter/axi_to_reg_v2.sv',rtl/'soc_axi/clk/dco_regs.sv',tests/'dco_axi_tb.sv'],[f'-GCUT_MEM_REQS={q}',f'-GCUT_MEM_RSPS={r}','-y',rtl/'misc_common','-y',rtl/'soc_axi/bus_converter','-y',rtl/'soc_axi/axi_bus','-y',rtl/'soc_axi/reg_bus/pulp'])
if 'lint' in selected:
 # Diagnostic intentionally remains separate from passing targeted tests.
 # BLKANDNBLK and BLKLOOPINIT are Verilator restrictions (continuous and clocked assignments to elements
 # of one array in the FPnew pipeline registers; clocked byte-enable writes to the generic tc_sram array
 # inside a loop), not design errors; the upstream CVA6 flow disables BLKANDNBLK as well.
 # -fno-dfg works around an internal error (std::out_of_range in the DFG optimiser) of Verilator 5.024 on this design.
 env=os.environ.copy();os.environ['SRC_DIR']=str(rtl)
 run('fullchip_lint',['verilator','--lint-only','--timing','-Wno-fatal','-Wno-BLKANDNBLK','-Wno-BLKLOOPINIT','-fno-dfg','--timescale','1ns/1ps','--error-limit','50','--top-module','soc_noc_top','-f',rtl/'filelist.f'],kind='diagnostic',timeout=1800)
(out/'source_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
test_rows=[x for x in rows if x['kind']=='test']
summary=dict(source_root=str(root),tests_all_passed=all(x['exit_code']==0 for x in test_rows) if test_rows else None,simulation_runs=sum(x['name'].endswith('_run') for x in rows),diagnostics=[x for x in rows if x['kind']=='diagnostic'])
(out/'summary.json').write_text(json.dumps(summary,indent=2)+'\n');print(json.dumps(summary,indent=2))
sys.exit(any(x['exit_code'] for x in rows))
