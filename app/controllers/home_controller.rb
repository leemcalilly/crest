class HomeController < ApplicationController
  def show
    @record = Match::Record.new(Match.all)
    @opponents = Match.distinct.count(:opponent)
    @latest = Match.recent_first.first
    @first = Match.chronological.first
    @cycles = Cycle.chronological.includes(:matches)
    @current = Cycle.for(@latest.played_on)
    @leader = Player.by_goals.first
  end
end
