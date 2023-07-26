require 'simple-spreadsheet-extractor'

class FileTemplatesController < ApplicationController

  include Seek::IndexPager
  include SysMODB::SpreadsheetExtractor

  include Seek::AnnotationCommon

  include Seek::AssetsCommon

#  before_action :file_templates_enabled?
  before_action :find_assets, :only => [ :index ]
  before_action :find_and_authorize_requested_item, :except => [ :index, :new, :create,:preview, :update_annotations_ajax]
  before_action :find_display_asset, :only=>[:show, :download]

  include Seek::Publishing::PublishingCommon

  include Seek::Doi::Minting

  include Seek::IsaGraphExtensions

  api_actions :index, :show, :create, :update, :destroy

  def create_version

    if handle_upload_data(true)

      comments = params[:revision_comments]

      respond_to do |format|
        if @file_template.save_as_new_version(comments)
          flash[:notice] = "New version uploaded - now on version #{@file_template.version}"
        else
          flash[:error] = "Unable to save new version"
        end

        format.html { redirect_to @file_template }
      end
    else
      flash[:error] = flash.now[:error]
      redirect_to @file_template
    end
  end

  def update
    update_annotations(params[:tag_list], @file_template) if params.key?(:tag_list)
    update_sharing_policies @file_template
    update_relationships(@file_template,params)

    respond_to do |format|

      if @file_template.update(file_template_params)
        flash[:notice] = "#{t('file_template')} metadata was successfully updated."
        format.html { redirect_to file_template_path(@file_template) }
        format.json { render json: @file_template, include: [params[:include]] }
      else
        format.html { render action: 'edit' }
        format.json { render json: json_api_errors(@file_template), status: :unprocessable_entity }
      end
    end
  end

  private

  def file_template_params
    params.require(:file_template).permit(:title, :description, { project_ids: [] }, :license, :other_creators,
                                { special_auth_codes_attributes: [:code, :expiration_date, :id, :_destroy] },
                                { creator_ids: [] }, { assay_assets_attributes: [:assay_id] },
                                { data_format_annotations: [] }, { data_type_annotations: [] },
                                { publication_ids: [] }, { event_ids: [] },
                                discussion_links_attributes:[:id, :url, :label, :_destroy])
  end

  alias_method :asset_params, :file_template_params
end
