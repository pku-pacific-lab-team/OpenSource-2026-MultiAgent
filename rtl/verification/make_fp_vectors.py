#!/usr/bin/env python3
# Copyright 2025-2026 School of Integrated Circuits, Peking University
# SPDX-License-Identifier: Apache-2.0
#
"""Scalar integer/Fraction model of the existing arithmetic contract; no RTL calls.
The legacy quantizer uses magnitude round-half-up (not RNE), then saturation.
This regression preserves that existing numerical policy; it does not redefine MX.
"""
from pathlib import Path
from fractions import Fraction as F
import random,json,sys
out=Path(sys.argv[1]); seed=int(sys.argv[2]) if len(sys.argv)>2 else 0x2602; rng=random.Random(seed)
def p2(e): return F(2**e) if e>=0 else F(1,2**-e)
def rne(x):
 q,r=divmod(x.numerator,x.denominator)
 return q+int(2*r>x.denominator or (2*r==x.denominator and q%2))
def decode(b):
 e=(b>>7)&255;m=b&127
 return (-1 if b&0x8000 else 1)*F(m if e==0 else m+128)*p2((1 if e==0 else e)-134)
def bf_round(x):
 if not x:return 0
 sign=0x8000 if x<0 else 0;x=abs(x)
 e=x.numerator.bit_length()-x.denominator.bit_length()
 if x<p2(e):e-=1
 if e < -126:return sign|rne(x/p2(-133))
 sig=rne(x/p2(e-7))
 if sig==256:e+=1;sig=128
 return sign|0x7f80 if e>127 else sign|((e+127)<<7)|(sig-128)
def mx_bf(m,sf):
 if m==0:return 0
 sign=0x8000 if m<0 else 0;mag=abs(m);e=mag.bit_length()-1;biased=sf+e
 if biased>=255:return sign|0x7f80
 # Existing converter's normal-format encoding, including SF=0 boundary.
 sig=rne(F(mag,1)*p2(7-e))
 return sign|((biased<<7)+(sig-128))
def add(a,b):
 ea=(a>>7)&255;eb=(b>>7)&255
 if (ea==255 and a&127) or (eb==255 and b&127):return 0x7fc0
 if ea==255 and eb==255 and (a^b)&0x8000:return 0x7fc0
 if ea==255:return a
 if eb==255:return b
 return bf_round(decode(a)+decode(b))
def quant(group,mode):
 exps=[(x>>7)&255 for x in group];hasinf=any(e==255 and x&127==0 for x,e in zip(group,exps))
 maximum=max((e if e<255 else 0) for e in exps);vals=[]
 for x,e in zip(group,exps):
  m=x&127;s=-1 if x&0x8000 else 1
  if e==255:q=0 if m else (7 if s>0 else -8)
  elif hasinf:q=0
  else:
   significand=F(m,4) if e==0 else F(128+m,8)
   mag=significand*p2(e-maximum)
   n=(mag+F(1,2)).numerator//(mag+F(1,2)).denominator
   q=max(-8,min(7,s*n))
  if mode and q==-8:q=-7
  vals.append(q&15)
 return max(0,maximum-2),vals
cases=[]
def addcase(name,fn):
 for mode in (0,1):cases.append((name,mode,[[fn(n,k) for k in range(4)] for n in range(256)]))
addcase('zero',lambda n,k:(0,127))
addcase('positive_one',lambda n,k:(1,127))
addcase('negative_one',lambda n,k:(-1,127))
addcase('cancel_pairs',lambda n,k:((32767 if k%2==0 else -32767),127))
addcase('signed_min',lambda n,k:(-32768,127))
addcase('signed_max',lambda n,k:(32767,127))
addcase('rounding_ties',lambda n,k:([257,259,-257,-259][(n+k)%4],110+(n//32)%5))
addcase('first_last_groups',lambda n,k:((1 if n in (0,31,32,255) else 0),127))
addcase('lane_mapping',lambda n,k:(((n*37+k*113)%8191)-4095,100+(n//32)*3+k))
addcase('exponent_spread',lambda n,k:([1,-1,32767,-32768][k],[1,64,128,220][(n+k)%4]))
addcase('overflow_infinity',lambda n,k:((32767 if k%2==0 else 1),255))
addcase('opposite_infinity_nan',lambda n,k:((32767 if k%2==0 else -32768),255))
addcase('sf_zero',lambda n,k:([0,1,2,32767][(n+k)%4],0))
addcase('sf_one',lambda n,k:([1,2,-1,-32768][(n+k)%4],1))
addcase('mixed_zero_and_inf',lambda n,k:((32767 if n%32==0 else 0),255))
for c in range(64):
 addcase('random_%02d'%c,lambda n,k:(rng.randrange(-32768,32768),rng.randrange(8,225)))
with (out/'fp_vectors.txt').open('w') as f:
 f.write(str(len(cases))+'\n')
 for idx,(name,mode,inputs) in enumerate(cases):
  man=[0]*256;sf=[0]*128;bf=[]
  for n,lanes in enumerate(inputs):
   b=[]
   for k,(m,s) in enumerate(lanes):
    mi=(n%32//8)*64+(n%8//4)+(n//32)*2+16*k
    si=n//32+(n%32//8)*32+8*k
    man[mi]|=(m&65535)<<(16*(n%4));sf[si]|=s<<(8*(n%8));b.append(mx_bf(m,s))
   bf.append(add(add(b[0],b[1]),add(b[2],b[3])))
  mout=[];sout=0
  for g in range(8):
   s,vs=quant(bf[32*g:32*g+32],mode);sout|=s<<(8*g)
   mout.extend([sum(vs[k+h*16]<<(4*k) for k in range(16)) for h in range(2)])
  f.write(f'{idx} {mode}\n')
  for v in man+sf+mout+[sout]:f.write(f'{v:016x}\n')
(out/'fp_case_manifest.json').write_text(json.dumps([dict(id=i,name=n,mode=m,seed=seed) for i,(n,m,_) in enumerate(cases)],indent=2)+'\n')
print(f'{len(cases)} FP vectors: 30 boundary/mapping + 128 seeded random, 256 results per case')
