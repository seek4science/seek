module AssetsHelper
  include ApplicationHelper
  include BootstrapHelper
  include SessionsHelper

  def form_submit_buttons(item, options = {})
    # defaults
    options[:validate] = true if options[:validate].nil?
    if options[:preview_permissions].nil?
      options[:preview_permissions] = show_form_manage_specific_attributes?
    end
    options[:button_text] ||= submit_button_text(item)
    options[:cancel_path] = polymorphic_path(item)
    options[:resource_name] = item.class.name.underscore
    options[:button_id] ||= "#{options[:resource_name]}_submit_btn"

    render partial: 'assets/form_submit_buttons', locals: { item: item, **options }
  end

  # determine the text for the submit button, based on whether it is an edit or creation, and whether upload is required
  def submit_button_text(item)
    if item.new_record?
      if item.is_downloadable?
        t('submit_button.upload')
      else
        t('submit_button.create')
      end
    else
      t('submit_button.update')
    end
  end

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
    if content.blank?
      ''
    else
      content_tag(:div, class: 'renderer') do
        content.html_safe
      end
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
    html = if size.nil?
             "<span class='none_text'>Unknown</span>"
           else
             number_to_human_size(size)
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

  def sharing_item_param(item)
    if item.try(:is_isa?)
      "share_isa[#{item.class.name}][#{item.id}]"
    elsif  (item.respond_to? (:investigations)) && (!item.investigations.any?)
      "share_not_isa[#{item.class.name}][#{item.id}]"
    elsif !item.respond_to? (:investigations)
      "share_not_isa[#{item.class.name}][#{item.id}]"
    else
      "share_isa[#{item.class.name}][#{item.id}]"
    end
  end

  def include_downloadable_item?(items)
    has_downloadable_item = false
    items.each do |item|
      if (item.try(:is_downloadable?))
        has_downloadable_item = true
      end
      break if has_downloadable_item
    end
    has_downloadable_item
  end

  def text_for_resource(resource_or_text)
    if resource_or_text.is_a?(String)
      text = resource_or_text.underscore.humanize
    else
      resource_type = resource_or_text.class.name
      text = if resource_or_text.is_a?(Assay)
               resource_or_text.is_modelling? ? t('assays.modelling_analysis') : t('assays.assay')
             elsif !(translated = translate_resource_type(resource_type)).include?('translation missing')
               translated
             else
               resource_type.underscore.humanize
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
    if resource.class.name.include?('::Version')
      polymorphic_path(resource.parent, version: resource.version)
    elsif resource.is_a?(Snapshot)
      polymorphic_path([resource.resource, resource])
    else
      polymorphic_path(resource)
    end
  end

  def edit_resource_path(resource)
    if resource.class.name.include?('::Version')
      edit_polymorphic_path(resource.parent)
    else
      edit_polymorphic_path(resource)
    end
  end

  def manage_resource_path(resource)
    if resource.class.name.include?('::Version')
      polymorphic_path(resource.parent, action:'manage')
    else
      polymorphic_path(resource, action:'manage')
    end
  end

  # provides a list of assets, according to the class, that are authorized according the 'action' which defaults to view
  # if projects is provided, only authorizes the assets for that project
  # assets are sorted by title except if they are projects and scales (because of hierarchies)
  def authorised_assets(asset_class, projects = nil, action = 'view')
    assets = asset_class
    assets = assets.filter_by_projects(projects) if projects
    assets = assets.authorized_for(action, User.current_user).to_a
    assets = assets.sort_by(&:title) if !assets.blank? && !%w[Project Scale].include?(assets.first.class.name)
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

  def download_or_link_button(asset, download_path, link_url, _human_name = nil, opts = {})
    download_button = icon_link_to('Download', 'download', download_path, opts)
    link_button_or_nil = link_url ? icon_link_to('External Link', 'external_link', link_url, opts.merge(target: 'blank')) : nil

    # that handles OpenBIS uses case
    return download_button if asset.respond_to?(:external_asset) && !asset.external_asset.nil?

    if asset.respond_to?(:content_blobs)
      if asset.content_blobs.detect { |blob| !blob.show_as_external_link? }
        download_button
      else
        link_button_or_nil
      end
    elsif asset.respond_to?(:content_blob) && asset.content_blob.present?
      if asset.content_blob.nels?
        icon_link_to('Open in NeLS', 'external_link', link_url, opts.merge(target: 'blank'))
      elsif asset.content_blob.show_as_external_link?
        link_button_or_nil
      else
        download_button
      end
    end
  end

  def open_with_copasi_button (asset)

    files =   asset.content_blobs
    download_path = polymorphic_path([files.first.asset, files.first], action: :download, code: params[:code])
    copasi_download_path =  "copasi://process?downloadUrl=http://"+request.host_with_port+download_path+"&activate=Time%20Course&createPlot=Concentrations%2C%20Volumes%2C%20and%20Global%20Quantity%20Values&runTask=Time-Course"

    tooltip_text_copasi_button = "Simulate the publicly accessible model in your local installed Copasi. "

    button= button_link_to('Simulate Model in Copasi', 'copasi', copasi_download_path, class: 'btn btn-default', disabled: asset.download_disabled?, 'data-tooltip' => tooltip(tooltip_text_copasi_button))

    button
  end

  def view_content_button(asset)
    render partial: 'assets/view_content', locals: { content_blob: asset.single_content_blob, button_style: true }
  end

  def doi_link(doi, opts = { target: '_blank' })
    link_to(doi, "https://doi.org/#{doi}", opts) + content_tag(:span, '', class: :doi_icon)
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

  def create_button(opts)
    text = opts.delete(:button_text) || t('submit_button.upload')
    submit_tag(text, opts.merge('data-upload-button' => ''))
  end

  def mini_file_download_icon(fileinfo)
    image_tag_for_key('download', polymorphic_path([fileinfo.asset, fileinfo], action: :download, code: params[:code]), 'Download', { title: 'Download this file' }, '')
  end

  def add_to_dropdown(item)
    return unless Seek::AddButtons.add_dropdown_for(item)
    tooltip = "This option allows you to add a new item, whilst associating it with this #{text_for_resource(item)}"
    dropdown_button(t('add_new_dropdown.button'), 'attach', menu_options: {class: 'pull-right', id: 'item-admin-menu'}, tooltip:tooltip) do
      add_item_to_options(item) do |text, path|
        content_tag(:li) do
          image_tag_for_key('add', path, text, nil, text)
        end
      end.join(" ").html_safe
    end
  end

  def add_item_to_options(item)
    elements = []
    Seek::AddButtons.add_for_item(item).each do |type,param|

      text="#{t('add_new_dropdown.option')} #{t(type.name.underscore)}"
      path = new_polymorphic_path(type,param=>item.id)
      elements << yield(text,path)
    end
    elements
  end

  # whether the viewable content is available, or converted to pdf, or capable to be converted to pdf
  def view_content_available?(content_blob)
    return true if content_blob.is_text? || content_blob.is_pdf? || content_blob.is_cwl? || content_blob.is_image?
    if content_blob.is_pdf_viewable?
      content_blob.file_exists?('pdf') || Seek::Config.soffice_available?
    else
      false
    end
  end

  def source_link_button(source_link)
    url = source_link.url
    uri = URI.parse(url)
    if uri.hostname.include?('github.com')
      image = 'github'
      text = 'View on GitHub'
    else
      image = 'external_link'
      text = 'Visit source'
    end

    button_link_to(text, image, source_link.url, target: :_blank)
  end

  #if there are creators, the email will be sent only to them, otherwise sent to the contributor
  #if the contact requester is one of the contirbutor/creators, the person is allowed to send request to others, but not to himself.
  def get_email_recipients(resource)
    if resource.creators.present?
      email_recipients = resource.creators
    else
      email_recipients = [resource.contributor] unless resource.contributor.nil?
    end
    email_recipients = email_recipients - [ User.current_user.person ] unless email_recipients.nil?
  end

  # whether the request contact button should be showns
  def request_contact_button_enabled?(resource)
    Seek::Config.email_enabled && logged_in_and_registered? && get_email_recipients(resource).present? && ContactRequestMessageLog.recent_requests(User.current_user.try(:person),resource).empty?
  end

  # whether the request contact has been made within 12 hours
  def request_contact_pending?(resource)
    return nil unless logged_in_and_registered?
    return nil unless Seek::Config.email_enabled
    return nil unless get_email_recipients(resource).present?
    ContactRequestMessageLog.recent_requests(current_user.try(:person), resource).first
  end

  def edam_ontology_items(ontologyCVItems)
    ontologyCVItems.collect do |item|
      browser_url = "https://edamontology.github.io/edam-browser/#{URI.parse(item.iri).path.gsub('/','#')}"
      link_to(item.label, browser_url, target: :_blank).html_safe
    end.join(', ').html_safe
  end

end
