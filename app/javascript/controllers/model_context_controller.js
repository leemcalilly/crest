import { Controller } from "@hotwired/stimulus"

// Registers this page's tools with the browser, so an agent looking at the
// page can act on it through the reader's own session.
//
// WebMCP is young and still moving. The normative IDL puts modelContext on
// Document, but shipping builds have exposed it on Navigator, so we accept
// either rather than betting the whole site on one spelling.
export default class extends Controller {
  static targets = ["indicator", "label", "histogram", "cycleName"]

  connect() {
    this.controller = new AbortController()

    this.context = this.findModelContext()
    if (!this.context) {
      this.report("Site tools · not supported here")
      return
    }

    const manifest = document.getElementById("model-context-manifest")
    if (!manifest) return

    const { tools } = JSON.parse(manifest.textContent)
    Promise.all(tools.map((tool) => this.register(tool)))
      .then(() => {
        this.element.querySelector(".tools")?.classList.add("live")
        this.report(`Site tools · ${tools.length}`)
      })
      .catch(() => this.report("Site tools · unavailable"))
  }

  disconnect() {
    // Page-scoped tools unregister themselves on Turbo navigation.
    this.controller?.abort()
  }

  // Document first, Navigator second — whichever this browser actually has.
  findModelContext() {
    for (const host of [document, navigator, window]) {
      const context = host && host.modelContext
      if (context && typeof context.registerTool === "function") return context
    }
    return null
  }

  register(tool) {
    return this.context.registerTool({
      name: tool.name,
      description: tool.description,
      inputSchema: tool.inputSchema,
      annotations: tool.annotations,
      execute: (input) => this.run(tool, input || {})
    }, { signal: this.controller.signal })
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

  readCurrentPage() {
    return {
      url: window.location.pathname,
      title: document.title,
      cycle_on_screen: this.hasCycleNameTarget ? this.cycleNameTarget.textContent.trim() : null,
      cycles_visible: this.hasHistogramTarget
    }
  }

  barFor(slug) {
    if (!this.hasHistogramTarget) return null
    return this.histogramTarget.querySelector(`[data-cycle="${CSS.escape(slug)}"]`)
  }

  announce(name) {
    if (!this.hasLabelTarget) return
    this.labelTarget.textContent = name
    clearTimeout(this.resetAt)
    this.resetAt = setTimeout(() => this.report(`Site tools · ${this.toolCount || 7}`), 4000)
  }

  report(text) {
    if (this.hasLabelTarget) this.labelTarget.textContent = text
  }
}
