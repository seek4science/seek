module MenuHelper

  def menu_section_id title
    "#{title.underscore}_menu_section"
  end

  def menu_definitions
    definitions=[
        {:title=>t("menu.yellow_pages"), :sections=>[
            {:controller=>"people",:title=>"People"},
            {:controller=>"projects",:title=>"Projects"},
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
        {:controller=>"help_documents",:title=>t("menu.documentation"),:spacer=>true}
        ]
    if admin_logged_in?
      definitions << {:controller=>"admin",:title=>t("menu.admin"),:spacer=>true}
    end
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
        "<li #{attributes}>#{link_to(menu[:title],path,{:onmouseover=>click_js})}</li>"
      else
        click_js = 'update_menu_text("'+menu_section_id(menu[:title])+'",true);return false;'
        "<li #{attributes}>#{link_to(menu[:title],{},{:onmouseover=>click_js,:onclick=>click_js})}</li>"
      end

    end.join(" ").html_safe
  end

  def section_menu_items sections
    sections||=[]
    sections.collect do |section|
      c = section[:controller]
      title = section[:title]
      title ||= c.capitalize
      path = eval "#{c}_path"

      link = link_to title, path
      attributes = "class='selected_menu'" if c == controller.controller_name.to_s

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


  def current_top_level_tab definitions
    c = controller.controller_name.to_s
    menu = definitions.select do |menu|
      !menu[:sections].nil? && !menu[:sections].select{|section| section[:controller]==c}.empty?
    end.first
    menu
  end

end
