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

  // The canonical call this page makes is:
  //
  //     document.modelContext.registerTool({ name, description, inputSchema, execute })
  //
  // The normative IDL puts modelContext on Document. Some shipping builds have
  // exposed it on Navigator instead, so both are accepted rather than betting
  // the site on one spelling.
  //
  // NOTE: the result is stored on `this.modelContext`, never `this.context`.
  // Stimulus owns `this.context`; assigning to it breaks every target helper
  // and every action on the controller.
  findModelContext() {
    if (document.modelContext && typeof document.modelContext.registerTool === "function") {
      return document.modelContext
    }
    if (navigator.modelContext && typeof navigator.modelContext.registerTool === "function") {
      return navigator.modelContext
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
      case "plotChart":
        return this.plotChart(input)
      case "readCurrentPage":
        return this.readCurrentPage()
      default:
        return { error: `crest has no page tool named ${tool.action}` }
    }
  }

  // Navigation must not depend on what the chart happens to be showing. The
  // chart may be drawing opponents or venues, in which case no cycle bar
  // exists — so ask the server whether the cycle is real, then go.
  async setCycle(slug) {
    const path = `/cycles/${encodeURIComponent(String(slug || "").trim())}`
    const response = await fetch(`${path}.json`, { headers: { Accept: "application/json" } })
    if (!response.ok) {
      return { error: `No cycle named "${slug}". Call list_cycles for the slugs.` }
    }
    Turbo.visit(path)
    return { moved_to: slug, note: "The reader's page is now showing this cycle." }
  }

  // Highlighting needs a cycle bar on screen. If the chart is showing
  // something else, draw the cycles back first rather than failing.
  async highlightCycle(slug) {
    if (!this.hasHistogramTarget) return { error: "There is no chart on this page." }

    let bar = this.barFor(slug)
    let redrew = false
    if (!bar) {
      await this.plotChart({ view: "cycles", metric: this.chart?.metric || "matches" })
      bar = this.barFor(slug)
      redrew = true
    }
    if (!bar) return { error: `No cycle named "${slug}". Call list_cycles for the slugs.` }

    this.bars().forEach((node) => node.classList.remove("lit"))
    bar.classList.add("lit")
    bar.scrollIntoView({ behavior: "smooth", block: "nearest", inline: "center" })
    return {
      highlighted: slug,
      redrew_cycles: redrew,
      note: redrew
        ? "The chart was showing something else, so the cycles were drawn back before highlighting."
        : "The bar is lit on the reader's screen."
    }
  }

  // The chart is a surface, not a fixed histogram. The agent picks what it
  // shows — cycles, opponents, venues, scorers — and the panel redraws from
  // whatever the server returns. Cycles are one view among several.
  async plotChart(input) {
    if (!this.hasHistogramTarget) return { error: "There is no chart on this page." }

    const query = new URLSearchParams()
    for (const key of ["view", "metric", "opponent"]) {
      if (input[key]) query.append(key, input[key])
    }

    const response = await fetch(`/chart.json?${query}`, { headers: { Accept: "application/json" } })
    if (!response.ok) return { error: `crest answered ${response.status} drawing that chart.` }

    const chart = await response.json()
    if (!chart.bars || chart.bars.length === 0) {
      return { error: `Nothing to draw for that combination. The chart is unchanged.` }
    }

    this.chart = chart
    const drawn = this.draw(chart)
    return {
      drawn: chart.view,
      measuring: chart.label,
      opponent: chart.opponent || null,
      bars: chart.bars.length,
      highest: drawn.highest,
      lowest: drawn.lowest,
      note: "The chart has re-animated on the reader's screen."
    }
  }

  // Render an arbitrary set of bars into the one chart panel.
  draw(chart) {
    const values = chart.bars.map((b) => Number(b.value))
    const scale = Math.max(...values.map((v) => Math.abs(v)), 1)
    const hasNegatives = values.some((v) => v < 0)

    this.histogramTarget.replaceChildren(...chart.bars.map((bar) => {
      const value = Number(bar.value)
      const node = document.createElement(bar.href ? "a" : "span")
      if (bar.href) node.href = bar.href
      node.style.height = `${Math.max(Math.round((Math.abs(value) / scale) * 160), 2)}px`
      node.title = `${bar.title} — ${value}`
      node.dataset.cycle = bar.key
      node.dataset.name = bar.title
      // Only a diverging measure earns colour. Bars that are all positive —
      // matches played, goals scored — stay neutral rather than turning the
      // whole chart green for no reason.
      if (hasNegatives && value < 0) node.classList.add("negative")
      if (hasNegatives && value > 0) node.classList.add("positive")
      if (value === 0) node.classList.add("dim")
      return node
    }))

    this.ticksFor(chart)
    this.caption(chart, hasNegatives)

    const sorted = [...chart.bars].sort((a, b) => Number(a.value) - Number(b.value))
    return {
      highest: { name: sorted.at(-1).title, value: Number(sorted.at(-1).value) },
      lowest: { name: sorted[0].title, value: Number(sorted[0].value) }
    }
  }

  // Cycles get sparse year labels; every other view labels every bar.
  ticksFor(chart) {
    const ticks = this.element.querySelector(".ticks")
    if (!ticks) return

    const many = chart.bars.length > 12
    ticks.replaceChildren(...chart.bars.map((bar, i) => {
      const node = document.createElement("div")
      node.className = "cap"
      const sparse = chart.view === "cycles" && (i === 0 || i % 5 === 0 || i === chart.bars.length - 1)
      node.textContent = chart.view === "cycles" ? (sparse ? bar.label : "") : bar.label
      if (many && chart.view !== "cycles") node.classList.add("turned")
      return node
    }))
  }

  caption(chart, hasNegatives = false) {
    if (!this.hasCaptionTarget) return
    const who = chart.opponent && chart.view !== "opponents" ? ` · vs ${chart.opponent}` : ""
    const key = hasNegatives ? " · red bars are negative" : ""
    this.captionTarget.textContent = `${chart.title} · ${chart.label}${who}${key}`
  }

  readCurrentPage() {
    return {
      url: window.location.pathname,
      title: document.title,
      cycle_on_screen: this.hasCycleNameTarget ? this.cycleNameTarget.textContent.trim() : null,
      cycles_visible: this.hasHistogramTarget,
      chart_showing: this.chart ? `${this.chart.title} by ${this.chart.label}` : "World Cup cycles by matches played",
      chart_filtered_to: this.chart?.opponent || null
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
