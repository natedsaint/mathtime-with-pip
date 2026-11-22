# Mathtime With Pip — Game Plan

A flashcard-style math game for Godot 4.7 (GDScript). One big question fills the screen, the player answers by tapping an on-screen keypad or typing, and a friendly mascot cheers them on.

---

## 1. Core experience

**The flashcard**
- One question per screen, in large type, centered on a card: `7 × 8 = ?`
- Under the card is the answer box. Below that is a big on-screen number pad (0–9, ⌫, ✓) sized for fingers.
- The physical keyboard always works too: digits, Backspace, and Enter. Both inputs fill the same answer box, so the player can mix them freely.
- When an answer is right, the card flips or slides away and the next one comes in. The motion should make each question feel like a new card.

**Operations**
- The player picks any mix of ➕ ➖ ✖️ ➗ before playing. At least one must be on.
- Subtraction never goes negative: the larger number always comes first.
- Division always comes out to a whole number. It is built backwards from multiplication: pick `a × b = c`, then ask `c ÷ a`.

**Difficulty levels** (the player picks one; the default is Level 1)

| Level | ➕ / ➖ | ✖️ / ➗ |
|---|---|---|
| 1 – Starter | sums up to 10 | tables 1–5 |
| 2 – Builder | sums up to 20 | tables 1–10 |
| 3 – Pro | sums up to 100 | tables 1–12 |

The same question never shows up twice in a row. The generator also avoids too many `× 1` and `+ 0` freebies.

---

## 2. The three modes

### A — Practice (free play)
- No clock and no limit. Questions keep coming until the player taps **I'm done**.
- The results screen shows: *"You got **18** right!"*, the best streak, and the number of questions tried.
- The score is framed as the number right, never as a fraction wrong. "18 right" feels better than "18/25".

### B — Beat Your Time (stopwatch)
- A fixed set of questions: 10, 20, or 30, chosen on the setup screen.
- A stopwatch counts **up** from 0, and there is no time limit.
- Each question stays on screen until it's answered correctly (see §3), so every run means "finish N questions." That keeps times fair to compare.
- At the end the game shows the time and compares it with the saved best for the **same settings** (operations, level, and count):
  - New record: a big celebration, *"New best! 1:42 — 6 seconds faster!"*
  - No record: *"1:48! Your best is 1:42 — so close!"* The message never says "you lost."
- The game saves a best time and a short history (the last 10 runs) per settings combo, so a "my times" list can show progress.

### C — Countdown (timed)
- The clock counts **down** from 30, 60, or 120 seconds, picked on the setup screen (default 60).
- The goal is to answer as many as possible before time runs out.
- At the end it shows the number right and compares it with the best score for the same settings.
- In the last 10 seconds the timer gently pulses. No alarm sound, nothing stressful.

---

## 3. Encouragement without discouragement

**Mascot: "Pip"**, an original, simple cartoon character (for example, a round little star-shaped creature with big eyes). Pip sits in a corner of the flashcard screen and reacts to every answer.

| Moment | What happens |
|---|---|
| Correct | Pip hops and cheers. A short sparkle burst plays, along with a soft "ding". Pip says a random line: *"Nice!"*, *"You got it!"*, *"Math wizard!"* |
| Streak (every 5 in a row) | A bigger celebration: confetti, a star counter, and *"5 in a row!!"* |
| Wrong | **No red X, no buzzer, no shake.** Pip tilts their head and says *"Hmm, let's try again!"* The answer box clears so the player can retry. |
| Wrong three times on the same question | Pip shows the answer kindly: *"It's 56! 7 × 8 = 56."* The player taps **Got it**, and the question comes back later in the session. |
| End of any mode | Pip celebrates whatever the result was. Every results screen opens with something positive. |

Rules that keep it kind:
- Colors are warm and calm. Wrong answers get a soft neutral color, never red.
- Wrong answers never add a time penalty or deduct points. In mode B a miss costs only the seconds spent retrying.
- Encouragement lines are drawn from a pool with no immediate repeats, so they don't get stale.
- Optional later addition: **hint visuals** for small numbers, such as dots for addition or a grid of rows for multiplication, shown after the first miss.

---

## 4. Screens / flow

```
Title ──► Mode Select ──► Setup ──► Flashcard (game) ──► Results
  ▲        (A / B / C)   (ops, level,                      │
  │                       count/time)                      │
  └──────────────────── Play again / Menu ◄────────────────┘
                     (also: My Best Times screen from Title)
```

- **Title:** Pip waves. Buttons: **Play** and **My Records**.
- **Mode Select:** three big, colorful cards, each with an icon and a one-line description.
- **Setup:** operation toggles, level picker, and question count (B) or duration (C). The last choices are remembered.
- **Flashcard:** the card, answer box, keypad, Pip, and the HUD (timer or count, and streak). There is also a pause/quit button.
- **Results:** the score or time, the comparison with the best, Pip's reaction, and the buttons **Play Again** and **Menu**.
- **My Records:** best times (B) and best scores (C) for each settings combo, plus a small list of recent runs.

---

## 5. Godot architecture

**Project settings**
- Base resolution 1280×720 (landscape) with stretch mode `canvas_items` and aspect `expand`. All layout uses Containers and anchors, so it also works in portrait on tablets and phones.
- One `Theme` resource (`theme/main_theme.tres`) holds a rounded, friendly font (for example Fredoka or Baloo from Google Fonts, both OFL), big button styles, and the color palette.

**Autoloads (singletons)**
| Script | Job |
|---|---|
| `GameSettings.gd` | Current mode, operations, level, count/duration. Passes them from Setup to the game. |
| `SaveData.gd` | Loads and saves `user://progress.cfg` (ConfigFile): best times, best scores, history, and the last settings used. |
| `Audio.gd` | Plays the short sound effects (ding, sparkle, celebration) and handles a mute toggle. |

**Core scripts / scenes**
```
res://
  scenes/
    title.tscn
    mode_select.tscn
    setup.tscn
    game.tscn            # flashcard screen; mode logic lives here
    results.tscn
    records.tscn
    components/
      flashcard.tscn     # card visual + flip/slide animation
      number_pad.tscn    # emits digit_pressed / backspace / submit
      mascot.tscn        # Pip: AnimationPlayer with idle/cheer/think/celebrate + speech bubble
      confetti.tscn      # GPUParticles2D / CPUParticles2D burst
  scripts/
    question.gd          # class Question: a, b, op, answer, text()
    question_generator.gd# make(ops, level) -> Question, no-repeat logic, retry queue
    modes/
      mode_base.gd       # interface: start(), on_correct(), on_wrong(), is_finished(), result()
      practice_mode.gd   # A
      stopwatch_mode.gd  # B
      countdown_mode.gd  # C
  autoload/  (GameSettings, SaveData, Audio)
  assets/  (fonts, mascot sprites, sfx)
  tests/   (headless tests for question_generator)
```

**Why a mode strategy:** `game.tscn` stays the same for all three modes. It creates the right `ModeBase` subclass and asks it what to do: whether to show a timer and which direction it runs, when the game ends, and what result to report. Adding a fourth mode later (for example "Daily Challenge") means writing one more script.

**Answer checking flow** (in `game.gd`)
1. Keypad or keyboard input → `answer_text`. Input is capped at 4 digits.
2. On submit: compare with `question.answer`.
3. If correct: `mode.on_correct()` → Pip cheers → confetti if on a streak → card flips → next question.
4. If wrong: increment `attempts`. On the first two misses Pip says "try again" and the box clears (the second time: "One more try!"). On the third miss Pip shows the answer, and the question goes on the retry queue.
5. After each answer, `mode.is_finished()` is checked. If it's true, the result is saved through `SaveData` and the game moves to Results.

**Timers:** the game uses its own `elapsed` float, which advances in `_process` and stops while paused. A `Timer` node is not used here, which keeps pause/resume and display formatting simple. The time is shown as `m:ss.t`.

---

## 6. Art & audio (keep it light to start)
- **Pip v1:** built from simple shapes (Polygon2D/TextureRect plus a few PNGs), animated by tweening scale and rotation. That's enough to look alive without an artist. A drawn sprite sheet can replace it later.
- **Sound effects:** a handful of soft, short sounds from CC0 sources such as Kenney.nl or freesound CC0, plus a mute button.
- **Accessibility:** large text, high contrast, and no reliance on color alone. Optionally, a "calm mode" that turns off confetti and sound.

---

## 7. Build order (milestones)

**Status (2026-11-22):** Milestones 1–5 are done, and so are the My Records screen and pause from milestone 6. Pip the calc-bot is drawn from pixel grids in `scripts/components/pip.gd`. His screen changes color by mood (mint when idle, yellow for cheer, rainbow for celebrate, lavender for think) and shows the answer on a dark calculator display when a card is revealed. His lines appear in a pixel speech bubble. Sounds are synthesized chiptune blips in `autoload/audio.gd`; drop a file like `assets/sfx/correct.ogg` into the project to replace one. There's a Sound on/off toggle on the title screen. Pixel confetti pops on every correct answer, bursts bigger on 5 in a row, and rains on a new record. Pause (the HUD button or Esc) stops the clock and hides the card, and timed games pause themselves when the app loses focus. My Records lists the best result for each settings combo with a chart of recent tries; preview it with sample data using `--shot=records --fake-records=1`. Exports: macOS and Web build and run. The iOS (iPad) and Android presets are ready but need an Apple developer account plus Xcode, or the Android tools. See RELEASE.md. To export the sounds for listening: `godot --headless --path . -- --export-sfx=/tmp/sfx` To preview every mood: `godot --path . -- --shot=dev/pip_gallery --out=/tmp/pip.png`

Run the tests:
```
godot --headless --path . --script res://tests/test_question_generator.gd
godot --headless --path . --script res://tests/test_game_flow.gd
```
Screenshot any screen (dev helper, `scripts/dev/dev_tools.gd`): `godot --path . -- --shot=game --mode=1 --out=/tmp/game.png`

1. **Skeleton.** Create the project, theme, and autoloads. Add the Title → Mode Select → Setup → Game → Results navigation with placeholder UI.
2. **Questions.** Write `question_generator.gd` with all 4 operations and 3 levels, the no-negatives rule, whole-number division, no repeats, and a retry queue. Add headless tests.
3. **Flashcard + input.** Build the card, the number pad, keyboard input, and submit/clear. Mode A works end-to-end.
4. **Modes B and C.** Add the stopwatch and countdown, the results screens, and SaveData records with the comparison messages.
5. **Encouragement layer.** Add Pip's animations and speech lines, the confetti and streaks, the gentle wrong-answer flow, and the sounds.
6. **Polish.** Add card transitions, the My Records screen, pause, settings memory, and portrait layout checks. Export to macOS, then iPad/Android if wanted.

---

## 8. Open questions
- **Who's playing?** The age range sets the default level and how much reading Pip's lines should require.
- **Mode C duration:** fixed at 60s, or selectable (planned: 30/60/120)?
- **Mode B wrong answers:** the plan is retry until correct, so times stay comparable. The alternative is to move on and show the count right next to the time.
- **Platforms:** desktop only, or also iPad/phone? This decides portrait support and export work.
- **Multiple profiles:** will siblings share one device? If so, add a simple "who's playing?" picker so records stay separate.
