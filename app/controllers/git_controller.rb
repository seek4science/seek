class GitController < ApplicationController
  before_action :fetch_parent
  before_action :authorize_parent
  before_action :get_tree, only: [:tree]
  before_action :get_blob, except: [:tree]

  def tree
    respond_to do |format|
      format.html
    end
  end

  def download
    send_data(@blob.content, filename: path_param.split('/').last, disposition: 'attachment')
  end

  def blob
    respond_to do |format|
      format.html
    end
  end

  def raw
    respond_to do |format|
      format.all { render plain: @blob.content }
    end
  end

  private

  def get_tree
    if path_param.blank? || path_param == '/'
      @tree = @parent_resource.tree
    else
      @tree = @parent_resource.object(path_param)
    end

    return if @tree&.is_a?(Rugged::Tree)

    raise ActionController::RoutingError.new('Not Found')
  end

  def get_blob
    @blob = @parent_resource.object(path_param)

    return if @blob&.is_a?(Rugged::Blob)

    raise ActionController::RoutingError.new('Not Found')
  end

  def path_param
    params[:path] || ''
  end

  def fetch_parent
    get_parent_resource
    raise ActiveRecord::RecordNotFound unless @parent_resource
  end

  def authorize_parent
    unless @parent_resource.can_download?
      flash[:error] = "Not authorized."
      redirect_to :root
    end
  end

  # # Rugged does not allow streaming blobs
  # def stream_blob(blob, filename)
  #   response.headers['Content-Disposition'] = "attachment; filename=#{filename}"
  #   response.headers['Content-Length'] = blob.size.to_s
  #
  #   self.response_body = Enumerator.new do |yielder|
  #     blob.content do |io|
  #       while (bytes = io.read(1024))
  #         yielder << bytes
  #       end
  #     end
  #   end
  # end
end
