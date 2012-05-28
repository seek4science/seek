class DataFileWithSamplesController < ApplicationController

  def controller_name
      DataFilesController.controller_name
  end

  def new
    page_title =  "Samples Data File Parser"
    redirect_to new_data_file_path(:page_title=>page_title)
  end

end
