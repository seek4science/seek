require 'zenodo/oauth2/client'
require 'zenodo-client'

class SnapshotsController < ApplicationController
  before_filter :find_investigation
  before_filter :auth_investigation, only: [:mint_doi, :new, :create, :export_preview, :export_submit]
  before_filter :check_investigation_permitted_for_ro, only: [:new, :create]
  before_filter :find_snapshot, only: [:show, :mint_doi, :download, :export_preview, :export_submit]
  before_filter :doi_minting_enabled?, only: [:mint_doi]
  before_filter :zenodo_oauth_client
  before_filter :zenodo_oauth_session, only: [:export_submit]

  include Seek::BreadCrumbs
  include Zenodo::Oauth2::SessionHelper
  include Seek::ExternalServiceWrapper

  def create
    @snapshot = @investigation.create_snapshot
    flash[:notice] = "Snapshot created"
    redirect_to polymorphic_path([@investigation, @snapshot])
  end

  def show
  end

  def new
  end

  def download
    @content_blob = @snapshot.content_blob
    send_file @content_blob.filepath,
              :filename => @content_blob.original_filename,
              :type => @content_blob.content_type || "application/octet-stream"
  end

  def mint_doi
    wrap_service('DataCite', polymorphic_path([@investigation, @snapshot])) do
      if @snapshot.mint_doi
        flash[:notice] = "DOI successfully minted"
        redirect_to polymorphic_path([@investigation, @snapshot])
      else
        flash[:error] = @snapshot.errors.full_messages
        redirect_to polymorphic_path([@investigation, @snapshot])
      end
    end
  end

  def export_preview
  end

  def export_submit # Export AND publish
    access_token = @oauth_session.access_token

    metadata = params[:metadata].delete_if { |k,v| v.blank? }

    wrap_service('Zenodo', polymorphic_path([@investigation, @snapshot]), rescue_all: true) do
      if @snapshot.export_to_zenodo(access_token, metadata) && @snapshot.publish_in_zenodo(access_token)
        flash[:notice] = "Snapshot successfully exported to Zenodo"
        redirect_to polymorphic_path([@investigation, @snapshot])
      else
        flash[:error] = @snapshot.errors.full_messages
        redirect_to polymorphic_path([@investigation, @snapshot])
      end
    end
  end

  private

  def find_investigation
    @investigation = Investigation.find(params[:investigation_id])
  end

  def auth_investigation
    unless is_auth?(@investigation, :manage)
      flash[:error] = "You are not authorized to manage snapshots of this investigation."
      redirect_to polymorphic_path(@investigation)
    end
  end

  def check_investigation_permitted_for_ro
    unless @investigation.permitted_for_research_object?
      flash[:error] = "You may only create snapshots of publicly accessible investigations."
      redirect_to polymorphic_path(@investigation)
    end
  end

  def find_snapshot
    @snapshot = @investigation.snapshots.where(snapshot_number: params[:id]).first
    if @snapshot.nil?
      flash[:error] = "Snapshot #{params[:id]} doesn't exist."
      redirect_to polymorphic_path(@investigation)
    end
  end

  def doi_minting_enabled?
    unless Seek::Config.doi_minting_enabled
      flash[:error] = "DOI minting is not enabled."
      redirect_to polymorphic_path([@investigation, @snapshot])
    end
  end

end
