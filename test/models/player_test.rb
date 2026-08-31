require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  test "the leading scorer's arc rises every cycle" do
    dempsey = Player.find_by!(name: "Clint Dempsey")
    assert_equal 41, dempsey.goal_count
    assert_equal [ 2, 10, 13, 16 ], dempsey.goals_by_cycle.map(&:last)
  end

  test "only United States scorers become players" do
    assert_not Player.exists?(name: "Diego Maradona")
    assert Goal.where(for_us: false).any?
  end
end
