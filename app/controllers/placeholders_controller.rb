class PlaceholdersController < ApplicationController

  include Seek::IndexPager

  include Seek::AssetsCommon

  before_action :find_assets, :only=>[:index]
  before_action :find_and_authorize_requested_item,:only=>[:edit, :manage, :update, :manage_update, :destroy, :show,:new_object_based_on_existing_one]

  api_actions :index, :show, :create, :update, :destroy

  def create
    item = initialize_asset
    update_template() if params.key?(:file_template_id)
    create_asset_and_respond(item)
  end
  
  def show
    @last_used_before_now = @placeholder.last_used_at

    # update timestamp in the current record
    # (this will also trigger timestamp update in the corresponding Asset)
    @placeholder.just_used
    respond_to do |format|
        format.html
        format.xml
        format.rdf { render template: 'rdf/show' }
        format.json { render json: @placeholder, include: json_api_include_param }
      end
    end

  def update

    update_sharing_policies @placeholder
    update_relationships(@placeholder,params)
    update_template() if params.key?(:file_template_id)

    respond_to do |format|

      if @placeholder.update_attributes(placeholder_params)
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
                                :format_type,
                                :data_type,
                                discussion_links_attributes:[:id, :url, :label, :_destroy])
  end

  alias_method :asset_params, :placeholder_params

end
