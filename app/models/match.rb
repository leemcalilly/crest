class Match < ApplicationRecord
  belongs_to :cycle
  has_many :goals, dependent: :destroy

  scope :chronological, -> { order(:played_on) }
  scope :recent_first, -> { order(played_on: :desc) }
  scope :in_tournament, ->(name) { where(tournament: name) }

  # The source writes "FIFA World Cup". Readers see "World Cup".
  TOURNAMENT_NAMES = { "FIFA World Cup" => "World Cup",
                       "FIFA World Cup qualification" => "World Cup qualifying" }.freeze

  def tournament_name = TOURNAMENT_NAMES.fetch(tournament, tournament)

  def won?  = us_score > opponent_score
  def drew? = us_score == opponent_score
  def lost? = us_score < opponent_score

  def result = won? ? "W" : (drew? ? "D" : "L")

  def score = "#{us_score} – #{opponent_score}"
  def venue = "#{city}, #{country}"

  def scorers = goals.includes(:player).order(:minute)
end
