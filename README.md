# teach-me

A [Claude Code](https://claude.com/claude-code) skill that turns Claude into a one-on-one adaptive tutor for any topic: it measures exactly what you already know, plans a teaching path around that specific gap, and then teaches it one idea at a time with real comprehension checks — instead of dumping a generic explanation on you the way a chat window normally does.

## Why

Normal learning is many-to-many: one book/course/teacher serves many students, so it can't be tuned to any one of them, and one student pulls from many sources, each with its own notation, style, and a trust cost your brain re-pays every time. The fix isn't more resources — it's collapsing both directions to one-to-one: a single tutor that knows exactly where your understanding currently ends, and puts all the *logistics* of learning (sourcing, sequencing, fact-checking, pacing) on itself instead of on you, so the only thing you have to struggle with is the actual material.

## What it does

`/teach-me <topic>` runs three phases:

1. **Probe** — asks graded multiple-choice questions (via Claude Code's native question tool) that binary-search the edge of your understanding on every concept the topic depends on. Answer what you know; it skips ahead. Answer wrong or "I don't know"; it narrows in on exactly where the gap is.
2. **Plan** — reasons out a teaching path from your current understanding to your goal, fact-checks the plan with a separate subagent before committing to it, and shows you the result as a dependency graph (a mermaid diagram) — partly so you can see what's coming, mostly because being forced to draw the graph stops the plan from being improvised on the fly.
3. **Teach** — walks the graph one reasoning step at a time (never bundling multiple new ideas into one message), generates and self-verifies diagrams through a subagent when a visual would help, quizzes you after each step to confirm it actually landed, and reteaches — differently, not just repeats — anything you get wrong.

Everything is written to a persistent markdown log per topic as it happens, so you can reopen it later (Obsidian renders it live, LaTeX included) and so a later `/teach-me` on the same topic resumes from exactly where you left off instead of re-probing from scratch.

## Install

Copy `SKILL.md` into your Claude Code skills directory as its own folder:

```
~/.claude/skills/teach-me/SKILL.md
```

or, for a single project only:

```
<project>/.claude/skills/teach-me/SKILL.md
```

Restart Claude Code (or start a new session) and `/teach-me` will be available.

## Use

```
/teach-me differential forms
/teach-me how transformers do attention
/teach-me                      # it'll ask what you want to learn and your goal
```

Before probing starts, you can front-load anything you already know solidly — that skips the corresponding questions instead of asking you to sit through them.

If you invoke `/teach-me` again on a topic you've already started, it reads the existing log, re-checks only the shakiest recent nodes, and resumes teaching from where it left off.

## Requirements

- Claude Code, with the `AskUserQuestion` and `Agent` (subagent) tools available — both are standard.
- A way to render and view an SVG/image (a browser tool, an image-capable file viewer, etc.) for the visual-verification step in the teach phase. If none is available, the skill says so plainly rather than shipping an unverified diagram — visuals just get skipped or described in words instead.
- Nothing else. No MCP server, no external API, no paid tooling.

## Notes and known limitations

- The quiz mechanic has been exercised against a scripted learner persona during development, not yet against a large sample of real, unpredictable answers — expect to file sharp edges as you actually use it.
- Diagram rendering falls back to whatever's available in your environment; the fallback path is more fragile than the primary one and won't look identical across machines.
- The skill deliberately doesn't prescribe a teaching voice or personality — it optimizes for pacing, rigor, and correctness, and leaves style up to you to specify if you care about it.

## Credits

Based on the process described in [this video](https://youtu.be/kzcI5F4tGiU) by Eero Alvar — all credit for the original probe/plan/teach philosophy goes to him. This repo is an independent reimplementation of that process for Claude Code's actual tools, plus some extensions of its own (session resuming, wrong-answer reteaching, an end-of-session review queue).

## License

MIT — see [LICENSE](LICENSE).
