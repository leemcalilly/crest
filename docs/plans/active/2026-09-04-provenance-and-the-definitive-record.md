# Provenance, and becoming the definitive record

**Status:** Superseded · 2026-09-04 · the data model here is replaced by the `provable` gem, and the order of work now lives in the private planning repo. Phases 3–5 (research runs, the missing teams, provenance as a tool) remain valid as follow-ons once crest is on the gem.
**Goal:** make every number on crest carry its own evidence, so the site can be
trusted by a person and cited by an agent.

---

## Human Checklist

Actions only Lee can take. Each names what it blocks.

- [ ] **Decide the copyright position on snapshots.** *Blocks: Phase 2, and the
      whole public-archive idea.* Capturing a page to prove a number is one
      thing; republishing that capture is another. The safe default is: store
      snapshots privately for verification, show the public a short excerpt plus
      a live link. Going further — a public Wayback-style archive of other
      people's pages — is a legal question, not an engineering one, and this
      plan does not assume the answer.
- [ ] **Decide the Wikipedia position.** *Blocks: Phase 3.* Wikipedia is the
      most complete source for caps and it is CC BY-SA. Facts are not
      copyrightable, so importing *values* is fine; copying prose or tables
      wholesale pulls share-alike onto this repo. Confirm we only take values
      plus attribution.
- [ ] **Check `robots.txt` and terms for every source before it is added.**
      *Blocks: adding that source.* One polite crawler with a real user agent
      and a slow rate, or nothing.
- [ ] **Set a spend cap on whatever model key does the research.** *Blocks:
      Phase 3.* Research runs are the only part of crest that costs money.

---

## Why this, and why now

crest currently has one source. It is CC0, it is complete for match results, and
on the thing people care most about it is **wrong**.

The site says Clint Dempsey scored **41** goals. The figure reported everywhere
else is **57**. Our own player card already admits the gap in a footer — the
open dataset covers major tournaments and only some friendlies, so every goal
total is a floor rather than a total.

That footnote is honest, and it is also the ceiling on what crest can ever be.
A single unattributed number cannot be authoritative no matter how carefully it
is caveated. The fix is not "find a better dataset". Any single better dataset
has the same problem one layer down.

**The fix is provenance.** A number that carries where it came from, when that
was last checked, and whether other sources disagree, is a different kind of
object than a number in a CSV. It can be argued with. It can be corrected. It
can be cited.

## What "the agent-friendly source" actually means

An agent repeating a number to someone has no way to judge it. Today it either
trusts crest or it does not. The interesting version of this site gives the
agent the evidence along with the answer:

```json
{
  "player": "Clint Dempsey",
  "goals": { "value": 57, "confidence": "corroborated",
             "sources": 3, "disagreement": true,
             "cite": "/players/clint-dempsey/goals/sources.json" }
}
```

That is the product. Not more rows — **verifiable rows**. It is also a real
answer to "why would an agent choose this site over scraping three others": we
already did that, we kept the receipts, and we show our work.

## The shape

Four new ideas, each a plain model.

**`Source`** — a publication. US Soccer, RSSSF, Wikipedia, a newspaper archive.
Carries a reliability tier we assign and defend, plus crawl rules.

**`Document`** — one fetched URL at one moment. `fetched_at`, HTTP status,
content hash, and the captured body. A source changes; a document does not.
This is the Wayback-like part, and it is what makes a citation survive the page
being edited or going dark.

**`Claim`** — one atomic assertion: *this subject, this predicate, this value*.
`Player #12 / career_goals / 57`. Claims belong to subjects polymorphically, so
matches, players, cycles and venues all work the same way.

**`Citation`** — joins a claim to a document, with the excerpt the value was
read from and a `verified_at` set only when a machine confirmed that excerpt is
really in that document.

Then the thing that makes it honest: **disagreement is a state, not an error.**
When two sources give different values for the same claim, crest shows both and
says so, rather than silently picking. The Dempsey number becomes a small
argument the reader can inspect instead of a figure they have to accept.

## Display

Every number on the site becomes clickable. A number with corroboration is
plain; a disputed one is marked; an unverified one says so. No number ever
looks more certain than it is — which is the same rule the current player card
already follows with its em-dash for caps.

## Phases

**Phase 1 — the spine, on data we already have.** `Source`, `Document`,
`Claim`, `Citation`, and the CC0 import rewritten to create claims rather than
bare columns. Nothing changes on screen. Every current number gains one
citation pointing at the file it came from. This phase is entirely offline and
has no legal or cost exposure.

**Phase 2 — fetching and proving.** A fetcher that captures a URL, hashes it,
and stores the snapshot. A verifier that confirms the claimed value actually
appears in the captured text. A rot checker that revisits documents on a
schedule and marks the ones that have gone dark.

Three things this must get right, all of them borrowed in spirit from how
please_quote_me solved the same problem — reimplemented here, not copied:

- **An SSRF guard in front of every fetch**, because in Phase 3 the URLs come
  from a model and a prompt-injected page can make a model emit any URL it
  likes. The guard must resolve the host, reject private and link-local
  addresses, and then **connect to the exact IP it vetted** — re-resolving at
  connect time reopens a DNS-rebind hole between the check and the request.
- **A byte cap and a timeout**, so one enormous or slow page cannot stall a run.
- **The HTTP call as an injected seam**, so the whole pipeline is testable
  without a network.

**Phase 3 — research runs.** An agent proposes claims with sources; the Phase 2
verifier decides whether they stand. The model never writes a value directly to
the record: it proposes, the verifier confirms the text is really there, and
anything unconfirmed sits in a queue for a human. The model is a research
assistant with no write access, which is the only arrangement that makes the
result trustworthy.

**Phase 4 — the missing teams.** The women's record first, if and only if a
licensed source exists (the current blocker is recorded on `/sources`). Then
youth national teams, which nobody has assembled well and which would be the
clearest demonstration that this is a record rather than a dataset copy.

**Phase 5 — provenance as a tool.** New WebMCP tools over the same catalog:

- `cite(subject, predicate)` — where did this number come from?
- `show_disagreement(subject, predicate)` — draw the conflicting sources.

An agent that can ask a page to justify itself is a genuinely new thing, and it
is the natural continuation of what v1 already does: the reader and the agent
looking at the same evidence at the same moment.

## What could go wrong

**The archive is the legal risk.** Storing captures privately to verify a claim
is defensible. Serving them publicly is republishing someone else's page. The
Human Checklist puts that decision where it belongs.

**Scope.** Youth national teams are a large, poorly-recorded space. Phase 4
should not begin until Phases 1 to 3 are proven on the men's record, which is
small enough to finish.

**Cost and trust drift.** A model that proposes fifty claims an hour will
produce plausible wrong ones. The verifier is the whole defence, and it has to
stay strict: no `verified_at` without a machine-checked excerpt.

## Open questions

- Does a claim need a validity window? Career totals change while a player is
  active. `valid_from` / `valid_to` may be necessary, and it complicates
  everything it touches.
- How is a source's reliability tier decided, and can a reader see the reasoning?
- Should corrections be public — a visible history of what crest used to say?
  That would be unusual, and it might be the most trustworthy thing on the site.
