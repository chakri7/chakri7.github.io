"""Dump the Jev Ultrafast action table on 247 Free Poker without requiring a model call.

uv run --env-file .env python examples/observe_poker.py
"""

from __future__ import annotations

import json
import time
from datetime import datetime, timezone
from pathlib import Path

from jev_ultrafast import Agent
from jev_ultrafast.browser import POKER_HOME, _is_isolated_poker_frame, poker_start_url
from jev_ultrafast.demo import POKER_GOAL, load_environment

POKER_SITE = poker_start_url(POKER_HOME)
GOAL = POKER_GOAL


def main() -> None:
    load_environment()
    output = Path("artifacts/poker-observe") / datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    output.mkdir(parents=True, exist_ok=True)
    with Agent(POKER_SITE, GOAL, screenshots=False) as agent:
        time.sleep(3)
        page = agent.browser.observe(screenshot=False)
        play = next(
            (
                a
                for a in page.get("actions", [])
                if a.get("kind") == "click" and "play" in (a.get("label") or "").lower()
            ),
            None,
        )
        if play and "play" in (play.get("label") or "").lower():
            try:
                agent.browser.act(play, page)
                time.sleep(4)
                page = agent.browser.observe(screenshot=False)
            except Exception as error:
                print(f"play click skipped: {error}", flush=True)
        agent.state["page"] = page
        try:
            shot = agent.browser.call("Page.captureScreenshot", format="jpeg", quality=60)
            page["screenshot"] = shot.get("data")
        except Exception as error:
            print(f"screenshot skipped: {error}", flush=True)
        state = agent.snapshot()
        actions = [
            {
                "id": action.get("id"),
                "kind": action.get("kind"),
                "role": action.get("role"),
                "label": action.get("label"),
                "rect": action.get("rect"),
            }
            for action in page.get("actions", [])
        ]
        report = {
            "url": page.get("url"),
            "title": page.get("title"),
            "text_preview": (page.get("text") or "")[:1500],
            "action_count": len(actions),
            "actions": actions,
            "has_fold_call_raise_dom": any(
                "canvas" not in (action.get("label") or "").lower()
                and any(word in (action.get("label") or "").lower() for word in ("fold", "call", "raise", "check"))
                for action in actions
            ),
        }
        if _is_isolated_poker_frame(page.get("url")):
            raise SystemExit(
                "Observed isolated game/frame.html. The live table is the homepage iframe, "
                "not this loader tab."
            )
        print(f"PARENT {page.get('url')}  (iframe may still be game/frame.html)", flush=True)
        (output / "actions.json").write_text(json.dumps(report, indent=2))
        if page.get("screenshot"):
            import base64

            (output / "table.jpg").write_bytes(base64.b64decode(page["screenshot"]))
        print(json.dumps(report, indent=2))
        print(f"Wrote {output}", flush=True)
        _ = state


if __name__ == "__main__":
    main()
