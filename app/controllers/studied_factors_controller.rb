class StudiedFactorsController < ApplicationController
  include Seek::FactorStudied
  include Seek::AnnotationCommon
  include Seek::AssetsCommon

  before_action :login_required, except: [:show]
  before_action :find_data_file_edit_auth, except: [:show]
  before_action :find_data_file_view_auth, only: [:show]
  before_action :create_new_studied_factor, only: [:index]
  before_action -> { no_comma_for_decimal(studied_factor_params) }, only: %i[create update]

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

    if @studied_factor.save
      respond_to do |format|
        format.js
      end
    else
      render plain: @studied_factor.errors.full_messages, status: :unprocessable_entity
    end
  end

  def create_from_existing
    new_studied_factors = []
    # create the new FSes based on the selected FSes
    existing_studied_factor_params[:existing_studied_factor].each do |id|
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

    @saved_factors, @errored_factors = new_studied_factors.partition(&:save)
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @studied_factor = StudiedFactor.find(params[:id])

    if @studied_factor.destroy
      render js: "$j('#condition_or_factor_row_#{@studied_factor.id}').fadeOut();"
    else
      render plain: @studied_factor.errors.full_messages, status: :unprocessable_entity
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
      respond_to do |format|
        format.js
      end
    else
      render plain: @studied_factor.errors.full_messages, status: :unprocessable_entity
    end
  end

  def show
    @studied_factor = StudiedFactor.find(params[:id])
    respond_to do |format|
      format.rdf { render plain: 'not yet available',status: :forbidden }
    end
  end

  private

  def studied_factor_params
    params.require(:studied_factor).permit(:measured_item_id, :unit_id, :start_value, :end_value, :standard_deviation)
  end

  def existing_studied_factor_params
    params.permit(existing_studied_factor: [])
  end

  def find_data_file_view_auth
    data_file = DataFile.find(params[:data_file_id])
    if data_file.can_view? current_user
      @data_file = data_file
      find_display_asset @data_file
    else
      respond_to do |format|
        flash[:error] = 'You are not authorized to perform this action'
        format.html { redirect_to data_files_path }
        format.rdf { render plain: 'You are not authorized to perform this action', status: :forbidden }
      end
      return false
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      flash[:error] = "Couldn't find the Data file"
      format.html { redirect_to data_files_path }
      format.rdf { render plain: 'Not found', status: :not_found }
    end
    return false
  end

  def find_data_file_edit_auth
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
