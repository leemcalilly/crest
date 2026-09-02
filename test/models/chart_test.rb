require "test_helper"

class ChartTest < ActiveSupport::TestCase
  test "cycles are one view among several, and every view draws" do
    Chart::VIEWS.each_key do |view|
      bars = Chart.new(view: view).bars
      assert bars.any?, "#{view} drew nothing"
      assert bars.all? { it[:value].is_a?(Integer) }, "#{view} produced a non-numeric bar"
    end
  end

  test "the cycles view keeps all 24, others are capped" do
    assert_equal 24, Chart.new(view: "cycles").bars.size
    assert_operator Chart.new(view: "opponents").bars.size, :<=, Chart::LIMIT
  end

  test "bars are ordered by value in the ranked views" do
    values = Chart.new(view: "opponents").bars.map { it[:value] }
    assert_equal values.sort.reverse, values
  end

  test "an unknown view falls back to cycles rather than failing" do
    assert_equal "cycles", Chart.new(view: "nonsense").view
  end

  test "an unsupported measure falls back to one the view supports" do
    assert_equal "goals", Chart.new(view: "scorers", metric: "win_rate").metric
  end

  test "narrowing to an opponent changes what is drawn" do
    all = Chart.new(view: "cycles", metric: "matches").bars.sum { it[:value] }
    mexico = Chart.new(view: "cycles", metric: "matches", opponent: "Mexico").bars.sum { it[:value] }
    assert_equal 795, all
    assert_equal 76, mexico
  end

  test "goal difference goes negative, and win rate never divides by zero" do
    assert Chart.new(view: "cycles", metric: "goal_difference").bars.any? { it[:value] < 0 }
    assert Chart.new(view: "cycles", metric: "win_rate", opponent: "Nowhere").bars.all? { it[:value].zero? }
  end

  test "cycle and scorer bars carry a link so a reader can follow them" do
    assert Chart.new(view: "cycles").bars.all? { it[:href].present? }
    assert Chart.new(view: "scorers").bars.all? { it[:href].present? }
  end
end
