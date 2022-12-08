class PlaceholdersController < ApplicationController

  include Seek::IndexPager

  include Seek::AssetsCommon

  before_action :find_assets, :only=>[:index]
  before_action :find_and_authorize_requested_item,:only=>[:edit, :manage, :update, :manage_update, :destroy, :show,:new_object_based_on_existing_one ]

  api_actions :index, :show, :create, :update, :destroy

  def create
    item = initialize_asset
    update_template() if params.key?(:file_template_id)
    resolve() if params.key?(:data_file_id)
    create_asset_and_respond(item)
  end
  
  def show
    respond_to do |format|
        format.html
        format.rdf { render template: 'rdf/show' }
        format.json { render json: @placeholder, include: json_api_include_param }
      end
    end

  def data_file
    @placeholder = Placeholder.find(params[:id])
    unless @placeholder.data_file.blank?
      respond_to do |format|
        format.html { redirect_to data_file_path(@placeholder.data_file) }
      end
    else
      flash[:error] = 'Unable to view contents of the data file'
      format.html { redirect_to placeholder_path(@placeholder) }
    end
  end
  
  def update

    update_sharing_policies @placeholder
    update_relationships(@placeholder,params)
    update_template() if params.key?(:file_template_id)
    resolve() if params.key?(:data_file_id)

    respond_to do |format|

      if @placeholder.update(placeholder_params)
        flash[:notice] = "#{t('placeholder')} metadata was successfully updated."
        format.html { redirect_to placeholder_path(@placeholder) }
        format.json { render json: @placeholder, include: [params[:include]] }
      else
        format.html { render action: 'edit' }
        format.json { render json: json_api_errors(@placeholder), status: :unprocessable_entity }
      end
    end
  end

  def update_template
    if (params[:file_template_id].empty?)
      @placeholder.file_template_id = nil
      ft = nil
    else
      @placeholder.file_template_id = params[:file_template_id]
      ft = FileTemplate.find(params[:file_template_id])
    end
  end
  
  def resolve
    if params.key?(:data_file_id)
      df = DataFile.find(params[:data_file_id])
      if df.can_edit?
        @placeholder.data_file = df
        @placeholder.assays.each do |a|
          assay_asset = a.assay_assets.detect { |aa| aa.asset == @placeholder }
          direction = assay_asset.direction
          a.associate(df, direction: direction)
          a.save!
        end
        @placeholder.save!
      end
    end
  end
  
  def filter
    scope = Placeholder
    scope = scope.joins(:projects).where(projects: { id: current_user.person.projects }) unless (params[:all_projects] == 'true')
    scope = scope.where(simulation_data: true) if (params[:simulation_data] == 'true')
    @placeholders = scope.where('placeholders.title LIKE ?', "%#{params[:filter]}%").distinct.authorized_for('view').first(20)

    respond_to do |format|
      format.html { render partial: 'data_files/association_preview', collection: @placeholders, locals: { hide_sample_count: !params[:with_samples] } }
    end
  end
  private

  def placeholder_params
    params.require(:placeholder).permit(:title, :description, { project_ids: [] }, :license, :other_creators,
                                { special_auth_codes_attributes: [:code, :expiration_date, :id, :_destroy] },
                                { creator_ids: [] }, { assay_assets_attributes: [:assay_id] },
                                :file_template_id,
                                :data_format_annotations, :data_type_annotations,
                                :data_file_id,
                                discussion_links_attributes:[:id, :url, :label, :_destroy])
  end

  alias_method :asset_params, :placeholder_params

end
