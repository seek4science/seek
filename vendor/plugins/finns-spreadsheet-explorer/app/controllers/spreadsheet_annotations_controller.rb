class SpreadsheetAnnotationsController < ApplicationController

  unloadable

  before_filter :login_required

  def create
    data_file = DataFile.find(params[:annotation_data_file_id])
    worksheet = data_file.content_blob.worksheets.select { |w| w.sheet_number == params[:annotation_sheet_id].to_i }.first

    if data_file.can_download?

      cell = CellRange.new(:worksheet => worksheet,
                           :cell_range => params[:annotation_cell_coverage])

      if (cell.save)
        new_annotation = Annotation.new(:source => current_user,
                                        :annotatable => cell,
                                        :attribute_name => "annotation",
                                        :value => params[:annotation_content])

        if (new_annotation.save)

          respond_to do |format|
            format.html { render :partial => "annotations/annotations", :locals=>{:annotations => data_file.spreadsheet_annotations} }
          end
        else
          respond_to do |format|
            format.html { render :partial => "spreadsheets/spreadsheet_errors", :status => 500, :locals=>{:verb => "adding", :errors => new_annotation.errors} }
          end
        end
      else
        respond_to do |format|
          format.html { render :partial => "spreadsheets/spreadsheet_errors", :status => 500, :locals=>{:verb => "adding", :errors => cell.errors} }
        end
      end
    end
  end

  def update
    annotation= Annotation.find(params[:id])
    data_file = DataFile.find_by_content_blob_id(annotation.annotatable.worksheet.content_blob_id)

    if annotation.update_attributes(:value => params[:annotation_content])

      annotations = data_file.spreadsheet_annotations

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
    annotation= Annotation.find(params[:id])
    data_file = DataFile.find_by_content_blob_id(annotation.annotatable.worksheet.content_blob_id)
    cell_range_to_destroy = annotation.annotatable

    if annotation.destroy && cell_range_to_destroy.destroy

      annotations = data_file.spreadsheet_annotations
      respond_to do |format|
        format.html { render :partial => "annotations/annotations", :locals=>{ :annotations => annotations} }
      end
    else
      respond_to do |format|
        format.html { render :partial => "spreadsheets/spreadsheet_errors", :status => 500, :locals=>{ :verb => "deleting", :errors => cell_range_to_destroy.errors} }
      end
    end
  end

end