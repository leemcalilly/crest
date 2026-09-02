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
match it has played — 795 of them, from 1885 to the 2026 World Cup —
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
point a judge at first. crest has a single chart panel, and `plot_chart` lets the
agent decide what it shows — World Cup cycles, opponents, host cities, or scorers —
and what the bar heights measure.

Ask *"were they actually any good in the seventies, or just playing a lot?"* and the
24 cycle bars redraw from match counts to win rate. Switch to goal difference and
half the timeline turns red: the United States used to lose on aggregate, and
stopped. Ask *"who do they play most?"* and the same panel becomes a ranking of
opponents — Mexico at 76. Ask where, and it becomes host cities, where Mexico City
leads at 27. The cycles view is one view among several, not the only thing the
panel can draw.

A server MCP could return those numbers, or render an image and hand it over. It
could not reshape the chart the reader is already looking at. That is the whole
distinction, and it is the moment where the agent stops being a research assistant
and starts operating the interface alongside you.

---

## How WebMCP was implemented

Eight tools — four read the record, four work on the page in front of you.
(The split is not read versus write: `read_current_page` only reads, but what it
reads is the live page, which no server tool can see.)

| Tool | Kind | What it does |
|---|---|---|
| `list_cycles` | read | Every World Cup cycle with its match count |
| `read_cycle` | read | One cycle's record and every match in it |
| `search_matches` | read | Find matches by opponent, year or tournament |
| `read_player` | read | A scorer's card, goals broken down by cycle |
| `set_cycle` | **page** | Moves the time machine; the reader watches it happen |
| `highlight_cycle` | **page** | Lights one bar while the agent explains |
| `plot_chart` | **page** | Draws a different view in the chart: cycles, opponents, venues or scorers |
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

**Tools are scoped to the page that can run them.** `plot_chart` and
`highlight_cycle` are offered only where a chart is rendered; a page without one
never advertises them, so an agent is never handed a tool that would fail. This
is the page-scoping WebMCP exists for, and it is asserted by a test.

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

## Try it yourself — the repeatable test

This is the sequence in the demo video, and it is also how anyone can verify the
entry. It needs no setup: in ChatGPT, ask it to open **crest.soccer** in its
browser and tell you what tools the site offers, then work down the list.

Everything below happens in the one chart at the top of the page. Nothing is
clicked.

| # | Ask | What should happen | Tool |
|---|---|---|---|
| 1 | *"Open crest.soccer and tell me what tools this site gives you."* | Eight tools listed — four read, four act on the page | discovery |
| 2 | *"Were they actually any good in the seventies, or just playing a lot?"* | The 24 cycle bars redraw from match counts to win rate | `plot_chart` |
| 3 | *"What about goal difference?"* | Half the timeline turns red — the United States used to lose on aggregate, and stopped | `plot_chart` |
| 4 | *"Who do they play the most?"* | The same panel becomes a ranking of opponents. Mexico, 76 matches | `plot_chart` |
| 5 | *"And where do they play?"* | Host cities. Mexico City leads with 27, one ahead of Washington, D.C. | `plot_chart` |
| 6 | *"Show me only the matches against Mexico, cycle by cycle."* | Back to cycles, narrowed to one rivalry across a century | `plot_chart` |
| 7 | *"Take me to the cycle that ended at the home World Cup."* | The page navigates to 1994 | `set_cycle` |
| 8 | *"Which cycle had no tournament at all?"* | The 1939–1950 bar lights up: twelve years, no World Cup | `highlight_cycle` |

**If the chart does not move**, the agent is describing the page instead of using
its tools. Ask it to use the site's tools, or check that the badge in the header
says they are ready.

The same list is on the site at [crest.soccer/tools](https://crest.soccer/tools),
alongside instructions for enabling WebMCP in Chrome.

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
