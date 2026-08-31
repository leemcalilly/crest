class Match < ApplicationRecord
  belongs_to :cycle
  has_many :goals, dependent: :destroy

  scope :chronological, -> { order(:played_on) }
  scope :recent_first, -> { order(played_on: :desc) }
  scope :in_tournament, ->(name) { where(tournament: name) }
  scope :against, ->(name) { where("opponent LIKE ?", "%#{name}%") }
  scope :in_year, ->(year) { where(played_on: Date.new(year.to_i)..Date.new(year.to_i, 12, 31)) }

  # One place both the HTML page and the JSON representation filter through.
  def self.search(params)
    scope = all
    scope = scope.against(params[:opponent]) if params[:opponent].present?
    scope = scope.in_year(params[:year]) if params[:year].present?
    scope = scope.in_tournament(TOURNAMENT_NAMES.key(params[:tournament]) || params[:tournament]) if params[:tournament].present?
    scope
  end

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

  def as_json(options = nil)
    { id:, played_on:, opponent:, us_score:, opponent_score:, result:,
      tournament: tournament_name, city:, country:, neutral:,
      cycle: cycle.slug }
  end

  def as_full_json
    as_json.merge(scorers: scorers.map { |g|
      { name: g.scorer_name, minute: g.minute, for_united_states: g.for_us,
        penalty: g.penalty, own_goal: g.own_goal }
    })
  end
end
