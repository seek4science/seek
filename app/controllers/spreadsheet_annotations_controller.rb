class SpreadsheetAnnotationsController < ApplicationController

  unloadable

  before_filter :login_required
  before_filter :auth

  def create
    content = params[:annotation_content].strip
    if !content.blank?
      worksheet = @content_blob.worksheets.select {|w| w.sheet_number == params[:annotation_sheet_id].to_i}.first

      cell = CellRange.new(:worksheet => worksheet,
                           :cell_range => params[:annotation_cell_coverage])
      attribute_name = params[:annotation_attribute_name] || "annotation"
      if cell.save
        @annotation = Annotation.new(:source => current_user,
                                     :annotatable => cell,
                                     :attribute_name => attribute_name,
                                     :value => content)

        if(@annotation.save)
          render_success_update attribute_name
        else
          render_failure_update attribute_name, @annotation.errors
        end
      else
        render_failure_update attribute_name, cell.errors
      end
    else
      render_success_update attribute_name
    end

  end

  def update
    if @annotation.errors.empty? && @annotation.update_attributes(:value => params[:annotation_content])
      render :update do |page|
        page.replace_html "annotations", :partial => "spreadsheets/annotations", :locals=>{ :annotations => @content_blob.spreadsheet_annotations }
        page["spinner" + @annotation.id.to_s].hide
        page["spreadsheet_errors"].hide
      end
    else
      render :update do |page|
        page.replace_html "spreadsheet_errors", :partial => "spreadsheets/spreadsheet_errors", :status => 500, :locals=>{ :verb => "adding", :errors => @annotation.errors}
        page["spinner" + @annotation.id.to_s].hide
        page["spreadsheet_errors"].show
      end
    end
  end

  def destroy
    cell_range_to_destroy = @annotation.annotatable

    if @annotation.errors.empty? && @annotation.destroy && cell_range_to_destroy.destroy
      respond_to do |format|
        format.html { render :partial => "spreadsheets/annotations", :locals=>{ :annotations => @content_blob.spreadsheet_annotations} }
      end
    else
      respond_to do |format|
        format.html { render :partial => "spreadsheets/spreadsheet_errors", :status => 500, :locals=>{ :verb => "deleting", :errors => @annotation.errors} }
      end
    end
  end

  private

  def auth
    @content_blob = nil
    @annotation = nil

    if action_name == "create"
      @content_blob = ContentBlob.find(params[:annotation_content_blob_id])
    elsif action_name == "update" || action_name =="destroy"
      @annotation = Annotation.find(params[:id])
      @content_blob = @annotation.annotatable.worksheet.content_blob
    end

    unless @content_blob.nil?
      df = @content_blob.asset
      if !df.can_download?
        flash[:error] = "You are not permitted to annotate this spreadsheet."
        redirect_to data_file_path(df)
      elsif (!@annotation.nil? && (@annotation.source != current_user))
        @annotation.errors[:base] << "You may not edit or remove other users' annotations."
      end
    else
      respond_to do |format|
        flash[:error] = "Content not found."
        redirect_to root_url
      end
    end
  end

  def render_success_update attribute_name
    render :update do |page|
      page.replace_html "annotations", :partial => "spreadsheets/annotations", :locals=>{ :annotations => @content_blob.spreadsheet_annotations }
      page["annotation_form"].hide
      page["spreadsheet_errors"].hide
      if attribute_name == "annotation"
        page["spinner"].hide
      else
        page["spinner_plot"].hide
        page["plot_panel"].hide
      end
    end
  end

  def render_failure_update attribute_name, errors
    render :update do |page|
      page.replace_html "spreadsheet_errors", :partial => "spreadsheets/spreadsheet_errors", :status => 500, :locals=>{ :verb => "adding", :errors => errors}
      page["annotation_form"].hide
      page["spreadsheet_errors"].show
      if attribute_name == "annotation"
        page["spinner"].hide
      else
        page["spinner_plot"].hide
        page["plot_panel"].hide
      end
    end
  end
end