class MatchesController < ApplicationController
  def index
    @matches = Match.search(params).chronological.limit(50)
    respond_to do |format|
      format.html { redirect_to root_path }
      format.json { render json: { count: @matches.size, matches: @matches.map(&:as_json) } }
    end
  end

  def show
    @match = Match.includes(goals: :player).find(params[:id])
    respond_to do |format|
      format.html
      format.json { render json: @match.as_full_json }
    end
  end
end
