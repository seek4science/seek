class ToolsController < ApplicationController

  def filter
    client = BioTools::Client.new
    res = client.filter(params[:filter])

    respond_to do |format|
      format.html { render partial: 'tools/association_preview', collection: res['list'] }
    end
  end

end
