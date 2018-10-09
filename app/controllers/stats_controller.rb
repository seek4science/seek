class StatsController < ApplicationController
  before_filter :is_user_admin_auth

  def dashboard
    respond_to do |format|
      format.html { render 'dashboard/dashboard' }
    end
  end

  def asset_activity
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])
    @most_activity = stats.asset_activity(params[:activity], start_date, end_date, type: params[:type])

    respond_to do |format|
      format.json { render 'stats/activity' }
    end
  end

  def contributors
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])
    @most_activity = stats.contributor_activity(start_date, end_date)

    respond_to do |format|
      format.json { render 'stats/activity' }
    end
  end

  def contributions
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])
    interval = params[:interval] || 'month'
    @contribution_stats = stats.contributions(start_date, end_date, interval)

    respond_to do |format|
      format.json { render 'stats/contributions' }
    end
  end

  def asset_accessibility
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])
    @asset_accessibility_stats = stats.asset_accessibility(start_date, end_date, type: params[:type])

    respond_to do |format|
      format.json { render 'stats/asset_accessibility' }
    end
  end

  private

  def stats
    Seek::Stats::DashboardStats.new
  end
end
