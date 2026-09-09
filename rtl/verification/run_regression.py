#!/usr/bin/env python3
# Copyright 2025-2026 School of Integrated Circuits, Peking University
# SPDX-License-Identifier: Apache-2.0
#
"""Reproducible, timeout-bounded Verilator regressions. Every invocation is logged."""
from pathlib import Path
import argparse, subprocess, os, json, time, sys
HERE=Path(__file__).resolve().parent
p=argparse.ArgumentParser();p.add_argument('--rtl',type=Path,default=HERE.parent);p.add_argument('--out',type=Path,default=HERE.parent/'build/regression');p.add_argument('--only',default='fp,int,adder,sum,addr,sba,cluster');p.add_argument('--width',type=int,default=8);p.add_argument('--seed',type=int,default=97282);a=p.parse_args()
r=a.rtl.resolve();out=a.out.resolve();out.mkdir(parents=True,exist_ok=True)
results=[]
def cmdrun(name,cmd,timeout=240):
 start=time.time()
 try:
  q=subprocess.run([str(x) for x in cmd],cwd=out,capture_output=True,text=True,timeout=timeout)
  text=q.stdout+q.stderr; rc=q.returncode
 except subprocess.TimeoutExpired as e:
  text=str(e.stdout)+str(e.stderr)+'\nTIMEOUT\n';rc=124
 (out/(name+'.log')).write_text(text)
 row=dict(name=name,command=[str(x) for x in cmd],exit_code=rc,seconds=round(time.time()-start,2),log=name+'.log');results.append(row)
 (out/'results.json').write_text(json.dumps(results,indent=2)+'\n')
 print(name,'PASS' if rc==0 else 'FAIL',f'({rc})',flush=True)
 if rc: print('\n'.join(text.splitlines()[-20:]),flush=True)
 return rc

def sim(name,top,sources,extra=(),args=()):
 build=out/('obj_'+name)
 cmd=['verilator','--binary','--timing','--assert','-j','4','-Wno-fatal','--top-module',top,'--Mdir',build,'+incdir+'+str(r/'include'),*[r/x for x in sources],*extra]
 if cmdrun(name+'_build',cmd)==0:
  cmdrun(name+'_run',[build/('V'+top),'+verilator+seed+'+str(a.seed),*args],timeout=120)

sel=a.only.split(',')
if not set(sel) <= {'fp','int','adder','sum','addr','sba','cluster'} or not sel: p.error('unknown or empty --only selection')
if 'fp' in sel:
 subprocess.run([sys.executable,str(HERE/'make_fp_vectors.py'),str(out),str(a.seed)],check=True)
 sim('fp_p'+str(a.width),'tb_fpcore',['misc_common/cf_math_pkg.sv','cpu_cva6/package/fpnew_pkg.sv','misc_common/lzc.sv','cpu_cva6/fpu/fpnew_rounding.sv','cpu_cva6/fpu/fpnew_classifier.sv','fp_core/src/int2bf.sv','fp_core/src/fp_adder.sv','fp_core/src/quant.sv','fp_core/src/fp_core.sv','fp_core/tb/tb_fpcore.sv'],['-GPARALLEL_WIDTH='+str(a.width)],['+vectors='+str(out/'fp_vectors.txt')])
if 'int' in sel:
 sim('int','int_core_tb',['int_core/src/pe.sv','int_core/src/pe_array.sv','int_core/src/sf.sv','int_core/src/adder_tree.sv','int_core/src/sum_reduce.sv','int_core/src/sf_array.sv','int_core/src/int_core.sv','int_core/tb/int_core_tb.sv'])
if 'adder' in sel:
 sim('adder','adder_tree_tb',['int_core/src/adder_tree.sv','int_core/tb/adder_tree_tb.sv'])
if 'sum' in sel:
 sim('sum','sum_reduce_tb',['int_core/src/adder_tree.sv','int_core/src/sum_reduce.sv','int_core/tb/sum_reduce_tb.sv'])
if 'sba' in sel:
 subprocess.run([sys.executable,str(HERE/'make_sba_probe.py'),str(r),str(out)],check=True)
 sim('sba_route_probe','sba_route_probe_tb',['misc_common/cf_math_pkg.sv','soc_axi/axi_bus/axi_pkg.sv','misc_common/addr_decode_dync.sv','misc_common/addr_decode.sv'],[out/'sba_route_probe_tb.sv'])
if 'cluster' in sel:
 sim('cluster','int_fp_cluster_tb',['misc_common/cf_math_pkg.sv','cpu_cva6/package/fpnew_pkg.sv','misc_common/lzc.sv','cpu_cva6/fpu/fpnew_rounding.sv','cpu_cva6/fpu/fpnew_classifier.sv','fp_core/src/int2bf.sv','fp_core/src/fp_adder.sv','fp_core/src/quant.sv','fp_core/src/fp_core.sv','int_core/src/pe.sv','int_core/src/pe_array.sv','int_core/src/sf.sv','int_core/src/adder_tree.sv','int_core/src/sum_reduce.sv','int_core/src/sf_array.sv','int_core/src/int_core.sv','tech_specific/tc_clk.v','core_cluster/int_fp_cluster.sv','core_cluster/tb/int_fp_cluster_tb.sv'],[])
if 'addr' in sel:
 subprocess.run([sys.executable,str(HERE/'make_addr_harness.py'),str(r),str(out)],check=True)
 sim('addr','soc_addr_tb',['misc_common/cf_math_pkg.sv','cpu_cva6/package/config_pkg.sv','cpu_cva6/package/cv64a6_config_pkg.sv','cpu_cva6/package/riscv_pkg.sv','cpu_cva6/package/ariane_pkg.sv','cpu_cva6/package/wt_cache_pkg.sv','soc_axi/axi_bus/axi_pkg.sv','soc_axi/riscv-dbg/dm_pkg.sv','soc_pkg.sv','misc_common/lzc.sv','cpu_cva6/load_unit.sv','cpu_cva6/cache_subsystem/wt_dcache_ctrl.sv'],[out/'soc_addr_tb.sv','+incdir+'+str(out)])
sys.exit(any(x['exit_code'] for x in results))
