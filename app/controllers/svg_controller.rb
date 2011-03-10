#temporary hack to get things working for workshop
class SvgController < ApplicationController

  layout nil

  def show
    id = params[:id]
    path = "/tmp/#{id}.svg"
    svg=open(path).read
    raise Exception.new("Not svg") unless svg.include?("<svg")
    respond_to do |format|
      format.html { render :file=>path}
    end
  end
end
