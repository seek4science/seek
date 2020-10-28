class GitController < ApplicationController
  before_action :fetch_parent
  before_action :authorize_parent

  def tree
    @tree = @parent_resource.tree
    path.each do |segment|
      @tree = @tree.trees[segment]
      break if @tree.nil?
    end

    respond_to do |format|
      if @tree
        format.html
        format.all { render plain: @tree.children.keys.join(', ')}
      else
        format.all { render plain: ':(', status: :not_found }
      end
    end
  end

  def blob
    @tree = @parent_resource.tree
    path[0..-2].each do |segment|
      @tree = @tree.trees[segment]
      break if @tree.nil?
    end

    @blob = @tree.blobs[path.last]

    respond_to do |format|
      if @blob
        format.html
        format.all { render plain: "Yes!" }
      else
        format.all { render plain: ':(', status: :not_found }
      end
    end
  end

  def raw
    @tree = @parent_resource.tree
    path[0..-2].each do |segment|
      @tree = @tree.trees[segment]
      break if @tree.nil?
    end

    @blob = @tree.blobs[path.last]

    respond_to do |format|
      if @blob
        format.all { render plain: @blob.contents }
      else
        format.all { render plain: ':(', status: :not_found }
      end
    end
  end

  private

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
end
