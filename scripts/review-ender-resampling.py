from pathlib import Path
from PIL import Image, ImageFilter, ImageEnhance, ImageDraw
import json,hashlib
root=Path(r'C:\Users\Admin\aetherwake-ender-art-pr262-inspect')
base=root/'art-staging/field/ender'
receipt=json.loads((base/'candidate/conversion.json').read_text())
out=base/'review-alt'
out.mkdir(parents=True,exist_ok=True)
result={'status':'REVIEW_ONLY_NOT_ADMITTED','basePr262':'ff6ae22eadb3aa373a47febdf4cfc57815f2657b','algorithms':{},'actions':{}}
for action,detail in receipt['actions'].items():
 src=Image.open(base/'sources'/f'{action}-source-20261008.png').convert('RGBA')
 count=detail['frames']
 original=Image.open(base/'candidate'/f'field-{action}.png').convert('RGBA')
 variants={}
 for variant in ('lanczos','bicubic'):
  strip=Image.new('RGBA',(64*count,96))
  bounds=[]
  for i,c in enumerate(detail['conversion']):
   l,t,r,b=c['source']
   dx,dy,w,h=c['placed']
   crop=src.crop((l,t,r,b))
   # Premultiplication avoids matte color halos around transparent exported illustration.
   channel=crop.getchannel('A')
   matte=Image.new('RGBA',crop.size,(0,0,0,0))
   matte.alpha_composite(crop)
   im=matte.resize((w,h),Image.Resampling.LANCZOS if variant=='lanczos' else Image.Resampling.BICUBIC)
   im=ImageEnhance.Contrast(im).enhance(1.08)
   # restore strong pixel edges at final pixel resolution while preserving tonal gradations
   alpha=im.getchannel('A').point(lambda a:255 if a>=128 else 0)
   im.putalpha(alpha)
   strip.alpha_composite(im,(i*64+dx,dy))
   bounds.append({'frame':i+1,'opaqueBounds':strip.crop((i*64,0,(i+1)*64,96)).getchannel('A').getbbox()})
  dest=out/f'field-{action}-{variant}.png'
  strip.save(dest)
  variants[variant]={'filename':dest.name,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'bytes':dest.stat().st_size,'frames':bounds}
 result['actions'][action]={'originalSha256':hashlib.sha256((base/'candidate'/f'field-{action}.png').read_bytes()).hexdigest(),'variants':variants}
(out/'review-manifest.json').write_text(json.dumps(result,indent=2)+'\n')
sheet=Image.new('RGB',(1250,600),(26,33,42));draw=ImageDraw.Draw(sheet)
draw.text((14,12),'ENDER WALK: 64x96 / six frames. Review-only conversion alternatives.',fill='white')
for j,(name,img) in enumerate([('Existing nearest',original if action=='walk' else Image.open(base/'candidate/field-walk.png').convert('RGBA')),('Lanczos',Image.open(out/'field-walk-lanczos.png')),('Bicubic',Image.open(out/'field-walk-bicubic.png'))]):
 y=55+j*170
 draw.text((20,y),name,fill=(230,230,220))
 im=img.resize((img.width*3,img.height*3),Image.Resampling.NEAREST)
 im.thumbnail((1152,140),Image.Resampling.NEAREST)
 sheet.paste(im,(24,y+24),im)
sheet.save(out/'ender-conversion-comparison.png')
print('ACTIONS',list(result['actions']),'ALT_STRIPS',sum(len(v['variants']) for v in result['actions'].values()),'PATH',out)
