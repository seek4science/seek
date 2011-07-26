class SpreadsheetAnnotationsController < ApplicationController

  unloadable

  before_filter :login_required

  def create
    content_blob = ContentBlob.find(params[:annotation_content_blob_id])
    worksheet = content_blob.worksheets.select {|w| w.sheet_number == params[:annotation_sheet_id].to_i}.first

    cell = CellRange.new( :worksheet => worksheet,
                         :cell_range => params[:annotation_cell_coverage])

    if (cell.save)
      new_annotation = Annotation.new(:source => current_user,
                                     :annotatable => cell,
                                     :attribute_name => params[:annotation_attribute_name],
                                     :value => params[:annotation_content])

      if(new_annotation.save)
        respond_to do |format|
          format.html { render :partial => "spreadsheets/annotations", :locals=>{ :annotations => content_blob.spreadsheet_annotations }}
        end
      else
        respond_to do |format|
          format.html { render :partial => "spreadsheets/spreadsheet_errors", :status => 500, :locals=>{ :verb => "adding", :errors => new_annotation.errors} }
        end
      end
    else
      respond_to do |format|
        format.html { render :partial => "spreadsheets/spreadsheet_errors", :status => 500, :locals=>{ :verb => "adding", :errors => cell.errors} }
      end
    end

  end

  def update
    annotation = Annotation.find(params[:id])
    content_blob = annotation.annotatable.worksheet.content_blob

    if annotation.update_attributes(:value => params[:annotation_content])
      respond_to do |format|
        format.html { render :partial => "spreadsheets/annotations", :locals=>{ :annotations => content_blob.spreadsheet_annotations} }
      end
    else
      respond_to do |format|
        format.html { render :partial => "spreadsheets/spreadsheet_errors", :status => 500, :locals=>{ :verb => "editing", :errors => annotation.errors} }
      end
    end
  end

  def destroy
    annotation = Annotation.find(params[:id])
    content_blob = annotation.annotatable.worksheet.content_blob
    cell_range_to_destroy = annotation.annotatable

    if annotation.destroy && cell_range_to_destroy.destroy
      respond_to do |format|
        format.html { render :partial => "spreadsheets/annotations", :locals=>{ :annotations => content_blob.spreadsheet_annotations} }
      end
    else
      respond_to do |format|
        format.html { render :partial => "spreadsheets/spreadsheet_errors", :status => 500, :locals=>{ :verb => "deleting", :errors => annotation.errors} }
      end
    end
  end

end