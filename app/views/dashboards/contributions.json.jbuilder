strft = case @interval
        when 'year'
          '%Y'
        when 'month'
          '%B %Y'
        when 'day'
          '%Y-%m-%d'
        end

assets = (@project.investigations + @project.studies + @project.assays + @project.assets + @project.samples).select { |a| a.created_at > @start_date }
date_grouped = assets.group_by { |a| a.created_at.strftime(strft) }
types = assets.map(&:class).uniq
dates = dates_between(@start_date, Date.today, @interval)

json.labels dates.map { |d| d.strftime(strft) }
json.datasets do
  json.array! types do |type|
    json.label type.name.humanize
    json.backgroundColor ISAHelper::FILL_COLOURS[type.name]
    json.data dates.map { |date| (date_grouped[date.strftime(strft)] || []).select { |a| a.class == type }.count }
  end
end
