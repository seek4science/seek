class SnapshotsController < ApplicationController
  before_filter :find_investigation
  before_filter :find_snapshot, only: [:show, :mint_doi, :download]

  include Seek::BreadCrumbs

  def create
    @snapshot = @investigation.create_snapshot
    flash[:notice] = "Snapshot created"
    redirect_to investigation_snapshot_path(@investigation, @snapshot.snapshot_number)
  end

  def show
  end

  def download
    @content_blob = @snapshot.content_blob
    send_file @content_blob.filepath, :filename => @content_blob.original_filename, :type => @content_blob.content_type || "application/octet-stream"
  end

  def mint_doi
    if @snapshot.mint_doi
      flash[:notice] = "DOI successfully minted"
      redirect_to investigation_snapshot_path(@investigation, @snapshot.snapshot_number)
    end
  end

  private

  def find_investigation
    @investigation = Investigation.find(params[:investigation_id])
  end

  def find_snapshot
    @snapshot = @investigation.snapshots.where(snapshot_number: params[:id]).first
  end

end
