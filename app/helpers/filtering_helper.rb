module FilteringHelper
  def filter_link(key, filter, hidden: false, replace: false)
    link_to(page_and_sort_params.merge({ page: nil, filter: filter.active ? without_filter(key, filter.value) : with_filter(key, filter.value, replace: replace) }),
            title: filter.title,
            class: "filter-option#{' filter-active' if filter.active}#{' filter-hidden' if hidden}") do
      content_tag(:span, filter.title, class: 'filter-title') +
          content_tag(:span, filter.count, class: 'filter-count')
    end
  end

  def with_filter(key, value, replace: false)
    existing = @filters[key]
    if existing && !replace
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
