class AttachmentsController < ApplicationController

  def destroy
		@attachment = Attachment.find(params[:id])
		@attachment.destroy
		asset = @attachment.attachable
		@allowed = 5 - asset.attachments.count
	end

  def index
    @attachments = Attachment.all
  end

  def show
    @attachment = Attachment.find(params[:id])
  end
end
