module FilteringHelper
  def sorted_filters(key, filters)
    filters.sort_by do |title, value, count|
      is_active = @active_filters[key] && @active_filters[key][value.to_s]
      val = is_active ? -1000 : 0
      val - count
    end
  end

  def filter_link(key, title, value, count)
    is_active = @active_filters[key] && @active_filters[key][value.to_s]
    content_tag(:div, class: "filter-option#{' filter-active' if is_active}") do
      link_to({ filter: is_active ? without_filter(key, value) : with_filter(key, value) }, class: 'filter-link') do
        content_tag(:span, title, class: 'filter-title') +
            content_tag(:span, count, class: 'filter-count')
      end
    end
  end

  def with_filter(key, value)
    existing = @filters[key]
    if existing
      existing = [existing] unless existing.is_a?(Array)
      existing |= [value]
    else
      existing = value
    end

    @filters.merge(key => existing)
  end

  def without_filter(key, value)
    existing = @filters[key]
    if existing
      existing = [existing] unless existing.is_a?(Array)
      existing -= [value]
    end

    if existing.empty?
      @filters.except(key)
    else
      @filters.merge(key => existing)
    end
  end
end
