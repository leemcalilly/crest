class Player < ApplicationRecord
  has_many :goals, dependent: :nullify

  scope :by_goals, -> { left_joins(:goals).group(:id).order("COUNT(goals.id) DESC, players.name") }

  def to_param = slug

  def self.slug_for(name) = name.parameterize

  def goal_count = goals.count
  def first_goal_on = goals.joins(:match).minimum("matches.played_on")
  def last_goal_on  = goals.joins(:match).maximum("matches.played_on")

  def cycles = Cycle.joins(matches: :goals).where(goals: { player_id: id }).distinct.chronological

  def goals_by_cycle
    cycles.map { |cycle| [ cycle, goals.joins(:match).where(matches: { cycle_id: cycle.id }).count ] }
  end

  def penalties = goals.where(penalty: true).count
  def average_minute = goals.where.not(minute: nil).average(:minute)&.round
end
