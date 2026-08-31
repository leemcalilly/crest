class CyclesController < ApplicationController
  def index
    @cycles = Cycle.chronological.includes(:matches)
    respond_to do |format|
      format.html { redirect_to cycle_path(@cycles.last) }
      format.json { render json: { cycles: @cycles.map { |c| c.as_json.slice(:slug, :name, :world_cup_year, :from, :to).merge(matches: c.matches.size) } } }
    end
  end

  def show
    @cycle = Cycle.find_by!(slug: params[:slug])
    @cycles = Cycle.chronological.includes(:matches)
    @record = @cycle.record
    @matches = @cycle.matches.chronological.includes(:goals)
    @world_cup = @matches.select { it.tournament == "FIFA World Cup" }

    respond_to do |format|
      format.html
      format.json { render json: @cycle.as_json.merge(matches: @matches.map(&:as_json)) }
    end
  end
end
