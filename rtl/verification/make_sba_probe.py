#!/usr/bin/env python3
# Copyright 2025-2026 School of Integrated Circuits, Peking University
# SPDX-License-Identifier: Apache-2.0
#
from pathlib import Path
import sys,re,json,hashlib
r=Path(sys.argv[1]);o=Path(sys.argv[2]);s=(r/'soc_axi/axi_llc/axi_llc_config.sv').read_text()
a=s.index('  rule_full_t [1:0] axi_addr_map;');b=s.index('  //////////////////////////////////////////////////////////////////',a)
logic=s[a:b]
t=(r/'soc_noc.sv').read_text()
params='\n'.join(re.findall(r'  localparam LLCNum(?:Set|Lines|Blocks).*?;',t))
tb='''`timescale 1ns/1ps
module sba_route_probe_tb;
  typedef axi_pkg::xbar_rule_64_t rule_full_t;
  typedef logic[63:0] addr_full_t;
  typedef struct packed {logic[7:0] flushed;} conf_t;
  conf_t conf_regs_i;
  logic[63:0] slv_aw_addr_i,slv_ar_addr_i;
  logic mst_aw_bypass_o,mst_ar_bypass_o;
  rule_full_t axi_spm_rule_i,axi_cached_rule_i;
'''+params+'\n'+logic+'''
  initial begin
    for(int die=0;die<4;die++)begin
      logic[63:0] b;
      b=64'(die)<<32;
      conf_regs_i='0;
      axi_spm_rule_i='{idx:0,start_addr:b+'h80000000,end_addr:b+'h80000000+LLCNumSet*LLCNumLines*LLCNumBlocks*8};
      axi_cached_rule_i='{idx:0,start_addr:b+'h90000000,end_addr:b+'ha0000000};
      for(int c=0;c<7;c++)begin
        logic want;
        case(c)
          0:begin slv_ar_addr_i=b+'h80000000;want=0;end
          1:begin slv_ar_addr_i=b+'h80007fff;want=0;end
          2:begin slv_ar_addr_i=b+'h8000ffff;want=0;end
          3:begin slv_ar_addr_i=b+'h80010000;want=1;end
          4:begin slv_ar_addr_i=b+'h8fffffff;want=1;end
          5:begin slv_ar_addr_i=b+'h90000000;want=0;end
          6:begin slv_ar_addr_i=b+'ha0000000;want=1;end
        endcase
        slv_aw_addr_i=slv_ar_addr_i;#1;
        if(mst_ar_bypass_o!==want || mst_aw_bypass_o!==want)$fatal(1,"SBA route probe mismatch");
      end
    end
    $display("[PASS] SBA classification probe: 28 addresses x AR/AW; outside 64KiB goes to bypass");
    $display("[LIMIT] This reproduces routing only. It does not verify external endpoint responses.");
    $finish;
  end
endmodule
'''
(o/'sba_route_probe_tb.sv').write_text(tb)
(o/'sba_source_manifest.json').write_text(json.dumps(dict(source=str(r/'soc_axi/axi_llc/axi_llc_config.sv'),sha256=hashlib.sha256(s.encode()).hexdigest(),logic=logic,params=params),indent=2)+'\n')
