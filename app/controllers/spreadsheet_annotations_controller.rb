class SpreadsheetAnnotationsController < ApplicationController
  
  before_filter :login_required
  
  def create
    data_file = DataFile.find(params[:annotation_data_file_id])
    start_cell, end_cell = params[:annotation_cell_coverage].split(":")
    unless start_cell.nil? || start_cell.match(/[a-zA-Z]+[1-9][0-9]*/).nil? #FIXME: VALIDATION - NEED TO MOVE TO MODEL
      start_cell = start_cell.upcase
      start_column, start_row = SpreadsheetAnnotation.from_alpha(start_cell.sub(/[0-9]+/,"")), start_cell.sub(/[A-Z]+/,"").to_i
      end_column, end_row = nil, nil
      if end_cell.nil?        
        end_column = start_column
        end_row = start_row
      else
        end_cell = end_cell.upcase
        end_column, end_row = SpreadsheetAnnotation.from_alpha(end_cell.sub(/[0-9]+/,"")), end_cell.sub(/[A-Z]+/,"").to_i  
      end
    end
        
    new_annotation = SpreadsheetAnnotation.new(:data_file => data_file, :sheet => params[:annotation_sheet_id],
                              :start_row => start_row, :start_column => start_column,
                              :end_row => end_row, :end_column => end_column,
                              :source => current_user, :annotation_type => params[:annotation_type],
                              :content => params[:annotation_content])
    if(new_annotation.save)
      annotations = data_file.spreadsheet_annotations
      respond_to do |format|
        format.html { render :partial => "annotations/annotations", :locals=>{ :annotations => annotations} } 
      end
    else
      respond_to do |format|
        format.html { render :partial => "spreadsheets/spreadsheet_errors", :status => 500, :locals=>{ :verb => "adding", :errors => new_annotation.errors} } 
      end
    end
  end 

  def update
    annotation = SpreadsheetAnnotation.find(params[:id])
    params[:annotation_cell_coverage] = annotation.cell_coverage #FIXME: I AM BROKEN
    start_cell, end_cell = params[:annotation_cell_coverage].split(":")
    start_column, start_row = SpreadsheetAnnotation.from_alpha(start_cell.sub(/[0-9]+/,"")), start_cell.sub(/[A-Z]+/,"").to_i
    end_column, end_row = nil, nil
    if end_cell.nil?
      end_column = start_column
      end_row = start_row
    else
      end_column, end_row = SpreadsheetAnnotation.from_alpha(end_cell.sub(/[0-9]+/,"")), end_cell.sub(/[A-Z]+/,"").to_i  
    end
           
        
    if annotation.update_attributes(:start_row => start_row, :start_column => start_column,
                                                  :end_row => end_row, :end_column => end_column,
                                                  :annotation_type => params[:annotation_type],
                                                  :content => params[:annotation_content])
      annotations = annotation.data_file.spreadsheet_annotations
      respond_to do |format|
        format.html { render :partial => "annotations/annotations", :locals=>{ :annotations => annotations} } 
      end
    else
      respond_to do |format|
        format.html { render :partial => "spreadsheets/spreadsheet_errors", :status => 500, :locals=>{ :verb => "editting", :errors => annotation.errors} } 
      end
    end
  end 
  
  def destroy
    annotation = SpreadsheetAnnotation.find(params[:id])
    data_file = annotation.data_file
            
    if annotation.destroy
      annotations = data_file.spreadsheet_annotations
      respond_to do |format|
        format.html { render :partial => "annotations/annotations", :locals=>{ :annotations => annotations} } 
      end
    else
      respond_to do |format|
        format.html { render :partial => "spreadsheets/spreadsheet_errors", :status => 500, :locals=>{ :verb => "deleting", :errors => annotation.errors} } 
      end
    end
  end 

end