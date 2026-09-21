"""Observed actions through Browser Harness; one CDP session, no per-step subprocess."""

import hashlib
import json
import sys
import time
from pathlib import Path

from browser_harness.admin import ensure_daemon
from browser_harness.helpers import cdp

# Atomically read visible content and controls, preserving actual DOM node identity.
READ_STATE = Path(__file__).with_name("snapshot.js").read_text()
MARKER = f"(() => {{ const state={READ_STATE}; return state?.marker ?? null; }})()"
POKER_HOME = "https://www.247freepoker.com/"


def poker_start_url(url):
    """Isolated game/frame.html is a static loader; only the parent page boots CreateJS."""
    raw = url or ""
    if "247freepoker.com" in raw.lower() and "frame.html" in raw.lower():
        return POKER_HOME
    return url


def _is_isolated_poker_frame(url):
    raw = (url or "").lower()
    return "247freepoker.com" in raw and "frame.html" in raw


class StalePage(ValueError):
    """A decision no longer refers to the observed page."""


class Browser:
    def __init__(self, url):
        ensure_daemon()
        self.target = cdp("Target.createTarget", url="about:blank", background=True)["targetId"]
        self.session = cdp("Target.attachToTarget", targetId=self.target, flatten=True)["sessionId"]
        self.call("Emulation.setDeviceMetricsOverride", width=1120, height=780, deviceScaleFactor=1, mobile=False)
        # Keep rAF/menus rendering in an owned background tab, without activating the user's Chrome tab.
        self.call("Emulation.setFocusEmulationEnabled", enabled=True)
        self.open_page(poker_start_url(url))

    def _wait_ready(self, seconds=15):
        deadline = time.monotonic() + seconds
        while time.monotonic() < deadline:
            try:
                if self.evaluate("document.readyState") == "complete":
                    return
            except StalePage:
                pass
            time.sleep(0.02)

    def _wait_poker_iframe(self, seconds=20):
        deadline = time.monotonic() + seconds
        while time.monotonic() < deadline:
            try:
                if self.evaluate(
                    """(() => {
                      const f = document.querySelector('#app-player-cjs-frame, iframe');
                      try {
                        const doc = f && f.contentDocument;
                        return !!(doc && doc.querySelector('canvas'));
                      } catch (e) { return false; }
                    })()"""
                ):
                    return
            except StalePage:
                pass
            time.sleep(0.2)

    def open_page(self, url):
        target = poker_start_url(url)
        self.call("Page.navigate", url=target)
        self._wait_ready(15)
        try:
            href = self.evaluate("location.href") or ""
        except StalePage:
            href = ""
        if _is_isolated_poker_frame(href):
            self.call("Page.navigate", url=POKER_HOME)
            self._wait_ready(15)
            href = POKER_HOME
        if "247freepoker.com" in href.lower():
            self._close_stray_isolated_frames()
            cdp("Target.activateTarget", targetId=self.target)
            self._wait_poker_iframe(20)

    def _close_stray_isolated_frames(self):
        """Isolated top-level game/frame.html tabs are leftover loaders, not the live table."""
        try:
            infos = cdp("Target.getTargets").get("targetInfos") or []
        except Exception:
            return
        for info in infos:
            if info.get("targetId") == self.target or info.get("type") != "page":
                continue
            if _is_isolated_poker_frame(info.get("url")):
                cdp("Target.closeTarget", targetId=info["targetId"])

    def call(self, method, **params):
        return cdp(method, session_id=self.session, **params)

    def evaluate(self, expression):
        response = self.call("Runtime.evaluate", expression=expression, returnByValue=True)
        if response.get("exceptionDetails"):
            raise StalePage("Document changed during evaluation")
        return response.get("result", {}).get("value")

    def observe(self, screenshot=True):
        if getattr(self, "after_input", None):
            action, self.after_input = self.after_input, None
            # This is read-only and happens after execution was logged, even if navigation interrupts it.
            try:
                self.call(
                    "Runtime.evaluate",
                    expression="""(action => new Promise(resolve => {
                      const field=window.__jevFast?.nodes.get(action.node);
                      const autocomplete=action.kind==='fill' && field?.getAttribute('role')==='combobox';
                      let frames=0, stopped=false;
                      const finish=()=>{stopped=true;resolve()};
                      setTimeout(finish,autocomplete ? 200 : 50);
                      const ready=()=>{
                        if (stopped) return;
                        const ids=(field?.getAttribute('aria-controls')||field?.getAttribute('aria-owns')||'')
                          .split(/\\s+/).filter(Boolean);
                        const roots=ids.length ? ids.map(id=>document.getElementById(id)).filter(Boolean) : [document];
                        const options=roots.flatMap(root=>[...root.querySelectorAll('[role="option"]')]);
                        if (++frames>=2 && (!autocomplete || options.some(e=>{
                          const r=e.getBoundingClientRect();
                          return r.width && r.height && r.bottom>0 && r.top<innerHeight &&
                            e.checkVisibility({checkOpacity:true,checkVisibilityCSS:true});
                        }))) finish();
                        else requestAnimationFrame(ready);
                      };
                      requestAnimationFrame(ready);
                    }))(""" + json.dumps(action) + ")",
                    awaitPromise=True,
                    returnByValue=True,
                )
            except RuntimeError:
                pass
        for attempt in range(10):
            try:
                page = browser_operation(
                    {"operation": "observe", "session": self.session, "screenshot": screenshot}
                )
                if _is_isolated_poker_frame(page.get("url")):
                    self.open_page(POKER_HOME)
                    continue
                return page
            except StalePage:
                if attempt == 9:
                    raise
                time.sleep(0.02)
        raise StalePage("Page did not settle")

    def fresh(self, page, action=None):
        if action is not None and action["kind"] in {"click", "select"}:
            node = action["node"]
            if type(node) is not int:
                return False
            current = self.evaluate(
                "(() => { const c=window.__jevFast; "
                f"return c ? [c.pageKey(),c.guard(c.nodes.get({node}))] : null; }})()"
            )
            return current == [page["page_key"], page["guards"].get(str(node))]
        return self.evaluate(MARKER) == page["marker"]

    def act(self, action, page, text=None):
        if not self.fresh(page, action):
            raise StalePage("Page changed since this decision. Observe again.")
        if action["kind"] == "wait":
            time.sleep(0.1)
        result = browser_operation({"operation": "act", "session": self.session, "action": action, "text": text})
        self.after_input = action if action["kind"] != "wait" else None
        return result

    def close(self):
        if self.target:
            cdp("Target.closeTarget", targetId=self.target)
            self.target = None


def fingerprint(state):
    content = {k: state[k] for k in ("url", "text", "actions", "scroll")}
    return hashlib.sha256(json.dumps(content, sort_keys=True).encode()).hexdigest()


def browser_operation(request):
    operation = request["operation"]
    session = request["session"]

    def call(method, **params):
        return cdp(method, session_id=session, **params)

    def evaluate(expression):
        result = call("Runtime.evaluate", expression=expression, returnByValue=True)
        if result.get("exceptionDetails"):
            if operation == "act" and request["action"]["kind"] == "select":
                raise RuntimeError("Dropdown execution was interrupted; inspect before retrying.")
            raise StalePage("Document changed during evaluation")
        return result.get("result", {}).get("value")

    if operation == "act":
        action = request["action"]
        kind = action["kind"]
        if kind == "scroll":
            call("Input.dispatchMouseEvent", type="mouseWheel", x=550, y=650, deltaX=0, deltaY=action["delta"])
        elif kind != "wait":
            if type(action["node"]) is not int:
                raise ValueError("Invalid observed node")
            # Code-owned node IDs refer to actual observed elements, never model-generated selectors.
            target = evaluate("""(action => {
              const e=window.__jevFast?.nodes.get(action.node);
              if (!e?.isConnected || e.matches(':disabled') || e.closest('[aria-disabled="true"],[inert]') ||
                  !e.checkVisibility({checkOpacity:true,checkVisibilityCSS:true})) return null;
              if (action.kind==='fill' && (e.readOnly || e.getAttribute('aria-readonly')==='true')) return null;
              const r=e.getBoundingClientRect();
              const frame=e.ownerDocument?.defaultView?.frameElement;
              const fr=frame ? frame.getBoundingClientRect() : {x:0,y:0};
              const x=r.x+fr.x+r.width/2, y=r.y+fr.y+r.height/2;
              if (!r.width || !r.height || x<0 || y<0 || x>=innerWidth || y>=innerHeight) return null;
              const hit=document.elementFromPoint(x,y);
              if (frame) {
                if (hit!==frame && !frame.contains(hit)) return null;
              } else if (!e.contains(hit)) return null;
              if (action.kind==='select') {
                if (e.tagName!=='SELECT' || ![...e.options].some(o=>o.value===action.value &&
                    !o.disabled && !o.closest('optgroup[disabled]'))) return null;
                e.value=action.value;
                e.dispatchEvent(new Event('input',{bubbles:true}));
                e.dispatchEvent(new Event('change',{bubbles:true}));
              }
              return {x,y};
            })(""" + json.dumps(action) + ")")
            if target is None:
                if kind == "select":
                    raise RuntimeError("Dropdown execution was not confirmed; inspect before retrying.")
                raise StalePage("Target changed or is covered. Observe again.")
            if kind != "select":
                x, y = target["x"], target["y"]
                for event in ("mousePressed", "mouseReleased"):
                    call("Input.dispatchMouseEvent", type=event, x=x, y=y, button="left", clickCount=1)
                if kind == "fill":
                    call(
                        "Input.dispatchKeyEvent",
                        type="keyDown",
                        key="a",
                        code="KeyA",
                        modifiers=4 if sys.platform == "darwin" else 2,
                        commands=["selectAll"],
                    )
                    call(
                        "Input.dispatchKeyEvent",
                        type="keyUp",
                        key="a",
                        code="KeyA",
                        modifiers=4 if sys.platform == "darwin" else 2,
                    )
                    call("Input.insertText", text=request["text"])
        return {"executed": action["id"]}

    info = evaluate(READ_STATE)
    if info is None:
        raise StalePage("Document is navigating")
    info["fingerprint"] = fingerprint(info)
    if request.get("screenshot", True):
        try:
            info["screenshot"] = cdp(
                "Page.captureScreenshot",
                session_id=session,
                format="jpeg",
                quality=72,
                _response_timeout=60,
            )["data"]
        except TimeoutError:
            info["screenshot"] = None
    return info
