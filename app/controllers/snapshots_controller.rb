require 'zenodo/oauth2/client'
require 'zenodo-client'

class SnapshotsController < ApplicationController
  before_action :get_parent_resource
  before_action :auth_resource, only: [:mint_doi_confirm, :mint_doi, :new, :create, :edit, :update, :export_preview, :export_submit, :destroy]
  before_action :check_resource_permitted_for_ro, only: [:new, :create]
  before_action :find_snapshot, only: [:show, :edit, :update, :mint_doi_confirm, :mint_doi, :download, :export_preview, :export_submit, :destroy]
  before_action :doi_minting_enabled?, only: [:mint_doi_confirm, :mint_doi]
  before_action :check_doi, only: [:edit, :update, :destroy]

  before_action :zenodo_oauth_client
  before_action :zenodo_oauth_session, only: [:export_submit]

  include Zenodo::Oauth2::SessionHelper
  include Seek::ExternalServiceWrapper

  def create
    @snapshot = @parent_resource.create_snapshot(snapshot_params)
    if @snapshot&.valid?
      flash[:notice] = "Snapshot created"
      redirect_to polymorphic_path([@parent_resource, @snapshot])
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    respond_to do |format|
      if @snapshot.content_blob.present?
        format.html
        format.json { render json: @snapshot, include: [params[:include]] }
      else
        format.html {  render "show_no_content_blob" }
        format.json { render json: { errors: [{ title: 'Incomplete snapshot', details: 'Snapshot has no content. It may still be being generated' }] }, status: :unprocessable_entity }
      end
    end
  end

  def new
  end

  def edit
  end

  def update
    if @snapshot.update(snapshot_params)
      flash[:notice] = "Snapshot updated"
      redirect_to polymorphic_path([@parent_resource, @snapshot])
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def download
    @content_blob = @snapshot.content_blob
    send_file @content_blob.filepath,
              :filename => @content_blob.original_filename,
              :type => @content_blob.content_type || "application/octet-stream"
  end

  def mint_doi_confirm
  end

  def mint_doi
    wrap_service('DataCite', polymorphic_path([@parent_resource, @snapshot])) do
      if @snapshot.mint_doi
        flash[:notice] = "DOI successfully minted"
        redirect_to polymorphic_path([@parent_resource, @snapshot])
      else
        flash[:error] = @snapshot.errors.full_messages
        redirect_to polymorphic_path([@parent_resource, @snapshot])
      end
    end
  end

  def export_preview
  end

  def export_submit # Export AND publish
    access_token = @oauth_session.access_token

    wrap_service('Zenodo', polymorphic_path([@parent_resource, @snapshot]), rescue_all: !Rails.env.test?) do
      if @snapshot.export_to_zenodo(access_token, metadata_params) && @snapshot.publish_in_zenodo(access_token)
        flash[:notice] = "Snapshot successfully exported to Zenodo"
        redirect_to polymorphic_path([@parent_resource, @snapshot])
      else
        flash[:error] = @snapshot.errors.full_messages
        redirect_to polymorphic_path([@parent_resource, @snapshot])
      end
    end
  end

  def destroy
    if @snapshot.destroy
      flash[:notice] = "Snapshot successfully deleted"
      redirect_to polymorphic_path(@parent_resource)
    else
      flash[:error] = @snapshot.errors.full_messages
      redirect_to polymorphic_path([@parent_resource, @snapshot])
    end
  end

  private

  def auth_resource
    unless is_auth?(@parent_resource, :manage)
      flash[:error] = "You are not authorized to manage snapshots of this resource."
      redirect_to polymorphic_path(@parent_resource)
    end
  end

  def check_resource_permitted_for_ro
    unless @parent_resource.permitted_for_research_object?
      flash[:error] = "You may only create snapshots of publicly accessible resources."
      redirect_to polymorphic_path(@parent_resource)
    end
  end

  def find_snapshot
    @snapshot = @parent_resource.snapshots.where(snapshot_number: params[:id]).first
    if @snapshot.nil?
      flash[:error] = "Snapshot #{params[:id]} doesn't exist."
      redirect_to polymorphic_path(@parent_resource)
    end
  end

  def doi_minting_enabled?
    unless Seek::Config.doi_minting_enabled
      flash[:error] = "DOI minting is not enabled."
      redirect_to polymorphic_path([@parent_resource, @snapshot])
    end
  end

  def check_doi
    if @snapshot.has_doi?
      flash[:error] = "You cannot #{action_name} a snapshot that has a DOI."
      redirect_to polymorphic_path([@parent_resource, @snapshot])
    end
  end

  def metadata_params
    params.require(:metadata).permit(:access_right, :license, :embargo_date, :access_conditions, creators: [:name]).delete_if { |k,v| v.blank? }
  end

  def snapshot_params
    params.fetch(:snapshot, {}).permit(:title, :description)
  end
end
