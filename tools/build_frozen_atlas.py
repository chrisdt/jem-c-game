"""Analyze alpha bounds and boot anchors; never repaint or resize source art."""
from pathlib import Path
import json
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
FOLDER=ROOT/'assets/frozen'
result={}
def analyze(name,cols,bands):
 a=np.asarray(Image.open(FOLDER/(name+'.png')).convert('RGBA'))[:,:,3]
 entries=[]
 for y0,y1 in bands:
  row=[]
  for col in range(cols):
   x0=round(col*a.shape[1]/cols); x1=round((col+1)*a.shape[1]/cols)
   cell=a[y0:y1,x0:x1]; ys,xs=np.nonzero(cell>64)
   left,top,right,bottom=int(xs.min()),int(ys.min()),int(xs.max()+1),int(ys.max()+1)
   # Only the boot strip sets horizontal anchors; blades and raised hands
   # cannot move the planted body between directional attack poses.
   fy,fx=np.nonzero(cell[max(top,bottom-int((bottom-top)*.12)):bottom]>64)
   row.append({'region':[x0+left,y0+top,right-left,bottom-top], 'anchor':[float((fx.min()+fx.max())/2-left),bottom-top]})
  entries.append(row)
 result[name]=entries
for name,cols,rows in [('snow_sprites',4,2),('items',4,2),('yeti',3,3)]:
 h=Image.open(FOLDER/(name+'.png')).height
 analyze(name,cols,[(round(i*h/rows),round((i+1)*h/rows)) for i in range(rows)])
analyze('frost_jab',4,[(0,228),(228,448),(448,650)])
h=Image.open(FOLDER/'space_jab.png').height
analyze('space_jab',4,[(0,354),(354,690),(690,h)])
(FOLDER/'atlas.json').write_text(json.dumps(result,indent=2)+'\n')
print('Analyzed',sum(len(row) for sheet in result.values() for row in sheet),'poses/items')
