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

  def edit
    respond_with(@programme)
  end

  def new
    @programme=Programme.new
    respond_with(@programme)
  end

  def index
    respond_with(@programmes)
  end

  def show
    respond_with(@programme)
  end

end
