# SPDX-License-Identifier: GPL-3.0-only
"""Texture packaging tests, with only the Python standard library."""
import importlib.util
from pathlib import Path
import struct
import unittest
import zlib
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('build_media',ROOT/'tools/build_media.py')
media=importlib.util.module_from_spec(spec);spec.loader.exec_module(media)

class MediaTests(unittest.TestCase):
    def test_tga_header_pixels_and_alpha(self):
        data=(ROOT/'Searchlight/Media/Icon.tga').read_bytes()
        fields=struct.unpack('<BBBHHBHHHHBB',data[:18])
        self.assertEqual(fields,(0,0,2,0,0,0,0,0,128,128,32,8))
        self.assertEqual(len(data),18+128*128*4)
        self.assertEqual(min(data[21::4]),0)
        self.assertEqual(max(data[21::4]),255)

    def test_converter_bottom_left_bgra_orientation(self):
        class Pixels:
            size=(2,2)
            def convert(self,mode):
                assert mode=='RGBA'
                return self
            def getpixel(self,xy):
                return {(0,0):(255,0,0,1),(1,0):(0,255,0,2),
                        (0,1):(0,0,255,3),(1,1):(255,255,255,4)}[xy]
        data=media.tga_bytes(Pixels())
        self.assertEqual(data[18:],bytes((255,0,0,3,255,255,255,4,0,0,255,1,0,255,0,2)))
        self.assertEqual(data[17]&32,0)

    def test_canonical_png_dimensions_rgba(self):
        data=(ROOT/'docs/logo.png').read_bytes()
        self.assertEqual(data[:8],b'\x89PNG\r\n\x1a\n')
        self.assertEqual(data[12:16],b'IHDR')
        self.assertEqual(struct.unpack('>IIBBBBB',data[16:29]),(512,512,8,6,0,0,0))
        self.assertEqual(zlib.crc32(data[12:29]),struct.unpack('>I',data[29:33])[0])

    def test_toc_load_order_and_logo_reference(self):
        toc=(ROOT/'Searchlight/Searchlight.toc').read_text()
        self.assertIn(r'## IconTexture: Interface\AddOns\Searchlight\Media\Icon',toc)
        self.assertLess(toc.index('Icons.lua'),toc.index('UI.lua'))
        self.assertIn('docs/logo.png',(ROOT/'README.md').read_text())
        self.assertIn('## Version: @project-version@',toc)
        self.assertIn('\n## X-Curse-Project-ID: 1799220\n',toc)

if __name__=='__main__':unittest.main()
