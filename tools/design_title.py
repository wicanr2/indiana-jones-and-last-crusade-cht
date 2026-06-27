#!/usr/bin/env python3
"""為 crusade 火車車廂標題設計中文片名,風格對齊金色 INDIANA JONES / LAST CRUSADE:
  main : 印第安納·瓊斯  (橘→金漸層,厚重,深色描邊)
  sub  : 最後聖戰       (黃金漸層)
大圖渲染再 nearest 縮成 retro 像素;合成到實機標題圖預覽;烘 crusade_title.spr 給引擎疊圖。
位置用 game(320x240) 座標;crusade_cht_title.png = 960x720 = 320x240 ×3(無 letterbox)。
"""
from PIL import Image, ImageDraw, ImageFont
import os, struct, sys

FONT = next(p for p in [
    "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc",
    "/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc"] if os.path.exists(p))
SCALE = 6
os.makedirs("design_title", exist_ok=True)

# 位置(game 座標,可由參數覆寫調整)
GX_C   = int(sys.argv[1]) if len(sys.argv) > 1 else 160
MAIN_Y = int(sys.argv[2]) if len(sys.argv) > 2 else 168
SUB_Y  = int(sys.argv[3]) if len(sys.argv) > 3 else 188

def render(text, ch_h, top, bot, outline, shear):
    H = ch_h*SCALE; pad = 1*SCALE
    font = ImageFont.truetype(FONT, int(H*0.95), index=0)
    tmp = Image.new("RGBA",(10,10)); d=ImageDraw.Draw(tmp)
    bb = d.textbbox((0,0), text, font=font); tw=bb[2]-bb[0]
    W = tw+pad*2
    big = Image.new("RGBA",(W,H+pad*2),(0,0,0,0)); db=ImageDraw.Draw(big)
    ox,oy = pad-bb[0], pad-bb[1]
    for dx in range(-SCALE,SCALE+1,SCALE):
        for dy in range(-SCALE,SCALE+1,SCALE):
            if dx or dy: db.text((ox+dx,oy+dy),text,font=font,fill=outline)
    mask=Image.new("L",big.size,0); dm=ImageDraw.Draw(mask); dm.text((ox,oy),text,font=font,fill=255)
    grad=Image.new("RGBA",big.size,(0,0,0,0)); gp=grad.load()
    for y in range(big.size[1]):
        t=y/max(1,big.size[1]-1)
        c=(int(top[0]*(1-t)+bot[0]*t),int(top[1]*(1-t)+bot[1]*t),int(top[2]*(1-t)+bot[2]*t),255)
        for x in range(big.size[0]):
            if mask.getpixel((x,y))>110: gp[x,y]=c
    big=Image.alpha_composite(big,grad)
    if shear:
        w2=big.size[0]+int(big.size[1]*shear)
        big=big.transform((w2,big.size[1]),Image.AFFINE,(1,shear,-big.size[1]*shear,0,1,0),resample=Image.BILINEAR)
    return big.resize((max(1,big.size[0]//SCALE),max(1,big.size[1]//SCALE)),Image.NEAREST)

# main: 橘→金(像 INDIANA JONES),厚、微斜;sub: 黃金(像 LAST CRUSADE)
main = render("印第安納·瓊斯", 13, (255,150,30), (250,205,0), (70,28,0,255), 0.10)
sub  = render("最後聖戰",      12, (255,225,80), (220,150,0), (60,30,0,255), 0.12)
main.save("design_title/cht_main.png"); sub.save("design_title/cht_sub.png")
print("main",main.size,"sub",sub.size,"pos",(GX_C,MAIN_Y,SUB_Y))

# ---- 預覽合成到實機標題圖(scale 3,無 offset)----
base = "screenshots/crusade_cht_title.png"
if os.path.exists(base):
    shot = Image.open(base).convert("RGBA")
    def place(layer, gx_center, gy_top):
        L = layer.resize((layer.size[0]*3, layer.size[1]*3), Image.NEAREST)
        ix = int(gx_center*3 - L.size[0]/2); iy = int(gy_top*3)
        shot.alpha_composite(L,(ix,iy))
    place(main, GX_C, MAIN_Y); place(sub, GX_C, SUB_Y)
    shot.convert("RGB").save("design_title/preview.png")
    print("preview -> design_title/preview.png")

# ---- 烘 crusade_title.spr ----
mx = GX_C - main.size[0]//2; sx = GX_C - sub.size[0]//2
left = min(mx, sx); right = max(mx+main.size[0], sx+sub.size[0])
top = MAIN_Y; bottom = SUB_Y + sub.size[1]
W = right-left; H = bottom-top
canvas = Image.new("RGBA",(W,H),(0,0,0,0))
canvas.alpha_composite(main,(mx-left, MAIN_Y-top))
canvas.alpha_composite(sub ,(sx-left, SUB_Y-top))
px = canvas.load()
with open("build-engine/game-cht/crusade_title.spr","wb") as f:
    f.write(struct.pack("<HHHH", left, top, W, H))
    for y in range(H):
        for x in range(W):
            r,g,b,a = px[x,y]
            f.write(struct.pack("BBBB", r,g,b, 255 if a>=128 else 0))
print(f"spr: pos=({left},{top}) size=({W}x{H}) bytes={16+W*H*4}")
