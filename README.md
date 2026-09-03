# crest

**Every match the USMNT has played.**

A time machine for the United States men's national team, measured in World Cup
cycles. 795 matches, 1885 to 2026, built entirely from open data — and it hands
its tools to the agent looking at the page.

Built for the [WebMCP Challenge](https://openai.com/webmcp-challenge/) — the full
entry, including the demo video, is in [SUBMISSION.md](SUBMISSION.md).

## What WebMCP does here

crest registers eight tools with the browser through `document.modelContext`.
Four read the record; four work on the page you are looking at:

| Tool | Kind | What it does |
|---|---|---|
| `list_cycles` | read | Every World Cup cycle with its match count |
| `read_cycle` | read | One cycle's record and every match in it |
| `search_matches` | read | Find matches by opponent, year or tournament |
| `read_player` | read | A scorer's card, with goals broken down by cycle |
| `set_cycle` | **page** | Moves the time machine. The reader watches it happen |
| `highlight_cycle` | **page** | Lights one bar on the timeline while you explain |
| `plot_chart` | **page** | Draws a different view in the chart: cycles, opponents, venues or scorers |
| `read_current_page` | **page** | What the reader is looking at right now |

The second four are the reason this is WebMCP and not a server. A server tool can
*describe* the timeline. A page tool **moves** it, so the person and the agent
are looking at the same thing at the same moment.

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

## Architecture

One body, many mouths. The domain models hold all the logic; every surface is thin.

```
Cycle  Match  Player            ← the body
   ↑       ↑       ↑
   │       │       └─ #as_json          the JSON contract, one place
   │       └───────── ordinary routes   /cycles/1994.json — no /api namespace
   └───────────────── ModelContext::    the tool catalog
```

- **No `/api` namespace.** The site's own URLs are the API. `/cycles/1994.json`
  is the same controller, the same model and the same scope as the HTML page.
- **The tool catalog is Ruby**, in `app/models/model_context/`, so descriptions
  and schemas are testable rather than stranded in JavaScript.
- **One Stimulus controller** reads the server-rendered manifest and registers
  the tools, aborting them on Turbo navigation so page-scoped tools do not leak.

It is `document.modelContext`, not `navigator.modelContext` — the normative IDL
puts it on `Document`, and a lot of secondhand write-ups get this wrong.

## The data, and what it does not contain

Everything comes from [martj42/international_results](https://github.com/martj42/international_results),
**CC0-1.0**. The four source files ship unmodified in `db/source` so any figure
here can be checked against the original.

What no source gives us, and what crest therefore refuses to invent:

- **Appearances.** Caps render as `—`, never `0`. A zero is a claim; a dash is an
  absence. crest counts caps from launch forward.
- **Goals are a floor, not a career total.** The record covers major tournaments
  and friendlies unevenly, so a player's real total is higher than the card shows.
  Every player card says so.
- Positions, clubs, minutes played, line-ups, attendance, stadium names, and
  venue coordinates — which is why there is no map.

**The women's record is not here yet.** The women's dataset carries no license
file, so it cannot be redistributed in an open repository. `/sources` says so
plainly rather than shipping it quietly or pretending the site is complete.

## Running it

```bash
bin/setup
bin/rails crest:import   # reads db/source, ~3 seconds
bin/rails server
```

Or `bin/up` for the container.

To see the tools, open the site in ChatGPT's desktop browser, or in Chrome with
`chrome://flags/#enable-webmcp-testing` enabled. Without WebMCP the header says
so and the site works exactly as it always did — nothing here is agent-only.

## License

MIT. See [LICENSE](LICENSE).
