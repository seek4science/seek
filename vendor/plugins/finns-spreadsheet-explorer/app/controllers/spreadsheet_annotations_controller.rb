class SpreadsheetAnnotationsController < ApplicationController
  
  def fucker
    @data_file = DataFile.first
    annotations = @data_file.spreadsheet_annotations
    respond_to do |format|
      format.html { render :partial => "annotations/annotation", :collection=>annotations } 
    end
  end

end