class GitController < ApplicationController
  include RawDisplay
  include Seek::MimeTypes

  before_action :fetch_parent
  before_action :authorize_parent
  before_action :authorized_to_edit, only: [:add_file, :remove_file, :move_file, :freeze, :update]
  before_action :fetch_git_version
  before_action :get_tree, only: [:tree]
  before_action :get_blob, only: [:blob, :download, :raw]
  before_action :coerce_format

  user_content_actions :raw

  rescue_from Git::ImmutableVersionException, with: :render_immutable_error
  rescue_from Git::PathNotFoundException, with: :render_path_not_found_error
  rescue_from Git::InvalidPathException, with: :render_invalid_path_error
  rescue_from URI::InvalidURIError, with: :render_invalid_url_error

  def browse
    respond_to do |format|
      format.html
    end
  end

  def tree
    respond_to do |format|
      format.json { render json: @tree, adapter: :attributes, root: '' }
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
      format.json { render json: @blob, adapter: :attributes, root: '' }
      if request.xhr?
        format.html { render partial: 'blob' }
      else
        format.html
      end
    end
  end

  def raw
    if render_display?
      render_display(@blob)
    elsif @blob.binary? || @blob.is_image? # SVG is an image but not binary
      send_data(@blob.content, filename: path_param.split('/').last, disposition: 'inline')
    else
      # Set Content-Type if it's an image to allow use in img tags
      ext = path_param.split('/').last&.split('.')&.last&.downcase
      content_type = if Seek::ContentTypeDetection::IMAGE_VIEWABLE_FORMAT.include?(ext)
                       mime_types_for_extension(path_param.split('.').last).first
                     else
                       'text/plain'
                     end
      render body: @blob.content, content_type: content_type
    end
  end

  def add_file
    if file_params[:url].present?
      add_remote_file
      operation_response("Registered #{file_params[:url]}", status: 201)
    else
      add_local_file
      operation_response("Uploaded #{file_params[:path] || params[:path]}", status: 201)
    end
  end

  def remove_file
    @git_version.remove_file(params[:path])
    @git_version.save!

    operation_response("Removed #{params[:path]}")
  end

  def move_file
    @git_version.move_file(params[:path], file_params[:new_path])
    @git_version.save!

    operation_response("Moved #{params[:path]} to #{file_params[:new_path]}")
  end

  def freeze_preview

  end

  def freeze
    if @git_version.update(git_version_params) && @git_version.lock
      flash[:notice] = "#{@git_version.name} was frozen"
    else
      flash[:error] = "Could not freeze #{@git_version.name} - #{@git_version.errors.full_messages.join(', ')}"
    end

    redirect_to polymorphic_path(@parent_resource)
  end

  def update
    if @git_version.update(git_version_params)
      flash[:notice] = "#{@git_version.name} was successfully updated."
    else
      flash[:error] = "Could not update #{@git_version.name_was} - #{@git_version.errors.full_messages.join(', ')}"
    end

    redirect_to polymorphic_path(@parent_resource)
  end

  private

  def operation_response(notice = nil, status: 200)
    respond_to do |format|
      format.json { render json: { }, status: status, adapter: :attributes, root: '' }
      format.html do
        if request.xhr?
          render partial: 'files', locals: { resource: @parent_resource, git_version: @git_version }, status: status
        else
          flash[:notice] = notice if notice
          redirect_to polymorphic_path(@parent_resource, tab: 'files')
        end
      end
    end
  end

  def render_immutable_error
    render_git_error(@git_version.immutable_error, status: 409)
  end

  def render_path_not_found_error(ex)
    render_git_error("Couldn't find path: #{ex.path}", status: 404)
  end

  def render_invalid_path_error(ex)
    render_git_error("Invalid path: #{ex.path}", status: 422)
  end

  def render_invalid_url_error(ex)
    render_git_error(ex.message, status: 422)
  end

  def render_git_error(message, status: 400, redirect: polymorphic_path(@parent_resource, tab: 'files'))
    respond_to do |format|
      format.html do
        flash[:error] = message
        redirect_to redirect
      end
      format.json do
        render json: { error: message }, status: status
      end
      format.all do
        head status
      end
    end
  end

  def get_tree
    if path_param.blank? || path_param == '/'
      @tree = @git_version.tree
    else
      @tree = @git_version.get_tree(path_param)
    end

    raise Git::PathNotFoundException.new(path: path_param) unless @tree
  end

  def get_blob
    @blob = @git_version.get_blob(path_param)

    raise Git::PathNotFoundException.new(path: path_param) unless @blob
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
      target = @parent_resource.can_view? ? @parent_resource : :root
      render_git_error('Not authorized', status: 403, redirect: target)
    end
  end

  def authorized_to_edit
    render_git_error('Not authorized', status: 403, redirect: :root) unless @parent_resource.can_edit?
  end

  def file_params
    params.require(:file).permit(:path, :data, :content, :new_path, :url, :fetch)
  end

  def fetch_git_version
    @git_version = params[:version] ? @parent_resource.find_git_version(params[:version]) : @parent_resource.git_version
    raise ActiveRecord::RecordNotFound unless @git_version
  end

  def git_version_params
    p = [:name, :comment]
    p << :visibility if @git_version.can_change_visibility?
    params.require(:git_version).permit(*p)
  end

  def add_local_file
    path = file_params[:path] || params[:path]
    path = file_params[:data].original_filename if path.blank? && file_params[:data]
    @git_version.add_file(path, file_content)
    @git_version.save!
  end

  def add_remote_file
    path = file_params[:path] || params[:path]
    path = file_params[:url].split('/').last if path.blank?
    @git_version.add_remote_file(path, file_params[:url], fetch: file_params[:fetch] == '1')
    @git_version.save!
  end

  def coerce_format
    # I have to do this because Rails doesn't seem to be behaving as expected.
    # In routes.rb, the git routes are scoped with "format: false", so Rails should disregard the extension
    # (e.g. /git/1/blob/my_file.yml) when determining the response format.
    # However this results in an UnknownFormat error when trying to load the HTML view, as Rails still seems to be
    # looking for an e.g. application/yaml view.
    # You can fix this by adding { defaults: { format: :html } }, but then it is not possible to request JSON,
    # even with an explicit `Accept: application/json` header! -Finn
    request.format = :html unless json_api_request?
  end

  def file_content
    file_params.key?(:content) ? StringIO.new(Base64.decode64(file_params[:content])) : file_params[:data]
  end

  def log_event
    action = action_name.downcase
    data = { path: path_param }
    if action == 'raw'
      if render_display?
        action = 'inline_view'
        data[:display] = params[:display]
      else
        action = 'download'
      end
    end

    if %w(download inline_view).include?(action)
      ActivityLog.create(action: action,
                         culprit: current_user,
                         referenced: @git_version,
                         controller_name: controller_name,
                         activity_loggable: @parent_resource,
                         user_agent: request.env['HTTP_USER_AGENT'],
                         data: data)
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
