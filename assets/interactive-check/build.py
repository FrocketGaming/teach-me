#!/usr/bin/env python3
"""Build a self-contained interactive lesson-check Artifact from a LESSON config.

Usage:
    python build.py lesson.json output.html

lesson.json shape (mc / free / code are each optional - set to null to omit):
{
  "eyebrow": "Lesson check",
  "titleHTML": "Short title, may include $math$ or &amp;",
  "subtitle": "One sentence describing what this checks.",
  "mc": {
    "eyebrow": "Concept check",
    "prompt": "Plain text prompt, may include $math$.",
    "options": [{"text": "...", "correct": true}, ...],
    "explainCorrect": "Shown when the right option is picked.",
    "explainWrong": "Shown when a wrong option is picked."
  },
  "free": {
    "eyebrow": "Explain it",
    "prompt": "Plain text prompt.",
    "minChars": 8
  },
  "code": {
    "eyebrow": "Code it",
    "promptHTML": "May include <code>...</code> tags - not auto-escaped.",
    "fnName": "theFunctionNameTheLearnerMustDefine",
    "starter": "function theFunctionNameTheLearnerMustDefine(...) {\\n  // ...\\n}",
    "tests": [{"args": [...], "expected": ...}, ...]
  }
}

Math in "prompt" / "explainCorrect" / "explainWrong" / "options[].text" uses
$...$ / $$...$$ delimiters (KaTeX auto-render) and is HTML-escaped, so plain
LaTeX source is safe there. "titleHTML" and "code.promptHTML" are NOT escaped
(they may contain trusted inline HTML like <code>) - never put learner input
in those fields, only Claude-authored lesson text.
"""
import json
import sys
import pathlib

HERE = pathlib.Path(__file__).parent


def build(lesson: dict, output_path: pathlib.Path):
    template = (HERE / "template.html").read_text(encoding="utf-8")
    katex_css = (HERE / "katex.inline.css").read_text(encoding="utf-8")
    katex_js = (HERE / "katex.min.js").read_text(encoding="utf-8")
    autorender_js = (HERE / "auto-render.min.js").read_text(encoding="utf-8")

    out = template
    out = out.replace("/*__KATEX_CSS__*/", katex_css)
    out = out.replace("/*__KATEX_JS__*/", katex_js)
    out = out.replace("/*__AUTORENDER_JS__*/", autorender_js)

    # Capture the fully-substituted head markup (title/meta/fonts/KaTeX/CSS) as
    # a static text snapshot the client script falls back on when rebuilding
    # the document on submit, since the live document.head cannot be trusted
    # at runtime (the artifact viewer's own sandbox runtime rewrites it before
    # any page script sees it - see the comment on buildDoc() in template.html).
    start_marker = "<!--HEAD_START-->"
    end_marker = "<!--HEAD_END-->"
    s = out.index(start_marker) + len(start_marker)
    e = out.index(end_marker)
    head_snapshot = out[s:e]
    out = out.replace(start_marker, "").replace(end_marker, "")
    # head_snapshot embeds katex/auto-render <script> blocks verbatim, so their
    # raw text contains literal "</script>" sequences. json.dumps() does not
    # escape "/", so without this the HTML parser would end the outer
    # <script id="app-script"> block at the first one of those - breaking the
    # page on the very first load, not just on republish. Escaping every "<"
    # neutralizes that regardless of tag or case (mirrors the state-blob escape
    # below, and is exercised by test_file_structure.py in this directory).
    static_head_js = json.dumps(head_snapshot).replace("<", "\\u003c")
    out = out.replace("__STATIC_HEAD_JSON__", static_head_js)

    out = out.replace("__LESSON_JSON__", json.dumps(lesson).replace("<", "\\u003c"))

    initial_state = {
        "mc": {"selected": None, "submitted": False},
        "free": {"text": "", "submitted": False},
        "code": {
            "code": (lesson.get("code") or {}).get("starter", ""),
            "results": None,
            "submitted": False,
        },
    }
    out = out.replace("__STATE_JSON__", json.dumps(initial_state).replace("<", "\\u003c"))

    output_path.write_text(out, encoding="utf-8")
    print(f"wrote {output_path} ({len(out)} bytes)")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    lesson_path, out_path = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
    build(json.loads(lesson_path.read_text(encoding="utf-8")), out_path)
