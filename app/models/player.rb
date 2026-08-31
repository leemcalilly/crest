class Player < ApplicationRecord
  has_many :goals, dependent: :nullify

  scope :by_goals, -> { left_joins(:goals).group(:id).order(Arel.sql("COUNT(goals.id) DESC, players.name")) }

  def to_param = slug

  def self.slug_for(name) = name.parameterize

  def goal_count = goals.count
  def first_goal_on = goals.joins(:match).minimum("matches.played_on")
  def last_goal_on  = goals.joins(:match).maximum("matches.played_on")

  def cycles = Cycle.joins(matches: :goals).where(goals: { player_id: id }).distinct.chronological

  def goals_by_cycle
    cycles.map { |cycle| [ cycle, goals.joins(:match).where(matches: { cycle_id: cycle.id }).count ] }
  end

  # The opponents this player scored most against.
  def top_opponents(limit = 5)
    goals.joins(:match).group("matches.opponent").order(Arel.sql("COUNT(*) DESC")).limit(limit).count
  end

  def world_cup_goals
    goals.joins(:match).where(matches: { tournament: "FIFA World Cup" })
         .includes(:match).order("matches.played_on")
  end

  def rank = Player.by_goals.map(&:id).index(id) + 1

  def as_json(options = nil)
    { name:, slug:, rank:, goals: goal_count,
      caps: nil,
      caps_note: "Appearance data does not exist in the source. crest counts caps from launch forward.",
      first_goal_on: first_goal_on, last_goal_on: last_goal_on,
      penalties:, average_minute:,
      goals_by_cycle: goals_by_cycle.map { |c, n| { cycle: c.slug, name: c.name, goals: n } },
      world_cup_goals: world_cup_goals.map { |g|
        { year: g.match.played_on.year, opponent: g.match.opponent, minute: g.minute } },
      top_opponents: top_opponents }
  end

  def penalties = goals.where(penalty: true).count
  def average_minute = goals.where.not(minute: nil).average(:minute)&.round
end
