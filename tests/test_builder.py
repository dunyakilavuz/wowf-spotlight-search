# SPDX-License-Identifier: GPL-3.0-only
"""Offline compiler invariants, input integrity, and reproducibility witnesses."""
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('build_db',ROOT/'tools/build_db.py')
build=importlib.util.module_from_spec(spec);spec.loader.exec_module(build)

class BuilderTests(unittest.TestCase):
    def test_all_pinned_sources_match(self):
        lock=json.loads((ROOT/'tools/sources.lock.json').read_text())
        build.verify(lock,ROOT/'vendor/QuestieDB')
        self.assertEqual(lock['revision'],'ae4404b01a45163d3ef05909395b29aafc437bc2')

    def test_changed_source_fails_closed(self):
        with tempfile.TemporaryDirectory() as directory:
            p=Path(directory);(p/'data.lua').write_text('changed')
            lock={'files':{'data.lua':hashlib.sha256(b'original').hexdigest()}}
            with self.assertRaisesRegex(ValueError,'Input changed'):
                build.verify(lock,p)

    def test_ascii_word_normalization(self):
        self.assertEqual(build.normalize("  FiSHING--Trainer! "),'fishing trainer')
        self.assertEqual(build.normalize("Shen'dralas"),'shen dralas')

    def test_profession_alias_not_only_literal_title(self):
        words=build.source_words({'name':'Example','subName':'Journeyman Blacksmith','npcFlags':19},'npc')
        self.assertIn('blacksmithing trainer',words)
        self.assertIn('fishing trainer',build.source_words({'subName':'Expert Fisherman','npcFlags':19},'npc'))

    def test_coverage_consistency(self):
        coverage=json.loads((ROOT/'Searchlight/Data/coverage.json').read_text())
        counts=coverage['counts']
        self.assertEqual(counts['rows'],counts['npc']+counts['item']+counts['object'])
        self.assertEqual(counts['npc_spawns']+counts['object_spawns'],
                         counts['mapped_spawn_points']+counts['unmapped_spawn_points'])
        self.assertLessEqual(counts['item_mapped'],counts['item_with_sources'])
        self.assertGreater(counts['item_mapped'],7000)
        for name,size in coverage['files'].items():
            self.assertEqual((ROOT/'Searchlight'/name).stat().st_size,size)

    def test_acquisition_metadata_coverage(self):
        coverage=json.loads((ROOT/'Searchlight/Data/coverage.json').read_text())
        self.assertEqual(coverage['counts']['auctioneers'],29)
        self.assertGreater(coverage['counts']['drop_rate_links'],15000)
        self.assertGreater(coverage['counts']['items_with_drop_rates'],1200)
        database=(ROOT/'Searchlight/Data/Database.lua').read_text()
        for name in ('auctioneers','npcRanks','questItems','dropRates'):
            self.assertIn(f'D.{name} = {{',database)
        self.assertIn('schema=3',database)

    def test_no_addon_saved_variables(self):
        toc=(ROOT/'Searchlight/Searchlight.toc').read_text()
        self.assertNotIn('SavedVariables:',toc)
        self.assertIn('## Interface: 16001',toc)

if __name__=='__main__':unittest.main(verbosity=2)
