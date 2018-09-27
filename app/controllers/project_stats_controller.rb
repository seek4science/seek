class ProjectStatsController < ApplicationController
  before_filter :find_project
  before_filter :member_of_this_project

  include DashboardsHelper

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

    assets = (@project.investigations + @project.studies + @project.assays + @project.assets + @project.samples).select { |a| a.created_at >= start_date && a.created_at <= end_date }
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
      format.json { render 'projects/stats/contributions' }
    end
  end

  private

  def find_project
    name = t('project')
    @project = Project.find_by_id(params[:project_id])
    if @project.nil?
      respond_to do |format|
        flash[:error] = "The #{name.humanize} does not exist!"
        format.html { redirect_to project_path(@project) }
      end
    end
  end

  def member_of_this_project
    unless @project.has_member?(current_user)
      flash[:error] = "You are not a member of this #{t('project')}, so cannot access this page."
      redirect_to project_path(@project)
      false
    end
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
