# A won/drawn/lost summary over any set of matches.
class Match::Record
  def initialize(matches) = @matches = matches.to_a

  def played = @matches.size
  def won    = @matches.count(&:won?)
  def drawn  = @matches.count(&:drew?)
  def lost   = @matches.count(&:lost?)

  def goals_for     = @matches.sum(&:us_score)
  def goals_against = @matches.sum(&:opponent_score)

  def cities = @matches.map { |m| [ m.city, m.country ] }.uniq.size
end
