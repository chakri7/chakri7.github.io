# 247 Free Poker on Jev Ultrafast

This tree is [Browser Use’s Jev Ultrafast](https://github.com/browser-use/jev-ultrafast) plus a poker scenario for the **live site**, not the isolated game frame.

## What the site actually is

`https://www.247freepoker.com/` is the real player. It embeds:

```html
<iframe id="app-player-cjs-frame" src="game/frame.html">
```

`game/frame.html` is **not** a playable page by itself. Its boot script does `window.parent.games247.gameSupport.ready(...)`, which loads `js/game.js`. Opened as a top-level URL, `parent.games247` is missing, so CreateJS never starts and you only see the static “247 GAMES / LOADING…” art.

Checked live (HTTP + CDP, 2026-09-21): **the homepage does not redirect**. `https://www.247freepoker.com/` stays 200 with no `Location` header and no `location.assign` / `top.location` in page scripts. For 24s after load, `location.href` remained the homepage. The site **embeds** the game (`<iframe id="app-player-cjs-frame" src="game/frame.html?v=…">`). That iframe uses the same yellow loader art, then `game.js` paints PLAY. A leftover Chrome tab titled **247 Game Frame** is a previous top-level open of `frame.html`, not a redirect. The agent now closes those stray tabs and brings the homepage tab to the front.

The table, cards, and Fold / Call / Raise are still a **CreateJS canvas** after boot. They are not HTML buttons. `#pause-overlay` (“Press here to play!”) is the DOM click inside the iframe.

This fork:

1. Starts the inspector on `https://www.247freepoker.com/` so the parent handshake can run.
2. If Chrome or an old clone still asks for `game/frame.html`, the browser **rewrites that URL to the homepage**.
3. Snapshots **same-origin iframes** first (the game), then the outer page.
4. Indexes `#pause-overlay` and `canvas` as click targets.
5. Windows `bootstrap-windows.ps1` / `run-windows.cmd` **hard-reset** the clone to `origin/cursor/jev-ultrafast-poker-4ef6` so you are not stuck on the old `frame.html` commit.

Jev still cannot rank Fold vs Call from DOM. That needs canvas OCR after the table is actually running.

If you still see the static “247 GAMES / LOADING…” art, you are on isolated `frame.html`. Close that tab. Re-run `run-windows.cmd` (it prints the git commit) and Start demo from the inspector — the URL bar in the inspector must be `https://www.247freepoker.com/`.

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

The inspector **defaults to poker**. **Start demo** → **Choose next** → **Execute choice**. Do not type `game/frame.html` into Chrome.

## macOS / Linux inspector

```bash
cd jev-ultrafast
cp .env.example .env   # TYPESAFE_API_KEY is required for Choose / Run automatically
uv sync
# Chrome must already be running with --remote-debugging-port=9222
uv run jev
```

Open `http://127.0.0.1:8766/?scenario=poker` and Start demo.

`Choose next` calls TypeSafe. Observing the page does not.

## Dump the action table (no Jev call)

```bash
cd jev-ultrafast
uv sync
uv run python examples/observe_poker.py
```

Writes `artifacts/poker-observe/<timestamp>/actions.json` and `table.jpg`.
