# Methods added to this helper will be available to all templates in the application.
# require_dependency File.join(Gem.loaded_specs['my_annotations'].full_gem_path,'lib','app','helpers','application_helper')

module ApplicationHelper
  include FancyMultiselectHelper
  include Recaptcha::ClientHelper
  include VersionHelper
  include ImagesHelper
  include SessionsHelper

  def no_items_to_list_text
    content_tag :div, id: 'no-index-items-text' do
      "There are no #{resource_text_from_controller.pluralize} found that are visible to you."
    end
  end

  def required_span
    content_tag :span, class: 'required' do
      '*'
    end
  end

  # e.g. SOP for sops_controller, taken from the locale based on the controller name
  def resource_text_from_controller
    internationalized_resource_name(controller_name.singularize.camelize, false)
  end

  def index_title(title = nil)
    content_tag(:h1) { title || resource_text_from_controller.pluralize }
  end

  def is_front_page?
    current_page?(main_app.root_url)
  end

  # turns the object name from a form builder, in the equivalent id
  def sanitized_object_name(object_name)
    object_name.gsub(/\]\[|[^-a-zA-Z0-9:.]/, '_').sub(/_$/, '')
  end

  def seek_stylesheet_tags(main = 'application')
    css = (Seek::Config.css_prepended || '').split(',').map { |c| "prepended/#{c}" }
    css << main
    css |= (Seek::Config.css_appended || '').split(',').map { |c| "appended/#{c}" }
    css.empty? ? '' : stylesheet_link_tag(*css)
  end

  def seek_javascript_tags(main = 'application')
    js = (Seek::Config.javascript_prepended || '').split(',').map { |c| "prepended/#{c}" }
    js << main
    js |= (Seek::Config.javascript_appended || '').split(',').map { |c| "appended/#{c}" }
    js.empty? ? '' : javascript_include_tag(*js)
  end

  def date_as_string(date, show_time_of_day = false, year_only_1st_jan = false, time_zone = nil)
    # for publications, if it is the first of jan, then it can be assumed it is just the year (unlikely have a publication on New Years Day)

    if date.to_s == nil
      str = "<span class='none_text'>No date defined</span>"
    elsif year_only_1st_jan && !date.blank? && date.month == 1 && date.day == 1
      str = date.year.to_s
    else
      date = Time.parse(date.to_s) unless date.is_a?(Time) || date.blank?
      if date.blank?
        str = "<span class='none_text'>No date defined</span>"
      else
        str = date.localtime.strftime("#{date.day.ordinalize} %b %Y")
        str = date.localtime.strftime("#{str} at %H:%M") if show_time_of_day
        if time_zone.present?
          date_in_tz = date.in_time_zone(time_zone)
          tz_str = date_in_tz.strftime("#{date_in_tz.day.ordinalize} %b %Y")
          tz_str = date_in_tz.strftime("#{tz_str} at %H:%M") if show_time_of_day
          str += "\t(#{tz_str} (#{time_zone}))"
        end
      end
    end

    str.html_safe
  end

  # provide the block that shows the URL to the resource, including the version if it is a versioned resource
  # label is based on the application name, for example <label>FAIRDOMHUB ID: </label>
  def persistent_resource_id(resource)
    # FIXME: this contains some duplication of Seek::Rdf::RdfGeneration#rdf_resource - however not every model includes that Module at this time.
    # ... its also a bit messy handling the version
    url = if resource.is_a_version?
            polymorphic_url(resource.parent, version: resource.version, **Seek::Config.site_url_options)
          else
            polymorphic_url(resource, **Seek::Config.site_url_options)
          end

    content_tag :p, class: :id do
      content_tag(:strong) do
        t('seek_id') + ':'
      end + ' ' + link_to(url, url)
    end
  end

  def show_title(title)
    render partial: 'general/page_title', locals: { title: title }
  end

  def version_text
    "(v.#{Seek::Version::APP_VERSION})"
  end

  def authorized_list(all_items, attribute, sort = true, max_length = 75, count_hidden_items = false)
    items = all_items.select(&:can_view?)
    title_only_items = []

    if count_hidden_items
      original_size = all_items.size
      hidden_items = []
      hidden_items |= (all_items - items - title_only_items)
    else
      hidden_items = []
    end

    html = "<b>#{(items.size > 1 ? attribute.pluralize : attribute)}:</b> "
    if items.empty? && title_only_items.empty? && hidden_items.empty?
      html << "<span class='none_text'>No #{attribute}</span>"
    else
      items = items.sort_by { |i| get_object_title(i) } if sort
      title_only_items = title_only_items.sort_by { |i| get_object_title(i) } if sort

      list = items.collect { |i| link_to truncate(i.title, length: max_length), show_resource_path(i), title: get_object_title(i) }
      list += title_only_items.collect { |i| h(truncate(i.title, length: max_length)) }
      html << list.join(', ')
      if count_hidden_items && !hidden_items.empty?
        text = !items.empty? ? ' and ' : ''
        text << "#{hidden_items.size} hidden #{hidden_items.size > 1 ? 'items' : 'item'}"
        html << hidden_items_html(hidden_items, text)
      end

    end
    html.html_safe
  end

  def hidden_items_html(hidden_items, text = 'hidden item')
    html = "<span class='none_text'>#{text}</span>"
    contributor_links = hidden_item_contributor_links hidden_items
    unless contributor_links.empty?
      html << "<span class='none_text'> - Please contact: #{contributor_links.join(', ')}</span>"
    end
    html.html_safe
  end

  def hidden_item_contributor_links(hidden_items)
    contributor_links = []
    hidden_items = hidden_items.reject { |hi| hi.contributing_user.try(:person).nil? }
    hidden_items.sort! { |a, b| a.contributing_user.person.name <=> b.contributing_user.person.name }
    hidden_items.each do |hi|
      contributor_person = hi.contributing_user.person
      next unless current_user.try(:person) && hi.can_see_hidden_item?(current_user.person) && contributor_person.can_view?
      contributor_name = contributor_person.name
      contributor_link = "<a href='#{person_path(contributor_person)}'>#{h(contributor_name)}</a>"
      contributor_links << contributor_link if contributor_link && !contributor_links.include?(contributor_link)
    end
    contributor_links
  end

  # joins the list with seperator and the last item with an 'and'
  def join_with_and(list, seperator = ', ')
    return list.first if list.count == 1
    result = ''
    list.each do |item|
      result << item
      next if item == list.last
      result << if item == list[-2]
                  ' and '
                else
                  seperator
                        end
    end
    result
  end

  # Classifies each result item into a hash with the class name as the key.
  #
  # This is to enable the resources to be displayed in the asset tabbed listing by class, or defined by .tab. Items not originating within SEEK are identified by is_external
  def classify_for_tabs(result_collection)
    results = {}

    result_collection.each do |res|
      tab = res.respond_to?(:tab) ? res.tab : res.class.name
      results[tab] ||= { items: [],
                         items_count: 0,
                         hidden_count: 0,
                         is_external: (res.respond_to?(:is_external_search_result?) && res.is_external_search_result?) }

      results[tab][:items] << res
      results[tab][:items_count] += 1
    end

    results
  end

  # selection of assets for new asset gadget
  def new_creatable_selection_list
    Seek::Util.user_creatable_types.collect { |c| [c.name.underscore.humanize, url_for(controller: c.name.underscore.pluralize, action: 'new')] }
  end

  def is_nil_or_empty?(thing)
    thing.nil? || thing.empty?
  end

  def empty_list_li_text(list)
    return "<li><div class='none_text'> None specified</div></li>".html_safe if is_nil_or_empty?(list)
  end

  def render_markdown(markdown)
    doc = CommonMarker.render_doc(markdown, :UNSAFE, [:tagfilter, :table, :strikethrough, :autolink])
    renderer = CommonMarker::SeekHtmlRenderer.new(options: [:UNSAFE, :GITHUB_PRE_LANG], extensions: [:tagfilter, :table, :strikethrough, :autolink])
    renderer.render(doc)
  end

  def text_or_not_specified(text, options = {})
    text = text.to_s
    if text.nil? || text.chomp.empty?
      not_specified_text ||= options[:none_text]
      not_specified_text ||= 'No description specified' if options[:description]
      not_specified_text ||= 'Not specified'
      res = content_tag(:span, not_specified_text, class: 'none_text')
    else
      text.capitalize! if options[:capitalize]
      res = text.html_safe
      res = sanitized_text(res)
      res = truncate_without_splitting_words(res, options[:length]) if options[:length]
      if options[:markdown]
        # Convert `&gt;` etc. back to `>` so markdown blockquotes can be used.
        # The markdown renderer will cope with rogue `>`s that are not part of quotes.
        res = render_markdown(CGI::unescapeHTML(res))
      elsif options[:description] || options[:address]
        res = simple_format(res, {}, sanitize: false).html_safe
      end
      res = auto_link(res, html: { rel: 'nofollow' }, sanitize: false) if options[:auto_link] && !options[:markdown]
      res = mail_to(res) if options[:email]
      res = link_to(res, res, popup: true, target: :_blank) if options[:external_link]
      res = res + '&nbsp;' + flag_icon(text) if options[:flag]

    end
    res.html_safe
  end

  def tooltip(text)
    h(text)
  end

  # text in "caption" will be used to display the item next to the image_tag_for_key;
  # if "caption" is nil, item.name will be used by default
  def list_item_with_icon(icon_type, item, caption, truncate_to, custom_tooltip = nil, size = nil)
    list_item = '<li>'
    list_item += if icon_type.casecmp('flag').zero?
                   flag_icon(item.country)
                 elsif icon_type == 'data_file' || icon_type == 'sop'
                   file_type_icon(item)
                 else
                   image_tag_for_key(icon_type.downcase, nil, icon_type.camelize, nil, '', false, size)
                 end
    item_caption = ' ' + (caption.blank? ? item.title : caption)
    list_item += link_to truncate(item_caption, length: truncate_to), url_for(item), 'data-tooltip' => tooltip(custom_tooltip.blank? ? item_caption : custom_tooltip)
    list_item += '</li>'

    list_item.html_safe
  end

  def contributor(contributor, _avatar = false, _size = 100, _you_text = false)
    return unless contributor

    contributor_name = h(contributor.name)
    contributor_name_link = link_to(contributor_name, contributor)

    contributor_name_link.html_safe
  end

  # this helper is to be extended to include many more types of objects that can belong to the
  # user - for example, SOPs and others
  def mine?(thing)
    return false if thing.nil?
    return false unless logged_in?

    c_id = current_user.id.to_i

    case thing.class.name
    when 'Person'
      return (current_user.person.id == thing.id)
    else
      return false
    end
  end

  def link_to_draggable(link_name, url, link_options = {})
    link_to(link_name, url, link_options)
  end

  def page_title(controller_name, _action_name)
    resource = resource_for_controller
    if resource && resource.respond_to?(:title) && resource.title
      h(resource.title)
    elsif (page_title = get_page_title).present?
      title = ''
      if @parent_resource
        title << "#{h(@parent_resource.title)} - "
      end
      t = page_title
      if t.is_a?(Hash)
        t = t[action_name] || t['*']
      end
      title << t
      title
    else
      "#{Seek::Config.instance_name}"
    end
  end

  def preview_permission_popup_link(resource)
    render partial: 'assets/preview_permission_link', locals: { resource: resource }
  end

  # Finn's truncate method. Doesn't split up words, tries to get as close to length as possible
  def truncate_without_splitting_words(text, length = 50, ellipsis = true)
    truncated_result = ''
    remaining_length = length
    stop = false
    truncated = false
    # lines
    text.split("\n").each do |l|
      # words
      l.split(' ').each do |w|
        # If we're going to go over the length, and we've not already
        if (remaining_length - w.length) <= 0 && !stop
          truncated = true
          stop = true
          # Decide if adding or leaving out the last word puts us closer to the desired length
          if (remaining_length - w.length).abs < remaining_length.abs
            truncated_result += (w + ' ')
          end
        elsif !stop
          truncated_result += (w + ' ')
          remaining_length -= (w.length + 1)
        end
      end
      truncated_result += "\n"
    end
    # Need some kind of whitespace before elipses or auto-link breaks
    html = truncated_result.strip + (truncated && ellipsis ? "\n..." : '')
    html.html_safe
  end

  def get_object_title(item)
    h(item.title)
  end

  def can_manage_announcements?
    admin_logged_in?
  end

  def show_or_hide_block(visible = true)
    html = 'display:' + (visible ? 'block' : 'none')
    html.html_safe
  end

  def toggle_appear_javascript(block_id, reverse: false)
    "#{reverse ? '!' : ''}this.checked ? $j('##{block_id}').slideDown() : $j('##{block_id}').slideUp();".html_safe
  end

  def folding_box(id, title, options = nil)
    render partial: 'assets/folding_box', locals:         { fold_id: id,
                                                            fold_title: title,
                                                            contents: options[:contents],
                                                            hidden: options[:hidden] }
  end

  def resource_tab_item_name(resource_type, pluralize = true)
    resource_type = resource_type.singularize
    if resource_type == 'Assay'
      result = t('assays.assay')
    else
      result = translate_resource_type(resource_type) || resource_type
    end
    pluralize ? result.pluralize : result
  end

  def internationalized_resource_name(resource_type, pluralize = true)
    resource_type = resource_type.singularize
    if resource_type == 'Assay'
      result = I18n.t('assays.assay')
    elsif resource_type == 'TavernaPlayer::Run'
      result = 'Run'
    else
      result = translate_resource_type(resource_type) || resource_type
    end
    pluralize ? result.pluralize : result
  end

  def translate_resource_type(resource_type)
    key = resource_type.underscore.to_s
    return nil unless I18n.exists?(key)
    I18n.t(key)
  end

  def no_deletion_explanation_message(clz)
    no_deletion_explanation_messages[clz] || "You are unable to delete this #{clz.name}. It might be published"
  end

  def no_deletion_explanation_messages
    { Assay => "You cannot delete this #{I18n.t('assays.assay')}. It might be published or it has items associated with it.",
      Study => "You cannot delete this #{I18n.t('study')}. It might be published or it has #{I18n.t('assays.assay').pluralize} associated with it.",
      Investigation => "You cannot delete this #{I18n.t('investigation')}. It might be published or it has #{I18n.t('study').pluralize} associated with it.",
      Strain => 'You cannot delete this Strain. Samples associated with it or you are not authorized.',
      Project => "You cannot delete this #{I18n.t 'project'}. It may have people or items associated with it.",
      Institution => "You cannot delete this #{I18n.t 'institution'}. It may have people associated with it.",
      SampleType => 'You cannot delete this Sample Type, it may have Samples associated with it or have another Sample Type linked to it',
      SampleControlledVocab => 'You can delete this Controlled Vocabulary, it may be associated with a Sample Type' }
  end

  def unable_to_delete_text(model_item)
    no_deletion_explanation_message(model_item.class).html_safe
  end

  def cancel_button(path, html_options = {})
    html_options[:class] ||= ''
    html_options[:class] << ' btn btn-default'
    text = html_options.delete(:button_text) || 'Cancel'
    link_to text, path, html_options
  end

  # to display funding codes on the 'show' page if present
  def show_funding_codes(item)
    return if item.funding_codes.empty?
    html = content_tag(:strong, 'Funding codes:')
    html << content_tag(:ul, class: 'funding-codes') do
      inner = ''
      item.funding_codes.each do |code|
        inner += content_tag(:li, code)
      end
      inner.html_safe
    end

    html.html_safe
  end

  def using_docker?
    Seek::Docker.using_docker?
  end

  def sanitized_text(text)
    Rails::Html::SafeListSanitizer.new.sanitize(text)
  end

  # whether manage attributes should be shown, dont show if editing (rather than new or managing)
  def show_form_manage_specific_attributes?
    !(action_name == 'edit' || action_name == 'update' || action_name == 'update_paths') # TODO: Figure out a better check here...
  end

  def pending_project_creation_request?
    return false unless admin_logged_in? || programme_administrator_logged_in?

    ProjectCreationMessageLog.pending_requests.detect do |log|
      log.can_respond_project_creation_request?(User.current_user)
    end.present?
  end

  def pending_project_join_request?
    return false unless project_administrator_logged_in?
    return false if ProjectMembershipMessageLog.pending.count == 0
    person = User.current_user.person
    projects = person.administered_projects
    return ProjectMembershipMessageLog.pending_requests(projects).any?
  end

  def pending_programme_creation_request?
    return false unless admin_logged_in?
    return Programme.not_activated.where('activation_rejection_reason IS NULL').any?
  end

  #whether to show a banner encouraging you to join or create a project
  def join_or_create_project_banner?
    return false unless logged_in_and_registered?
    return false if logged_in_and_member?
    return false if current_page?(create_or_join_project_home_path) ||
        current_page?(guided_create_projects_path) ||
        current_page?(guided_join_projects_path)

    #current_page? doesn't work with POST
    return false if ['request_join','request_create'].include?(action_name)

    return Seek::Config.programmes_enabled && Programme.site_managed_programme
  end

  def render_menu_group(title, options)
    return unless options.any? { |opt_title, url, enabled| enabled }
    html = content_tag(:li, title, role: 'presentation', class: 'dropdown-header')
    options.each do |opt_title, url, enabled|
      next unless enabled
      html += content_tag(:li) do
        link_to(opt_title, url)
      end
    end

    html
  end

  PAGE_TITLES = { 'home' => 'Home', 'sessions' => 'Login', 'users' => { 'new' => 'Signup', '*' => 'Account' },
                  'search' => 'Search', 'biosamples' => 'Biosamples', 'help_documents' => 'Help' }.freeze

  def show_page_tab
    return 'overview' unless params.key?(:tab)

    params[:tab]
  end

  def get_page_title
    class_name = controller_name.classify

    if PAGE_TITLES.key?(controller_name)
      PAGE_TITLES[controller_name]
    elsif Seek::Util.searchable_types.any? { |t| t.name == class_name }
      I18n.t(class_name.underscore).pluralize
    else
      nil
    end
  end

  def format_field_name(field_name)
    return field_name unless displaying_single_page?

    type = field_name.split('[')[0]
    rest = '[' + field_name.split('[')[1]
    # Converts study[other_creators] to isa_study[study][other_creators]
    "isa_#{type}[#{type}]#{rest}"
  end

  def expandable_list(items, limit: 10, none_text: 'None', id: nil, &block)
    content_tag(:div, 'data-role' => 'seek-expandable-list') do
      concat(if items.empty?
               content_tag(:span, none_text, class: 'none_text')
             else
               content_tag(:ul, id: id, class: 'list collapsed') do
                 items.each_with_index do |item, index|
                   concat content_tag(:li, capture(item, &block), class: index >= limit ? 'hidden-item' : '')
                 end
               end
             end)
      if items.any? && items.length > limit
        concat link_to(('More ' + image('expand')).html_safe, '#', class: 'pull-right',
                       'data-role' => 'seek-expandable-list-expand')
        concat link_to(('Less ' + image('collapse')).html_safe, '#', class: 'pull-right',
                       style: 'display: none', 'data-role' => 'seek-expandable-list-collapse')
      end
    end
  end
end

class ApplicationFormBuilder < ActionView::Helpers::FormBuilder
  def fancy_multiselect(association, options = {})
    @template.fancy_multiselect object, association, options
  end
end

ActionView::Base.default_form_builder = ApplicationFormBuilder

def cookie_consent
  CookieConsent.new(cookies)
end
