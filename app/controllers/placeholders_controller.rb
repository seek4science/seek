class PlaceholdersController < ApplicationController

  include Seek::IndexPager

  include Seek::AssetsCommon

  before_action :find_and_authorize_requested_item, :except => [ :index, :new, :create,:preview, :update_annotations_ajax]

  api_actions :index, :show, :create, :update, :destroy

  def update

    update_sharing_policies @placeholder
    update_relationships(@placeholder,params)

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

  private

  def placeholder_params
    params.require(:placeholder).permit(:title, :description, { project_ids: [] }, :license, :other_creators,
                                { special_auth_codes_attributes: [:code, :expiration_date, :id, :_destroy] },
                                { creator_ids: [] }, { assay_assets_attributes: [:assay_id] },
                                :format_type,
                                :data_type,
                                discussion_links_attributes:[:id, :url, :label, :_destroy])
  end

end
