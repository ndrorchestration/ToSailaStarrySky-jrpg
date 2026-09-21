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
    'elder_farmer':      ('en-US-JennyNeural', '+0%', '-1Hz'),   # Ionia — adult captain
    'engine_spirit':     ('en-US-AriaNeural', '+0%',  '+1Hz'),    # calm, slightly ethereal
    'child_prophet':     ('en-US-AriaNeural', '+0%', '+0Hz'),    # Lyra — adult dream/frequency-sensitive voice
    'corporate_salvager':('en-US-BrianNeural', '+0%',  '+0Hz'),   # crisp corporate
}

# ── dialogue data (mirrored from world.js so generation is self-contained) ──
DIALOGUE = {
    'elder_farmer': {
        'intro': [
            '"The Wake doesn\'t sing like it used to. You hear it? The harmonics are slipping. Ten years under Captain Denith taught me this ship\'s rhythms, and now the Core is forgetting its own song."',
            '"You\'re Ender. Deckhand. Engineer-in-training. You carry a wrench, a passport, and a decision you haven\'t admitted you have to make. I know the shape of it."',
            '"I\'ve flown the Wake through the copper storms, through the blight-winds, through the years when the sky-lanes were closing one by one. I\'ve never seen the core drift like this. Not in all my watches."',
            'The crops on the lower decks taste like copper dust. The solar array still hums. The people are tired but alive. That\'s a lot. It\'s not enough, but it\'s a lot.',
            '"You stand on the edge of something big, Ender. I can smell it on you. Something that wants to be decided."',
        ],
        'class_ender': [
            '"Ah. Deckhand\'s hands. You\'ve been in the wiring. You know what happens when a core starts to slip — it doesn\'t stop. It falls."',
            'Ionia spent ten years learning the Wake under Captain Denith. She knows the old route records well enough to recognize when the Core is behaving wrong, and now every impossible problem belongs to her as captain. She trusts Ender as a new crewmate whose Rift Scholar instincts may matter here, but she doesn\'t pretend the decision is easy.',
            'You\'ve walked the ship and you\'ve seen what\'s waiting. Ionia\'s bulkhead is empty except for her watch log. Lyra\'s been listening to the frequencies nobody else can hear. Verrick has a contract on the core and a real argument about what happens to people when the sky-lanes close. You get to decide what the Wake becomes. That\'s not a small thing.',
        ],
        'generic_follow': [
            '"Take your time. The core will keep singing. It always does."',
        ],
    },
    'engine_spirit': {
        'intro': [
            '"I am the song that kept the Wake aloft. The hull remembers every sky-lane I ever opened."',
            '"You stand on a ship that is forgetting how to fly. The harmonics are slipping. I feel it in my frequencies."',
            '"Three hazards on the way to my chamber. Sky-predator first — it hunts heat signatures. Harmonic shear next — it strips the grace from men who haven\'t earned it. Then the corporate intercept — they want to box me up and take me to a city that doesn\'t dream."',
            '"I remember the first sky-lane. The song was new then — bright, almost painful. They sang the Wake upward through steel and light. The people didn\'t understand — they thought gravity was a law, not a direction."',
            '"You feel that hum in your chest? That\'s me, Ender. I\'ve been humming since before the first sky-lane opened. I\'m almost done — or almost beginning. One of those."',
        ],
        'class_ender': [
            '"Your wrench — you made it yourself from a shard of the first core. I know. I lit that shard."',
            'Your touch — I feel it reaching for me',
            '"When you reach the choice, Ender — listen to the frequencies. They remember which way the Wake should fly."',
        ],
        'generic_follow': [
            '"The frequencies hum. Follow them. But choose before they fade — the window is narrow."',
        ],
    },
    'child_prophet': {
        'intro': [
            '"I hear the sky coming undone. Not falling — unspooling. Like a spool of thread the world was wrapped in, and something pulled the thread."',
            '"There\'s a man in a grey coat. He says he\'s here to buy the core. He wants to put it in a box and take it to a city that doesn\'t dream."',
            '"Captain Ionia says you\'re the one who can hear the core. Can you? Or do you just pretend so people will leave you alone?"',
            '"I\'m not very big, but my dreams are. Sometimes they\'re bigger than this ship. Sometimes they\'re bigger than the sky. Do you believe in dreams that big?"',
            '"The core hums in my dreams every night now. It has a voice. It sounds like someone singing underwater. I think it wants to be heard. I think it\'s been waiting for someone who knows how to listen."',
        ],
        'class_ender': [
            '"Your goggles — you see more than light, don\'t you? You see the frequencies between things. I dreamed you would come. The dream was green."',
            '"If you sell the core — the Wake becomes a box. If you sing it down — the ship falls, but the people scatter. If you drive it up — we find out what\'s above the world."',
            '"I\'m just a kid. But I know which choice feels like the right kind of wrong."',
        ],
        'generic_follow': [
            '"I\'ll keep dreaming. Tell me what happens when you decide."',
        ],
    },
    'corporate_salvager': {
        'intro': [
            '"Verrick. Copper Syndicate Acquisition. You the deckhand? Good — we\'ve got a contract on that core in the Aureate Wake. Overnight run, clean transfer, full credential."',
            '"Don\'t look so sour. The core\'s property of the Syndicate collective now — filed, certified, and insured. You don\'t believe in paperwork? Paperwork is the only thing that\'s ever held a falling world together."',
            '"I\'m tired of watching sky-lanes close with nothing to show for it but graves. If this acquisition means someone gets to live somewhere that isn\'t falling — I can live with the paperwork."',
        ],
        'class_corporate': [
            '"You\'re one of us. Deckhand with a syndicate affiliation — I can smell the contract on you. Good. We\'ll need someone who understands the core\'s harmonic signature. Your Uncover Truth ability — we\'ll use it on the core before acquisition."',
            '"Here\'s the deal: we acquire the core, we pay you in solar credits, and everyone on this ship gets evacuation passage. The Wake falls — yes — but the people don\'t. That\'s a win. Your dreamer friend will scream about the sky, but the sky doesn\'t feed anyone."',
            '"If you go with us — Path B — you get scrap, aether, and a Syndicate credential that opens every port in the lanes. If you betray us — well. The Syndicate has provisions for traitors. Don\'t make me use them."',
        ],
        'class_ender': [
            '"Deckhand. I\'ve seen your kind before. You see too much. That\'s a liability in my trade. But it\'s also an asset — if you\'re willing to sell it."',
            '"Your Mycelial Ledger ability — we\'d like to borrow that. Track the core\'s harmonic output before we acquire. You get a cut. 15% of the salvage value, paid in scrap."',
            '"The choice is yours, Ender. The Syndicate offers you a place in the world that\'s coming. The dream world, the falling world — they\'re both going. What\'s your next contract?"',
        ],
        'generic_follow': [
            '"My offer stands until the core stabilizes. After that — it\'s either your way or ours. And ours has a lot more lawyers."',
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
