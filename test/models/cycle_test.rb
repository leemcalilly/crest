require "test_helper"

class CycleTest < ActiveSupport::TestCase
  test "the record covers every United States match" do
    assert_equal 795, Match.count
    assert_equal 24, Cycle.count
  end

  test "the 1994 cycle holds the run-up to the home World Cup" do
    cycle = Cycle.find_by!(slug: "1994")
    assert_equal Date.new(1991, 1, 1), cycle.starts_on
    assert_equal 97, cycle.record.played
    assert_equal 16, cycle.position
  end

  test "only the war gap counts as interrupted" do
    assert Cycle.find_by!(slug: "1950").interrupted?
    assert_not Cycle.find_by!(slug: "1994").interrupted?
    assert_not Cycle.where(world_cup_year: nil).first.interrupted?
  end

  test "cycles link forward and back" do
    cycle = Cycle.find_by!(slug: "1994")
    assert_equal "1990", cycle.previous.slug
    assert_equal "1998", cycle.next.slug
  end
end
