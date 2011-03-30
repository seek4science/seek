class SvgController < ApplicationController

  layout nil

  def show
    id = params[:id]
    dir="#{RAILS_ROOT}/tmp/models"
    path = "#{dir}/#{id}.svg"
    svg=open(path).read
    raise Exception.new("Not svg") unless svg.include?("<svg")
    respond_to do |format|
      format.svg { render :file=>path}
    end
  end
end
