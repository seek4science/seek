class SnapshotsController < ApplicationController

  def show
    @snapshot = Snapshot.find(params[:id])
  end

end
