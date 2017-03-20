module MenuHelper
  def menu_section_id(title)
    "#{title.underscore}_menu_section"
  end

  def menu_definitions
    definitions = [
      { title: t('menu.yellow_pages'), sections: [
        { controller: 'programmes', title: t('programme').pluralize, hide: !Seek::Config.programmes_enabled },
        { controller: 'people', title: 'People' },
        { controller: 'projects', title: t('project').pluralize },
        { controller: 'institutions', title: 'Institutions' }
      ] },

      { title: t('menu.isa'), sections: [
        { controller: 'investigations', title: t('investigation').pluralize },
        { controller: 'studies', title: t('study').pluralize },
        { controller: 'assays', title: t('assays.assay').pluralize }
      ] },

      { title: t('menu.assets'), sections: [
        { controller: 'data_files', title: t('data_file').pluralize },
        { controller: 'models', title: t('model').pluralize, hide: !Seek::Config.models_enabled },
        { controller: 'sops', title: t('sop').pluralize },
        { controller: 'publications', title: 'Publications' }
      ] },
      { title: t('menu.activities'), sections: [
        { controller: 'presentations', title: t('presentation').pluralize },
        { controller: 'events', title: t('event').pluralize, hide: !Seek::Config.events_enabled },
        { controller: 'forums', title: 'Forums', hide: !Seek::Config.forum_enabled }
      ] }
    ]

    if show_scales?
      scales_menu = { title: t('scale').pluralize, sections: [] }
      scales_menu[:sections] << { controller: 'scales', title: "Browse #{t('scale').pluralize}" }
      definitions << scales_menu
    end

    definitions << { title: t('menu.documentation'), spacer: true, hide: !Seek::Config.documentation_enabled, sections: [
      { controller: 'help_documents', title: t('menu.help') },
      { controller: 'help_documents', page: 'faq', title: t('menu.faq') },
      { controller: 'help_documents', page: 'templates', title: t('menu.jerm_templates') },
      { controller: 'help_documents', page: 'isa-best-practice', title: t('menu.isa_best_practice') }
    ] }
    definitions
  end

  def top_level_menu_tabs(definitions)
    selected_tab = current_top_level_tab(definitions)
    definitions.select { |d| !d[:hide] }.collect do |menu|
      attributes = ''
      attributes << "id = 'selected_tabnav'" if selected_tab == menu
      attributes << " class='spacer_before'" if menu[:spacer]

      c = menu[:controller]
      if !c.nil?
        path = eval("#{c}_path")
        click_js = "$('section_menu_items').hide();"
        "<li #{attributes}>#{link_to(menu[:title], path)}</li>"
      else
        click_js = 'update_menu_text("' + menu_section_id(menu[:title]) + '",true);return false;'
        "<li #{attributes}>#{link_to(menu[:title], {}, onclick: click_js, class: 'curved_top')}</li>"
      end
    end.join(' ').html_safe
  end

  def section_menu_items(sections)
    sections ||= []
    selected_section = current_second_level_section sections
    sections.collect do |section|
      next if section[:hide]
      title = section[:title]
      title ||= c.capitalize

      options = section[:options] || {}
      options[:class] = 'curved'
      link = link_to title, determine_path(section), options
      classes = 'curved'
      classes << ' selected_menu' if section == selected_section
      attributes = "class='#{classes}'"

      "<li #{attributes}>#{link}</li>"
    end.join('').html_safe
  end

  def select_menu(definitions)
    menu = current_top_level_tab(definitions)
    unless menu.nil?
      section_id = menu_section_id(menu[:title])
      "<script type='text/javascript'>select_menu_item('#{section_id}');</script>".html_safe
    end
  end

  def current_second_level_section(sections)
    sections.find do |section|
      determine_path(section).end_with?(controller_name)
    end
  end

  def determine_path(section)
    unless section[:stored_path]
      path = eval("#{section[:controller]}_path")
      path = path + '/' + section[:page] if section[:page]
      section[:stored_path] = path
    end
    section[:stored_path]
  end

  def current_top_level_tab(definitions)
    c = controller.controller_name.to_s
    path = request.path

    menu = definitions.find do |definition|
      !definition[:sections].nil? && !definition[:sections].select { |section| !section[:page].nil? && path.end_with?(section[:page]) }.empty?
    end

    menu ||= definitions.find do |definition|
      !definition[:sections].nil? && !definition[:sections].select { |section| section[:controller] == c }.empty?
    end

    menu
  end

  def navigation_link(text, url, active = false)
    content_tag(:li, class: (active ? 'active' : nil)) do
      link_to(text, url)
    end
  end
end
