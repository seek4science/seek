# Primary use is to locally serve SVG diagrams provided by JWS Online (The schema diagrams) as the SVGWEB javascript library
# requires that it is served locally, and also that the URL has a .svg extension

class SvgController < ApplicationController

  before_filter :login_required

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
