class ToolsController < ApplicationController
  # The repeatable test. One prompt, eight steps. Kept in Ruby so the copy
  # button, the page, and the submission can never drift apart.
  INTRO = <<~TEXT.strip
    Open crest.soccer in a visible browser window — I want to watch the page while
    you work, so do not use a background or headless browser.

    Then use the site's own WebMCP tools to work through these steps in order,
    telling me what changed on screen at each one.
  TEXT

  STEPS = [
    [ "Tell me what tools this site gives you.",
      "Eight tools on the homepage: four read the record, four work on the page." ],
    [ "Were they actually any good in the seventies, or just playing a lot?",
      "The 24 cycle bars redraw from match counts to win rate. <em>plot_chart</em>" ],
    [ "What about goal difference?",
      "Half the timeline turns red. The United States used to lose on aggregate, and stopped." ],
    [ "Who do they play the most?",
      "The same panel becomes a ranking of opponents. Mexico, 76 matches." ],
    [ "And where do they play?",
      "Host cities. Mexico City leads with 27, one ahead of Washington, D.C." ],
    [ "Show me only the matches against Mexico, cycle by cycle.",
      "Back to cycles, narrowed to one rivalry across a century." ],
    [ "Take me to the cycle that ended at the home World Cup.",
      "The page navigates to 1994. <em>set_cycle</em>" ],
    [ "Which cycle is twelve years long, and why?",
      "The 1939&ndash;1950 bar lights up: twelve years between tournaments, because the 1942 and 1946 World Cups were cancelled for the war. <em>highlight_cycle</em>" ]
  ].freeze

  def self.full_prompt
    numbered = STEPS.each_with_index.map { |(ask, _), i| "#{i + 1}. #{ask}" }
    "#{INTRO}\n\n#{numbered.join("\n")}"
  end

  def show
    @tools = ModelContext::Manifest.new(page: "home").tools
    @steps = STEPS
    @full_prompt = self.class.full_prompt
  end
end
