class ExperimentsController < ApplicationController

  before_filter :login_required, :except=>:index

  def index
    @experiments=Experiment.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @experiments.to_xml}
    end
  end
end
