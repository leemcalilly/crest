# crest — WebMCP Challenge submission

| | |
|---|---|
| **Live site** | https://crest.soccer |
| **Repository** | https://github.com/leemcalilly/crest |
| **License** | [MIT](LICENSE) |
| **Demo video** | *(YouTube link — pending)* |
| **Built by** | Lee McAlilly |

> **Status: draft.** This file is the working copy of the Devpost entry. It is
> edited in git until submission, so the answers below and the ones on the form
> stay identical.

---

## What it is

crest is a time machine for the United States men's national soccer team. Every
match it has ever played — 795 of them, from 1885 to the 2026 World Cup —
organized not by decade but by **World Cup cycle**, the four years leading to and
including each tournament.

That is how the sport actually measures time, and it is the difference between a
table of numbers and a story. Sorted by decade, the 1990s are a large bar. Sorted
by cycle, the 1994 cycle is a *spike* — 97 matches in four years, the run-up to a
home World Cup — and the line goes flat at about 60 a cycle forever after. One
choice of unit surfaces a fact the other hides.

---

## Why this use case is a strong fit for WebMCP

A stats site is a browsing problem, not a lookup problem. The interesting
questions are comparative and spatial — *which era was this, how does it compare
to the one before, show me where that sits* — and the answers live in a visual
object: a 24-bar timeline of cycles.

A conventional API can describe that timeline. It cannot **move** it. That gap is
what WebMCP closes, and it is why this site would be worse with a server MCP and
no better with an API alone.

A second fit matters more than it sounds: crest has **no accounts, no API keys,
and no model of its own**. The agent brings its own inference. The tools cost
nothing to serve, leak nothing, and rate-limit nothing.

---

## How it creates a better user experience

Most of the time it doesn't change the experience at all, and that was a design
goal. **Nothing on crest is agent-only.** Every tool does something you can
already do by clicking. With no agent present the site behaves exactly as before.

What changes is when you arrive *with* an agent. The conversation and the page
stop being separate places. You ask which cycle had the most matches and the
timeline moves to 1994 while you are looking at it. You ask about the war years
and the 1939–1950 bar lights up on your screen. You never translate the agent's
answer back into a click.

A badge in the header states plainly whether your browser can do this and links
to [an explanation of WebMCP](https://crest.soccer/tools) and how to turn it on.
The capability is disclosed, not hidden.

---

## What people and agents can do together that was difficult or impossible before

**Shared attention.** Before WebMCP, an agent looking at a page could describe it
to you and you could describe it back. Neither could point. `highlight_cycle` lets
the agent point — the bar lights up on the reader's screen, and both parties are
now certainly looking at the same thing. A small primitive with a large
consequence: it removes the translation step that made agent-assisted browsing
feel like a phone call with someone reading a different document.

**Navigation as an answer.** `set_cycle` means the answer to "take me to 1994" is
the page being at 1994, not a paragraph describing it. The agent's reply and the
application's state become the same act.

**Grounded questions about what is on screen.** `read_current_page` lets the agent
ask the page what the reader is actually looking at, so "compare this to the
previous cycle" resolves without the human restating context the screen holds.

**The agent composes a visualization inside your page.** This is the one we would
point a judge at first. Ask *"were they actually any good in the seventies, or just
playing a lot?"* and `plot_cycles` redraws all 24 bars from match counts to win
rate — the chart re-animates and the answer becomes visible rather than described.
Switch it to goal difference and half the timeline turns red: the United States
used to lose on aggregate, and stopped. Then `filter_by_opponent("Mexico")` narrows
the same bars to 76 matches against one rival across a century.

A server MCP could return those numbers, or render an image and hand it over. It
could not reshape the chart the reader is already looking at. That is the whole
distinction, and it is the moment where the agent stops being a research assistant
and starts operating the interface alongside you.

---

## How WebMCP was implemented

Nine tools — four read, five act on the live page.

| Tool | Kind | What it does |
|---|---|---|
| `list_cycles` | read | Every World Cup cycle with its match count |
| `read_cycle` | read | One cycle's record and every match in it |
| `search_matches` | read | Find matches by opponent, year or tournament |
| `read_player` | read | A scorer's card, goals broken down by cycle |
| `set_cycle` | **page** | Moves the time machine; the reader watches it happen |
| `highlight_cycle` | **page** | Lights one bar while the agent explains |
| `plot_cycles` | **page** | Redraws the timeline by wins, goals, goal difference or win rate |
| `filter_by_opponent` | **page** | Redraws the same bars for one opponent across all 24 cycles |
| `read_current_page` | **page** | What the reader is looking at right now |

**The catalog is Ruby, not JavaScript.** [`app/models/model_context/`](app/models/model_context)
holds a `Tool` descriptor and a `Manifest`. Each tool declares a name, a
natural-language description, a JSON Schema with `required` and
`additionalProperties: false`, and `annotations` including `readOnlyHint`.
Because the catalog is server-side it is unit-tested: [a test](test/models/model_context/manifest_test.rb)
asserts every read tool points at a real site URL, that page tools name no URL,
and that tools which move the page are never marked read-only.

**The manifest is server-rendered** into a `<script type="application/json">` tag.
[One Stimulus controller](app/javascript/controllers/model_context_controller.js)
reads it and calls `registerTool` for each entry, passing an `AbortSignal` so
page-scoped tools unregister cleanly on Turbo navigation.

**Read tools call the site's own URLs.** There is no `/api` namespace.
`read_cycle` fetches `/cycles/1994.json` — the same controller, model and scope
that renders the HTML page, with the reader's own cookies.

**Page tools have no server equivalent.** `set_cycle` performs a Turbo visit;
`highlight_cycle` adds a class to a bar and scrolls it into view;
`read_current_page` reports live DOM state. These exist only in the browser, which
is the whole argument for WebMCP over a server MCP.

### Two traps worth passing on

**`modelContext` is not in one place.** The normative IDL puts it on `Document`,
but shipping builds have exposed it on `Navigator`. crest checks both rather than
betting the site on one spelling.

**Never name it `this.context` inside a Stimulus controller.** Stimulus owns that
property, and every target helper reads through it. Assigning to it broke all
seven tools while *discovery still passed* — the tool list looked healthy and
every invocation failed with `Cannot read properties of undefined (reading
'targets')`. There is now [a test](test/javascript_conventions_test.rb) that fails
if any controller assigns to a reserved Stimulus property.

---

## On the data, and what crest refuses to invent

Everything comes from [martj42/international_results](https://github.com/martj42/international_results),
**CC0-1.0**, shipped unmodified in `db/source` so any figure can be checked
against the original.

- **Caps render as an em dash, never zero.** The source has no appearance data. A
  zero is a claim; a dash is an absence.
- **Goal totals are a floor, not a career total** — the record covers major
  tournaments and friendlies unevenly. Every player card says so in its footer.
- **The women's record is absent**, and [`/sources`](https://crest.soccer/sources)
  says why: that dataset carries no license file, so it cannot be redistributed in
  an open-source repository.

An agent reading this site is told the same limits a person is. That felt like the
right standard for a tool designed to be read by something that will repeat what
it finds.

---

## Running it yourself

```bash
bin/setup
bin/rails crest:import   # reads db/source, about three seconds
bin/rails server
```

Or pull the exact production image:

```bash
docker run -p 3000:80 -e SECRET_KEY_BASE=$(openssl rand -hex 32) \
  -e APP_HOST=localhost ghcr.io/leemcalilly/crest
```

To see the tools, open the site in ChatGPT's desktop browser, or in Chrome with
`chrome://flags/#enable-webmcp-testing` enabled.
