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

  def explore
    #drop invalid explore params
    [:page_rows, :page, :sheet].each do |param|
      if params[param].present? && (params[param] =~ /\A\d+\Z/).nil?
        params.delete(param)
      end
    end
    if @file_template.contains_extractable_spreadsheet?
      respond_to do |format|
        format.html
      end
    else
      respond_to do |format|
        flash[:error] = 'Unable to view contents of this file template'
        format.html { redirect_to file_template_path(@file_template,
                                                     version: @file_template.version) }
      end
    end
  end

  private

  def file_template_params
    params.require(:file_template).permit(:title, :description, { project_ids: [] }, :license, :other_creators,
                                { special_auth_codes_attributes: [:code, :expiration_date, :id, :_destroy] },
                                { creator_ids: [] }, { assay_assets_attributes: [:assay_id] },
                                :edam_formats,
                                :edam_data,
                                { publication_ids: [] }, { event_ids: [] },
                                discussion_links_attributes:[:id, :url, :label, :_destroy])
  end

  alias_method :asset_params, :file_template_params
end
