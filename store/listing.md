# App Store listing: Mathtime With Pip

Copy each field into App Store Connect. Character limits are Apple's, and every field below is checked against them.
Anything in [BRACKETS] needs filling in.

---

## App information

| Field | Value |
|---|---|
| **Name** (≤30) | Mathtime With Pip |
| **Subtitle** (≤30) | Math flashcards that cheer you |
| **Primary category** | Education |
| **Secondary category** | Games → Educational (optional) |
| **Bundle ID** | [com.yourname.mathtime], the same as in the iOS export preset |
| **SKU** | mathtime-001 |
| **Price** | Free, or your choice |

If "Mathtime With Pip" is taken, try "Mathtime With Pip: Flashcards" or "Mathtime With Pip: Math Facts". Both are 29 characters, inside the 30 limit.

## Promotional text (≤170, can be changed anytime without review)

Practice +, −, × and ÷ with Pip the calc-bot! Beat your best time, race the clock, or just practice. Pip cheers every right answer and helps with the tricky ones.

## Description (≤4000)

Meet Pip, a cheerful little calc-bot who makes math practice feel like a game.

Mathtime With Pip shows one big flashcard at a time. Tap the answer on the big number pad or type it on a keyboard. Get it right and Pip hops, cheers, and sets off confetti. Miss one? No buzzers and no red X's. Pip tilts his head and says "let's try again!" After three tries, Pip shows the answer on his screen, and that card comes back a little later so you can try it again.

THREE WAYS TO PLAY
• Practice: no clock, no pressure. Play as long as you like and see how many you got right.
• Beat Your Time: finish 10, 20 or 30 cards as fast as you can, then try to beat your best time.
• Countdown: answer as many as you can in 30 seconds, 1 minute or 2 minutes.

PICK WHAT TO PRACTICE
• Addition, subtraction, multiplication and division, in any mix
• Three levels: Starter (sums to 10, tables to 5), Builder (sums to 20, tables to 10) and Pro (sums to 100, tables to 12)
• Subtraction never goes below zero, and division always comes out to a whole number

WATCH YOURSELF IMPROVE
My Records keeps your best time or score for every setting you play, with a chart of your recent tries.

MADE FOR KIDS, FRIENDLY FOR PARENTS
• No ads
• No in-app purchases
• No accounts, no tracking, no data collected
• Works fully offline
• Encouraging feedback that never punishes mistakes

## Keywords (≤100, comma-separated, no spaces after commas)

math,flashcards,addition,subtraction,multiplication,division,times tables,kids,arithmetic,practice

## URLs

| Field | Value |
|---|---|
| **Privacy policy URL** (required) | [where you host `store/privacy-policy.html`] |
| **Support URL** (required) | [a page or email link where parents can reach you. The privacy page works if it has your contact.] |
| **Marketing URL** (optional) | (none) |

**Free hosting for the privacy page:** create a public GitHub repo, add `privacy-policy.html` (renamed `index.html`), and turn on Settings → Pages. The URL will look like `https://<username>.github.io/<repo>/`. Fill in your name and contact email in the page first.

---

## App Privacy (the "nutrition label")

- **Do you or your third-party partners collect data from this app?** → **No, we do not collect data from this app.**

That gives the label **"Data Not Collected"**.

## Age rating questionnaire

Answer **None / No** to every content question (violence, mature themes, gambling, contests, unrestricted web access, user-generated content, and so on). The result should be **4+**.

## Kids Category (optional)

If you choose **Made for Kids**, pick one age band. Suggested: **6–8**, which fits the Starter and Builder levels best. Use **9–11** if your audience is mostly older kids learning times tables to 12.

Mathtime With Pip already meets the Kids Category rules: no third-party ads or analytics, no links out of the app, no purchases, and no data collection. Note that once an app is in the Kids Category it's hard to leave, so decide before the first submission.

## Screenshots

Upload the files in `store/screenshots/` (2732×2048, 13-inch iPad, landscape) in this order:

1. `2-correct.png`: a flashcard with Pip cheering *(good first impression)*
2. `4-pip-helps.png`: Pip showing the answer on his screen after three tries
3. `3-streak.png`: the 5-in-a-row celebration
4. `5-modes.png`: the three ways to play
5. `6-records.png`: My Records with the recent-tries chart
6. `1-title.png`: the title screen

To regenerate them (for example after UI changes), run this from the project folder:
```
godot --path . -- --shot=game --size=2732x2048 --mode=0 --ops=2 --level=2 --answer=1 --wait=22 --out=$PWD/store/screenshots/2-correct.png
```
The other screenshots use the same command with different flags. The flags are listed at the top of `scripts/dev/dev_tools.gd`.

## Notes for App Review (optional field)

Mathtime With Pip is a fully offline arithmetic practice game for children. There is no login, no network access, no ads, no purchases, and no data collection. Progress (best times and scores) is stored locally on the device only.
