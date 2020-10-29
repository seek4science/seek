class GitController < ApplicationController
  before_action :fetch_parent
  before_action :authorize_parent
  before_action :get_tree
  before_action :get_blob, except: [:tree]

  def tree
    respond_to do |format|
      format.html
    end
  end

  def download
    stream_blob(@blob, path.last)
  end

  def blob
    respond_to do |format|
      format.html
    end
  end

  def raw
    respond_to do |format|
      format.all { render plain: @blob.contents }
    end
  end

  private

  def get_tree
    @tree = @parent_resource.tree
    path[0..(action_name == 'tree' ? -1 : -2)].each do |segment|
      @tree = @tree.trees[segment]
      break if @tree.nil?
    end

    return if @tree

    respond_to do |format|
      format.all { render plain: 'Tree not found :(', status: :not_found }
    end
  end

  def get_blob
    @blob = @tree.blobs[path.last]

    return if @blob

    respond_to do |format|
      format.all { render plain: 'Blob not found :(', status: :not_found }
    end
  end

  def path
    (params[:path] || '').split('/')
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

  def stream_blob(blob, filename)
    response.headers['Content-Disposition'] = "attachment; filename=#{filename}"

    begin
      self.response_body = Enumerator.new do |yielder|
        blob.contents do |io|
          bytes = io.read(1024)
          break if bytes.nil?
          yielder << bytes
        end
      end
    rescue Git::GitExecuteError => e

    end
  end
end
