class StatsController < ApplicationController
  before_action :get_scope
  before_action :check_access_rights
  before_action :get_dates, only: %i[asset_activity contributors contributions asset_accessibility]
  before_action :add_breadcrumbs

  def dashboard
    respond_to do |format|
      format.html { render 'dashboard/dashboard' }
    end
  end

  def asset_activity
    @most_activity = stats.asset_activity(params[:activity], @start_date, @end_date, type: params[:type])

    respond_to do |format|
      format.json { render 'stats/activity' }
    end
  end

  def contributors
    @most_activity = stats.contributor_activity(@start_date, @end_date)

    respond_to do |format|
      format.json { render 'stats/activity' }
    end
  end

  def contributions
    interval = params[:interval] || 'month'
    @contribution_stats = stats.contributions(@start_date, @end_date, interval)

    respond_to do |format|
      format.json { render 'stats/contributions' }
    end
  end

  def asset_accessibility
    @asset_accessibility_stats = stats.asset_accessibility(@start_date, @end_date, type: params[:type])

    respond_to do |format|
      format.json { render 'stats/asset_accessibility' }
    end
  end

  def clear_cache
    stats.clear_caches

    redirect_back(fallback_location: root_path)
  end

  private

  def get_dates
    @start_date = Date.parse(params[:start_date])
    @end_date = Date.parse(params[:end_date])

    # add a day, to make the end_date inclusive
    @end_date += 1.day if @end_date
  end

  def stats
    Seek::Stats::DashboardStats.new
  end

  def get_scope
    @scope = :admin
  end

  def check_access_rights
    is_user_admin_auth
  end

  def add_breadcrumbs
    if @scope == :admin
      add_breadcrumb 'Administration', admin_path
    else
      type = @scope.class.name.downcase
      add_breadcrumb type.pluralize.humanize, polymorphic_path(type.pluralize.to_sym)
      add_breadcrumb @scope.title, polymorphic_path(@scope)
    end

    add_breadcrumb 'Dashboard'
  end
end
