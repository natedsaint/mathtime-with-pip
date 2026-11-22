# Google Play listing: Mathtime With Pip

Everything for Play Console → **Grow users → Store presence → Main store listing**.
The full description and most answers are shared with the App Store; see `../listing.md`.

## Text

| Field | Value |
|---|---|
| **App name** (≤30) | Mathtime With Pip |
| **Short description** (≤80) | Fun math flashcards with Pip the robot: add, subtract, multiply and divide! *(75)* |
| **Full description** (≤4000) | Copy the **Description** section from `../listing.md` (1,345 characters) |

Alternative short description: *Math flashcards with a cheerful robot buddy. No ads, no tracking, all offline.* (78)

## Graphics

| Asset | File | Play's requirement |
|---|---|---|
| App icon | `icon-512.png` | 512×512 PNG |
| Feature graphic | `feature-graphic.png` | 1024×500 PNG/JPG |
| Phone screenshots | `phone/` (6, 1080×1920) | 2–8 required |
| 7-inch tablet screenshots | `tablet-7in/` (6, 1200×1920) | Optional, but needed for tablet promotion |
| 10-inch tablet screenshots | `tablet-10in/` (6, 2560×1600) | Optional, but needed for tablet promotion |

Upload the screenshots in number order:
1. A flashcard with Pip cheering
2. Pip showing the answer after three tries
3. The 5-in-a-row celebration
4. The three ways to play
5. My Records
6. The title screen

## Store settings

| Setting | Value |
|---|---|
| App or game | App |
| Category | Education |
| Tags | Math, Education, Kids (pick the closest available) |
| Contact email | Your support email (required, shown publicly) |
| Privacy policy | https://natedsaint.github.io/mathtime-with-pip/privacy.html |

## Regenerating

From the project folder (Godot must be able to open a window):
```
godot --path . -- --shot=dev/feature_graphic --size=1024x500 --answer=0 --wait=60 --out=$PWD/store/google-play/feature-graphic.png
sips -Z 512 icon.png --out store/google-play/icon-512.png
```
The screenshots use the same `--shot=… --size=WxH` flags as the App Store ones. See the flag list at the top of `scripts/dev/dev_tools.gd`.
