class PlayersController < ApplicationController
  def index
    @players = Player.by_goals.limit(50)
    respond_to do |format|
      format.html
      format.json { render json: { players: @players.map { |p| { name: p.name, slug: p.slug, goals: p.goal_count } } } }
    end
  end

  def show
    @player = Player.find_by!(slug: params[:slug])
    respond_to do |format|
      format.html
      format.json { render json: @player }
    end
  end
end
