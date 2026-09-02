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
    this.aborter = new AbortController()

    this.modelContext = this.findModelContext()
    if (!this.modelContext) {
      this.report("Agent tools · not in this browser")
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
      this.element.querySelector(".tools")?.classList.add("live")
      this.report(`${this.toolCount} agent tools ready`)
      console.info(`[crest] registered ${this.toolCount} WebMCP tools:`,
                   tools.map((t) => t.name).join(", "))
    } else {
      this.report("Agent tools · none registered")
    }
  }

  failed(tool, error) {
    this.toolCount = Math.max(0, this.toolCount - 1)
    console.warn(`[crest] tool ${tool.name} failed to register`, error)
    this.report(this.toolCount > 0 ? `${this.toolCount} agent tools ready` : "Agent tools · unavailable")
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
    this.resetAt = setTimeout(() => this.report(`${this.toolCount || 7} agent tools ready`), 4000)
  }

  report(text) {
    if (this.hasLabelTarget) this.labelTarget.textContent = text
  }
}
