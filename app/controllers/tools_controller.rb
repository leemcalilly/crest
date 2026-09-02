class ToolsController < ApplicationController
  def show
    @tools = ModelContext::Manifest.new.tools
  end
end
