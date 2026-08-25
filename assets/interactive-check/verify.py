#!/usr/bin/env python3
"""Structural sanity check for a built interactive-check artifact.

Run this on whatever build.py just produced, before publishing it. It catches
the two real bugs found while building this template - both silent, both fatal:

1. A raw "</script" sequence hiding inside the embedded KaTeX/head snapshot
   truncating the outer <script id="app-script"> block, so most of the app's
   JS never parses (the page loads with buttons that silently do nothing).
2. A leftover __PLACEHOLDER__ that never got substituted.

It does NOT check that the page renders correctly or that KaTeX actually
typesets - there is no browser available in this environment to check that.
Treat a clean run here as "structurally sound," not "visually verified."

Usage: python verify.py output.html
"""
import sys
import pathlib

def verify(html_path: pathlib.Path) -> bool:
    html = html_path.read_text(encoding="utf-8")
    failures = []

    def check(name, cond):
        if not cond:
            failures.append(name)

    start = html.find('<script id="app-script">')
    check("app-script tag found", start != -1)
    if start == -1:
        print("FAILED:", *failures, sep="\n - ")
        return False
    open_end = start + len('<script id="app-script">')
    real_close = html.find("</script>", open_end)
    check("a closing </script> exists after the open tag", real_close != -1)
    segment = html[open_end:real_close]

    for marker in ["const STATIC_HEAD", "const LESSON", "function buildDoc",
                    "function pickMC", "function submitCode", "if (document.readyState"]:
        check(f'app-script segment contains "{marker}"', marker in segment)

    check("app-script segment is the full ~500KB+ script, not a truncated fragment",
          len(segment) > 400000)

    for placeholder in ["__STATIC_HEAD_JSON__", "__LESSON_JSON__", "__STATE_JSON__",
                          "/*__KATEX_CSS__*/", "/*__KATEX_JS__*/", "/*__AUTORENDER_JS__*/",
                          "<!--HEAD_START-->", "<!--HEAD_END-->"]:
        check(f'no leftover placeholder "{placeholder}"', placeholder not in html)

    if failures:
        print("FILE STRUCTURE CHECK FAILED:")
        for f in failures:
            print(" -", f)
        return False
    print(f"FILE STRUCTURE CHECK OK ({len(html)} bytes, app-script segment {len(segment)} bytes)")
    return True


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    ok = verify(pathlib.Path(sys.argv[1]))
    sys.exit(0 if ok else 1)
