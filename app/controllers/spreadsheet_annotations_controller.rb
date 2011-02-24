class SpreadsheetAnnotationsController < ApplicationController
  
  before_filter :login_required
  
  def create
    data_file = DataFile.find(params[:data_file_id])
    start_cell, end_cell = params[:cell_coverage].split(":")
    start_column, start_row = SpreadsheetAnnotation.from_alpha(start_cell.sub(/[0-9]+/,"")), start_cell.sub(/[A-Z]+/,"").to_i
    end_column, end_row = nil, nil
    if end_cell.nil?
      end_column = start_column
      end_row = start_row
    else
      end_column, end_row = SpreadsheetAnnotation.from_alpha(end_cell.sub(/[0-9]+/,"")), end_cell.sub(/[A-Z]+/,"").to_i  
    end
           
        
    new_annotation = SpreadsheetAnnotation.new(:data_file => data_file, :sheet => params[:sheet_id],
                              :start_row => start_row, :start_column => start_column,
                              :end_row => end_row, :end_column => end_column,
                              :source => current_user, :annotation_type => "test",
                              :content => params[:content])
    if(new_annotation.save)
      annotations = data_file.spreadsheet_annotations
      respond_to do |format|
        format.html { render :partial => "annotations/annotations", :locals=>{ :annotations => annotations} } 
      end
    end
  end 

end