# 247 Free Poker on Jev Ultrafast

This tree is [Browser Use’s Jev Ultrafast](https://github.com/browser-use/jev-ultrafast) plus a poker scenario aimed at the **same-origin game frame**, not the marketing page.

## What the site actually is

`https://www.247freepoker.com/` embeds the table in:

```html
<iframe id="app-player-cjs-frame" src="game/frame.html">
```

`game/frame.html` loads `js/game.js`, which is **CreateJS**. The table, cards, and Fold / Call / Raise controls are drawn on a `<canvas>` inside `#game`. They are not HTML buttons. The only real DOM click on that frame is `#pause-overlay` (“Press here to play!”).

Jev Ultrafast’s default snapshot only indexes `a, button, input, …`. Upstream also states that **canvas is outside the MVP**. This fork:

1. Starts the inspector on `https://www.247freepoker.com/game/frame.html` (avoids the ad-heavy parent and the iframe).
2. Indexes `#pause-overlay` and `canvas` as click targets so the first gate is visible in the action table.

That is enough to **see the table and click Play**. It is **not** enough for Jev to choose Fold vs Call: those labels never appear as DOM options. The next step after this dump is on-device OCR of the canvas (TipTour / typesafe-computer-use), not more DOM scraping.

## Run the inspector

```bash
cd jev-ultrafast
cp .env.example .env   # TYPESAFE_API_KEY is required for Choose / Run automatically
uv sync
uv run jev
```

Open `http://127.0.0.1:8766`, pick **247 Free Poker · real web**, Start demo.

`Choose next` calls TypeSafe. Observing the page does not.

## Dump the action table (no Jev call)

```bash
cd jev-ultrafast
uv sync
uv run python examples/observe_poker.py
```

Writes `artifacts/poker-observe/<timestamp>/actions.json` and `table.jpg`.
