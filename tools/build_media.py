#!/usr/bin/env python3
"""SPDX-License-Identifier: GPL-3.0-only. Build the WoW TGA from the canonical PNG.

Only this optional artwork-conversion tool needs Pillow; normal DB builds/tests do not.
Use --source image.jpg to replace the canonical 512px logo, or no args to regenerate TGA.
"""
from pathlib import Path
import argparse
import struct

ROOT=Path(__file__).resolve().parents[1]
LOGO=ROOT/'docs/logo.png'
TARGET=ROOT/'Searchlight/Media/Icon.tga'

def tga_bytes(image):
    image=image.convert('RGBA')
    width,height=image.size
    # Type 2: uncompressed true color. 32 bits/pixel, 8 alpha bits, bottom-left
    # origin (descriptor bit 5 clear). Pixels are written bottom row first, BGRA.
    header=struct.pack('<BBBHHBHHHHBB',0,0,2,0,0,0,0,0,width,height,32,8)
    pixels=bytearray()
    for y in range(height-1,-1,-1):
        for x in range(width):
            r,g,b,a=image.getpixel((x,y));pixels.extend((b,g,r,a))
    return header+pixels

def main():
    from PIL import Image, ImageDraw
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--source',type=Path,default=LOGO)
    args=ap.parse_args()
    image=Image.open(args.source).convert('RGBA')
    if args.source.resolve()!=LOGO.resolve():
        image=image.resize((512,512),Image.Resampling.LANCZOS)
        # Antialiased rounded outer silhouette; the artwork itself stays opaque.
        mask=Image.new('L',(2048,2048),0)
        ImageDraw.Draw(mask).rounded_rectangle((12,12,2035,2035),radius=360,fill=255)
        image.putalpha(mask.resize((512,512),Image.Resampling.LANCZOS))
        LOGO.parent.mkdir(parents=True,exist_ok=True)
        image.save(LOGO)
    if image.size!=(512,512):raise ValueError('Canonical docs/logo.png must be 512x512')
    TARGET.parent.mkdir(parents=True,exist_ok=True)
    TARGET.write_bytes(tga_bytes(image.resize((128,128),Image.Resampling.LANCZOS)))
    print(f'{TARGET.relative_to(ROOT)}: 128x128 uncompressed BGRA, bottom-left, {TARGET.stat().st_size} bytes')

if __name__=='__main__':main()
