class StatsController < ApplicationController
  before_filter :is_user_admin_auth
  before_filter :get_dates, only: %i[asset_activity contributors contributions asset_accessibility]

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

    redirect_to :back
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
end
