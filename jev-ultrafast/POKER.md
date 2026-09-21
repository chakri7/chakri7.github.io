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

## Windows: run everything

You do **not** already have `chakri7.github.io` under your user folder until you clone it. From PowerShell in any directory:

```powershell
irm https://raw.githubusercontent.com/chakri7/chakri7.github.io/cursor/jev-ultrafast-poker-4ef6/bootstrap-windows.ps1 | iex
```

Or, equivalently:

```powershell
Set-Location $HOME
git clone -b cursor/jev-ultrafast-poker-4ef6 https://github.com/chakri7/chakri7.github.io.git
Set-Location .\chakri7.github.io
cmd /c .\run-windows.cmd
```

That clones into `$HOME\chakri7.github.io` (on your PC that is `C:\Users\2024\chakri7.github.io` **after** clone, not before), starts Chrome with `--remote-debugging-port=9222`, then the inspector.

Install [Git](https://git-scm.com/download/win) and [uv](https://docs.astral.sh/uv/) first if the script says they are missing.

That script:

1. Starts **Google Chrome in debugging mode** (`--remote-debugging-port=9222`) with a dedicated profile `%TEMP%\chrome-jev-debug` (your everyday Chrome can stay closed or ignored).
2. `uv sync`
3. `uv run browser-harness --doctor`
4. `uv run python examples\observe_poker.py` (no TypeSafe key)
5. Starts `uv run jev` and opens `http://127.0.0.1:8766`

Install [uv](https://docs.astral.sh/uv/) first if needed:

```bat
powershell -ExecutionPolicy Bypass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

Put `TYPESAFE_API_KEY` in `jev-ultrafast\.env` before **Choose next**.

Pieces, if you do not want the full chain:

| Script | What it does |
|---|---|
| `scripts\windows\start-chrome-debug.cmd` | Chrome debugging only |
| `scripts\windows\observe-poker.cmd` | Action-table dump |
| `scripts\windows\run-inspector.cmd` | Inspector only (Chrome debug must already be up) |

In the inspector: **247 Free Poker · real web** → **Start demo** → **Choose next** → **Execute choice**.

## macOS / Linux inspector

```bash
cd jev-ultrafast
cp .env.example .env   # TYPESAFE_API_KEY is required for Choose / Run automatically
uv sync
# Chrome must already be running with --remote-debugging-port=9222
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
