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
      name: "read_current_page",
      description: "Read what the person is looking at right now: which page, and which cycle or " \
                   "player is on screen. Call this first so you talk about what they can see.",
      kind: :page, action: "readCurrentPage")
  ].freeze

  def initialize(page: nil) = @page = page

  def tools = GLOBAL

  def to_json(*) = { tools: tools.map(&:as_json) }.to_json
end
