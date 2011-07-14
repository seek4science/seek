class StudiedFactorsController < ApplicationController
  before_filter :login_required
  before_filter :find_data_file_auth
  before_filter :create_new_studied_factor, :only=>[:index]
  before_filter :no_comma_for_decimal, :only=>[:create, :update]


  include StudiedFactorsHelper

  def index
    respond_to do |format|
      format.html
      format.xml {render :xml=>@data_file.studied_factors}
    end
  end

  def create
    @studied_factor=StudiedFactor.new(params[:studied_factor])
    @studied_factor.data_file=@data_file
    @studied_factor.data_file_version = params[:version]
    new_substances = params[:substance_autocompleter_unrecognized_items] || []
    known_substance_ids_and_types = params[:substance_autocompleter_selected_ids] || []
    @studied_factor.substance = find_or_create_substance new_substances,known_substance_ids_and_types

    render :update do |page|
      if @studied_factor.save
        page.insert_html :bottom,"condition_or_factor_rows",:partial=>"condition_or_factor_row",:object=>@studied_factor,:locals=>{:asset => 'data_file', :show_delete=>true}
        page.visual_effect :highlight,"condition_or_factor_rows"
        # clear the _add_factor form
        page.call "autocompleters['substance_autocompleter'].deleteAllTokens"
        page[:add_condition_or_factor_form].reset
        page[:substance_autocomplete_input].disabled = true
      else
        page.alert(@studied_factor.errors.full_messages)
      end
    end
  end

  def destroy
    @studied_factor=StudiedFactor.find(params[:id])
    render :update do |page|
      if @studied_factor.destroy
         page.visual_effect :fade, "condition_or_factor_row_#{@studied_factor.id}"
         page.visual_effect :fade, "edit_condition_or_factor_#{@studied_factor.id}_form"
      else
        page.alert(@studied_factor.errors.full_messages)
      end
    end
  end

  def update
    @studied_factor = StudiedFactor.find(params[:id])

    new_substances = params["#{@studied_factor.id}_substance_autocompleter_unrecognized_items"] || []
    known_substance_ids_and_types = params["#{@studied_factor.id}_substance_autocompleter_selected_ids"] || []
    substance = find_or_create_substance new_substances,known_substance_ids_and_types

    params[:studied_factor][:substance_id] = substance.try :id
    params[:studied_factor][:substance_type] = substance.class.name == nil.class.name ? nil : substance.class.name

    render :update do |page|
      if  @studied_factor.update_attributes(params[:studied_factor])
        page.visual_effect :fade,"edit_condition_or_factor_#{@studied_factor.id}_form"
        page.replace_html "condition_or_factor_row_#{@studied_factor.id}", :partial => 'condition_or_factor_row', :object => @studied_factor, :locals=>{:asset => 'data_file', :show_delete=>true}
      else
        page.alert(@studied_factor.errors.full_messages)
      end
    end
  end

  private

  def find_data_file_auth
    begin
      data_file = DataFile.find(params[:data_file_id])
      if data_file.can_edit? current_user
        @data_file = data_file
        @display_data_file = params[:version] ? @data_file.find_version(params[:version]) : @data_file.latest_version
      else
        respond_to do |format|
          flash[:error] = "You are not authorized to perform this action"
          format.html { redirect_to data_files_path }
        end
        return false
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        flash[:error] = "Couldn't find the Data file"
        format.html { redirect_to data_files_path }
      end
      return false
    end
  end

  def create_new_studied_factor
    @studied_factor=StudiedFactor.new(:data_file=>@data_file)
  end

end
