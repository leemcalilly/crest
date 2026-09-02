class CyclesController < ApplicationController
  def index
    @cycles = Cycle.chronological.includes(:matches)
    respond_to do |format|
      format.html { redirect_to cycle_path(@cycles.last) }
      format.json do
        opponent = params[:opponent].presence
        render json: {
          opponent: opponent,
          cycles: @cycles.map { |c|
            measures = opponent ? c.metrics_against(opponent) : c.metrics
            { slug: c.slug, name: c.name, world_cup_year: c.world_cup_year,
              from: c.starts_on.year, to: c.ends_on.year }.merge(measures)
          }
        }
      end
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
