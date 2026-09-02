import { Controller } from "@hotwired/stimulus"

// Registers this page's tools with the browser, so an agent looking at the
// page can act on it through the reader's own session.
//
// WebMCP is young and still moving. The normative IDL puts modelContext on
// Document, but shipping builds have exposed it on Navigator, so we accept
// either rather than betting the whole site on one spelling.
export default class extends Controller {
  static targets = ["indicator", "label", "histogram", "cycleName", "caption"]

  connect() {
    this.aborter = new AbortController()

    this.modelContext = this.findModelContext()
    if (!this.modelContext) {
      this.report("how to turn it on")
      return
    }

    const manifest = document.getElementById("model-context-manifest")
    if (!manifest) return

    const { tools } = JSON.parse(manifest.textContent)
    this.toolCount = 0

    // Register each tool independently. registerTool may return a promise, a
    // value, or nothing at all depending on the build, so never gate the
    // interface on all of them settling — one slow tool would leave the page
    // looking broken while everything actually worked.
    for (const tool of tools) {
      try {
        const result = this.register(tool)
        this.toolCount += 1
        if (result && typeof result.catch === "function") {
          result.catch((error) => this.failed(tool, error))
        }
      } catch (error) {
        this.failed(tool, error)
      }
    }

    if (this.toolCount > 0) {
      this.element.querySelector(".badge")?.classList.add("live")
      this.report(`${this.toolCount} tools ready`)
      console.info(`[crest] registered ${this.toolCount} WebMCP tools:`,
                   tools.map((t) => t.name).join(", "))
    } else {
      this.report("no tools registered")
    }
  }

  failed(tool, error) {
    this.toolCount = Math.max(0, this.toolCount - 1)
    console.warn(`[crest] tool ${tool.name} failed to register`, error)
    this.report(this.toolCount > 0 ? `${this.toolCount} tools ready` : "unavailable")
  }

  disconnect() {
    // Page-scoped tools unregister themselves on Turbo navigation.
    this.aborter?.abort()
  }

  // Document first, Navigator second — whichever this browser actually has.
  // NOTE: the result is stored on `this.modelContext`, never `this.context`.
  // Stimulus owns `this.context`; assigning to it breaks every target helper
  // and every action on the controller.
  findModelContext() {
    for (const host of [document, navigator, window]) {
      const context = host && host.modelContext
      if (context && typeof context.registerTool === "function") return context
    }
    return null
  }

  register(tool) {
    return this.modelContext.registerTool({
      name: tool.name,
      description: tool.description,
      inputSchema: tool.inputSchema,
      annotations: tool.annotations,
      execute: (input) => this.run(tool, input || {})
    }, { signal: this.aborter.signal })
  }

  async run(tool, input) {
    this.announce(tool.name)
    return tool.kind === "page" ? this.runPage(tool, input) : this.runRead(tool, input)
  }

  // Read tools go through the page's own URLs, with the reader's cookies.
  async runRead(tool, input) {
    let path = tool.action
    const query = new URLSearchParams()

    for (const [key, value] of Object.entries(input)) {
      if (value === null || value === undefined || value === "") continue
      if (path.includes(`:${key}`)) path = path.replace(`:${key}`, encodeURIComponent(value))
      else query.append(key, value)
    }

    const url = query.toString() ? `${path}?${query}` : path
    const response = await fetch(url, { headers: { Accept: "application/json" } })
    if (!response.ok) return { error: `crest answered ${response.status} for ${url}` }
    return response.json()
  }

  // Page tools act on what the reader is looking at. No server equivalent.
  runPage(tool, input) {
    switch (tool.action) {
      case "setCycle":
        return this.setCycle(input.cycle)
      case "highlightCycle":
        return this.highlightCycle(input.cycle)
      case "plotCycles":
        return this.plotCycles(input.metric)
      case "filterByOpponent":
        return this.filterByOpponent(input.opponent)
      case "readCurrentPage":
        return this.readCurrentPage()
      default:
        return { error: `crest has no page tool named ${tool.action}` }
    }
  }

  setCycle(slug) {
    const bar = this.barFor(slug)
    if (!bar) return { error: `No cycle named ${slug}. Call list_cycles for the slugs.` }
    Turbo.visit(bar.getAttribute("href"))
    return { moved_to: slug, note: "The reader's page is now showing this cycle." }
  }

  highlightCycle(slug) {
    const bar = this.barFor(slug)
    if (!bar) return { error: `No cycle named ${slug}. Call list_cycles for the slugs.` }

    this.histogramTarget.querySelectorAll("a").forEach((a) => a.classList.remove("lit"))
    bar.classList.add("lit")
    bar.scrollIntoView({ behavior: "smooth", block: "nearest", inline: "center" })
    return { highlighted: slug, note: "The bar is lit on the reader's screen." }
  }

  // Redraw the timeline by a different measure. Every value is already in the
  // page as a data attribute, so this is instant and needs no server.
  METRICS = {
    matches: "Matches played",
    wins: "Matches won",
    goals_for: "Goals scored",
    goal_difference: "Goal difference",
    win_rate: "Win rate"
  }

  plotCycles(metric) {
    if (!this.hasHistogramTarget) return { error: "There is no timeline on this page." }

    const key = String(metric || "").trim()
    if (!this.METRICS[key]) {
      return { error: `Unknown measure "${metric}". Use one of: ${Object.keys(this.METRICS).join(", ")}.` }
    }

    this.metric = key
    const values = this.draw((bar) => Number(bar.dataset[this.camel(key)]))
    return {
      plotted: key,
      label: this.METRICS[key],
      note: "The bars have re-animated on the reader's screen.",
      highest: values.highest,
      lowest: values.lowest
    }
  }

  // Narrow the same bars to one opponent, across every cycle.
  async filterByOpponent(opponent) {
    if (!this.hasHistogramTarget) return { error: "There is no timeline on this page." }

    const name = String(opponent || "").trim()
    if (!name || name.toLowerCase() === "all") {
      this.opponent = null
      this.bars().forEach((bar) => { bar.dataset.filtered = "" })
      this.draw((bar) => Number(bar.dataset[this.camel(this.metric || "matches")]))
      return { filtered: null, note: "The timeline shows every opponent again." }
    }

    const response = await fetch(`/cycles.json?opponent=${encodeURIComponent(name)}`,
                                { headers: { Accept: "application/json" } })
    if (!response.ok) return { error: `crest answered ${response.status} looking up ${name}.` }

    const { cycles } = await response.json()
    const bySlug = Object.fromEntries(cycles.map((c) => [c.slug, c]))
    const metric = this.metric || "matches"

    let total = 0
    this.bars().forEach((bar) => {
      const row = bySlug[bar.dataset.cycle]
      const value = row ? Number(row[metric]) : 0
      bar.dataset.filtered = String(value)
      if (row) total += Number(row.matches)
    })

    if (total === 0) {
      this.bars().forEach((bar) => { bar.dataset.filtered = "" })
      this.draw((bar) => Number(bar.dataset[this.camel(metric)]))
      return { error: `The United States has no recorded matches against "${name}". The timeline is unchanged.` }
    }

    this.opponent = name
    this.draw((bar) => Number(bar.dataset.filtered))
    return { filtered: name, matches: total, measure: this.METRICS[metric],
             note: `The timeline now shows only matches against ${name}.` }
  }

  // One drawing routine for both tools. Negative values keep their sign.
  draw(valueOf) {
    const bars = this.bars()
    const values = bars.map(valueOf)
    const scale = Math.max(...values.map((v) => Math.abs(v)), 1)

    let highest = null, lowest = null
    bars.forEach((bar, i) => {
      const value = values[i]
      const height = Math.max(Math.round((Math.abs(value) / scale) * 124), 2)
      bar.style.height = `${height}px`
      bar.classList.toggle("negative", value < 0)
      bar.classList.toggle("dim", value === 0)
      bar.title = `${bar.dataset.name} — ${value}`
      if (!highest || value > highest.value) highest = { cycle: bar.dataset.cycle, value }
      if (!lowest || value < lowest.value) lowest = { cycle: bar.dataset.cycle, value }
    })

    this.caption(values.some((v) => v < 0))
    return { highest, lowest }
  }

  caption(hasNegatives = false) {
    if (!this.hasCaptionTarget) return
    const measure = this.METRICS[this.metric || "matches"]
    const who = this.opponent ? `against ${this.opponent}` : "all opponents"
    // A negative bar grows upward like any other, so the colour is the only
    // thing carrying its sign. Say so rather than leaving it to be guessed.
    const key = hasNegatives ? " · red bars are negative" : ""
    this.captionTarget.textContent = `${measure} · ${who}${key}`
  }

  bars() { return Array.from(this.histogramTarget.querySelectorAll("a")) }

  camel(key) { return key.replace(/_([a-z])/g, (_, c) => c.toUpperCase()) }

  readCurrentPage() {
    return {
      url: window.location.pathname,
      title: document.title,
      cycle_on_screen: this.hasCycleNameTarget ? this.cycleNameTarget.textContent.trim() : null,
      cycles_visible: this.hasHistogramTarget,
      timeline_showing: this.hasHistogramTarget ? (this.METRICS[this.metric || "matches"]) : null,
      timeline_filtered_to: this.opponent || null
    }
  }

  barFor(slug) {
    if (!this.hasHistogramTarget) return null
    return this.histogramTarget.querySelector(`[data-cycle="${CSS.escape(slug)}"]`)
  }

  announce(name) {
    if (this.labelTargets.length === 0) return
    this.report(name)
    clearTimeout(this.resetAt)
    this.resetAt = setTimeout(() => this.report(`${this.toolCount || 7} tools ready`), 4000)
  }

  // There is more than one place that shows status — the header badge and the
  // panel on the tools page. Write to every one of them.
  report(text) {
    this.labelTargets.forEach((label) => { label.textContent = text })
  }
}
