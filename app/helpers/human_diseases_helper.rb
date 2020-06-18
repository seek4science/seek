module HumanDiseasesHelper
  # helper method to help consilidate the fact that human diseases are both tags and model entities
  def human_disease_link_to(model_or_tag)
    return "<span class='none_text'>No Human Disease specified</span>" if model_or_tag.nil?
    if model_or_tag.instance_of?(HumanDisease)
      link_to model_or_tag.title.capitalize, model_or_tag
    end
  end

  def human_diseases_link_list(human_diseases)
    link_list = ''
    link_list = "<span class='none_text'>No Human Disease specified</span>" if human_diseases.empty?
    human_diseases.each do |o|
      link_list << human_disease_link_to(o)
      link_list << ', ' unless o == human_diseases.last
    end
    link_list.html_safe
  end

  def link_to_obo_taxonomy_browser(human_disease, text, html_options = {})
    html_options[:alt] ||= text
    html_options[:title] ||= text
    id = human_disease.doid_id
    link_to text, "http://purl.obolibrary.org/obo/#{id}", html_options
  end

  def delete_human_disease_icon(human_disease)
    if human_disease.can_delete?
      image_tag_for_key('destroy', human_disease_path(human_disease), 'Delete Human Disease', { data: { confirm: 'Are you sure?' }, method: :delete }, 'Delete Human Disease')
    else
      explanation = 'Unable to delete an Human Disease that is associated with other items.'
      html = "<span class='disabled_icon disabled' onclick='javascript:alert(\"#{explanation}\")' data-tooltip='#{tooltip(explanation)}' >" + image('destroy', alt: 'Delete', class: 'disabled') + ' Delete Human Disease</span>'
      html.html_safe
    end
  end

  def can_create_human_diseases?
    Seek::Config.human_diseases_enabled and HumanDisease.can_create?
  end

  def bioportal_search_enabled?
    !Seek::Config.bioportal_api_key.blank?
  end

  # Get a hash of appropriate related resources for the given resource. Also returns a hash of hidden resources
  def get_transitive_related_resources(resource, limit = nil)
    return resource_hash_lazy_transitive_load(resource) if Seek::Config.tabs_lazy_load_enabled

    items_hash = {}
    resource.class.related_type_methods.each_key do |type|
      next if type == 'Organism' && !resource.is_a?(Sample)
      enabled_method = "#{type.pluralize.underscore}_enabled"
      next if Seek::Config.respond_to?(enabled_method) && !Seek::Config.send(enabled_method)

      items_hash[type] = resource.get_transitive_related(type)
      items_hash[type] = items_hash[type].uniq
    end

    related_items_hash(items_hash, limit)
  end

  def resource_hash_lazy_transitive_load(resource, limit = nil)
    resource_hash = {}
    all_related_items_hash = get_transitive_related_resources(resource)
    all_related_items_hash.each_key do |resource_type|
      all_related_items_hash[resource_type][:items] = all_related_items_hash[resource_type][:items].uniq.compact
      unless all_related_items_hash[resource_type][:items].empty?
        resource_hash[resource_type] = all_related_items_hash[resource_type][:items]
      end
    end
    resource_hash
  end

  def get_human_diseases_plot_data()
    Rails.cache.fetch('human_diseases_plot_data', expires_in: 12.hours) do
      HumanDisease.all.order(:id).map do |c|
        {
          id:           c.id.to_s,
          title:        c.title,
          parent:       c.parents.first ? c.parents.first.id.to_s : '',
          projects:     c.projects.count,
          assays:       c.assays.count,
          publications: c.publications.count,
          models:       c.models.count,
        }
      end
    end
  end
end
