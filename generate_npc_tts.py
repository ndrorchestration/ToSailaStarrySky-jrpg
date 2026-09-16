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
            "The soil here remembers the fall better than we do. Every stone, every root \u2014 they all fell once, and now they refuse to.",
            "You got that look. Rift Scholar, yeah? The dream tells you things before they happen. What did it show you tonight?",
        ],
        'class_ender': [
            "Ah \u2014 green tubes on your back, mycelial marks on your skin. You traced the ley lines yourself, didn't you?",
            "The Unfinished Song ship is drifting east. The engine that lifted this whole archipelago is inside it. If it wakes \u2014 or if it dies \u2014 that decides which way gravity points tomorrow.",
            "I've been waiting for someone who can hear the engine. The child prophet's been screaming about it for weeks.",
        ],
        'generic_follow': [
            "Take your time. The crops won't bolt. But the sky might \u2014 it has a habit of doing that.",
        ],
    },
    'engine_spirit': {
        'intro': [
            "I am the song that never finished itself. The hull remembers every note it never got to sing.",
            "You stand on a world that fell up. The engine that did that is inside this ship \u2014 and it is waking. I feel it in my nav-lines.",
            "Three hazards on the crossing. Wind shear first \u2014 it strips the grace from men who haven't earned it. Then aether leak \u2014 be careful where you step. Then the sky-predator \u2014 it hunts heat signatures. Keep your aether low and your will higher.",
        ],
        'class_ender': [
            "Your staff \u2014 a cyan crystal, no wood. You made it yourself from a fallen shard of the first engine. I know. I lit that shard.",
            "The engine and your dream are wired together. Your Shared Dream ability \u2014 I can hear it from here. It reaches into the hull. Use it carefully. It can either steady the engine or tear it open.",
            "When you reach the choice, Scholar \u2014 listen to the nav-lines. They remember which way the world should fall.",
        ],
        'generic_follow': [
            "The nav-lines hum. Follow them. But choose before the hum fades \u2014 the choice window is narrow.",
        ],
    },
    'child_prophet': {
        'intro': [
            "I dreamed the sky came undone. Not fell \u2014 unwound. Like a spool of thread the world was wrapped in, and something pulled the thread.",
            "There's a man in a grey coat. He says he's here to buy the engine. He wants to put it in a box and take it to a city that doesn't dream.",
            "The elder farmer says you're the one who can hear the engine. Can you? Or do you just pretend so people will leave you alone?",
        ],
        'class_ender': [
            "Your goggles \u2014 you see more than light, don't you? You see the lines between things. I dreamed you would come. The dream was green.",
            "If you destroy the engine \u2014 the island falls. All of it. But the sky stays. If you preserve it \u2014 the engine goes with the ship, and some of us go too. If you let it ascend \u2014 we find out what's above.",
            "I'm just a kid. But I know which choice feels like the right kind of wrong.",
        ],
        'generic_follow': [
            "I'll keep dreaming. Tell me what happens when you decide.",
        ],
    },
    'corporate_salvager': {
        'intro': [
            "Holt. Meridian Salvage and Recovery. You the local guide? Good \u2014 we've got a contract on that engine in the Unfinished Song. Overnight run, clean transfer, full credential.",
            "Don't look so sour. The engine's property of the Meridian collective now \u2014 filed, certified, and insured. You don't believe in paperwork? Paperwork is the only thing that's ever held a falling world together.",
        ],
        'class_corporate': [
            "You're one of us. Rift Scholar with a corporate affiliation \u2014 I can smell the contract on you. Good. We'll need someone who understands the engine's resonance signature. Your Uncover Truth ability \u2014 we'll use it on the engine before extraction.",
            "Here's the deal: we extract the engine, we pay you in aether credits, and everyone on this island gets evacuation passage. The island falls \u2014 yes \u2014 but the people don't. That's a win. Your prophet friend will scream about the sky, but the sky doesn't feed anyone.",
            "If you go with us \u2014 Path B \u2014 you get scrap, aether, and a Meridian credential that opens every port in the arch. If you betray us \u2014 well. Meridian has provisions for traitors. Don't make me use them.",
        ],
        'class_ender': [
            "Rift Scholar. I've seen your kind before. You see too much. That's a liability in my trade. But it's also an asset \u2014 if you're willing to sell it.",
            "Your Mycelial Ledger ability \u2014 we'd like to borrow that. Track the engine's aether output before we extract. You get a cut. 15% of the salvage value, paid in scrap.",
            "The choice is yours, Scholar. Meridian offers you a place in the world that's coming. The dream world, the falling world \u2014 they're both going. What's your next contract?",
        ],
        'generic_follow': [
            "My offer stands until the engine stabilises. After that \u2014 it's either your way or ours. And ours has a lot more lawyers.",
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
