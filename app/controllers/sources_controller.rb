class SourcesController < ApplicationController
  def show
    @matches = Match.count
    @players = Player.count
    @goals = Goal.count
  end
end
