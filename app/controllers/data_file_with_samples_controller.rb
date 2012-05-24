class DataFileWithSamplesController < ApplicationController

  def controller_name
      DataFilesController.controller_name
  end

  def new
    @data_file = DataFile.new
    redirect_to :controller => :data_files, :action => :new
  end

end
