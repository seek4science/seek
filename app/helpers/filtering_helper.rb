module FilteringHelper
  include SessionsHelper
  def filter_link(key, filter, hidden: false, replace: false)
    link_to(page_and_sort_params.merge({ page: nil, filter: filter.active ? without_filter(key, filter.value) : with_filter(key, filter.value, replace: replace) }),
            title: filter.label,
            rel: 'nofollow',
            class: "filter-option#{' filter-option-active' if filter.active}#{' filter-option-hidden' if hidden}") do
      content_tag(:span, filter.label, class: 'filter-option-label') +
          content_tag(:span, filter.count, class: 'filter-option-count')
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

  def without_filter(key, value = nil)
    existing = @filters[key]
    if existing
      existing = [existing] unless existing.is_a?(Array)
      existing -= [value]
      existing = existing.first if existing.length == 1
    end

    if existing.blank? || value.nil?
      @filters.except(key)
    else
      @filters.merge(key => existing)
    end
  end

  # Returns true if no user is logged in and the number of filters is equal to or exceeds the maximum allowed.
  def max_filters_met?
    return false unless @filters && @filters.is_a?(Hash)
    return false if logged_in_and_registered?

    @filters.values.flatten.size >= Seek::Config.max_filters
  end
end
