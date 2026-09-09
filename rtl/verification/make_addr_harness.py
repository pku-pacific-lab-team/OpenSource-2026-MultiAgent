#!/usr/bin/env python3
# Copyright 2025-2026 School of Integrated Circuits, Peking University
# SPDX-License-Identifier: Apache-2.0
#
"""Extract actual SoC constants and base assignments; test actual CVA6 submodules."""
from pathlib import Path
import re,sys,json,hashlib
r=Path(sys.argv[1]);out=Path(sys.argv[2]);top=[];meta=[]
paths=[r/'soc_noc.sv']
for idx,p in enumerate(paths):
 s=p.read_text();cfg=re.search(r"localparam config_pkg::cva6_cfg_t CVA6Cfg = '\{.*?\n  \};",s,re.S).group()
 assignments=re.findall(r"CachedRegionAddrBase\s*=\s*(1024'\(\{soc_pkg::SPMBase_\w+.*?\))\s*;",s)
 assert len(assignments)==4
 bases='\n'.join(f"2'd{i}: CachedRegionAddrBase = {v};" for i,v in enumerate(assignments))
 template=(Path(__file__).parent/'soc_addr_fixture.sv.in').read_text()
 top.append(template.replace('@NAME@',f'soc_addr_fixture_{idx}').replace('@CFG@',cfg).replace('@BASES@',bases))
 meta.append(dict(path=str(p),sha256=hashlib.sha256(p.read_bytes()).hexdigest(),config=cfg,bases=assignments))
top.append('module soc_addr_tb;\nlogic ['+str(len(paths)-1)+':0] done;')
for i in range(len(paths)):top.append(f'soc_addr_fixture_{i} f{i}(.done(done[{i}]));')
top.append("initial begin wait(&done);$display(\"[PASS] all SoC configuration variants\");$finish;end\ninitial begin #200000;$fatal(1,\"address timeout\");end\nendmodule")
(out/'soc_addr_tb.sv').write_text('`timescale 1ns/1ps\n'+'\n'.join(top))
(out/'soc_config_source_manifest.json').write_text(json.dumps(meta,indent=2)+'\n')
