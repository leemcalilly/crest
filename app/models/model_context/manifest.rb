# The descriptor list for the page being rendered. Built in Ruby so it is
# testable, and rendered into the page for one Stimulus controller to read.
class ModelContext::Manifest
  Tool = ModelContext::Tool

  GLOBAL = [
    Tool.new(
      name: "list_cycles",
      description: "List every World Cup cycle in the United States record — the four years " \
                   "leading to and including each World Cup. crest measures all time in cycles. " \
                   "Returns each cycle's slug, years and match count.",
      kind: :read, action: "/cycles.json"),

    Tool.new(
      name: "read_cycle",
      description: "Read one World Cup cycle: its won-drawn-lost record, goals, cities, and " \
                   "every match played in it. Use the cycle slug, which is the World Cup year " \
                   "(for example \"1994\"), or \"pre-1930\" for the years before the tournament existed.",
      kind: :read, action: "/cycles/:cycle.json",
      schema: { cycle: { type: "string", description: "Cycle slug, e.g. \"1994\"", required: true } }),

    Tool.new(
      name: "search_matches",
      description: "Find United States matches by opponent, year, or tournament. " \
                   "Returns up to 50 matches with score, result, tournament and venue.",
      kind: :read, action: "/matches.json",
      schema: {
        opponent: { type: "string", description: "Opponent name, e.g. \"Brazil\"" },
        year: { type: "integer", description: "Calendar year, e.g. 1994" },
        tournament: { type: "string", description: "Tournament name, e.g. \"World Cup\"" } }),

    Tool.new(
      name: "read_player",
      description: "Read a scorer's card: goals, rank, penalties, goals broken down by World Cup " \
                   "cycle, and World Cup goals. Caps are always null — appearance data does not " \
                   "exist in the open source this site is built from.",
      kind: :read, action: "/players/:player.json",
      schema: { player: { type: "string", description: "Player slug, e.g. \"clint-dempsey\"", required: true } }),

    Tool.new(
      name: "set_cycle",
      description: "Move the time machine to a World Cup cycle. The page navigates and the reader " \
                   "sees the change — use this to take the person you are helping somewhere, " \
                   "rather than only describing it.",
      kind: :page, action: "setCycle", read_only: false,
      schema: { cycle: { type: "string", description: "Cycle slug, e.g. \"1994\"", required: true } }),

    Tool.new(
      name: "highlight_cycle",
      description: "Point at one cycle on the timeline without leaving the page. The bar lights up " \
                   "for the reader. Use it while you explain something.",
      kind: :page, action: "highlightCycle", read_only: false,
      schema: { cycle: { type: "string", description: "Cycle slug, e.g. \"1994\"", required: true } }),

    Tool.new(
      name: "plot_chart",
      description: "Draw something new in the chart at the top of the page. This is the site's " \
                   "one visualization surface and you control what it shows. Pick a VIEW — " \
                   "cycles (all 24 World Cup cycles), opponents, venues (host cities), or " \
                   "scorers — and a MEASURE for the bar heights. Optionally narrow everything " \
                   "to one opponent. The bars re-animate on the reader's screen, so a question " \
                   "like \"were they good in the seventies or just busy?\" becomes visible " \
                   "rather than described. Scorers are always measured in goals.",
      kind: :page, action: "plotChart", read_only: false,
      schema: {
        view: { type: "string", description: "What the bars are: cycles, opponents, venues, or scorers",
                enum: Chart::VIEWS.keys, required: true },
        metric: { type: "string", description: "What the bar heights measure. Ignored for scorers.",
                  enum: Chart::METRICS.keys },
        opponent: { type: "string", description: "Narrow to one opponent, e.g. \"Mexico\". Omit for all." }
      }),

    Tool.new(
      name: "read_current_page",
      description: "Read what the person is looking at right now: which page, and which cycle or " \
                   "player is on screen. Call this first so you talk about what they can see.",
      kind: :page, action: "readCurrentPage")
  ].freeze

  # A tool that cannot work on this page should not be offered on it. The
  # chart tools exist only where a chart is rendered; everything else follows
  # the reader everywhere. This is the page-scoping WebMCP is built for.
  CHART_TOOLS = %w[ plot_chart highlight_cycle ].freeze
  CHART_PAGES = %w[ home cycles ].freeze

  def initialize(page: nil) = @page = page.to_s

  def tools
    return GLOBAL if CHART_PAGES.include?(@page)
    GLOBAL.reject { CHART_TOOLS.include?(it.name) }
  end

  def to_json(*) = { tools: tools.map(&:as_json) }.to_json
end
