module FavouritesHelper

  # A draggable icon for a thing that can be favourited
  def favouritable_icon(item, size = 100, options = {}, &block)
    options[:class] ||= "favouritable"
    options['data-favourite-url'] ||= add_favourites_path(:resource_id => item.id, :resource_type => item.class.name)

    draggable_icon(item, size, options, &block)
  end

  def savable_search_icon(path, size, search_options, options = {}, &block)
    html = block_given? ? capture(&block) : image("saved_search_avatar", {:class => "avatar curved with_smaller_shadow search_fav_avatar", :size => size})
    search_options[:resource_type] ||= 'SavedSearch'
    options['data-favourite-url'] ||= add_favourites_url(search_options)
    options['data-tooltip'] ||= tooltip("Drag to Favourites to save this search")
    html = link_to_draggable(html, path, options)
    html.html_safe
  end

  # A draggable icon for an existing favourite
  def favourite_icon(favourite, size = 100, options = {}, &block)
    options[:class] ||= "favourite"
    options['data-delete-url'] = delete_favourites_path(:id => favourite.id)

    draggable_icon(favourite.resource, size, options, &block)
  end
  
  def draggable_icon(item, size = 100, options = {}, &block)
    html = block_given? ? capture(&block) : avatar(item, size, true, nil, nil, true, options[:avatar_class])
    options['data-tooltip'] ||= tooltip(get_object_title(item))
    html = link_to_draggable(html, show_resource_path(item), options)
    html.html_safe
  end
end
