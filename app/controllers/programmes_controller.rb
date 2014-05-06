class ProgrammesController < ApplicationController
  include IndexPager

  before_filter :find_requested_item, :only=>[:show,:admin, :edit,:update, :destroy]
  before_filter :find_assets, :only=>[:index]
  before_filter :is_user_admin_auth,:only=>[:destroy,:new, :create, :edit, :update]

  respond_to :html

  def create
    @programme = Programme.new(params[:programme])
    flash[:notice] = "The #{t('programme').capitalize} was successfully created." if @programme.save
    respond_with(@programme)
  end

  def update
    avatar_id = params[:programme].delete(:avatar_id).to_i
    @programme.avatar_id = ((avatar_id.kind_of?(Numeric) && avatar_id > 0) ? avatar_id : nil)

    flash[:notice] = "The #{t('programme').capitalize} was successfully updated." if @programme.update_attributes(params[:programme])
    respond_with(@programme)
  end

  def edit
    respond_with(@programme)
  end

  def new
    @programme=Programme.new
    respond_with(@programme)
  end

  def show
    respond_with(@programme)
  end

end
