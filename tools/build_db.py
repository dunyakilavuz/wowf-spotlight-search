#!/usr/bin/env python3
"""SPDX-License-Identifier: GPL-3.0-only
Rebuild Searchlight's static data and word-prefix index from pinned QuestieDB inputs.
No game client, network scraping, third-party Python modules, or runtime Questie needed.
"""
from __future__ import annotations
import argparse
from collections import defaultdict, Counter
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
LOCK = ROOT / 'tools/sources.lock.json'
PROFESSIONS = {
    'fishing': ('fishing', 'fisherman', 'fisherwoman', 'angler'),
    'alchemy': ('alchemy', 'alchemist'),
    'blacksmithing': ('blacksmith', 'blacksmithing'),
    'cooking': ('cooking', 'cook', 'chef'),
    'enchanting': ('enchant', 'enchanter'),
    'engineering': ('engineering', 'engineer', 'mechanic'),
    'first aid': ('first aid', 'physician', 'surgeon'),
    'herbalism': ('herbal', 'herbalist', 'herbalism'),
    'leatherworking': ('leatherwork', 'leatherworker'),
    'mining': ('mining', 'miner'),
    'skinning': ('skinning', 'skinner'),
    'tailoring': ('tailor', 'tailoring'),
    'riding': ('riding',),
}
CLASSES = 'warrior paladin hunter rogue priest shaman mage warlock druid'.split()
FLAGS = {4:'vendor merchant shop', 8:'flight master flightmaster taxi gryphon wind rider',
         16:'trainer', 128:'innkeeper inn hearthstone', 256:'bank banker',
         4096:'auction house auctioneer', 8192:'stable stablemaster pet stable',
         16384:'repair repairs blacksmith repair vendor'}

def normalize(text):
    # Same ASCII tokenization as Search.lua; English names are shipped on all locales.
    return ' '.join(re.findall('[a-z0-9]+', text.lower()))

def vals(obj):
    if isinstance(obj, list):
        return obj
    return [obj[k] for k in sorted(obj or {}, key=lambda k: int(k))]

def lua(value):
    # JSON quoted ASCII is valid Lua for these characters, except \u escapes.
    # Keep UTF-8 literal and only use Lua-compatible control escapes.
    return ('"' + str(value).replace('\\','\\\\').replace('"','\\"')
            .replace('\t','\\t').replace('\r','\\r').replace('\n','\\n') + '"')

def fetch_sources(lock, source):
    source.mkdir(parents=True, exist_ok=True)
    base = f"https://raw.githubusercontent.com/{lock['repository']}/{lock['revision']}/"
    for path, expected in lock['files'].items():
        dest = source / path
        if dest.exists() and hashlib.sha256(dest.read_bytes()).hexdigest() == expected:
            continue
        data = urllib.request.urlopen(base + path, timeout=60).read()
        if hashlib.sha256(data).hexdigest() != expected:
            raise ValueError(f'SHA256 mismatch: {path}; stopping, not updating lock silently')
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(data)
        print('Fetched', path)

def verify(lock, source):
    for path, expected in lock['files'].items():
        data = (source / path).read_bytes()
        if hashlib.sha256(data).hexdigest() != expected:
            raise ValueError(f'Input changed: {path}. Review and update sources.lock.json explicitly.')

def source_words(record, kind):
    name = record.get('name', '')
    title = record.get('subName', '')
    aliases = [name, title, kind]
    if kind == 'npc':
        flags = record.get('npcFlags', 0) or 0
        for flag, words in FLAGS.items():
            if flags & flag:
                aliases.append(words)
        if flags & 16:
            nt = normalize(title)
            for profession, stems in PROFESSIONS.items():
                if any(stem in nt for stem in stems):
                    aliases.append(profession + ' trainer')
            for klass in CLASSES:
                if klass in nt:
                    aliases.append(klass + ' trainer')
        if 'weapon master' in title.lower():
            aliases.append('weapon trainer weapons trainer')
    elif kind == 'object' and 'mail' in name.lower():
        aliases.append('mail mailbox post')
    return aliases

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--source', type=Path, default=ROOT/'vendor/QuestieDB')
    ap.add_argument('--fetch', action='store_true', help='Download missing pinned public source files; no Wowhead requests')
    ap.add_argument('--lua', default=shutil.which('lua5.1') or shutil.which('lua') or str(ROOT/'.build/lua-lua-5.1/src/lua'))
    ap.add_argument('--flavor', choices=['forever','era'], default='forever')
    ap.add_argument('--overlay', type=Path, help='Reviewed, licensed JSON overlay; see tools/overlay.example.json')
    args=ap.parse_args()
    lock=json.loads(LOCK.read_text())
    if args.fetch:
        fetch_sources(lock,args.source)
    verify(lock,args.source)
    snapshot=json.loads(subprocess.check_output([args.lua, str(ROOT/'tools/export_questie.lua'),str(args.source),args.flavor]))
    overlay_info=None
    if args.overlay:
        overlay=json.loads(args.overlay.read_text())
        overlay_info={key:overlay.get(key) for key in ('license','source')}
        overlay_info['sha256']=hashlib.sha256(args.overlay.read_bytes()).hexdigest()
        if not overlay.get('license') or not overlay.get('source'):
            raise ValueError('Overlay must declare license and source')
        for kind in ('npc','object','item'):
            for key,row in overlay.get(kind,{}).items():
                snapshot[kind].setdefault(key,{}).update(row)
        snapshot['maps'].update(overlay.get('maps',{}))
        snapshot['zones'].update(overlay.get('zones',{}))
    # English geographic labels from the upstream enum; exact common punctuation overrides.
    zone_names={str(value): key.replace('_',' ').title() for key,value in snapshot['zones'].items()}
    zone_names.update({'1519':'Stormwind City','1497':'Undercity','1637':'Orgrimmar','1638':'Thunder Bluff',
        '1657':'Darnassus','1537':'Ironforge','616':'Mount Hyjal','16591':'Riverglades',
        '16593':'Zephras Isle','16651':"Shen'dralas",'16606':'Darkspear Islands',
        '33':'Stranglethorn Vale','490':"Un'Goro Crater",'10073':'Kalimdor','10074':'Eastern Kingdoms'})
    records=[]
    by_key={}
    counts=Counter()
    for kind in ('npc','object','item'):
        for key,r in sorted(snapshot[kind].items(), key=lambda pair:int(pair[0])):
            if not r.get('name'):
                counts['unnamed_skipped']+=1
                continue
            by_key[(kind,int(key))]=len(records)+1
            records.append((kind,int(key),r))
            counts[kind]+=1
    map_names={}
    for area,ui in snapshot['maps'].items():
        map_names.setdefault(int(ui),zone_names.get(area,'Area '+area))
        if area in zone_names:
            map_names[int(ui)]=zone_names[area]
    def pack_spawns(record):
        result=[]
        for area,coords in sorted(record.get('spawns',{}).items(),key=lambda t:int(t[0])):
            for pair in vals(coords):
                p=vals(pair)
                if len(p)<2 or not isinstance(p[0],(int,float)) or not isinstance(p[1],(int,float)):
                    counts['malformed_spawns_skipped']+=1;continue
                x,y=p[:2]
                if x==-1 and y==-1:
                    counts['instance_sentinels']+=1;continue
                if not (0<=x<=100 and 0<=y<=100):
                    counts['off_map_spawns_skipped']+=1;continue
                # Quantize to 0.01%; keep all valid points, not zone centroids.
                result.append(f'{int(area)},{int(x*100+0.5)},{int(y*100+0.5)}')
        return ';'.join(dict.fromkeys(result))
    packed={idx:pack_spawns(r) for idx,(_,_,r) in enumerate(records,1)}
    mapped={idx:any(int(snapshot['maps'].get(point.split(',')[0],0))>0 for point in packed[idx].split(';') if point) for idx in packed}
    for idx,(kind,_,_) in enumerate(records,1):
        counts[kind+'_mapped']+=mapped[idx]
        for point in packed[idx].split(';'):
            if point:
                counts['mapped_spawn_points' if int(snapshot['maps'].get(point.split(',')[0],0))>0 else 'unmapped_spawn_points']+=1
        counts[kind+'_spawns']+=packed[idx].count(';')+bool(packed[idx])
        counts[kind+'_located']+=bool(packed[idx])
    # Only supplement non-quest items whose effective primary NPC source field is empty.
    # This avoids reintroducing explicitly removed quest-only sources from rate support.
    common_used=0
    def physical_sources(item_id, seen=None):
        nonlocal common_used
        seen=set() if seen is None else seen
        if item_id in seen:return set()
        seen.add(item_id)
        r=snapshot['item'].get(str(item_id),{})
        sources=set()
        for field,kind,code in [('vendors','npc','v'),('npcDrops','npc','d'),('objectDrops','object','o')]:
            for key in vals(r.get(field,{})):
                row=by_key.get((kind,int(key)))
                if row:sources.add((code,row))
                else:counts['missing_source_references']+=1
        if not r.get('npcDrops') and r.get('class')!=12:
            for key,rate in snapshot['commonDrops'].get(str(item_id),{}).items():
                row=by_key.get(('npc',int(key)))
                if row and rate>0:
                    sources.add(('d',row));common_used+=1
        # An item contained in another item routes to that container's physical source.
        for container_id in vals(r.get('itemDrops',{})):
            sources.update(physical_sources(int(container_id),seen))
        return sources
    prefixes=defaultdict(set)
    rows=[]
    spawn_pool, spawn_ids, source_pool, source_ids = [], {}, [], {}
    def intern(pool, ids, value):
        if not value:return 0
        if value not in ids:
            ids[value]=len(pool)+1;pool.append(value)
        return ids[value]
    forever_areas={'616','16591','16593','16651','16606'}
    forever_counts=defaultdict(Counter)
    source_count=0
    for idx,(kind,key,r) in enumerate(records,1):
        refs=physical_sources(key) if kind=='item' else set()
        source_count+=len(refs)
        if kind=='item' and refs:
            counts['item_with_sources']+=1
            if any(packed[s] for _,s in refs):counts['item_located']+=1
            if any(mapped[s] for _,s in refs):counts['item_mapped']+=1
        fields=[kind[0] if kind!='object' else 'o',str(key),r['name'],r.get('subName','') or '',
                str(r.get('npcFlags',0) or 0),r.get('friendlyToFaction','') or '',
                str(intern(spawn_pool,spawn_ids,packed[idx])),
                str(intern(source_pool,source_ids,';'.join(code+str(n) for code,n in sorted(refs)))),
                str(r.get('zoneID',0) or 0)]
        assert all('\t' not in f and '\n' not in f for f in fields)
        rows.append('\t'.join(fields))
        words=source_words(r,kind)
        areas=set(r.get('spawns',{}))
        if r.get('zoneID'):areas.add(str(r['zoneID']))
        words.extend(zone_names.get(area,'') for area in areas)
        for word in set(normalize(' '.join(words)).split()):
            for length in range(1,len(word)+1):
                prefixes[word[:length]].add(idx)
        for area in forever_areas:
            coords=r.get('spawns',{}).get(area,{})
            if coords:
                forever_counts[area][kind]+=1
                forever_counts[area]['spawn_pairs']+=len(coords)
    counts['item_sources']=source_count
    counts['common_drop_links_considered']=common_used
    counts['rows']=len(rows);counts['prefixes']=len(prefixes)
    data_dir=ROOT/'Searchlight/Data';data_dir.mkdir(parents=True,exist_ok=True)
    # Delete only generator-owned prior prefix chunks, never user overlays or addon code.
    for old in data_dir.glob('Index[0-9][0-9].lua'):old.unlink()
    generated=['Database.lua']
    header='-- Generated by tools/build_db.py. GPL-3.0-only; see THIRD_PARTY_NOTICES.md.\n'
    meta={'flavor':args.flavor,'sourceRevision':lock['revision'],'schema':3,'rows':len(rows)}
    if overlay_info:
        meta['overlayHash']=overlay_info['sha256']
        meta['overlaySource']=overlay_info['source']
    with (data_dir/'Database.lua').open('w') as out:
        out.write(header+'local D = Searchlight.DB\nD.meta = {')
        out.write(','.join(f'{k}={v if isinstance(v,int) else lua(v)}' for k,v in meta.items())+'}\nD.rows = {\n')
        for row in rows:out.write(lua(row)+',\n')
        out.write('}\nD.spawns = {\n')
        for value in spawn_pool:out.write(lua(value)+',\n')
        out.write('}\nD.sources = {\n')
        for value in source_pool:out.write(lua(value)+',\n')
        out.write('}\nD.auctioneers = {')
        auctioneers=[idx for idx,(kind,_,record) in enumerate(records,1)
                     if kind=='npc' and (record.get('npcFlags',0) or 0)&4096 and mapped[idx]
                     and record.get('friendlyToFaction') in ('A','H','AH')]
        out.write(','.join(map(str,auctioneers))+'}\nD.npcRanks = {\n')
        for idx,(kind,_,record) in enumerate(records,1):
            if kind=='npc' and record.get('rank',0):out.write(f'[{idx}]={int(record["rank"])},\n')
        out.write('}\nD.questItems = {\n')
        for idx,(kind,_,record) in enumerate(records,1):
            if kind=='item' and record.get('class')==12:out.write(f'[{idx}]=true,\n')
        out.write('}\nD.dropRates = {\n')
        rate_links,rate_items=0,0
        for idx,(kind,item_id,record) in enumerate(records,1):
            if kind!='item':continue
            rates=[]
            for npc,percent in sorted(snapshot['commonDrops'].get(str(item_id),{}).items(),key=lambda pair:int(pair[0])):
                source=by_key.get(('npc',int(npc)))
                if source and 0<=percent<=100:
                    rates.append(f'{source},{percent:.6g}')
            if rates:
                rate_links+=len(rates);rate_items+=1;out.write(f'[{idx}]={lua(";".join(rates))},\n')
        counts['auctioneers']=len(auctioneers)
        counts['drop_rate_links']=rate_links
        counts['items_with_drop_rates']=rate_items
        out.write('}\nD.zones = {\n')
        used_areas={str(int(p.split(',')[0])) for spawn in packed.values() for p in spawn.split(';') if p}
        used_areas.update(str(r.get('zoneID',0) or 0) for _,_,r in records)
        for area in sorted(used_areas,key=int):
            out.write(f'[{area}]={{{int(snapshot["maps"].get(area,0))},{lua(zone_names.get(area,"Area "+area))}}},\n')
        out.write('}\nD.zoneQueries = {\n')
        zone_queries=defaultdict(set)
        for area in used_areas:
            if area in zone_names:
                zone_queries[normalize(zone_names[area])].add(area)
        for phrase,areas in sorted(zone_queries.items()):
            out.write(f'[{lua(phrase)}]={lua(",".join(sorted(areas,key=int)))}' + ',\n')
        out.write('}\nD.zonePrefixes = {\n')
        zone_prefixes=defaultdict(set)
        for phrase,areas in zone_queries.items():
            for length in range(3,len(phrase)+1):zone_prefixes[phrase[:length]].update(areas)
        for phrase,areas in sorted(zone_prefixes.items()):
            out.write(f'[{lua(phrase)}]={lua(",".join(sorted(areas,key=int)))}' + ',\n')
        out.write('}\nD.prefix = {}\n')
    sorted_prefixes=sorted(prefixes)
    posting_pool,posting_ids,posting_for = [],{},{}
    for prefix in sorted_prefixes:
        previous=0;deltas=[]
        for row in sorted(prefixes[prefix]):
            deltas.append(str(row-previous));previous=row
        posting_for[prefix]=intern(posting_pool,posting_ids,' '.join(deltas))
    generated.append('Postings.lua')
    with (data_dir/'Postings.lua').open('w') as out:
        out.write(header+'Searchlight.DB._postings = {\n')
        for value in posting_pool:out.write(lua(value)+',\n')
        out.write('}\n')
    counts['unique_posting_lists']=len(posting_pool)
    counts['unique_spawn_lists']=len(spawn_pool)
    counts['unique_source_lists']=len(source_pool)
    for start in range(0,len(sorted_prefixes),12000):
        filename=f'Index{start//12000+1:02d}.lua';generated.append(filename)
        with (data_dir/filename).open('w') as out:
            out.write(header+'local P, L = Searchlight.DB.prefix, Searchlight.DB._postings\n')
            for prefix in sorted_prefixes[start:start+12000]:
                out.write(f'P[{lua(prefix)}]=L[{posting_for[prefix]}]\n')
            if start+12000>=len(sorted_prefixes):out.write('Searchlight.DB._postings = nil\n')
    interface=16001 if args.flavor=='forever' else 11509
    toc=[f'## Interface: {interface}','## Title: Searchlight',r'## IconTexture: Interface\AddOns\Searchlight\Media\Icon','## Version: @project-version@',
         '## Author: Searchlight contributors','## Notes: Spotlight-like NPC, item and object search with nearest-source waypoints.',
         '## OptionalDeps: TomTom','## X-License: GPL-3.0-only',
         '# TODO: once the CurseForge project exists, either add "## X-Curse-Project-ID: <id>" here',
         '# (and "## X-Wago-ID: <id>" for Wago) or set repository variables CF_PROJECT_ID / WAGO_PROJECT_ID.',
         'Init.lua']
    toc+=['Data/'+f for f in generated]+['Search.lua','Navigation.lua','Icons.lua','UI.lua','Core.lua','Bindings.xml']
    (ROOT/'Searchlight/Searchlight.toc').write_text('\n'.join(toc)+'\n')
    report={'source':lock['repository'],'revision':lock['revision'],'flavor':args.flavor,
            'counts':dict(sorted(counts.items())),'forever_zones':dict(forever_counts),'providers':snapshot['providers'],
            'files':{f'Data/{f}':(data_dir/f).stat().st_size for f in generated}}
    if overlay_info:report['overlay']=overlay_info
    (ROOT/'Searchlight/Data/coverage.json').write_text(json.dumps(report,indent=2,sort_keys=True)+'\n')
    (ROOT/'.build').mkdir(exist_ok=True)
    (ROOT/'.build/snapshot.json').write_text(json.dumps(snapshot))
    print(json.dumps(report,indent=2,sort_keys=True))

if __name__=='__main__':main()
