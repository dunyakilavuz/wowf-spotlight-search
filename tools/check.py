#!/usr/bin/env python3
"""SPDX-License-Identifier: GPL-3.0-only. Offline syntax and behavior checks."""
from pathlib import Path
import argparse, shutil, subprocess, sys, xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
ap=argparse.ArgumentParser()
ap.add_argument('--lua',default=shutil.which('lua5.1') or shutil.which('lua') or str(ROOT/'.build/lua-lua-5.1/src/lua'))
ap.add_argument('--luac',default=shutil.which('luac5.1') or shutil.which('luac') or str(ROOT/'.build/lua-lua-5.1/src/luac'))
args=ap.parse_args()
paths=[p for folder in ['Searchlight','tools','tests','vendor'] for p in (ROOT/folder).rglob('*.lua')]
for p in paths:subprocess.run([args.luac,'-p',str(p)],check=True)
print(f'luac -p: PASS ({len(paths)} Lua files)',flush=True)
ET.parse(ROOT/'Searchlight/Bindings.xml')
print('Bindings.xml: well-formed',flush=True)
subprocess.run([sys.executable,'-m','unittest','discover','-s','tests','-p','test_*.py','-v'],cwd=ROOT,check=True)
subprocess.run([args.lua,'tests/test_searchlight.lua'],cwd=ROOT,check=True)
