module ObservationUnitsHelper

  def observation_unit_selector(name, selected = nil, opts = {})
    opts[:data] ||= {}
    opts[:multiple] = false
    grouped_options = grouped_observation_unit_options
    opts[:select_options] = grouped_options_for_select(grouped_options, selected)

    objects_input(name, [selected&.id], opts)
  end

  private

  def grouped_observation_unit_options
    obs_units = authorised_assets(ObservationUnit, nil, :edit)
    grouped = obs_units.group_by(&:study)
    grouped.keys.collect do |study|
      title = study&.can_view? ? study.title : "Hidden #{t('study')}"
      [title, grouped[study].collect{|obs_unit| [obs_unit.title, obs_unit.id]}]
    end

  end

end