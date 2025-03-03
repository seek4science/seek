class SopsController < ApplicationController

  include Seek::IndexPager

  include Seek::AssetsCommon

  before_action :sops_enabled?
  before_action :find_assets, :only => [ :index ]
  before_action :find_and_authorize_requested_item, :except => [ :index, :new, :create, :preview, :update_annotations_ajax]
  before_action :find_display_asset, :only=>[:show, :explore, :download]

  
  include Seek::Publishing::PublishingCommon

  include Seek::Doi::Minting

  include Seek::ISAGraphExtensions

  api_actions :index, :show, :create, :update, :destroy

  def create_version
    if handle_upload_data(true)
      comments=params[:revision_comments]


      respond_to do |format|
        if @sop.save_as_new_version(comments)
          flash[:notice]="New version uploaded - now on version #{@sop.version}"
        else
          flash[:error]="Unable to save new version"
        end
        format.html {redirect_to @sop }
      end
    else
      flash[:error]=flash.now[:error]
      redirect_to @sop
    end

  end

  # PUT /sops/1
  def update
    update_annotations(params[:tag_list], @sop) if params.key?(:tag_list)
    update_sharing_policies @sop
    update_relationships(@sop,params)

    respond_to do |format|
      if @sop.update(sop_params)
        flash[:notice] = "#{t('sop')} metadata was successfully updated."
        format.html { redirect_to sop_path(@sop) }
        format.json { render json: @sop, include: [params[:include]] }
      else
        format.html { render action: 'edit' }
        format.json { render json: json_api_errors(@sop), status: :unprocessable_entity }
      end
    end
  end

  def dynamic_table_typeahead
    return if params[:study_id].blank? && params[:assay_id].blank?

    query = params[:query] || ''
    asset = if params[:study_id].present?
              Study.authorized_for('view').detect { |study| study.id.to_s == params[:study_id] }
            else
              Assay.authorized_for('view').detect { |assay| assay.id.to_s == params[:assay_id] }
            end

    sops = asset&.sops || []
    filtered_sops = sops.select { |sop| sop.title&.downcase&.include?(query.downcase) }
    items = filtered_sops.collect { |sop| { id: sop.id, text: sop.title } }

    respond_to do |format|
      format.json { render json: { results: items }.to_json }
    end
  end


  private

  def sop_params
    params.require(:sop).permit(:title, :description, { project_ids: [] }, :license, *creator_related_params,
                                { special_auth_codes_attributes: [:code, :expiration_date, :id, :_destroy] },
                                { assay_assets_attributes: [:assay_id] },
                                { publication_ids: [] }, {workflow_ids: []},
                                { extended_metadata_attributes: determine_extended_metadata_keys },
                                discussion_links_attributes:[:id, :url, :label, :_destroy])
  end

  alias_method :asset_params, :sop_params

end
