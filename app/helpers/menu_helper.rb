module MenuHelper

  def menu_section_id title
    "#{title.underscore}_menu_section"
  end

  def menu_definitions
    definitions=[
        {:title=>t("menu.yellow_pages"), :sections=>[
            {:controller=>"people",:title=>"People"},
            {:controller=>"projects",:title=>t("project").pluralize},
            {:controller=>"institutions",:title=>"Institutions"}
        ]},

        {:title=>t("menu.isa"),:sections=>[
            {:controller=>"investigations",:title=>t("investigation").pluralize},
            {:controller=>"studies",:title=>t("study").pluralize},
            {:controller=>"assays",:title=>t("assays.assay").pluralize}
        ]},

        {:title=>t("menu.assets"),:sections=>[
            {:controller=>"data_files",:title=>t("data_file").pluralize},
            {:controller=>"models", :title=>t("model").pluralize},
            {:controller=>"sops", :title=>t("sop").pluralize},
            {:controller=>"publications", :title=>"Publications"},
            {:controller=>"biosamples",:title=>"Biosamples"}
        ]},
        {:title=>t("menu.activities"),:sections=>[
            {:controller=>"presentations",:title=>t("presentation").pluralize},
            {:controller=>"events", :title=>t("event").pluralize},
        ]},
        ]
    if logged_in_and_registered?
      account_menu = {:title=>t("menu.account"),:spacer=>true,:sections=>[]}

      account_menu[:sections] << {:path=>person_path(User.current_user.person),:title=>"Your profile"}

      account_menu[:sections] << {:path=>admin_path,:title=>t("menu.admin")} if admin_logged_in?

      account_menu[:sections] << {:path=>feedback_home_path(),:title=>t("menu.feedback")} if Seek::Config.email_enabled

      account_menu[:sections] << {:path=>"/logout",:title=>"Logout",:options=>{:confirm=>"Are you sure you wish to logout?"}}

      definitions << account_menu
    end

    definitions << {:title=>t("menu.documentation"),:spacer=>true, :sections=>[
        {:controller=>"help_documents",:title=>t("menu.help")},
        {:path=>"/help/faq",:title=>t("menu.faq")},
        {:path=>"/help/templates",:title=>t("menu.jerm_templates")},
        {:path=>"/help/isa-best-practice",:title=>t("menu.isa_best_practice")}
    ]}
    definitions
  end

  def top_level_menu_tabs definitions
    selected_tab = current_top_level_tab(definitions)
    definitions.collect do |menu|

      attributes = ""
      attributes << "id = 'selected_tabnav'" if selected_tab == menu
      attributes << " class='spacer_before'" if menu[:spacer]

      c = menu[:controller]
      if !c.nil?
        path = eval("#{c}_path")
        click_js = "$('section_menu_items').hide();"
        "<li #{attributes}>#{link_to(menu[:title],path,)}</li>"
      else
        click_js = 'update_menu_text("'+menu_section_id(menu[:title])+'",true);return false;'
        "<li #{attributes}>#{link_to(menu[:title],{},{:onclick=>click_js,:class=>"curved_top"})}</li>"
      end

    end.join(" ").html_safe
  end

  def section_menu_items sections
    sections||=[]
    selected_section = current_second_level_section sections
    sections.collect do |section|
      c = section[:controller]
      path = section[:path]
      title = section[:title]
      title ||= c.capitalize

      path = section[:path] || eval("#{c}_path")
      options = section[:options] || {}
      link = link_to title, path,options
      attributes = "class='selected_menu'" if section == selected_section

      "<li #{attributes}>#{link}</li>"
    end.join("").html_safe
  end

  def select_menu definitions
    menu = current_top_level_tab(definitions)
    unless menu.nil?
      section_id = menu_section_id(menu[:title])
      "<script type='text/javascript'>select_menu_item('#{section_id}');</script>".html_safe
    end
  end

  def current_second_level_section sections
    section = sections.find do |section|
      request.path.end_with?(section[:path])
    end

    c = controller.controller_name.to_s


    section ||= sections.find do |section|
      section[:controller]==c
    end

    section
  end

  def current_top_level_tab definitions
    c = controller.controller_name.to_s
    path = request.path

    menu = definitions.find do |menu|
      !menu[:sections].nil? && !menu[:sections].select{|section| !section[:path].nil? && section[:path].end_with?(path)}.empty?
    end

    menu ||= definitions.find do |menu|
      !menu[:sections].nil? && !menu[:sections].select{|section| section[:controller]==c}.empty?
    end

    menu
  end

end
