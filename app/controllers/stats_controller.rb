class StatsController < ApplicationController
  before_filter :is_user_admin_auth

  include DashboardsHelper

  def asset_activity
    @activity = params[:activity]
    resource_types = params[:types] || Seek::Util.asset_types.map(&:name)
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])

    @most_activity = scoped_activities.
        where(action: @activity).
        where('created_at > ? AND created_at < ?', start_date, end_date).
        where(activity_loggable_type: resource_types).
        group(:activity_loggable_type, :activity_loggable_id).count.to_a.
        map { |(type, id), count| [type.constantize.find_by_id(id), count] }.
        select { |resource, _| !resource.nil? && resource.can_view? }.
        sort_by { |x| -x[1] }.first(10)

    respond_to do |format|
      format.json { render 'stats/activity' }
    end
  end

  def contributors
    @activity = 'contributors'
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])

    @most_activity = scoped_activities.
        where(action: ['update', 'create']).
        where('created_at > ? AND created_at < ?', start_date, end_date).
        group(:culprit_type, :culprit_id).count.to_a.
        map { |(type, id), count| [type.constantize.find_by_id(id).try(:person), count] }.
        reject { |resource, _| resource.nil? }.
        sort_by { |x| -x[1] }.
        first(10)

    respond_to do |format|
      format.json { render 'stats/activity' }
    end
  end

  def contributions
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])
    interval = params[:interval] || 'month'
    strft = case interval
            when 'year'
              '%Y'
            when 'month'
              '%B %Y'
            when 'day'
              '%Y-%m-%d'
            end

    assets = scoped_resources.select { |a| a.created_at >= start_date && a.created_at <= end_date }
    date_grouped = assets.group_by { |a| a.created_at.strftime(strft) }
    types = assets.map(&:class).uniq
    dates = dates_between(start_date, end_date, interval)

    @labels = dates.map { |d| d.strftime(strft) }
    @datasets = {}
    types.each do |type|
      @datasets[type] = dates.map do |date|
        assets_for_date = date_grouped[date.strftime(strft)]
        assets_for_date ? assets_for_date.select { |a| a.class == type }.count : 0
      end
    end

    respond_to do |format|
      format.json { render 'stats/contributions' }
    end
  end

  private

  def scoped_activities
    ActivityLog
  end

  def scoped_resources
    (Programme.all + Project.all + Investigation.all + Study.all + Assay.all + Seek::Util.asset_types.map(&:all).flatten)
  end

  def dates_between(start_date, end_date, interval = 'month')
    case interval
    when 'year'
      transform = -> (date) { Date.parse("#{date.strftime('%Y')}-01-01") }
      increment = -> (date) { date >> 12 }
    when 'month'
      transform = -> (date) { Date.parse("#{date.strftime('%Y-%m')}-01") }
      increment = -> (date) { date >> 1 }
    when 'day'
      transform = -> (date) { date }
      increment = -> (date) { date + 1 }
    else
      raise 'Invalid interval. Valid intervals: year, month, day'
    end

    start_date = transform.call(start_date)
    end_date = transform.call(end_date)
    date = start_date
    dates = []

    while date <= end_date
      dates << date
      date = increment.call(date)
    end

    dates
  end
end
