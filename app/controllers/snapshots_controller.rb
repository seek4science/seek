class SnapshotsController < ApplicationController

  before_filter :find_investigation
  before_filter :find_snapshot, only: :show

  def create
    @snapshot = @investigation.snapshot

    redirect_to investigation_snapshot_path(@investigation, @snapshot.snapshot_number)
  end

  def show
  end

  private

  def find_investigation
    @investigation = Investigation.find(params[:investigation_id])
  end

  def find_snapshot
    @snapshot = @investigation.snapshots.where(snapshot_number: params[:id]).first
  end

end
