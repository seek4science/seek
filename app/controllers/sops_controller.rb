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
    study_id = params[:study_id] if params[:study_id].present? && !%w[null undefined].include?(params[:study_id].to_s)
    assay_id = params[:assay_id] if params[:assay_id].present? && !%w[null undefined].include?(params[:assay_id].to_s)

    if study_id.blank? && assay_id.blank?
      raise "Invalid parameters! Either study id '#{params[:study_id]}' or assay id '#{params[:assay_id]}' must be a valid id."
    end

    query = params[:query] || ''
    asset = if study_id.present?
              study = Study.includes(:sops).find_by_id(study_id)
              study if study&.can_view?
            else
              assay = Assay.includes(:sops).find_by_id(assay_id)
              assay if assay&.can_view?
            end

    raise "No asset could be linked to the provided parameters. Make sure the ID is correct and you have at least viewing permission for #{study_id.present? ? "study ID '#{study_id}'." : "assay ID '#{assay_id}'."}" if asset.nil?

    sops = asset.sops || []
    filtered_sops = sops.authorized_for('view').select { |sop| sop.title&.downcase&.include?(query.downcase) }
    items = filtered_sops.collect { |sop| { id: sop.id, text: sop.title } }

    respond_to do |format|
      format.json { render json: { results: items }.to_json }
    end
  rescue Exception=>e
    respond_to do |format|
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
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
