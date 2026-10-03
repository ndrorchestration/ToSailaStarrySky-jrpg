#!/usr/bin/env python3
"""
Generate TTS for every written line in every NPC's dialogue tree.
Output: tts/{npc_id}/{batch}/LINE_N.mp3  (1-indexed within batch)
Voice/pitch/rate chosen per NPC for character fit.
"""

import asyncio
import edge_tts
import os
import re
import html

# ── voice mapping per NPC (chosen for character fit among reachable voices) ──
# Reachable male voices in your env: en-US-GuyNeural, en-US-BrianNeural, en-US-EricNeural, en-US-ChristopherNeural
# Reachable female voices: en-US-AriaNeural, en-US-JennyNeural
# All others return NoAudioReceived in your environment.
NPC_VOICE = {
    'elder_farmer':      ('en-US-EricNeural', '-15%', '+0Hz'),   # weathered older male
    'engine_spirit':     ('en-US-AriaNeural', '+0%',  '+1Hz'),    # calm, slightly ethereal
    'child_prophet':     ('en-US-JennyNeural', '-15%', '+2Hz'),   # softer, higher — closest we have to a kid voice
    'corporate_salvager':('en-US-BrianNeural', '+0%',  '+0Hz'),   # crisp corporate
}

# ── dialogue data (mirrored from world.js so generation is self-contained) ──
DIALOGUE = {
    'elder_farmer': {
        'intro': [
            '"The Aureate Wake can fly. That is not the mystery. The mystery is why some systems answer like a ship, and some answer like they are waiting for a crew I have not yet found."',
            '"Captain Denith left me a vessel, a set of impossible notes, and the bad habit of telling the truth when a comforting lie would travel faster. So here it is: the dock shield is failing, the storm is early, and this ship may be our best shelter."',
            '"Lyra has been able to coax responses from the Wake that my instruments only half-record. Useful responses. Incomplete ones. Then you came aboard, and the panels started disagreeing with their own limits."',
            '"I do not need a miracle from you, Ender. I need honest hands, a clear head, and someone willing to stand beside Lyra while we find out what the Wake is actually hearing."',
            '"If the storm reaches the berths before the colony shield steadies, the ships beside us take the shear first. We either leave early, hold dock, or ask the Wake to do something it has only hinted it can do."',
        ],
        'class_ender': [
            '"Your hands are on the rigging. You are not a navigator or a captain, and that may be why the ship is listening differently. You fix from inside the problem."',
            '"The frequencies settle when you cross the deck. Not enough for a doctrine. Enough for me to notice."',
            '"Do not mistake this for destiny. Ships do not need worship. They need crews who can hear one another under pressure."',
        ],
        'generic_follow': [
            '"Check the dock reports, then the shield console. Meaning can wait until the shielding holds."',
        ],
    },
    'engine_spirit': {
        'intro': [
            '"Primary lift: nominal. Solar intake: nominal. Shield lattice: partial. Crew resonance: unstable, increasing."',
            '"Captain authority recognized. Lyra-pattern recognized. New harmonic variable recognized. Cross-response exceeds prior thresholds."',
            '"Storm vectors converging on Wake Dock. Colony shield cycling below reliable tolerance. Adjacent berth stress rising."',
            '"Directional projection routine available. Warning: lateral shield faces will weaken while forward umbrella is extended."',
            '"Request: captain confirmation, reach stabilization, stranger-current consent."',
        ],
        'class_ender': [
            '"Ender-pattern produces nonstandard agreement across helm, reach, and hull. Diagnostic category unavailable."',
            '"Your adjustments do not add power. They reduce disagreement."',
            '"If command is given, shield geometry can widen beyond the Wake\'s own silhouette. Survival probability improves for adjacent berths."',
        ],
        'generic_follow': [
            '"Awaiting stable chord."',
        ],
    },
    'child_prophet': {
        'intro': [
            '"The ship is not asleep. People keep saying that because it makes them feel better. It is awake in the way a hand is awake before it knows what it is reaching for."',
            '"I can hear the shield lattice when it tries to open. It gets lonely halfway through."',
            '"When Ionia gives an order, the Wake stands up straighter. When you touch the console, Ender, it stops bracing for the wrong kind of answer."',
            '"The storm has teeth on the front edge. The little ships beside us are going to feel it first."',
            '"If the Wake can make an umbrella, we should let it. I know that sounds impossible. It also sounds kind."',
        ],
        'class_ender': [
            '"You hear it too, just lower than I do. Like something green under a floorboard."',
            '"Ionia is the helm. I am the reach. You are... I do not know yet. The place where the answer says yes, maybe."',
            '"Do not tell the ship what it is. Ask what it can hold."',
        ],
        'generic_follow': [
            '"The storm is closer. The ship knows. I think it wants us to notice the same thing at the same time."',
        ],
    },
    'corporate_salvager': {
        'intro': [
            '"Verrick, harbor shield office. If you are with the Wake, tell your captain the colony shield is cycling dirty and I am out of polite ways to describe bad math."',
            '"Procedure says every vessel clears dock before stormfall unless its berth shield is certified. Your berth shield is not certified. Your ship, however, keeps returning numbers my board insists are impossible."',
            '"The two craft beside you are lighter than they should be and crewed by people who waited too long to undock. If shear hits from the east, they peel before you do."',
            '"I do not care about legends. I care about vectors, hull stress, and whether somebody is about to turn a solvable weather event into paperwork with names on it."',
            '"So make a choice: launch before the front arrives, stay and stabilize your own berth, or prove the Wake can throw a shield wide without tearing herself open."',
        ],
        'class_corporate': [
            '"You understand systems, so here is the system: authority hates uncertainty, weather exploits delay, and captains hate being told both at once."',
            '"If you can give me a stable projection number, I can keep the dock from ordering you out."',
            '"A clean evacuation is a victory. A heroic mess is still a mess."',
        ],
        'class_ender': [
            '"You are the new variable? Good. Variables are annoying, but sometimes they are where the answer is hiding."',
            '"If your ledger can track shield draw, track it now. I need proof before the dock board panics."',
            '"Do not sell me poetry, Ender. Give me a number I can defend and a reason not to clear this berth."',
        ],
        'generic_follow': [
            '"My hold order stands until the stormfront crosses the outer pylons. After that, math gets rude."',
        ],
    },
}

OUT = 'tts'


async def clean_for_tts(text: str) -> str:
    """Strip surrounding quotes, escape HTML entities, replace unicode dashes with ASCII for TTS clarity."""
    t = html.unescape(text)
    # strip surrounding single or double quotes (world.js wraps lines in '...')
    t = t.strip()
    if (t.startswith('"') and t.endswith('"')) or (t.startswith("'") and t.endswith("'")):
        t = t[1:-1]
    # em-dash and en-dash → " - " (edge-tts reads them better as pause)
    t = t.replace('\u2014', ' - ').replace('\u2013', ' - ')
    # smart apostrophe → straight
    t = t.replace('\u2019', "'").replace('\u2018', "'")
    return t.strip()


async def gen_line(npc_id: str, batch: str, idx: int, text: str,
                   voice: str, rate: str, pitch: str) -> str:
    clean = await clean_for_tts(text)  # sync actually, but keep for consistency
    fname = f'{OUT}/{npc_id}/{batch}/{idx:02d}.mp3'
    comm = edge_tts.Communicate(clean, voice, rate=rate, pitch=pitch)
    await comm.save(fname)
    return fname


async def main():
    total = 0
    for npc_id, batches in DIALOGUE.items():
        voice, rate, pitch = NPC_VOICE[npc_id]
        for batch, lines in batches.items():
            npc_dir = f'{OUT}/{npc_id}/{batch}'
            os.makedirs(npc_dir, exist_ok=True)
            for i, line in enumerate(lines, start=1):
                out_path = f'{npc_dir}/{i:02d}.mp3'
                if os.path.exists(out_path) and os.path.getsize(out_path) > 4096:
                    print(f'  skip {out_path}')
                    total += 1
                    continue
                try:
                    path = await gen_line(npc_id, batch, i, line, voice, rate, pitch)
                    print(f'  OK   {path}  ({os.path.getsize(path)} bytes)')
                    total += 1
                except Exception as e:
                    print(f'  FAIL {npc_id}/{batch}/{i:02d}: {type(e).__name__} {e}')
    print(f'\nTotal lines generated: {total}')


if __name__ == '__main__':
    asyncio.run(main())
