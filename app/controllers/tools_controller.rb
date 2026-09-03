class ToolsController < ApplicationController
  # The repeatable test. Each entry is the prompt a person types and what they
  # should see happen. Kept in Ruby so a test can hold it to the real catalog.
  TRY_IT = [
    [ "Open crest.soccer in a visible browser window and tell me what tools this site gives you.",
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
    [ "Which cycle had no tournament at all?",
      "The 1939&ndash;1950 bar lights up: twelve years, no World Cup. <em>highlight_cycle</em>" ]
  ].freeze

  def show
    @tools = ModelContext::Manifest.new(page: "home").tools
    @try_it = TRY_IT
  end
end
