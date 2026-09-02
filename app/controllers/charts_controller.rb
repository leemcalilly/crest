class ChartsController < ApplicationController
  def show
    chart = Chart.new(view: params[:view].to_s, metric: params[:metric].to_s, opponent: params[:opponent])
    render json: { view: chart.view, metric: chart.metric, opponent: chart.opponent,
                   title: chart.title, label: chart.label, bars: chart.bars }
  end
end
