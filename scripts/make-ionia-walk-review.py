"""Ionia six-pose animated color study, opt-in QA only; no art admission."""
from pathlib import Path
from PIL import Image,ImageDraw
import json,hashlib,math
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'art-staging/field/ionia/review'
OUT.mkdir(parents=True,exist_ok=True)
S=3
def P(x): return int(round(x*S))
def draw_pose(frame):
 im=Image.new('RGBA',(64*S,96*S));d=ImageDraw.Draw(im)
 def ellipse(b,c,o=None,w=1):d.ellipse(tuple(P(x) for x in b),fill=c,outline=o,width=P(w))
 def poly(points,c,o=None,w=1):d.polygon([(P(x),P(y)) for x,y in points],fill=c);o and d.line([(P(x),P(y)) for x,y in points+[points[0]]],fill=o,width=P(w),joint='curve')
 def line(points,c,w=1):d.line([(P(x),P(y)) for x,y in points],fill=c,width=P(w),joint='curve')
 # all six contact poses have deliberately independent leg silhouettes
 phases=[(-8,7),(-5,4),(0,0),(7,-7),(4,-5),(0,0)]
 f,b=phases[frame];hair_swing=[-2,0,1,2,0,-1][frame]
 # long curly blonde hair, deep back mass, separately-shaded curved locks
 ellipse((18+hair_swing,21,49+hair_swing,66),'#735027','#493421')
 ellipse((21+hair_swing,19,46+hair_swing,62),'#c48a39','#5a4029')
 for j in range(6):
  cx=22+j*4+hair_swing
  ellipse((cx-3,42+(j%3)*3,cx+5,59+(j%2)*5),'#c18a35','#6d4c28')
  ellipse((cx-2,45+(j%3)*3,cx+1,55+(j%2)*5),'#efc66d')
 # grounded walking legs: tapered blue trousers and high leather boots
 for offset,front in [(b,False),(f,True)]:
  hx=32+(3 if front else -4)
  knee=hx+int(offset*.65);foot=hx+offset
  poly([(hx-4,64),(hx+4,64),(knee+3,78),(knee-4,79)],'#21365b','#102033')
  poly([(knee-3,76),(knee+3,76),(foot+3,90),(foot-4,90)],'#614332','#2b2630')
  poly([(foot-5,89),(foot+4,89),(foot+7,93),(foot-7,93)],'#352b35','#1b2026')
  line([(knee+2,78),(foot+2,88)],'#97774c',1)
 # captain white undercoat / split navy tails, large expressive silhouette
 poly([(23,41),(43,42),(48,67),(38,75),(34,62),(31,72),(21,67)],'#253c6b','#152441')
 poly([(23,45),(25,64),(31,70),(30,52)],'#375788')
 poly([(42,45),(42,64),(39,71),(37,53)],'#162d53')
 poly([(26,40),(39,40),(43,64),(33,67),(22,63)],'#e2e0d1','#55617b')
 poly([(22,43),(28,40),(32,63),(24,61)],'#243f75')
 poly([(39,41),(44,45),(40,61),(35,63)],'#324e83')
 poly([(31,43),(36,42),(36,61),(33,63)],'#f5edce')
 line([(30,44),(33,58)],'#c49c48',1)
 line([(37,43),(35,58)],'#c49c48',1)
 # decorative gold breast cord / captain belt and decorated buckle
 line([(24,45),(38,49),(43,43)],'#dbb664',2)
 line([(25,47),(39,51)],'#7d663f',1)
 poly([(24,60),(43,59),(44,64),(23,65)],'#644d43','#20253a')
 ellipse((32,60,36,64),'#f1c965','#654a3d')
 # arms swing opposing legs (cloth cuff, hands)
 for side,off in [(-1,-f*.28),(1,b*.28)]:
  shoulder=24 if side==-1 else 43
  elbow=shoulder+side*4+off;hand=elbow+side*1
  poly([(shoulder-3,44),(shoulder+2,43),(elbow+3,56),(elbow-3,57)],'#284574','#172d4c')
  ellipse((elbow-3,53,elbow+3,59),'#e7dbbf','#af9159')
  ellipse((hand-2,57,hand+3,62),'#edc1a3','#8a674a')
 # neck / young adult facial proportions
 poly([(28,37),(37,37),(37,44),(29,45)],'#d9a989','#805d4b')
 ellipse((23,21,43,42),'#e9bc97','#9e7352')
 ellipse((25,25,41,39),'#f5ccaa')
 # face angled slightly left, visible eyebrow, blue/teal eyes
 line([(26,31),(31,30)],'#765235')
 ellipse((27,31,29,33),'#43718b')
 ellipse((35,31,37,33),'#385e8a')
 line([(27,38),(34,38)],'#bb776f')
 # top curly hair & distinct blond fringe, not straight middle part
 ellipse((19,17,45,29),'#9e6f30','#624c2b')
 for j,(cx,cy) in enumerate([(20,25),(24,20),(29,17),(35,18),(41,22),(44,29)]):
  ellipse((cx-4,cy-4,cx+5,cy+6),'#e2aa4f','#956326')
  ellipse((cx-2,cy-2,cx+3,cy+1),'#ffda78')
 poly([(20,25),(24,21),(27,31),(20,34)],'#d8a04d')
 poly([(41,24),(47,32),(42,45),(39,40)],'#dbab55')
 # Captain epaulettes and central rank details
 poly([(22,43),(27,42),(30,47),(23,48)],'#deb968','#735b39')
 poly([(39,42),(45,45),(42,49),(36,45)],'#deb968','#735b39')
 for j in range(3):
  line([(22+j*2,47),(21+j*2,52)],'#ebc76e',1)
  line([(40+j*2,46),(39+j*2,51)],'#e3b45a',1)
 ellipse((33,52,35,54),'#d1a551')
 return im
sources=[draw_pose(i) for i in range(6)]
strip=Image.new('RGBA',(384,96))
hires=Image.new('RGBA',(64*S*6,96*S))
metrics=[]
for i,im in enumerate(sources):
 low=im.resize((64,96),Image.Resampling.LANCZOS)
 # keep readable opaque pixels, no black/white matte
 a=low.getchannel('A').point(lambda x:255 if x>=120 else 0);low.putalpha(a)
 strip.alpha_composite(low,(i*64,0))
 hires.alpha_composite(im,(i*64*S,0))
 metrics.append({'pose':i,'alphaBox':a.getbbox()})
strip.save(OUT/'ionia-walk-6frame-review.png')
hires.save(OUT/'ionia-walk-source-6frame.png')
frames=[strip.crop((64*i,0,64*(i+1),96)).resize((256,384),Image.Resampling.NEAREST) for i in range(6)]
frames[0].save(OUT/'ionia-walk-review.gif',save_all=True,append_images=frames[1:],duration=100,loop=0,disposal=2)
receipt={'status':'ORIGINAL_PROCEDURAL_REVIEW_NOT_ADMITTED','provenance':'hand-authored geometry in scripts/make-ionia-walk-review.py','sourceVersion':1,'frameCell':[64,96],'frames':metrics,'assets':{}}
for name in ['ionia-walk-6frame-review.png','ionia-walk-source-6frame.png','ionia-walk-review.gif']:
 receipt['assets'][name]=hashlib.sha256((OUT/name).read_bytes()).hexdigest()
(OUT/'source-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print('Generated Ionia review source:',[m['alphaBox'] for m in metrics])
