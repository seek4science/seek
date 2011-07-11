class SpreadsheetAnnotationsController < ApplicationController

  unloadable
  
  before_filter :login_required
  
  def create
    data_file = DataFile.find(params[:annotation_data_file_id])
        
    new_annotation = SpreadsheetAnnotation.new(:data_file => data_file, :sheet => params[:annotation_sheet_id],
                              :cell_range => params[:annotation_cell_coverage],
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
        
    if annotation.update_attributes(:annotation_type => params[:annotation_type],
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