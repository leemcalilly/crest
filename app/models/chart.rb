# The one visualization surface on the site. An agent chooses what it shows.
#
# A view decides *what* the bars are — cycles, opponents, venues, scorers — and
# a metric decides *how tall* they are. Cycles are one view among several, not
# the only thing this panel can draw.
class Chart
  VIEWS = {
    "cycles"    => "World Cup cycles",
    "opponents" => "Opponents",
    "venues"    => "Host cities",
    "scorers"   => "Scorers"
  }.freeze

  METRICS = {
    "matches"         => "Matches played",
    "wins"            => "Matches won",
    "goals_for"       => "Goals scored",
    "goal_difference" => "Goal difference",
    "win_rate"        => "Win rate"
  }.freeze

  # Scorers are ranked by goals; every other view can use any measure.
  SUPPORTED = {
    "cycles"    => METRICS.keys,
    "opponents" => METRICS.keys,
    "venues"    => METRICS.keys,
    "scorers"   => %w[ goals ]
  }.freeze

  LIMIT = 18

  attr_reader :view, :metric, :opponent

  def initialize(view: "cycles", metric: "matches", opponent: nil)
    @view = VIEWS.key?(view.to_s) ? view.to_s : "cycles"
    @opponent = opponent.presence
    @metric = resolve_metric(metric)
  end

  def error
    return nil if VIEWS.key?(view)
    "Unknown view. Use one of: #{VIEWS.keys.join(', ')}."
  end

  def title
    parts = [ VIEWS[view] ]
    parts << "vs #{opponent}" if opponent && view != "opponents"
    parts.join(" · ")
  end

  def label = view == "scorers" ? "Goals" : METRICS[metric]

  def bars
    case view
    when "cycles"    then cycle_bars
    when "opponents" then opponent_bars
    when "venues"    then venue_bars
    when "scorers"   then scorer_bars
    end
  end

  private
    def resolve_metric(requested)
      allowed = SUPPORTED.fetch(view)
      allowed.include?(requested.to_s) ? requested.to_s : allowed.first
    end

    def scope = opponent ? Match.against(opponent) : Match.all

    def cycle_bars
      Cycle.chronological.includes(:matches).map do |cycle|
        matches = opponent ? cycle.matches.against(opponent) : cycle.matches
        { key: cycle.slug, label: cycle.world_cup_year&.to_s || "<1930",
          title: cycle.name, value: measure(matches), href: Rails.application.routes.url_helpers.cycle_path(cycle) }
      end
    end

    def opponent_bars
      grouped(scope.group(:opponent)) { |name| { key: name, label: name, title: name } }
    end

    def venue_bars
      grouped(scope.group(:city)) { |city| { key: city, label: city, title: city } }
    end

    def scorer_bars
      Player.by_goals.limit(LIMIT).map do |player|
        { key: player.slug, label: player.name.split.last, title: player.name,
          value: player.goal_count,
          href: Rails.application.routes.url_helpers.player_path(player) }
      end
    end

    # One grouped query per view, measured the same way every time.
    def grouped(relation)
      rows = relation.pluck(Arel.sql(<<~SQL))
        COUNT(*),
        SUM(CASE WHEN us_score > opponent_score THEN 1 ELSE 0 END),
        SUM(us_score),
        SUM(us_score - opponent_score)
      SQL
      keys = relation.count.keys

      keys.each_with_index.map { |key, i|
        played, won, scored, difference = rows[i]
        yield(key).merge(value: pick(played, won, scored, difference))
      }.reject { it[:key].blank? }
        .sort_by { -it[:value] }
        .first(LIMIT)
    end

    def pick(played, won, scored, difference)
      case metric
      when "wins" then won.to_i
      when "goals_for" then scored.to_i
      when "goal_difference" then difference.to_i
      when "win_rate" then played.to_i.zero? ? 0 : ((won.to_f / played) * 100).round
      else played.to_i
      end
    end

    def measure(matches)
      record = Match::Record.new(matches)
      case metric
      when "wins" then record.won
      when "goals_for" then record.goals_for
      when "goal_difference" then record.goals_for - record.goals_against
      when "win_rate" then record.played.zero? ? 0 : ((record.won.to_f / record.played) * 100).round
      else record.played
      end
    end
end
