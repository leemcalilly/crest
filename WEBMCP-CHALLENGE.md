# crest — WebMCP Challenge submission

| | |
|---|---|
| **Live site** | https://crest.soccer |
| **Repository** | https://github.com/leemcalilly/crest |
| **License** | [MIT](LICENSE) |
| **The `registerTool` call** | [`model_context_controller.js#L79`](https://github.com/leemcalilly/crest/blob/24374df5397651612236cfd76c7753ef54bec191/app/javascript/controllers/model_context_controller.js#L79-L99) |
| **Tool catalog (Ruby)** | [`app/models/model_context/`](https://github.com/leemcalilly/crest/blob/24374df5397651612236cfd76c7753ef54bec191/app/models/model_context/manifest.rb) |
| **Try it in one prompt** | [crest.soccer/tools](https://crest.soccer/tools) |
| **Demo video** | *(YouTube link — pending)* |
| **Built by** | Lee McAlilly |

---

## What we actually built: a dashboard that assembles itself

The interesting thing here is not the soccer data. It is what happens to a chart
when an agent can draw on it.

crest has one visualization panel. I did not build a screen for "opponents by
win rate", or "host cities", or "goal difference against Mexico across a
century". I built a dataset, a small set of WebMCP tools, and a surface those
tools can paint on. **Everything else assembles itself in response to whatever
the person asks.**

Ask *"were they any good in the seventies, or just playing a lot?"* and the
twenty-four cycle bars redraw from match counts to win rate. Ask about goal
difference and half the timeline turns red. Ask who they play the most and the
same panel becomes a ranking of opponents. None of those views is a page we
designed. They are compositions the agent makes at the moment of the question,
out of parts I exposed.

That is a just-in-time interface — a **malleable dashboard**. The
old bargain was that a designer anticipates every question and builds a screen
for each one, and anything unanticipated becomes a support ticket or a CSV
export. Here the person asks, and the interface arrives. It is not hard to
imagine where this goes: analytics, admin panels, anything today buried under
forty saved views that still miss the one you want.

What I have built is a small demonstration — green shoots. But it is a complete
one, end to end, and the mechanism is all there.

## Why us, and why this data

I have followed the United States men's team since the 1994 World Cup —
the tournament that arrives, in this app, as the tallest bar on the timeline: 97
matches in the four years of building for a home World Cup, a spike that never
repeats. Picking a dataset you have cared about for thirty years is how you
notice that decades are the wrong unit and World Cup cycles are the right one.
That decision is what makes the chart worth handing to an agent at all.

## Why this use case is a strong fit for WebMCP

crest holds every match the United States men's team has played — 795 of them,
from 1885 to the 2026 World Cup — organised by World Cup cycle rather than by
decade. A stats site is a browsing problem, not a lookup problem. The interesting
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

**A view nobody designed in advance.** This is the one to look at first. Every
other item below is a nice primitive; this is the thing that feels new.

The chart is a surface, and `plot_chart` lets the agent choose what goes on it —
which dataset, which measure, narrowed to which opponent. That is four choices
the agent composes at the moment of the question, and most of the resulting
combinations were never a screen anyone built. "Goal difference against Mexico,
cycle by cycle" is a view that exists for about four seconds because somebody
wondered about it out loud.

Before WebMCP, the answer to an unanticipated question was a paragraph, a
screenshot, or a CSV. The interface itself was fixed at design time. Now the
person asks and the interface arrives — which is a different bargain than
software has offered before, and the reason this feels like more than a
convenience.

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

## The registration call

Rails serves JavaScript through importmap, so the call is in
[`app/javascript/controllers/model_context_controller.js`](app/javascript/controllers/model_context_controller.js)
rather than inline in the page. What runs is:

```js
document.modelContext.registerTool({
  name: tool.name,                 // "plot_chart"
  description: tool.description,   // written for a model, not a developer
  inputSchema: tool.inputSchema,   // JSON Schema: required, enum, additionalProperties: false
  annotations: tool.annotations,   // { readOnlyHint, untrustedContentHint }
  execute: (input) => this.run(tool, input)
}, { signal: this.aborter.signal })  // page-scoped tools unregister on Turbo navigation
```

The descriptors come from Ruby. Every page renders its own manifest into the
HTML, which **is** visible in view-source:

```html
<script type="application/json" id="model-context-manifest">
  {"tools":[{"name":"plot_chart","description":"...","kind":"page", ... }]}
</script>
```

One Stimulus controller reads that manifest and registers each entry. Because
the catalog is server-side, the manifest differs per page — a page with no
chart never advertises `plot_chart`.

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
entry. It needs no setup. [crest.soccer/tools](https://crest.soccer/tools) has a
button that copies the whole thing as one prompt; paste it into ChatGPT.

> Open crest.soccer in a visible browser window — I want to watch the page while
> you work, so do not use a background or headless browser.
>
> Then use the site's own WebMCP tools to work through these steps in order,
> telling me what changed on screen at each one.

Everything below happens in the one chart at the top of the page. Nothing is
clicked. The **visible browser** instruction matters: without it the agent may
do the work somewhere you cannot see, which defeats the point.

| # | Ask | What should happen | Tool |
|---|---|---|---|
| 1 | *"Tell me what tools this site gives you."* | Eight tools listed — four read the record, four work on the page | discovery |
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

---

## Requirements checklist

| Requirement | Where |
|---|---|
| Working live URL, usable in ChatGPT's browser | https://crest.soccer |
| Text description: why WebMCP fits | [Why this use case is a strong fit](#why-this-use-case-is-a-strong-fit-for-webmcp) |
| Text description: how it improves the experience | [How it creates a better user experience](#how-it-creates-a-better-user-experience) |
| Text description: what people and agents can do together | [What people and agents can do together](#what-people-and-agents-can-do-together-that-was-difficult-or-impossible-before) |
| Text description: how WebMCP was implemented | [How WebMCP was implemented](#how-webmcp-was-implemented) |
| Public repository, open source | github.com/leemcalilly/crest — MIT, detected by GitHub |
| All source, assets and instructions | This repo. Data ships unmodified in `db/source`; running instructions below |
| Tool registration with schema and execution | [The registration call](#the-registration-call) |
| Demo video, under 3 minutes, public, with audio | *(pending)* |
