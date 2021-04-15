class GitController < ApplicationController
  before_action :fetch_parent
  before_action :authorize_parent
  before_action :authorized_to_edit, only: [:add_file, :remove_file, :move_file]
  before_action :fetch_git_version
  before_action :get_tree, only: [:tree]
  before_action :get_blob, only: [:blob, :download, :raw]

  user_content_actions :raw

  rescue_from GitVersion::ImmutableVersionException, with: :render_immutable_error

  def browse
    respond_to do |format|
      format.html
    end
  end

  def tree
    respond_to do |format|
      if request.xhr?
        format.html { render partial: 'tree' }
      else
        format.html
      end
    end
  end

  def download
    send_data(@blob.content, filename: path_param.split('/').last, disposition: 'attachment')
  end

  def blob
    respond_to do |format|
      if request.xhr?
        format.html { render partial: 'blob' }
      else
        format.html
      end
    end
  end

  def raw
    respond_to do |format|
      format.all { render plain: @blob.content }
    end
  end

  def add_file
    @git_version.add_file(file_params[:path], file_params[:data])
    @git_version.save!

    flash[:notice] = "Uploaded #{file_params[:path]}"
    redirect_to polymorphic_path(@parent_resource, anchor: 'files')
  end

  def remove_file
    @git_version.remove_file(file_params[:path])
    @git_version.save!

    flash[:notice] = "Removed #{file_params[:path]}"
    redirect_to polymorphic_path(@parent_resource, anchor: 'files')
  end

  def move_file
    @git_version.move_file(file_params[:path], file_params[:new_path])
    @git_version.save!

    flash[:notice] = "Moved #{file_params[:path]} to #{file_params[:new_path]}"
    redirect_to polymorphic_path(@parent_resource, anchor: 'files')
  end

  private

  def render_immutable_error
    flash[:error] = 'This version cannot be modified.'
    respond_to do |format|
      format.html { render status: :unprocessable_entity }
    end
  end

  def get_tree
    if path_param.blank? || path_param == '/'
      @tree = @git_version.tree
    else
      @tree = @git_version.object(path_param)
    end

    return if @tree&.is_a?(Rugged::Tree)

    raise ActionController::RoutingError.new('Not Found')
  end

  def get_blob
    @blob = @git_version.object(path_param)

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

  def authorized_to_edit
    unless @parent_resource.can_edit?
      flash[:error] = "Not authorized."
      redirect_to :root
    end
  end

  def file_params
    params.require(:file).permit(:path, :data, :new_path)
  end

  def fetch_git_version
    @git_version = params[:version] ? @parent_resource.find_git_version(params[:version]) : @parent_resource.git_version
    raise ActiveRecord::RecordNotFound unless @git_version
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
