class AttachmentsController < ApplicationController

  def destroy
		@attachment = Attachment.find(params[:id])
		asset = @attachment.attachable
    asset.id_image = 0
    asset.save!
		@allowed = 5 - asset.attachments.count

    @attachment.destroy
	end

  def index
    @attachments = Attachment.all
  end

  def show
    @attachment = Attachment.find(params[:id])
  end
end
