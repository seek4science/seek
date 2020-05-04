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
  def get_related_transitive_resources(resource, limit = nil)
    return resource_hash_lazy_transitive_load(resource) if Seek::Config.tabs_lazy_load_enabled

    related = collect_related_transitive_items(resource)

    # Authorize
    authorize_related_items(related)

    Seek::ListSorter.related_items(related)

    # Limit items viewable, and put the excess count in extra_count
    related.each_key do |key|
      if limit && related[key][:items].size > limit && %w[Project Investigation Study Assay Person Publication Specimen Sample Snapshot].include?(resource.class.name)
        related[key][:extra_count] = related[key][:items].size - limit
        related[key][:items] = related[key][:items][0...limit]
      end
    end

    related
  end

  def collect_related_transitive_items(resource)
    related = relatable_types
    related.delete('HumanDisease')

    answerable = {}
    related.each_key do |type|
      related[type][:items] = related_transitive_items_method(resource, type)
      related[type][:hidden_items] = []
      related[type][:hidden_count] = 0
      related[type][:extra_count] = 0
      answerable[type] = !related[type][:items].nil?
    end
    related
  end

  def related_transitive_items_method(resource, item_type)
    related = related_items_method(resource, item_type)

    resource.children.each do |child|
      related = related + related_transitive_items_method(child, item_type)
    end
    related.uniq
  end

  def resource_hash_lazy_transitive_load(resource)
    resource_hash = {}
    all_related_items_hash = collect_related_transitive_items(resource)
    all_related_items_hash.each_key do |resource_type|
      all_related_items_hash[resource_type][:items] = all_related_items_hash[resource_type][:items].uniq.compact
      unless all_related_items_hash[resource_type][:items].empty?
        resource_hash[resource_type] = all_related_items_hash[resource_type][:items]
      end
    end
    resource_hash
  end
end
