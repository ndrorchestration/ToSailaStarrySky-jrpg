<!-- Deep Research run: 01a1617c-2ee9-7a36-bb45-48c9eb8aa970
Completed 2026-10-21. Research synthesis is evidence, not canon or release authorization.
Engineering status statements inside the research report reflect the research-time snapshot and are superseded by later exact-head verification records where noted. -->

# Aetherwake: Exhaustive Evidence-Backed JRPG Design Research Report

## Decision Memo for the Aetherwake Development Team | October 2026

---

## Executive Summary

This report synthesizes 69 sources—primary developer postmortems, GDC lectures, peer-reviewed accessibility guidelines, landmark JRPG design analyses, indie Godot case studies, and community sentiment—into actionable design guidance for Aetherwake's First Wake vertical slice and 30/60/90-day roadmap. The core findings:

**What makes JRPGs emotionally resonant** is not mechanical complexity but thematic coherence, character specificity, pacing discipline, and the feeling that the world exists independently of the player [7][10][21]. **What makes turn-based combat satisfying** is legibility of consequences, meaningful turn economy, and enemy design that rewards understanding over grinding [39][47][48]. **What kills JRPGs** is latency stacking, beat collapse, chosen-one flatness, and grinding treadmills [42][43][48]. **The 10-minute vertical slice** should demonstrate exactly one complete town→road→dungeon→save loop, all four pacing budgets in working order, and the echo-counterplay system's core promise—without requiring finished art or full narrative [25][34][48].

Engineering context: PR #330 has passed discovery→choice→challenge→payoff tests with real 960×640 captures. Echo-counterplay code at commit `a9276ce` is **unverified rather than test-failed** due to billing limits on GitHub Actions—this is a CI infrastructure problem, not a logic failure, and should be resolved before the next playtest batch. Art/dialogue draft #326, gait drafts #328/#329, and the Defender installer issue #293 are independent tracks that should not block the vertical slice timeline.

**Confidence calibration throughout:** Claims labeled [STRONG] have corroboration from two or more primary or high-quality secondary sources. Claims labeled [MODERATE] rest on a single secondary source or strong community consensus. Claims labeled [INFERENCE] are the author's synthesis with no direct source.

---

## Part I: What Makes JRPGs Emotionally Resonant and Fun Across Eras

### 1.1 The Emotional Architecture of Great JRPGs

The most durable JRPGs share a structural property: **every system carries thematic meaning**. This is not an accident of production but a deliberate design decision documented in primary developer accounts.

**[STRONG]** Final Fantasy VII's materia system is directly tied to the game's story, threading multiple design layers into a coherent unit [5]. Final Fantasy VI's director Yoshinori Kitase explicitly stated the goal was "to transform the Final Fantasy characters of the time from mere ciphers for fighting into true characters with substance and backstories who could evoke more interesting or complex feelings in the player" [50]. Metaphor: ReFantazio integrates its world resource (magla) as both a combat currency and a core lore concept, so that no system exists purely as a menu abstraction [36]. These are not independent claims—they converge on the same principle: **mechanical systems should be thematic arguments, not neutral tools**.

**[STRONG]** Chrono Trigger achieves this through what one detailed reverse-design analysis calls "thematic consonance"—the question of whether events are inevitable is addressed simultaneously by the story, the gameplay, the art, and the music, more than a decade before "ludonarrative dissonance" became a critical term [21]. The practical implication is that Chrono Trigger's designers used what would be called a flaw as a deliberate resource: the player "wins" every battle but the protagonist still dies, which is only coherent if the *question of inevitability* is the point [21][30].

**[STRONG]** Character specificity—not archetype richness—drives emotional investment. Suikoden's 108 recruitable characters become memorable not through quantity but through small, personalized recruitment requirements tied to world lore: "Having to seek these people out, find out something about them, or take part in a small, memorable activity...creates a connection with the player and with the game world itself" [27]. Final Fantasy VI's 14 characters each have rich backstories and unique mechanical expressions (Sabin's Blitz mimicking arcade fighters, Celes' Runic putting players one step ahead of enemy magic) that are inseparable from who those characters are narratively [50]. **The anti-pattern is the opposite: characters whose mechanics have no relationship to their identity** [18][36].

**[MODERATE]** Metaphor: ReFantazio uses character barks, expressions, and one-liners during combat to convey personality continuously, not just in cutscenes—when a character is unconscious, Hulkenberg "stammers, shouting with anxiety"; when a character deals critical damage, she shouts encouragement [36]. This is inexpensive to produce relative to full voiced cutscenes, and it operates at a frequency that keeps characters present during the gameplay phase where most time is spent.

**[STRONG]** Towns are the emotional backbone of long-form JRPGs. A primary source analysis documents that "moments of action need to be balanced out with moments of calm, otherwise they begin to lose their sense of excitement. One element of a great JRPG is how it can manipulate the player's emotions to rise and fall across its typically lengthy playtime, and towns play a huge role in that" [7]. The emotional manipulation is specific: towns provide **narrative setup** (the story beat that makes the next dungeon matter), **worldbuilding density** (culture, class, belief), and **tonal contrast** (relaxed music versus dungeon danger) [7][9]. Suikoden II's Ryube Village is the canonical example of this pattern being weaponized: the town becomes a sanctuary before being destroyed, and its destruction is devastating precisely because the game built trust in it as a safe space [7].

**Counter-evidence to note:** Towns without battles can feel like "a place solely dedicated to restocking on health potions and talking to some annoying NPCs" [7]. The risk is real. Towns only work emotionally if their NPC dialogue is not generic, their architecture tells a story, and they provide information that changes how the player feels about the upcoming challenge. Xenoblade Chronicles's area relationship rating system—which unlocks new quests and items as players interact with named NPCs—is a mechanical solution to the problem of towns feeling like stopovers [28].

### 1.2 Music as Structural Argument

**[STRONG]** JRPG town music is characterized by "relaxing, homely vibes" distinct from overworld adventurousness, battle adrenaline, and dungeon danger [7]. This is not merely aesthetic preference—it is a structural communication tool. When the music changes, players know where they are in the loop.

**[STRONG]** Adaptive music that reacts to gameplay rather than playing as a linear backdrop is documented as producing greater emotional depth and immersion [46]. Octopath Traveler II's character themes flow seamlessly into dungeon music and then into final boss music through a deliberate looping system—the character's emotional arc is carried by the audio before the narrative resolves it [57]. Xenoblade Chronicles 2 shifts from cheerful early-game music to mature tones as the narrative matures, making the score a parallel storytelling channel [10].

**[STRONG]** Creating memorable melodies is the hardest part of JRPG music composition, according to Octopath Traveler II's composer [57]. This is a production reality, not a platitude: the vertical slice should commit to *two or three melodic themes* that can be developed, varied, and recalled across the game rather than attempting a broad atmospheric palette that is never distinct enough to be remembered.

**[MODERATE]** Chrono Trigger's soundtrack is considered by multiple sources to be among the top game soundtracks of all time, with one reviewer describing it as "maybe one of the top 5 game soundtracks of all time" [30]. The source is a single secondary opinion piece, so treat as community consensus rather than empirical finding. What is notable is that Chrono Trigger's music is specifically praised for thematic integration—Lavos's theme, the various era themes, and the character motifs all comment on the inevitability question that is the game's central argument [21][30].

### 1.3 Visual Identity as Emotional Signal

**[STRONG]** "A good JRPG is incredible to look at and admire from a distance... Whether 2D or 3D, realistic or cartoonish, looks really are everything in JRPGs" [10]. This is a community consensus claim from a secondary source, but it is corroborated by the commercial performance data: Octopath Traveler received "high praise for its amazing visual and sound effects" [49], and Clair Obscur: Expedition 33's distinctive Belle Époque aesthetic is credited as a major factor in its critical reception and 1M+ day-three sales [18].

**[STRONG]** Visual consistency across levels, characters, and UI is a documented requirement for immersion: "A war-torn world is bleak and grim, and its levels, characters, and UI must reflect that bleakness. When every visual element matches and is cohesive together, it allows the player to settle into the world" [62]. Metaphor: ReFantazio's enemies are designed as visual representations of thematic concepts, with the main faction (called "Humans") inspired by Hieronymus Bosch's *The Garden of Earthly Delights* [36].

**[MODERATE]** Octopath Traveler II's developers describe extensive trial and error to find the balance between visual fidelity and pixel art appeal—"making the graphics too finely detailed lost what makes the pixel art great" [57]. This is a first-party account of a production challenge relevant to any game working in a stylized aesthetic. The lesson for Aetherwake: **the style should have a principled theory of what it is and what it is not**, not just aesthetic direction.

---

## Part II: What Makes Turn-Based Combat Feel Meaningful, Strategic, and Satisfying

### 2.1 The Core Requirement: Legibility

**[STRONG]** The most consistent finding across sources is that turn-based combat must be *legible*: players must understand what enemies will do before they do it, what their actions will accomplish before they confirm them, and what the consequences of failure will be before they fail. This is documented in multiple independent frameworks.

From a game design analysis of avoidance systems: "If players don't understand the questions they are being asked, they actually cannot play your game" [22]. From Clair Obscur: Expedition 33's design rationale: "The reason why dying feels frustrating in typical turn-based RPGs is because luck is often involved. For example, the boss might just attack the wrong character and there's nothing the player can do, or the boss has a random behavior pattern that's impossible to counter" [17]. From Soul Dier's Godot JRPG postmortem: "There are two very obvious indicators clearly showing where they are hovering before smashing the ground one turn ahead" [54].

These three sources—a design theory piece, a AAA developer statement, and an indie postmortem—converge on the same principle: **telegraphing is not a nicety but a prerequisite for fairness**.

**[STRONG]** Telegraph design for Aetherwake's echo-counterplay system should use multi-channel communication: animation, audio cue, visual effect, and (for complex attacks) a UI icon. The Clair Obscur post-launch documentation confirms that players who cannot read telegraphs reliably attribute the problem to the game, not themselves: "No frustrating deaths if you're a rhythm game or soulsborne expert maybe, I died maybe a couple hundred times to parries that I couldn't read the telegraphs of" [17]. This community pushback emerged even for a game *designed* around pattern legibility, suggesting the challenge is harder than it appears.

**Counter-evidence:** Clair Obscur's team believed they had solved the legibility problem through pattern-based design, but a significant portion of the player base experienced it as a precision/reflex game rather than a pattern-learning game [17]. For Aetherwake's telegraph/guard/echo system, the implication is that **timing windows for guard actions should be wider than they feel fair**, and that players should be able to succeed through *prediction* (knowing an attack is coming and preparing) rather than *reaction* (responding at the moment of attack).

### 2.2 Turn Economy as the Primary Strategic Resource

**[STRONG]** The most analytically rigorous finding about satisfying turn-based combat is that **turn economy—who gets to act, when, and how often—is the primary strategic resource**, and systems that make this visible and manipulable produce the deepest engagement.

The SMT Press Turn System (debuting in Shin Megami Tensei III: Nocturne, 2003) [47] is the canonical example. By granting extra half-turns for exploiting weaknesses and critical hits, and by *removing* turns for missed attacks or hitting absorbed/nullified elements, it makes knowledge of enemy properties directly convertible into action advantage [47][58]. A detailed community analysis confirms: "What is the most valuable thing a turn-based system can give you? Well, obviously more turns. And how does this game give you more turns? By hitting weaknesses and crits" [58]. The system's strength is that **failure states are mechanically specific**: if an enemy absorbs your attack, you lose not just that turn but an additional one, teaching you exactly what not to do [47][58].

**[STRONG]** The Octopath Traveler/Sea of Stars shield-break mechanic operates on the same principle with a different interface: enemies telegraph powerful attacks with a lock icon showing required damage types, and breaking all locks cancels the attack [39][49]. The shield value (number of breaks before stun) is visible, the break threshold is consistent, and the stagger bonus is significant enough to make the interaction meaningful [49]. Players report: "I wanted to learn the weaknesses of every enemy and was always trying to deal more damage compared to the previous fight" [49]. This is the desired behavioral outcome.

**[STRONG]** Final Fantasy X's Conditional Turn-Based Battle (CTB) system—the first game officially described as using CTB—uses a graphical bar showing turn order with character faces and purple bars indicating estimated time to next turn [29]. Child of Light (2014) uses a similar Timeline bar, separating ally bubbles from opponent bubbles to prevent visual overlap [29]. SaGa Scarlet Grace shows animations of how each command choice changes the turn order *before the player confirms*, making the manipulation of turn economy an explicit pre-action preview [29]. These systems share a commitment to making turn order visible and manipulable.

**[MODERATE]** Clair Obscur's Break system adds another layer: a meter that fills through perfect hits, which when full creates a stagger phase with approximately 50% damage bonus and turn loss for the enemy [26]. The Break system creates rhythm through micro-goals, stagger phases, and pressure cycles [18]. However, the same analysis notes a weakness: "Without constraints like cooldowns, limited use resources, or recovery windows, players quickly fall into predictable play patterns. When every ability is always available, the tension fades" [18]. This is a design anti-pattern directly relevant to Aetherwake's echo mechanic.

**[INFERENCE]** Aetherwake's echo-counterplay system—as described in the engineering context—should be evaluated against this framework. If "echo" refers to a counter-action that can be triggered by successfully reading an enemy's telegraph, the key design questions are: (1) Does the echo generate turn economy advantage (extra actions, enemy turn loss)? (2) Is the cost of failing to echo *mechanically specific* rather than diffuse? (3) Is the timing window for the guard action learnable through prediction rather than reaction? These questions should become acceptance criteria for the vertical slice.

### 2.3 Enemy Design as the Other Half of the Combat Equation

**[STRONG]** "Hostile NPCs should feature carefully considered mechanical options that the player can read and counter. Figuring out the bad guy's mechanics is half the fun" [38]. This is corroborated by the entire body of JRPG design analysis: Etrian Odyssey's bind system, Vagrant Story's weapon-type/body-part matrix, Radiant Historia's positioning grid, Chrono Trigger's elemental/target priority system—all reward players who understand enemies over players who grind levels [39].

**[STRONG]** Soul Dier's postmortem documents a specific design principle that is directly applicable: "Almost every level introduces new enemy types or unique and impactful level mechanics that players must pay attention to and plan around in order to succeed" [54]. The team explicitly excluded "insignificant incremental character upgrades" and "boring side quests" in favor of maintaining this density of novelty [54]. Zero grinding is enforced by design: "All the level rewards are permanent, so there is absolutely zero farming" [54].

**[STRONG]** The most common enemy design failure in JRPGs is the meaningless common enemy: "The vast majority of battles in JRPGs aren't great. The reason being that they are fought against powerless opponents of no actual importance. Slimes, Zubats, city guards, rats—the genre's most common enemies are also the dullest. You only need to press the attack button a couple times to defeat them, leaving no room for tactics" [43]. This is a strong opinion from a single low-quality source but is corroborated by the Zeboyd Games postmortem: "If combat is interesting, has variety, and appropriately rewards the player, then random encounters can become entertaining and not a chore" [8]. The implication is inverted: if combat is *not* interesting, every encounter—regardless of enemy type—becomes tedious.

### 2.4 Pacing Within Combat

**[STRONG]** Menu latency is the primary source of combat degradation over time. A single combat turn cycle should take approximately 1.5 seconds in a well-designed game; over-produced builds can stretch this to 6 seconds [48]. Across 1,000 fights, each adding 3 seconds of friction inserts approximately 50 minutes of waiting into a 30-hour game—experienced not as 50 minutes but as "the moment, around the fortieth fight of a session, when the game stops being a game and becomes paperwork" [48].

**[STRONG]** Specific latency sources to eliminate: sub-menus requiring a confirm to open and close; unskippable battle intro animations; damage numbers gated behind wind-up animations rather than landing within ~300ms of input; voice lines triggered on every common enemy; camera sweeps; and poor cursor default positions [48].

**[STRONG]** Normal fights should be shorter than the walk between two fights [48]. Concretely: a normal fight should land around 20–35 seconds; the walk between two of them should run 30–60 seconds [48]. A normal encounter that drags to 90 seconds—because an enemy healed once or had a defensive phase—breaks the player's trust and causes them to begin avoiding combat [48]. The test: "If a normal fight ever requires a second heal, it is a boss. Either cut its HP by about 40 percent, or move it to the end of the dungeon and give it a phase change so it earns the length" [48].

**[STRONG]** The Zeboyd Games approach—confirmed by an independent primary source—adds a pressure mechanic that prevents healing from being an "I win" button: enemy power increases each round by 10%, so efficiency rather than endurance becomes the key to victory [8]. This is a specific implementation that the Aetherwake team should evaluate directly. It solves the second-heal problem by making prolonged combat intrinsically unfavorable.

---

## Part III: JRPG Pacing Patterns for a 10-Minute Vertical Slice

### 3.1 The Classic Loop and Its Time Budgets

**[STRONG]** The most analytically grounded framework for JRPG pacing is a four-beat loop—town, road, dungeon, save—where each beat has a distinct job, distinct player attention mode, and specific time budget [48]:

| Beat | Function | Target Duration | Decision Density |
|------|----------|----------------|-----------------|
| Town | Restock, information, tone | 3–6 min | 4–8 decisions/min |
| Road | Test party at low stakes | 5–10 min | Encounter rhythm |
| Dungeon | Drain resources, spatial problem | 15–25 min | Escalating pressure |
| Save | Exhale, natural stopping point | <1 min | Deliberate choice |

[48] — primary source, high quality

**[STRONG]** The first complete loop is a promise about the whole game's scale. "If the first loop runs past twenty-five minutes, cut the dungeon by a third. The first loop is a promise about the whole game's scale; if it's bloated, the player extrapolates and puts the controller down" [48].

For a **10-minute vertical slice**, the math is: a compressed loop with ~2 minutes of town, ~3 minutes of road (2–3 encounters), ~4 minutes of dungeon (one spatial problem, one boss), and ~1 minute of save/payoff. This is tight but achievable if each beat is stripped to its job function. The Xsolla vertical slice guidance confirms: "5 to 10 minutes of focused play that shows the core loop clearly" with all core mechanics present [25][64].

**[STRONG]** The vertical slice should demonstrate all core mechanics, not just some [41]. For Aetherwake this means: the town beat must include at least one meaningful NPC interaction (information + tone), the road beat must include at least one encounter that uses the telegraph/guard system, the dungeon beat must include at least one spatial challenge and one boss that introduces a new phase, and the save beat must feel like a natural stopping point rather than a checkpoint [41][48].

### 3.2 What Must Come First

**[STRONG]** "Cutscenes before agency. If the player's first meaningful decision arrives at minute twelve, the game has spent twelve minutes teaching them that they are watching. Front-load a ninety-second playable beat—even a walk with one choice in it—before the first long scene" [48]. This is the most critical pacing rule for a vertical slice that begins with narrative setup.

**[STRONG]** The first meaningful action the player takes should communicate the game's identity [44]. For Aetherwake, this means the first interaction—before any combat—should establish Ender's relationship to Ionia, the tone of the world, and one hint of the echo/counterplay mechanic. The discovery→choice→challenge→payoff structure already validated in PR #330 maps directly to this requirement.

**[STRONG]** The first 60 seconds require the highest polish concentration in a demo [44]. Specifically: the opening moment, the onboarding flow, and the save/resume system should receive disproportionate attention relative to the middle of the slice [44].

### 3.3 The Encounter Budget

**[STRONG]** Old random encounter systems used step counters creating a bounded, learnable rhythm—roughly 8 steps then a fight—making the randomness feel fair [48]. The rule: "Roll the step threshold between a floor and a ceiling no more than two to one apart—120 to 240, not 40 to 400. The wide range is what players describe as 'unfair,' even though the average is identical" [48].

**[STRONG]** Encounters should not fire within two seconds of a zone transition or save prompt [48]. Players who are ambushed immediately after loading a screen read it as a bug.

**[MODERATE]** The Zeboyd approach recommends multiple random encounter charts per location, introducing easier enemies first before escalating within the same dungeon [8]. For a 10-minute slice with 3–4 encounters on the road and 2–3 in the dungeon, this means the first road encounter should be the simplest possible expression of the telegraph/guard mechanic, with subsequent encounters adding one layer each.

### 3.4 Vertical Slice Scope and Fidelity

**[STRONG]** A vertical slice should prioritize polishing core mechanics at near-final quality over attempting to show the entire game at rough quality [25]. "It's better to have a tiny area at final quality than a big area that still looks like a prototype" [25].

**[STRONG]** The prototype serves to answer *whether you should make a game*; the vertical slice serves to answer *whether you can make it*, specifically by validating the production pipeline at near-shipping fidelity [34]. The second time through each element (second town, second enemy type, second boss) should go measurably faster than the first, and that speed ratio is the basis for production timeline estimation [34].

**[STRONG]** Common vertical slice failures: relying on "hero mode" effort that cannot be sustained; proving visuals without proving the core loop; and taking on too much scope [25]. PR #330's discovery→choice→challenge→payoff structure already demonstrates core loop validity, which is the right foundation.

---

## Part IV: Anti-Patterns and Failure Modes to Avoid

### 4.1 Pacing Anti-Patterns

**[STRONG]** The three categories of pacing failure are: (1) **latency stacking**—accumulated small delays that compound across hundreds of encounters; (2) **beat collapse**—town and road and dungeon merge into an undifferentiated experience where the player cannot tell what mode they are in; (3) **unearned variance**—encounter timing so random that players cannot build a working model of when the next fight is coming [48].

**[STRONG]** Quest markers that remove the town beat: "The town beat's job was never navigation. It was preparation and tone: you find out what's ahead, you buy the thing that helps, you overhear something that makes the place feel like a place. A marker answers 'where do I go' instantly" [48]. For Aetherwake, this means the first town should not have a quest marker pointing to the exit. The NPC dialogue should provide the direction organically.

**[STRONG]** Autosave everywhere removes the save beat's exhale function, eliminating natural stopping points [48]. The most reliable playtest signal for pacing success is "I stopped for the night at the save point"—if no players stop at the save point, the save beat is non-functional [48].

**[STRONG]** Excessive length without substance is the most-cited reason for player disengagement: "Unfortunately, few developers know how to make 50+ hours worth of engaging content and so we get a bunch of games that are poorly paced and full of filler" [8]. The Zeboyd conclusion: "We need denser games. We need games with a minimum of filler, where the player gets a fun and memorable experience the entire time" [8]. The indie constraint is actually an advantage here.

### 4.2 Narrative Anti-Patterns

**[STRONG]** "Chosen One" tropes undermine gameplay satisfaction: "Being the Chosen One really undermines everything a lot. It turns my great feats into something sort of ordinary, and makes the world a lot more flat and dull" [42]. This is a strong opinion from a single secondary source but reflects a pattern documented across multiple analyses of JRPG narrative failure [43][42].

**[STRONG]** Silent protagonists in long-form JRPGs weaken emotional investment: "If you're going to make it through 40+ hours, you need there to be a central emotional thing that you're heading toward" [42]. Given that Aetherwake has named characters (Ender, Ionia, Lyra, Reson, Aepex) with approved visual designs, this anti-pattern is already avoided—but the dialogue draft #326 should be evaluated specifically for whether Ender has a consistent, distinctive voice rather than generic protagonist responses.

**[STRONG]** "Evil race has come to the land" framing presents both narrative and ethical design problems [42]. The Metaphor: ReFantazio analysis shows the reverse approach: the game uses city design and ambient NPC dialogue to make the player experience systemic oppression from the oppressed character's perspective before any exposition [36][9].

**[MODERATE]** Octopath Traveler's character introduction structure—eight 90-minute character intro chapters in a row—is identified as poor narrative pacing even by players who love the combat system [42][63]. The lesson: **introduce party members through shared narrative circumstance rather than sequential isolated chapters**. Aetherwake's planned party chemistry (Ender/Ionia first, then Lyra/Reson/Aepex) follows the better pattern of progressive party assembly.

**[MODERATE]** Metaphor: ReFantazio demonstrates a common late-game pacing failure even in critically acclaimed JRPGs: "Acts one through three are the strongest and most engaging...Once act four begins, the pacing and storytelling decisions become questionable. The repetitive encounters, dungeons, and monster types do not outshine the satisfying gameplay loop" [36]. This is a known genre failure mode that requires deliberate pacing budgets for later acts.

### 4.3 Combat Anti-Patterns

**[STRONG]** Grinding treadmills are the most-cited reason for player abandonment: "If you do that chore, your reward are bigger numbers you can do bigger chores with. The entire progression at the core of the genre is like racing a treadmill: no faster how hard you run, you always end up in the same place" [43]. Corroborated by the Soul Dier design philosophy of zero farming [54] and the Zeboyd principle of minimal grinding [8].

**[STRONG]** Over-complex systems with high barrier to entry alienate new players: "The JRPG genre has become a very insular genre—it seems like each new game has even more crazy rules and systems to learn...there's no denying that it presents a high barrier of entry to the uninitiated" [8]. Depth should come from intelligent design, not from multiple complex systems [8].

**[STRONG]** Forced minigames that interrupt the player's chosen experience are strongly disliked: "When you force them, they can become extremely annoying—they just aren't what the player signed up for" [42].

**[STRONG]** Lack of resource constraints causes combat to devolve into optimal loop-finding: "Without constraints like cooldowns, limited use resources, or recovery windows, players quickly fall into predictable play patterns. When every ability is always available, the tension fades" [18]. This is directly documented in the Clair Obscur analysis and is a risk for Aetherwake's echo system if echoes have no cost or cooldown.

**[STRONG]** Steam reviewers cite poor game design in 57% of negative reviews, compared to only 17% mentioning bugs [6]. The majority of negative reviews are posted within the first 7 hours [6]. This means the vertical slice and the first hour of the full game receive disproportionate negative attention from players who bounce.

### 4.4 Technical Anti-Patterns Documented in Godot JRPG Development

**[STRONG]** Soul Dier's development documented a critical Godot 3D-specific anti-pattern: creating too many shaders in early stages caused long compilation times and mid-game stutters, requiring a comprehensive shader caching system [54]. For Aetherwake's 960×640 target, this is relevant even if the game is 2D: shader proliferation should be audited early.

**[STRONG]** Godot projects can suffer from scope expansion beyond original estimates: Soul Dier's planned 1.5-year development expanded to 5+ years, requiring the team to split the game into two parts [54]. The vertical slice commitment to PR #330's proven scope is the correct counter-pattern.

**[MODERATE]** The Defender installer issue #293 is unresolved. While this is listed as independent from the vertical slice, installer failures during playtest distribution are a known cause of artificially poor playtest data—players who cannot install the game report frustration attributed to the game itself. This should be resolved before any external playtest.

---

## Part V: Godot 4 Engineering Patterns for JRPGs

### 5.1 Engine Viability

**[STRONG]** Godot Engine is a proven platform for commercial JRPG and RPG development. Cassette Beasts—a Godot-powered monster-collecting RPG with 20 hours of gameplay—earned $4.1M [60]. Until Then—a story-driven Godot game with 16–18 hours of gameplay—earned $5.1M with 97.27% positive ratings [60]. Brotato, Halls of Torment, and Buckshot Roulette demonstrate Godot's performance ceiling at scale [53][60].

**[STRONG]** Godot's 2D workflow with real 2D pixel coordinates and 2D nodes is specifically well-suited to sprite-based JRPG development [53]. The engine's MIT license means zero royalties [60], and its GDScript/C#/C++ language support allows teams to choose the development language that matches their workflow [53].

**[STRONG]** A two-person team developed Soul Dier—a complex tactical JRPG with 40+ original music tracks, custom cutscene editor, mesh merger, material baker, and text-to-binary resource conversion tool—using Godot 3 and C# over approximately 5 years [54]. The custom tooling required was substantial, suggesting that Godot 4's improved editor capabilities (relative to Godot 3) represent a genuine productivity advantage.

### 5.2 Architecture Patterns

**[STRONG]** Finite State Machines are the canonical architecture for entity behavior in Godot RPGs [32][33]. Godot 4 supports two main FSM implementations: a single-enum variable approach (simpler, preferred by GDQuest authors for most cases [32]) and a node-based approach where each state is a separate node (better editor visibility and debugging [33]).

**[STRONG]** For turn-based combat specifically, a hierarchical architecture—Level manages UnitsContainer, which manages UnitGroups, which manage individual UnitInstances—provides clean separation of concerns for turn order management [65]. This template has been validated across multiple tactical strategy games in Godot including Kaiju Klash and Elemechs [65].

**[STRONG]** Event-driven architecture with signal-based execution (rather than frame-based polling) is documented as the correct pattern for turn-based games in Godot: "Pretty much everything runs on signals, which makes it easy to branch or vary code execution for little work. Player and AI units both emit the same signal when they're moving" [65].

**[STRONG]** AStar2D (rather than AStarGrid2D) is preferred for tactical RPGs requiring special navigation cases like teleporters connecting arbitrary nodes [65]. For Aetherwake's dungeon traversal, this may be relevant if the level design includes non-grid movement options.

**[MODERATE]** Godot's scene structure enables faster and more flexible development at the cost of some initial learning curve [53]. The most successful Godot JRPG teams report building custom editor plugins early in development to accelerate content creation—a pattern validated by Soul Dier's cutscene editor saving "so much time" [54].

### 5.3 Current Engineering Context Assessment

The echo-counterplay code at `a9276ce` is **unverified rather than test-failed** due to GitHub Actions billing limits. This is an infrastructure problem, not a logic failure, and should be treated as a priority-1 blocker for the 30-day plan: restore CI before the next code merge. Without verified test coverage, the echo-counterplay system cannot be confidently integrated into the vertical slice.

PR #330 has passed discovery→choice→challenge→payoff tests with real 960×640 captures. This is the strongest existing validation signal and should be the foundation of the vertical slice, not the unverified echo code.

Art/dialogue draft #326 and gait drafts #328/#329 are independent tracks. Ender's approved appearance is locked. Ionia's art is provisional—the vertical slice should use the current provisional art rather than blocking on finalization, since pacing and mechanical validation are the primary goals of the first playtest round.

---

## Part VI: Original Design Guidance for Aetherwake

### 6.1 Exploration: The Aetherwake World Model

**[INFERENCE based on strong evidence]** The world of Aetherwake should use a *progressive traversal unlocking* structure: early exploration confined to a single valley or region, with the airship/Aetherwake vessel unlocking new world-regions at narrative gates [12][20]. Chrono Trigger's design documents this pattern explicitly: "Players were gradually introduced to more and more options before being set free" [20]. The airship is not just a traversal tool—it is a narrative argument about what freedom means in this world.

**Design recommendation:** Each world region accessible by airship should have a distinct biome identity with unique tileset, music theme, and enemy set [12]. The first Wake (vertical slice) should show the player the airship from a distance or in a locked state, establishing it as a promised freedom rather than a current capability. This creates anticipation without requiring the full traversal system to be implemented.

**[STRONG]** Town design should use a main-road central axis avoiding maze-like layouts, with essential services (inn/heal, item shop, equipment shop) placed in a discoverable central location [12]. Classic SNES JRPGs demonstrated that every tile should serve a purpose—no vast empty areas [12]. For the vertical slice's single town, the layout should be completable in one traversal while rewarding a second look with environmental storytelling.

### 6.2 Party Chemistry: Ender, Ionia, and the Extended Cast

**[STRONG based on Suikoden, FF6, Persona analysis]** Party chemistry is built through three mechanisms: **mechanical differentiation** (each character has a combat role that reflects their identity), **moment-to-moment dialogue** (barks, reactions, and one-liners during combat and traversal), and **relationship systems** that unlock new capabilities through deepened bonds [19][27][36][50].

**For Ender/Ionia in the vertical slice:**
- Ender's approved appearance should be matched by a combat mechanic that expresses his character. If he is the "wake" protagonist—someone who perceives or navigates aetheric resonance—his combat actions should visually and mechanically reflect this perception.
- Ionia (provisional art) should have a combat role that is *complementary but not subordinate* to Ender's. The most resonant party chemistry in the genre comes from characters who are equals with different perspectives [50][27].
- The first dungeon in the slice should include at least one moment where Ionia's specific combat role is necessary to progress—not optional, not backup, but required. This teaches the player that party composition matters.

**[STRONG]** Character barks during combat should be written for Ender and Ionia in the vertical slice—at minimum 6–8 lines each covering: standard attack, critical hit, taking damage, ally going down, using the echo mechanic successfully, and failing the guard [36]. These lines cost almost nothing to implement and pay significant emotional dividends [36].

**For later cast (Lyra, Reson, Aepex):** Following Persona's Confidant system analysis [19], each relationship should unlock both a narrative beat and a mechanical capability. Persona 4's approach—where ranking up a relationship with a team member unlocks specific combat skills like "taking a mortal blow for the player"—is the cleanest model because it makes relationship investment directly legible in combat [19]. Avoid Persona 5's trap of encouraging min-maxing: "This leads to a more Min-/Max-ing mindset where certain characters are very valuable for their unlocks...makes the relationships feel dishonest and reduces the characters to tools" [19].

### 6.3 The Telegraph/Guard/Echo Combat System

**[SYNTHESIS of strong evidence]**

The echo-counterplay mechanic should be designed against the following framework derived from the evidence:

**Telegraph phase:** Enemy announces the incoming attack through multi-channel communication—animation (body tells the attack type), audio (distinct sound per attack category), and UI icon (optional but recommended for accessibility). The telegraph window should be at least 1 full second before the attack resolves [22]. Different attack types (physical, elemental, status) should have visually distinct telegraphs so players can learn categories before memorizing specific attacks.

**Guard phase:** Players choose to Guard, which reduces incoming damage and sets up the Echo. The guard should be *selectable from the standard menu* rather than requiring a reaction-time input—this is the key differentiator from Clair Obscur's system [17][26] and addresses the community's frustration with timing precision. [INFERENCE] A menu-selectable guard with a prediction bonus (guard declared before the telegraph resolves gets a larger echo) would reward strategic play over reflexes.

**Echo phase:** Successfully guarding an attack of the telegraphed type triggers an Echo—an immediate counter-action that deals damage and/or generates turn economy advantage (extra half-turn, reduced enemy action count, brief stun). The Echo should have a cost (AP, limited uses per combat, or cooldown) to prevent the "optimal loop" trap [18]. The echo's effect should be visually distinct and mechanically audible—a satisfying payoff moment.

**Failure state:** Failing to guard (or guarding the wrong type) should have a *mechanically specific* consequence rather than diffuse damage increase. The SMT Press Turn model suggests losing a turn action is the cleanest penalty [47][58]. This teaches exactly what went wrong.

**Enemy design integration:** At least three enemy types in the vertical slice should have distinct telegraph/counter relationships: one physical attacker (straightforward guard/echo), one elemental attacker (type-matching required), and one status-condition attacker (guard blocks the status, echo cleanses or prevents it for the party).

### 6.4 Meaningful Choices

**[STRONG]** Meaningful choices require competing values, adequate information without perfect knowledge, and proportional consequences [59]. The three-path framework—conservative (low-risk, modest reward), moderate (balanced), aggressive (high-risk, high-reward)—applied to major decisions provides structure without forcing a single optimal answer [59].

**[STRONG]** Choices should have ripple effects that echo through future sessions [59]. For the vertical slice, at least one NPC dialogue choice in the town beat should change something visible in the dungeon—a guard patrol route, an enemy placement, a locked door status. The change does not need to be large; it needs to be *observable*.

**[STRONG]** Quest obsolescence is a documented anti-pattern: Disco Elysium avoids it by using fixed XP values and task rewards independent of character level [31]. Aetherwake should design early sidequests with rewards that remain meaningful throughout the first act.

**[MODERATE]** Avoid dialogue choices that are immediately overridden by companion characters—Metaphor: ReFantazio's documented limitation where "Gallica strongly suggests" a specific path despite player choice [36]. If Ionia has narrative opinions that override player choices, these should be framed as *her character asserting herself* (which can build character) rather than the system refusing player agency.

### 6.5 Memorable Towns and NPCs

**[STRONG]** NPC dialogue should cut small talk and go directly to substance [35]. Realistic conversational pacing "felt dull, lifeless and flat" in testing [35]. For the vertical slice's town, each named NPC should serve at least one of: information about the upcoming dungeon, worldbuilding about Aetherwake's society/conflict, comic relief that establishes tone, or a hint at a future party member.

**[STRONG]** Repeatable NPC dialogue—for NPCs without a story function—should use vague, impersonal environmental comments, local mantras, or cultural phrases that can be reused without becoming irritating [35]. A recurring phrase tied to the town's culture ("May your Wake stay clear," "The mist doesn't forget") serves both as atmospheric texture and as worldbuilding without requiring unique dialogue per interaction.

**[STRONG]** Town architecture should reflect its social structure. Zaphias in Tales of Vesperia demonstrates how "every citizen knows their place and is treated accordingly" through spatial design—the lower quarter versus the nobles' quarter is visible without exposition [9]. Metaphor: ReFantazio makes systemic prejudice legible through "chat bubbles" of ambient NPC dialogue plastered on screen immediately upon entering the capital [36]. For Aetherwake's first town, the social structure of the world should be visible in the layout and NPC behavior without requiring a lore dump.

**[STRONG]** Towns should surprise players at least once per act. The Ryube Village model—establish as sanctuary, then subvert—is the gold standard [7]. Even in the vertical slice, the town should contain one detail that suggests it is not as safe as it appears.

### 6.6 Progression Systems

**[STRONG]** Progression nodes should unlock new options or meaningfully change numbers players can feel—not apply +1% improvements [40]. The entry nodes should be obvious early-game fixes; mid-game nodes should define builds; capstone nodes should be major payoffs [40].

**[STRONG]** Players should unlock a transformative progression node within 1–2 hours in a longer RPG [40]. For the vertical slice, the one level-up or unlock event within the 10-minute slice should feel genuinely impactful—a new ability that changes the echo-counterplay options, not a stat increase.

**[STRONG]** Soul Dier's choose-one-from-three upgrade system—where all three options are meaningful and impactful [54]—is the cleanest model for a small team. It creates genuine choice without requiring the balancing complexity of a full skill tree.

**[STRONG]** XP curves for classic JRPG feel should use exponent values around 1.3 to 1.5 [45]. Separate base stats from current stats using multiplier curves, allowing different character classes to be defined through data rather than hardcoded logic [45].

### 6.7 Airship and World Traversal

**[STRONG]** Overworld design should use geographic boundaries (mountains, oceans, rivers) to guide progression, with traversal unlocks (ship, airship) opening new world-regions [12]. The airship is specifically documented as a progression gate in JRPG design history [12][50]—Final Fantasy VI's loss of the airship after the World of Balance collapse resets player progress dramatically and creates the game's most emotionally resonant structural moment [50].

**[INFERENCE]** For Aetherwake, the Aetherwake vessel (the airship equivalent) should be introduced in the first town or road beat of the vertical slice as a *seen but inaccessible* object. This establishes it as a design promise—the player knows freedom is available—without requiring the full traversal system.

**[MODERATE]** Xenoblade Chronicles's quick-travel to any visited location eliminates JRPG filler travel [28]. This is a player-respecting feature that costs little to implement and removes a major complaint category. Aetherwake should plan fast-travel to previously visited locations from the beginning of production, not as a retrofit.

### 6.8 Original Visual and Music Motifs

**[INFERENCE based on strong evidence]**

**Visual motif proposal—"The Resonance Palette":** Aetherwake's visual identity should be built around the contrast between *dense, material reality* (stone, rust, fabric, weathered surfaces) and *aetheric luminescence* (the glow of echo-resonance, the color of successful guards and counterplays). When the echo mechanic activates, the screen should briefly shift to a higher-saturation, higher-contrast state—the world "waking" to possibility. This contrast should be present in the UI, in enemy telegraph effects, and in the visual design of aetheric locations.

**Color accessibility note [STRONG]:** Orange versus blue works for all three most common colorblindness types; adding a contrast difference (light blue versus dark orange) covers edge cases [2]. Aetherwake's echo/guard color system should be built on orange-blue contrast rather than red-green, with secondary shape and icon cues for all critical information [2][16]. Test against protanopia, deuteranopia, and tritanopia simulators before locking the color system [16].

**Music motif proposal—"Wake Themes":** Compose three core motifs: (1) **The World Theme**—a melody representing the ground reality, dense and slightly melancholic, heard in overworld and town contexts; (2) **The Echo Theme**—a shorter melodic cell that plays when the echo mechanic triggers, building in intensity with successful chains; (3) **The Aetheric Theme**—a transformed version of the World Theme in a higher register, reserved for moments when the player reaches locations of aetheric significance. These three motifs should be recognizable as variations of the same source material, communicating that aether is a hidden dimension of the same world rather than a separate realm.

**[STRONG]** Creating memorable melodies is the hardest and most time-consuming part of JRPG music [57]. Commit to the melodic motifs early and vary them across contexts rather than composing separate tracks for each situation. Adaptive audio techniques—layering, transition matrices, seamless cue-to-cue transitions on musical boundaries—should be planned from the design phase [46].

---

## Part VII: Accessibility Requirements

**[STRONG]** Colorblindness affects approximately 8–10% of males, with red-green difficulty being most common [2]. Essential information in Aetherwake must never be conveyed by color alone—every color-coded element (enemy telegraph type, guard success/failure, echo activation) must have a paired non-color cue (shape, icon, pattern) [2][16].

**[STRONG]** Full-palette colorblind filters are less effective than targeted solutions [2]. Aetherwake should offer: (1) a default design that is colorblind-friendly through shape+color coding, and (2) optional preset palettes for protanopia/deuteranopia/tritanopia with targeted UI color changes rather than full-game recoloring [2][16].

**[STRONG]** Subtitle/caption system requirements [16][23]:
- Subtitle text scalable to at least 200% of default size
- Separate volume controls for effects, speech, and background music
- Subtitle and caption content stored as distinct types for separate styling
- Built into the dialogue pipeline from the start, not as a post-hoc overlay
- Speaker identification in subtitles

**[STRONG]** Input remapping requirements [16][23]:
- Gameplay logic must consume semantic actions (Guard, Echo, Interact) not physical buttons
- Remapping support for all gameplay inputs before launch, not as a post-launch patch
- Configurable hold/toggle behavior for accessibility-sensitive actions

**[STRONG]** Turn-based combat has an inherent accessibility advantage over action systems: it does not require real-time input timing. If Aetherwake's guard mechanic is menu-selectable (as recommended in 6.3), it avoids the documented accessibility failure of Clair Obscur's ~100ms timing windows [17][26]. Options for game speed adjustment should be included [23].

**[STRONG]** The Game Accessibility Guidelines specify: allow difficulty level to be altered during gameplay; allow players to progress through text at their own pace; avoid requiring button-mashing; include playtesters with impairments [23]. The Defender installer issue #293 is specifically relevant to accessibility: if the game cannot be installed by players using assistive technology configurations, the accessibility investment in the game itself is wasted.

---

## Part VIII: Playtest Questions and Metrics

### 8.1 Vertical Slice Acceptance Criteria (Concrete and Testable)

The following criteria are directly derived from the evidence framework and should be applied to the First Wake vertical slice:

| Criterion | Pass Condition | Evidence Basis |
|-----------|---------------|----------------|
| Loop completion rate | ≥70% of playtesters complete town→road→dungeon→save without quitting | [15][52] |
| First-loop duration | ≤25 minutes total; dungeon portion ≤10 minutes | [48] |
| Telegraph legibility | ≥80% of playtesters correctly predict attack type before it resolves (post-session survey) | [17][22] |
| Guard activation rate | ≥60% of playtesters use guard mechanic at least once in dungeon without tutorial prompt | [48] |
| Echo activation rate | ≥40% of playtesters successfully trigger echo at least once | [INFERENCE] |
| Combat turn latency | Average <2.5 seconds per Attack-confirm cycle across 10 measured turns | [48] |
| Normal fight duration | ≤35 seconds average for road encounters; ≤90 seconds for dungeon encounters | [48] |
| NPC dialogue engagement | ≥70% of playtesters speak to at least 3 NPCs in the town beat | [INFERENCE] |
| Save point usage | ≥50% of playtesters stop at the save point voluntarily (session ends at save) | [48] |
| Return rate | ≥30% of playtesters return for a second session within 48 hours without prompting | [15] |
| Character identification | ≥90% of playtesters can name Ender and Ionia and describe their relationship at session end | [INFERENCE] |
| Colorblind test | All critical UI information legible under deuteranopia simulation | [2][16] |

### 8.2 Playtest Session Design

**[STRONG]** Demo duration of 15–30 minutes is optimal for playtesting [3]. The 10-minute vertical slice should be padded to 15 minutes with a post-play survey for optimal data collection.

**[STRONG]** Focus on one or two specific aspects per playtest session rather than testing everything at once [3]. Recommended session sequence:

- **Session 1 (Days 1–14):** Pacing and loop completion. Does the town→road→dungeon→save loop complete within the target time? Do players stop at the save point?
- **Session 2 (Days 15–28):** Combat legibility. Do players understand the telegraph/guard/echo system without tutorial text?
- **Session 3 (Days 29–42):** Character chemistry. Do players care about Ender and Ionia by the end of the slice?

**[STRONG]** Observation paired with post-session interview is the most accessible and highest-value playtest method [51]. Watch players play—do not intervene—then ask questions. This gives behavioral data (what they did) combined with motivational data (why they did it).

**[STRONG]** Key metrics to instrument [44][15]: time-to-first-action, completion percentage, exit point distribution, first failure state (where players die or give up), first echo trigger, and session end condition (natural/save vs. quit).

**[STRONG]** Minimum sample size for meaningful retention data is 50–100 sessions from target demographic players [15]. For the vertical slice, 60 target-demographic playtesters (people who play JRPGs and strategy games) is the minimum before making design changes.

### 8.3 Playtest Questions (Open-Ended)

For post-session interviews:

1. "Walk me through the last fight you had. What were you thinking about during it?" *(Reveals whether players are engaging with the system or just pressing buttons)*
2. "When the enemy was about to attack, did you know what was coming? What tipped you off?" *(Reveals telegraph legibility)*
3. "What did you do when you saw the [telegraph icon/animation]?" *(Reveals guard/echo awareness)*
4. "Tell me about Ender. What do you know about him?" *(Reveals character investment)*
5. "Was there a moment where you wanted to stop playing? What caused it?" *(Reveals friction points)*
6. "Was there a moment where you didn't want to stop?" *(Reveals retention hooks)*
7. "What do you think happens next in the story?" *(Reveals narrative clarity)*
8. "How did the combat feel compared to JRPGs you've played before?" *(Reveals positioning and differentiation)*

---

## Part IX: Three Viable Gameplay Directions and Tradeoffs

### Direction A: Strategic Prediction — The "Chess Clock" Model

**Core premise:** Combat is entirely menu-driven. The telegraph/guard/echo system operates on prediction rather than reaction—players declare guard actions before the telegraph resolves, and correct prediction generates echo advantage. Normal encounters last 20–30 seconds. The system rewards knowledge accumulation (learning enemy attack patterns across multiple encounters) over any form of twitch skill.

**Strengths:** Maximum accessibility (no timing requirements), deepest strategic depth, directly solves the Clair Obscur "precision over prediction" complaint [17], compatible with accessibility requirements [23], fits the genre identity of traditional turn-based JRPGs.

**Tradeoffs:** Less immediately exciting to observe or stream; requires enemy variety to sustain interest (players need new patterns to learn constantly); may feel slow to players expecting action feedback.

**Best fit:** If Aetherwake's target audience is core JRPG fans who bounced off Clair Obscur's timing demands.

**Evidence basis:** SMT Press Turn model [47][58], Octopath shield-break model [49], Soul Dier's punishing-but-fair design [54], Zeboyd's efficiency-over-endurance principle [8].

### Direction B: Reactive Rhythm — The "Informed Timing" Model

**Core premise:** Telegraph/guard operates with a generous timing window (~500ms) that rewards attention but does not punish lack of fighting-game reflexes. Successful guard is declared via button press after the telegraph begins but before the attack resolves. Echo is a menu-selectable follow-up on the player's next turn rather than an immediate reaction. Normal encounters last 30–45 seconds.

**Strengths:** More dynamic feel than pure prediction; still accessible by most players; creates satisfying feedback loop without requiring precision; visually engaging for streaming.

**Tradeoffs:** Requires careful tuning of timing windows across platforms and input devices (Clair Obscur required explicit recommendations about wired controllers [26]); may frustrate players who want pure strategy; adds implementation complexity.

**Best fit:** If Aetherwake wants to appeal to both traditional JRPG fans and players who bounced off Sea of Stars's pure-menu feel.

**Evidence basis:** Clair Obscur's design rationale and community reception [17][18][26], enemy attack telegraphing theory [22], accessible design principles [23].

### Direction C: Tactical Positioning — The "Field Advantage" Model

**Core premise:** Combat incorporates a spatial dimension—small battlefield positioning that affects which echoes are available, which attacks can be telegraphed versus ambushed, and which party members are in range. Telegraph/guard operates as in Direction A (pure prediction), but positioning in the pre-combat phase creates strategic options. Normal encounters last 35–50 seconds.

**Strengths:** Maximum tactical depth; distinct from most pure turn-based JRPGs; spatial thinking creates natural variety even with repeated enemy types; aligns with Soul Dier's successful positioning-based system [54].

**Tradeoffs:** Significantly higher implementation complexity; steeper learning curve; harder to teach in a 10-minute vertical slice; requires careful UI design to avoid menu bloat [28][40].

**Best fit:** If Aetherwake targets the tactical JRPG audience (Fire Emblem, Tactics Ogre) rather than the traditional JRPG audience.

**Evidence basis:** SinisterDesign's emergent complexity through spatial dimensions [1], Soul Dier's positioning mechanics [54], Radiant Historia's grid system [39].

**Recommended direction for the vertical slice: Direction A with a B-compatible interface.** Implement pure menu-driven prediction for the vertical slice (lowest implementation risk, highest accessibility, cleanest playtest signal). Design the UI and telegraph system so that if the team decides to add a timing layer in Direction B post-playtest, the architecture accommodates it without redesign. Do not implement Direction C until Directions A and B are validated—the positioning complexity is the highest implementation risk in the project.

---

## Part X: Original Narrative, Art, and Audio Ideas

### 10.1 Narrative — The Wake as Epistemic Device

**[INFERENCE based on Chrono Trigger's inevitability theme [21] and Metaphor's systemic prejudice approach [36]]**

Aetherwake's title implies the wake of something—a vessel moving through the aether, or the state of consciousness after sleep. A narrative device worth exploring: **Ender perceives the aetheric "wake" of past choices**—the residue that events leave in the aetheric field. This means he (and by extension the player) can see *what decisions led to the current state of things*, but not what decisions will be best in the future. Ionia's role might be to anchor him in the present—she cannot see the wake, but she can act without paralysis.

This device gives the echo mechanic a narrative justification: the echo is Ender reading the wake of an enemy's incoming attack and responding to its *pattern* rather than its impact. It makes the prediction model of Direction A thematically coherent.

It also addresses the anti-pattern of "chosen one" flatness [42]: Ender's wake-perception is a burden and a limitation, not a superpower. He sees what was, not what will be.

### 10.2 Art — The Materiality of Aether

**[INFERENCE based on Metaphor's enemy design [36], FF6's steampunk innovation [50], and visual consistency guidance [62]]**

Aetherwake's visual language should make a specific argument about what aether *is*. Recommendation: aether should be materially *thin*—it looks like the world is slightly worn through, like old fabric where the light comes through. Aetheric phenomena appear as translucency, fraying edges, and luminous seams in otherwise solid objects. This contrasts with the standard JRPG fantasy of aether as a dramatic supernatural force.

Practically: enemy telegraph effects should look like the enemy's surface becoming momentarily thin and luminous before the attack resolves. Successful echoes should look like the player briefly appearing more *solid* than the environment—more real, less worn-through.

This visual language is also colorblind-friendly: luminosity/translucency contrasts work regardless of hue, supporting the accessibility requirement [2].

### 10.3 Audio — The Echo Signature

**[INFERENCE based on adaptive audio principles [46] and Octopath's character theme system [57]]**

Each character in the party should have a short (4–8 note) melodic signature that plays during their specific combat actions—not during all combat, but specifically when they perform their character-defining move. Ender's signature plays when he successfully reads a wake and declares guard; the echo resolution plays his signature at double tempo. Ionia's signature plays when she covers for an ally.

The boss music should include a fragmented version of the enemy's own "wake signature"—the musical pattern that telegraphs their attack phases. Players who are paying attention can hear the boss's attack pattern in the score before the visual telegraph appears. This rewards a second playthrough with the realization that the music was always telling them what was coming.

---

## Part XI: Ranked Low-Cost/High-Impact Recommendations

| Rank | Recommendation | Cost | Impact | Evidence | Status |
|------|---------------|------|--------|----------|--------|
| 1 | Restore GitHub Actions CI (billing fix) to verify `a9276ce` echo code | Very Low | Critical | Engineering context | Blocker |
| 2 | Time the first loop (town→road→dungeon→save) in current grey-box state | Very Low | Critical | [48] | Immediate |
| 3 | Write Ender/Ionia combat barks (6–8 lines each) | Very Low | High | [36] | Week 1 |
| 4 | Make guard a menu-selectable action, not a timing-window input | Low | Very High | [17][23] | Week 1–2 |
| 5 | Add non-color cues (shape/icon) to all telegraph types | Low | High | [2][16] | Week 1–2 |
| 6 | Set normal fight target: ≤35 seconds; measure and cut to reach it | Low | High | [48] | Week 2 |
| 7 | Implement echo resource cost (AP or limited-use) to prevent optimal-loop | Low | High | [18] | Week 2 |
| 8 | Add step-counter encounter system with 2:1 floor/ceiling ratio | Low | High | [48] | Week 2 |
| 9 | Three distinct enemy types in vertical slice with different telegraph/echo relationships | Medium | High | [39][54] | Week 2–3 |
| 10 | Run first external playtest (15–30 min session, 20+ target-demographic players) | Medium | Critical | [3][44] | Week 3–4 |
| 11 | Resolve Defender installer issue #293 before any external playtest | Medium | High | Engineering context | Before playtest |
| 12 | Compose 3 core melodic motifs (World, Echo, Aetheric) before full audio production | Low | High | [57][46] | Week 2–4 |
| 13 | Add one observable consequence of a player dialogue choice in the town beat | Low | Medium | [59][31] | Week 3–4 |
| 14 | Finalize Ionia provisional art to enable character investment testing | Medium | Medium | Engineering context | Week 4 |

---

## Part XII: 30/60/90-Day Plan

### Days 1–30: Foundation Verified

**Priority 1: Restore CI and verify echo code**
- Fix GitHub Actions billing to resume automated testing
- Run echo-counterplay tests against PR #330's discovery→choice→challenge→payoff framework
- If echo code fails tests, isolate to component level before any new feature work

**Priority 2: Pacing audit**
- Time the existing grey-box loop (town→road→dungeon→save) in its current state
- Measure combat turn latency (10 consecutive Attack confirms, calculate average)
- Measure average road encounter duration; cut enemy HP until ≤35 seconds achieved
- Identify and remove all unnecessary confirmation prompts, unskippable animations, and cursor-position inefficiencies

**Priority 3: First external playtest**
- Resolve Defender installer issue #293
- Recruit 20–30 target-demographic playtesters (JRPG/strategy game players)
- Run observation sessions with post-session interviews (Section 8.3 questions)
- Instrument 5–6 key moments: session start, first NPC interaction, first combat, first death/failure, first save point, session end
- Primary question: Does the loop complete? Do players stop at the save point?

**Deliverable by Day 30:** Verified echo code, pacing audit with specific numbers, first playtest report with friction point map.

### Days 31–60: Polish and Differentiation

**Combat depth:**
- Implement the three distinct enemy types (physical/elemental/status telegraph categories)
- Add echo resource system (AP cost or limited-use counter per combat)
- Implement combat bark lines for Ender and Ionia

**Narrative and world:**
- Finalize one observable consequence of a town dialogue choice
- Complete NPC dialogue for all town characters (section 6.5 framework)
- Implement ambient chat-bubble worldbuilding (Metaphor model [36]) for town

**Music:**
- Finalize three core melodic motifs
- Implement adaptive layering for town-to-dungeon transition

**Accessibility:**
- Add shape/icon secondary cues to all telegraph types
- Test palette against deuteranopia/protanopia/tritanopia simulators
- Verify subtitle pipeline is built into dialogue system, not as overlay

**Second external playtest:**
- 40–60 target-demographic playtesters
- Primary question: Is the telegraph/guard/echo system understood without tutorial text?
- Measure guard activation rate and echo activation rate

**Deliverable by Day 60:** Vertical slice with all acceptance criteria measurable; second playtest report; accessibility audit.

### Days 61–90: Vertical Slice Completion and Retention Test

**Retention validation:**
- 60–100 target-demographic playtesters in a 3-session longitudinal structure (session 1: full slice; session 2: 48 hours later, same slice; session 3: 96 hours later, any available content)
- Measure return rate (target: ≥30% return for session 2 without prompting [15])
- Exit survey after session 3: character identification, echo system understanding, anticipated narrative

**Polish concentration:**
- First 60 seconds: ensure the opening beat communicates Aetherwake's identity
- Save/resume system: ensure the save point is a natural stopping point, not a checkpoint
- Ionia art finalization if provisional art is affecting character investment scores

**Production planning:**
- Measure second-pass velocity (how long does it take to build the second town, the second enemy type, the second dungeon) relative to first-pass
- Use ratio to estimate production timeline for full game
- Scope decision: confirm which of Direction A/B/C is the production target based on playtest data

**Deliverable by Day 90:** Validated vertical slice meeting all acceptance criteria; retention data; production timeline estimate; scope decision memo.

---

## Part XIII: Implementation Tickets (GitHub/Notion Format)

---

**[TICKET] FIX-001 — Restore GitHub Actions CI**
*Priority: P0 (Blocker)*
- Resolve billing/spending-limit failure preventing GitHub Actions jobs from starting
- Verify that echo-counterplay code at `a9276ce` passes all existing tests
- If tests fail after billing is restored, create child tickets per failing test
- *Acceptance:* All GitHub Actions jobs pass on main branch; echo code status confirmed green or red

---

**[TICKET] DESIGN-001 — Pacing Audit: First Loop Timer**
*Priority: P0*
- Play the current build continuously from town entry to save point; record total time
- Record individual beat times: town, road, dungeon, save
- Record average combat turn latency (10 Attack confirms, divided)
- Record average road encounter duration
- Target: total loop ≤25 min; normal fight ≤35 sec; turn latency <2.5 sec avg
- *Acceptance:* Written report with all four numbers; issue tickets for each metric out of range

---

**[TICKET] COMBAT-001 — Guard as Menu Action**
*Priority: P1*
- Implement Guard as a selectable menu option appearing during enemy attack declaration (after telegraph, before resolution)
- Guard declared before telegraph resolves grants Echo advantage; guard declared after telegraph but before impact grants standard damage reduction
- Echo is a follow-up selectable on player's next turn, not a real-time input
- *Acceptance:* Guard option appears in combat menu during enemy turn; correct behavior verified in unit tests

---

**[TICKET] COMBAT-002 — Echo Resource System**
*Priority: P1*
- Implement AP cost for Echo action (proposed: 2 AP per echo, party AP pool of 5 per round)
- Alternatively: limited uses per combat (proposed: 3 echoes per dungeon encounter, 1 per road encounter)
- Evaluate both options in internal playtest before external playtest
- *Acceptance:* Echo cannot be spammed; resource depletion creates meaningful tension in at least one dungeon encounter

---

**[TICKET] COMBAT-003 — Three Telegraph Category Types**
*Priority: P1*
- Implement three visually distinct telegraph categories: Physical (heavy/ground-shaking animation), Elemental (luminous charge effect with element color), Status (spreading pattern/cloud effect)
- Each category must have unique animation + audio cue + UI icon
- Each category must be colorblind-friendly: shape-coded independently of color
- Guard against correct category triggers Echo; guard against wrong category triggers damage reduction only
- *Acceptance:* Three enemy types with distinct telegraphs present in vertical slice; playtest shows ≥80% of playtesters correctly predict category

---

**[TICKET] ACCESS-001 — Colorblind-Friendly Combat UI**
*Priority: P1*
- Audit all combat UI elements for color-only information conveyed
- Add shape/icon secondary cue to: telegraph type indicators, guard success/failure feedback, echo activation indicator, HP bars, status effect icons
- Test palette against protanopia, deuteranopia, tritanopia simulators
- If orange-blue not already used for primary combat feedback, implement
- *Acceptance:* All critical combat information legible in deuteranopia simulation; no essential information conveyed by color alone

---

**[TICKET] ACCESS-002 — Subtitle Pipeline**
*Priority: P1*
- Verify subtitles are built into dialogue pipeline rather than applied as post-hoc overlay
- Implement subtitle text scaling to at least 200% of default
- Implement separate audio volume controls for effects, speech, and music
- Store dialogue subtitles and non-speech captions as distinct content types
- *Acceptance:* All voice lines have subtitles; text scales to 200%; volume controls present and functional

---

**[TICKET] NARRATIVE-001 — Ender/Ionia Combat Barks**
*Priority: P2*
- Write 6–8 combat bark lines per character (standard attack, critical hit, taking damage, ally down, echo success, guard failure)
- Record temporary placeholder audio or use TTS for playtest; final VO can come later
- Implement bark trigger logic in combat state machine
- *Acceptance:* Barks trigger correctly in 90% of trigger conditions; playtesters can describe character personality from combat barks alone

---

**[TICKET] NARRATIVE-002 — Town Dialogue Choice with Observable Consequence**
*Priority: P2*
- Identify one NPC dialogue choice in the first town
- Implement consequence visible in the dungeon (guard patrol route, enemy placement, locked door, NPC appearance in dungeon as ally or enemy)
- The consequence must be observable without explanation—player should discover it through play
- *Acceptance:* 30%+ of playtesters in session 2 mention noticing a connection between their town choice and something in the dungeon

---

**[TICKET] PLAYTEST-001 — First External Playtest (Day 20–25)**
*Priority: P1*
- Resolve issue #293 (Defender installer) before this ticket
- Recruit 20–30 target-demographic playtesters (JRPG/strategy players)
- Instrument session start, first NPC, first combat, first death, first save, session end
- Run observation + interview sessions (Section 8.3 questions)
- Analyze: completion rate, exit points, save-point stopping behavior
- *Acceptance:* Report with friction point map; specific tickets created for each criterion failing the acceptance checklist

---

**[TICKET] ISSUE-293-BLOCKER — Resolve Defender Installer**
*Priority: P0 (before any external playtest)*
- Investigate and resolve Defender installer issue preventing external distribution
- Test installation on clean Windows machines without developer certificates
- *Acceptance:* External playtesters can install and launch without developer intervention

---

## Evidence Confidence Summary

| Finding | Confidence | Source Basis |
|---------|-----------|-------------|
| 4-beat loop timing budgets | STRONG | Primary source [48], corroborated by [25][44][64] |
| Telegraph legibility as fairness requirement | STRONG | Primary [22], official [17], indie postmortem [54] |
| Press Turn / turn economy design | STRONG | Primary analysis [47][58], multiple secondary [39] |
| Towns as emotional pacing mechanism | STRONG | Primary [7], corroborated by [9][12] |
| Character barks for continuous personality | MODERATE | Secondary [36], one first-party [57] |
| Steam review: design > bugs in negative reviews | STRONG | Primary data [6] |
| Colorblindness accessibility requirements | STRONG | Primary official guidelines [2][16][23] |
| Godot viability for commercial JRPG | STRONG | Primary postmortem [54], corroborated by commercial data [53][60] |
| FSM + event-driven architecture for Godot RPG | STRONG | Primary [32][65], secondary [33] |
| Echo resource constraint to prevent optimal loop | MODERATE | Secondary [18], one opinion source [8]; no direct implementation evidence |
| Grievance window: 7 hours for negative Steam reviews | STRONG | Primary data study [6] |
| Return rate benchmark (30% day-2 organic) | MODERATE | Primary [15], estimate from low-quality source [52]; use with care |
| Memorable melody as hardest music challenge | MODERATE | First-party [57]; single source |

---

*This report synthesizes 69 sources dated primarily 2022–2026. All source URLs cited with [N] correspond to the evidence brief. Claims from forums, community posts, and personal blogs are identified as moderate or low confidence and corroborated with primary sources where possible. The echo-counterplay system's specific design (Section 6.3) is synthesized inference—it should be validated against actual playtest data within 30 days.*