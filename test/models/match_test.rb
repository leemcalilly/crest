require "test_helper"

class MatchTest < ActiveSupport::TestCase
  test "readers never see the sponsor's name on the World Cup" do
    match = Match.find_by!(played_on: Date.new(1994, 7, 4))
    assert_equal "FIFA World Cup", match.tournament
    assert_equal "World Cup", match.tournament_name
  end

  test "results read from the United States point of view" do
    match = Match.recent_first.first
    assert_equal "Belgium", match.opponent
    assert_equal "L", match.result
    assert_equal 1, match.us_score
  end
end
