class StudiedFactorsController < ApplicationController
  include Seek::FactorStudied
  include Seek::AnnotationCommon
  include Seek::AssetsCommon

  before_filter :login_required
  before_filter :find_data_file_auth
  before_filter :create_new_studied_factor, only: [:index]
  before_filter :no_comma_for_decimal, only: %i[create update]

  include Seek::BreadCrumbs

  def index
    respond_to do |format|
      format.html
      format.xml { render xml: @data_file.studied_factors }
    end
  end

  def create
    @studied_factor = StudiedFactor.new(studied_factor_params)
    @studied_factor.data_file = @data_file
    @studied_factor.data_file_version = params[:version]
    substances = find_or_new_substances(params[:substance_list])

    substances.each do |substance|
      @studied_factor.studied_factor_links.build(substance: substance)
    end

    update_annotations(params[:annotation][:value], @studied_factor, 'description') if try_block { !params[:annotation][:value].blank? }

    render :update do |page|
      if @studied_factor.save
        page.insert_html :bottom, 'condition_or_factor_rows', partial: 'condition_or_factor_row', object: @studied_factor, locals: { asset: 'data_file', show_delete: true }
        page.visual_effect :highlight, 'condition_or_factor_rows'
        # clear the _add_factor form
        page.call "autocompleters['substance_autocompleter'].deleteAllTokens"
        page[:add_condition_or_factor_form].reset
        page[:substance_condition_factor].hide
        page[:growth_medium_or_buffer_description].hide
      else
        page.alert(@studied_factor.errors.full_messages)
      end
    end
  end

  def create_from_existing
    studied_factor_ids = []
    new_studied_factors = []
    # retrieve the selected FSes

    params.each do |key, value|
      studied_factor_ids.push value.to_i if (key =~ /checkbox/)
    end
    # create the new FSes based on the selected FSes
    studied_factor_ids.each do |id|
      studied_factor = StudiedFactor.find(id)
      new_studied_factor = StudiedFactor.new(measured_item_id: studied_factor.measured_item_id, unit_id: studied_factor.unit_id, start_value: studied_factor.start_value,
                                             end_value: studied_factor.end_value, standard_deviation: studied_factor.standard_deviation)
      new_studied_factor.data_file = @data_file
      new_studied_factor.data_file_version = params[:version]
      studied_factor.studied_factor_links.each do |sfl|
        new_studied_factor.studied_factor_links.build(substance: sfl.substance)
      end
      params[:annotation] = {}
      params[:annotation][:value] = try_block { Annotation.for_annotatable(studied_factor.class.name, studied_factor.id).with_attribute_name('description').first.value.text }
      update_annotations(params[:annotation][:value], new_studied_factor, 'description', false) if try_block { !params[:annotation][:value].blank? }

      new_studied_factors.push new_studied_factor
    end

    render :update do |page|
      new_studied_factors.each do |sf|
        if sf.save
          page.insert_html :bottom, 'condition_or_factor_rows', partial: 'studied_factors/condition_or_factor_row', object: sf, locals: { asset: 'data_file', show_delete: true }
        else
          page.alert("can not create factor studied: item: #{try_block { sf.substances.collect { |s| s.title + '/' } }} #{sf.measured_item.title}, values: #{sf.start_value}-#{sf.end_value}#{sf.unit.title}, SD: #{sf.standard_deviation}")
        end
      end
      page.visual_effect :highlight, 'condition_or_factor_rows'
    end
  end

  def destroy
    @studied_factor = StudiedFactor.find(params[:id])
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
    substances = find_or_new_substances(params[:substance_list])

    # delete the old studied_factor_links
    @studied_factor.studied_factor_links.each(&:destroy)

    # create the new studied_factor_links
    studied_factor_links = []
    substances.each do |substance|
      studied_factor_links.push StudiedFactorLink.new(substance: substance)
    end
    @studied_factor.studied_factor_links = studied_factor_links

    update_annotations(params[:annotation][:value], @studied_factor, 'description') if try_block { !params[:annotation][:value].blank? }

    if @studied_factor.update_attributes(studied_factor_params)
      render :update do |page|
        page.visual_effect :fade, "edit_condition_or_factor_#{@studied_factor.id}_form"
        page.call "autocompleters['#{@studied_factor.id}_substance_autocompleter'].deleteAllTokens"
        page.replace "condition_or_factor_row_#{@studied_factor.id}", partial: 'condition_or_factor_row', object: @studied_factor, locals: { asset: 'data_file', show_delete: true }
      end
    else
      render :update do |page|
        page.alert(@studied_factor.errors.full_messages)
      end
    end
  end

  private

  def studied_factor_params
    params.require(:studied_factor).permit(:measured_item_id, :unit_id, :start_value, :end_value, :standard_deviation)
  end

  def find_data_file_auth
    data_file = DataFile.find(params[:data_file_id])
    if data_file.can_edit? current_user
      @data_file = data_file
      find_display_asset @data_file
    else
      respond_to do |format|
        flash[:error] = 'You are not authorized to perform this action'
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

  def create_new_studied_factor
    @studied_factor = StudiedFactor.new(data_file: @data_file)
  end
end
