module AssetsHelper
  include ApplicationHelper

  # the prefix used on some field id's, e.g. data_files_data_url
  def asset_field_prefix
    controller_name.downcase.singularize.underscore
  end

  # will render a view of the asset, if available. For example, a slideshare based asset could give a embedded slideshare view
  def rendered_asset_view(asset)
    return '' unless asset.can_download?
    content = Rails.cache.fetch("#{asset.cache_key}/#{asset.content_blob.cache_key}") do
      Seek::Renderers::RendererFactory.instance.renderer(asset.content_blob).render
    end
    unless content.blank?
      content_tag(:div, class: 'renderer') do
        content.html_safe
      end
    else
      ''
    end
  end

  def can_create_new_items?
    # the state of being able to create assets is the same for all assets
    DataFile.can_create?
  end

  def request_request_label(resource)
    icon_filename = icon_filename_for_key('message')
    resource_type = text_for_resource(resource)
    image_tag(icon_filename, alt: 'Request', title: 'Request') + " Request #{resource_type}"
  end

  def filesize_as_text(content_blob)
    size = content_blob.nil? ? 0 : content_blob.file_size
    if size.nil?
      html = "<span class='none_text'>Unknown</span>"
    else
      html = number_to_human_size(size)
    end
    html.html_safe
  end

  def item_description(desc, options = {})
    options[:description] = desc
    render partial: 'assets/item_description', locals: options
  end

  # returns all the classes for models that return true for is_asset?
  def asset_model_classes
    @@asset_model_classes ||= Seek::Util.persistent_classes.select do |c|
      !c.nil? && c.is_asset?
    end
  end

  def publishing_item_param(item)
    "publish[#{item.class.name}][#{item.id}]"
  end

  def text_for_resource(resource_or_text)
    if resource_or_text.is_a?(String)
      text = resource_or_text.underscore.humanize
    else
      resource_type = resource_or_text.class.name
      if resource_or_text.is_a?(Assay)
        text = resource_or_text.is_modelling? ? t('assays.modelling_analysis') : t('assays.assay')
      elsif !(translated = translate_resource_type(resource_type)).include?('translation missing')
        text = translated
      else
        text = resource_type.underscore.humanize
      end
    end
    text
  end

  def get_original_model_name(model)
    class_name = model.class.name
    class_name = class_name.split('::')[0] if class_name.end_with?('::Version')
    class_name
  end

  def download_resource_path(resource, _code = nil)
    if resource.class.name.include?('::Version')
      polymorphic_path(resource.parent, version: resource.version, action: :download, code: params[:code])
    else
      polymorphic_path(resource, action: :download, code: params[:code])
    end
  end

  # returns true if this permission should not be able to be removed from custom permissions
  # it indicates that this is the management rights for the current user.
  # the logic is that true is returned if the current_user is the contributor of this permission, unless that person is also the contributor of the asset
  def prevent_manager_removal(resource, permission)
    permission.access_type == Policy::MANAGING && permission.contributor == current_user.person && resource.contributor != current_user
  end

  def show_resource_path(resource)
    path = ''
    if resource.class.name.include?('::Version')
      path = polymorphic_path(resource.parent, version: resource.version)
    else
      path = polymorphic_path(resource)
    end
    path
  end

  def edit_resource_path(resource)
    path = ''
    if resource.class.name.include?('::Version')
      path = edit_polymorphic_path(resource.parent)
    else
      path = edit_polymorphic_path(resource)
    end
    path
  end

  # provides a list of assets, according to the class, that are authorized according the 'action' which defaults to view
  # if projects is provided, only authorizes the assets for that project
  # assets are sorted by title except if they are projects and scales (because of hierarchies)
  def authorised_assets(asset_class, projects = nil, action = 'view')
    assets = asset_class.all_authorized_for action, User.current_user, projects
    assets = assets.sort_by(&:title) if !assets.blank? && !%w(Project Scale).include?(assets.first.class.name)
    assets
  end

  def asset_buttons(asset, version = nil)
    render partial: 'assets/asset_buttons', locals: { asset: asset, version: version }
  end

  # code is for authorization of temporary link
  def can_download_asset?(asset, code = params[:code], can_download = asset.can_download?)
    can_download || (code && asset.auth_by_code?(code))
  end

  # code is for authorization of temporary link
  def can_view_asset?(asset, code = params[:code], can_view = asset.can_view?)
    can_view || (code && asset.auth_by_code?(code))
  end

  def asset_link_url(asset)
    asset.single_content_blob.try(:url)
  end

  def download_or_link_button(asset, download_path, link_url, _human_name = nil, opts = {})
    download_button = icon_link_to('Download', 'download', download_path, opts)
    link_button_or_nil = link_url ? icon_link_to('External Link', 'external_link', link_url, opts.merge(target: 'blank')) : nil
    return asset.content_blobs.detect { |blob| !blob.show_as_external_link? } ? download_button : link_button_or_nil if asset.respond_to?(:content_blobs)
    return asset.content_blob.show_as_external_link? ? link_button_or_nil : download_button if asset.respond_to?(:content_blob)
  end

  def view_content_button(asset)
    render partial: 'assets/view_content', locals: { content_blob: asset.single_content_blob, button_style: true }
  end

  def doi_link(doi)
    link_to doi, "https://dx.doi.org/#{doi}"
  end

  def sharing_text(item)
    if item.private?
      sharing_text = "This item is <span style='color: red; font-weight: bold;'>Private</span> (only you can view it)"
    elsif item.is_published?
      sharing_text = "This item is <span style='color: green; font-weight: bold;'>Published</span> (all visitors, even without a login, may view/access this item)"
    elsif item.public?
      sharing_text = "This item is <span style='color: green; font-weight: bold;'>Public</span> visible (all visitors, even without a login, may view this item)"
    else
      sharing_text = "This item is <span style='font-weight: bold;'>Shared</span>, but not with all visitors to this site"
    end
    sharing_text.html_safe
  end
end
