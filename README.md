<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/banner-dark.svg">
  <img src="assets/banner-light.svg" alt="teach-me — adaptive AI tutoring, one reasoning step at a time">
</picture>

<div align="center">

[![License: MIT](https://img.shields.io/badge/license-MIT-2f6f5e.svg)](LICENSE)
[![Claude Code Skill](https://img.shields.io/badge/claude%20code-skill-b8712a.svg)](https://claude.com/claude-code)
[![Based on video](https://img.shields.io/badge/based%20on-Eero%20Alvar's%20video-1c231f.svg)](https://youtu.be/kzcI5F4tGiU)

</div>

A Claude Code skill that turns Claude into a one-on-one adaptive tutor for any topic. It measures exactly what you already know, plans a teaching path around that specific gap, and then teaches it one idea at a time with real comprehension checks — instead of dumping a generic explanation on you the way a chat window normally does.

```
/teach-me differential forms
```

---

## Why

Normal learning is many-to-many: one book/course/teacher serves many students, so it can't be tuned to any one of them, and one student pulls from many sources, each with its own notation, style, and a trust cost your brain re-pays every time.

The fix isn't more resources — it's collapsing both directions to one-to-one: a single tutor that knows exactly where your understanding currently ends, and puts all the *logistics* of learning (sourcing, sequencing, fact-checking, pacing) on itself instead of on you, so the only thing you have to struggle with is the actual material.

## What it does

`/teach-me <topic>` runs three phases, in order, every time:

```mermaid
graph LR
    A(["Probe\nfind the edge of\nwhat you know"]) --> B(["Plan\nfact-checked path,\nshown as a graph"])
    B --> C(["Teach\none step at a time,\nquizzed as it lands"])
```

A later `/teach-me` on the same topic reads the log and resumes teaching from wherever the graph was left, instead of starting the whole pipeline over.

| Phase | What happens |
|---|---|
| **Probe** | Multiple-choice binary-searches the edge of your understanding on every concept the topic depends on — answer what you know and it skips ahead, answer wrong or "I don't know" and it narrows in. But a correct multiple-choice pick is never the final word: once it lands on your edge, it confirms with a free-response question ("explain how you'd approach this," not "pick the right box"), because recognizing the right answer and being able to produce it are different skills, and MC alone lets a guess pass as understanding. |
| **Plan** | Reasons out a teaching path from your current understanding to your goal, fact-checks it with a separate subagent before committing, tiers each concept as core (the goal actually depends on it) or peripheral (helpful context) so depth gets spent where it's earned, and shows the result as a dependency graph — partly so you can see what's coming, mostly because being forced to draw the graph stops the plan from being improvised on the fly. |
| **Teach** | Walks the graph one reasoning step at a time — never bundling multiple new ideas into one message — generates and self-verifies diagrams through a subagent when a visual would help, and checks comprehension in a mix of formats: multiple-choice for a quick fact, free-response for anything that tests actual reasoning. A concept only gets marked mastered once it's been applied to something new, not just recognized or re-explained back verbatim. Anything wrong or hollow-sounding gets retaught a different way, not just corrected and left behind. Before starting each new concept, it pauses and hands you the floor for any question that a quiz wouldn't have surfaced — and you can jump in with one anytime, not just at that checkpoint. |

Everything is written to a persistent markdown log per topic as it happens, so you can reopen it later (Obsidian renders it live, LaTeX included), and a later `/teach-me` on the same topic resumes from exactly where you left off instead of re-probing from scratch.

## Example

A real excerpt from a session teaching differential forms to a learner who already knew standard vector calculus but had never seen a covector. This is unedited output, not a mockup.

<details>
<summary><strong>Probe →</strong> locating the edge of understanding</summary>

> **Q:** A dual vector / covector / linear functional on `V` is best described as...
> - **A.** A function `V → ℝ` that's linear: `f(av+bw) = af(v)+bf(w)` ✅ *(correct)*
> - B. A vector flipped to point opposite
> - C. Just another name for the dot product
> - D. Never heard this term
>
> **Answer: D.** Absent — narrow.
>
> **Q:** If `f(v)` returns a number with `f(av+bw) = af(v)+bf(w)`, do you recognize this property?
> - **A.** Yes, that's linearity, comfortable with it ✅ *(correct)*
> - B. That's continuity
> - C. Only makes sense if `f` is a matrix
> - D. Don't know this either
>
> **Answer: A**, confident. **Edge located:** linearity is solid; packaging linear functionals as their own object is genuinely absent — this becomes the session's root teaching gap.

</details>

<details>
<summary><strong>Plan →</strong> a gated dependency graph, not an improvised outline</summary>

```mermaid
graph TD
    L1["Linear functionals (solid)"] --> CV["Covectors: dual vectors as objects (ABSENT — root gap)"]
    CV --> GRAD["Gradient df as a concrete covector"]
    GRAD --> CVF["Covector fields = 1-forms"]
    CVF --> RF["Reframe: work integral as 1-form pairing"]
    CV --> WP["Wedge product: antisymmetric ∧"]
    WP --> TF["2-forms: oriented-area / flux objects"]
```

Every node here traces to a probe result, a front-loaded claim, or an explicit one-line reasoning note — nothing is on the graph just to make it look complete.

</details>

<details>
<summary><strong>Teach →</strong> one step, then a real check before moving on</summary>

> A covector on `V` is a function `α: V → ℝ` that's linear. The picture that makes this concrete: instead of drawing `α` as an arrow, draw it as a **stack of evenly-spaced parallel lines** — given a vector `v`, `α(v)` is the number of lines `v` pierces. A vector is a thing being measured; a covector is the measuring device itself.
>
> **Quiz:** `α` applied to `u` vs. `2u` (same direction, double length) — what's the relationship between `α(u)` and `α(2u)`?
> - **A.** `α(2u) = 2·α(u)` ✅ *(correct — linearity)*
> - B. `α(2u) = α(u)`, covectors only care about direction
> - C. `α(2u) = α(u)²`
> - D. No fixed relationship
>
> **Answer: A.** Correct — node solid, on to the next step.

</details>

A fresh critic later compared this session blind against the source video's own differential-forms demo, on probe quality, plan rigor, pacing, quiz follow-through, and whether any of the work fell on the learner instead of the material. It preferred this session on all five.

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

> Based on the process described in [this video](https://youtu.be/kzcI5F4tGiU) by **Eero Alvar** — all credit for the original probe/plan/teach philosophy goes to him.

This repo is an independent reimplementation of that process for Claude Code's actual tools, plus a few extensions of its own: session resuming, mixed multiple-choice/free-response checks that gate mastery on transfer rather than a lucky pick, per-node discussion pauses, depth tiering by how load-bearing a concept actually is, wrong-answer reteaching, and an end-of-session review queue.

## License

MIT — see [LICENSE](LICENSE).
