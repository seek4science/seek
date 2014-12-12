# Methods added to this helper will be available to all templates in the application.
#require_dependency File.join(Gem.loaded_specs['my_annotations'].full_gem_path,'lib','app','helpers','application_helper')
require 'savage_beast/application_helper'
require 'app_version'

module ApplicationHelper  
  include SavageBeast::ApplicationHelper
  include FancyMultiselectHelper
  include TavernaPlayer::RunsHelper
  include Recaptcha::ClientHelper


  def no_items_to_list_text
    content_tag :div,:id=>"no-index-items-text" do
      "There are no #{resource_text_from_controller.pluralize} found that are visible to you."
    end
  end

  #e.g. SOP for sops_controller, taken from the locale based on the controller name
  def resource_text_from_controller
    internationalized_resource_name(controller_name.singularize.camelize, false)
  end

  def index_title title=nil
    show_title(title || resource_text_from_controller.pluralize)
  end

  def is_front_page?
    current_page?(main_app.root_url)
  end

  #turns the object name from a form builder, in the equivalent id
  def sanitized_object_name object_name
    object_name.gsub(/\]\[|[^-a-zA-Z0-9:.]/, "_").sub(/_$/, "")
  end

  def seek_stylesheet_tags main='application'
    css = (Seek::Config.css_prepended || "").split(",")
    css << main
    css = css | (Seek::Config.css_appended || "").split(",")
    css.empty? ? "" : stylesheet_link_tag(*css)
  end

  def seek_javascript_tags main='application'
    js = (Seek::Config.javascript_prepended || "").split(",")
    js << main
    js = js | (Seek::Config.javascript_appended || "").split(",")
    js.empty? ? "" : javascript_include_tag(*js)
  end

  def date_as_string date,show_time_of_day=false,year_only_1st_jan=false
    #for publications, if it is the first of jan, then it can be assumed it is just the year (unlikely have a publication on New Years Day)
    if (year_only_1st_jan && !date.blank? && date.month==1 && date.day==1)
      str=date.year.to_s
    else
      date = Time.parse(date.to_s) unless date.is_a?(Time) || date.blank?
      if date.blank?
        str="<span class='none_text'>No date defined</span>"
      else
        str = date.localtime.strftime("#{date.day.ordinalize} %b %Y")
        str = date.localtime.strftime("#{str} at %H:%M") if show_time_of_day
      end
    end

    str.html_safe
  end

  def show_title title
    render :partial=>"general/item_title", :locals=>{:title=>title}
  end

  def version_text
    "(v.#{SEEK::Application::APP_VERSION.to_s})"
  end

  def authorized_list all_items, attribute, sort=true, max_length=75, count_hidden_items=false
    items = all_items.select &:can_view?
    if Seek::Config.is_virtualliver
      title_only_items = (all_items - items).select &:title_is_public?
    else
      title_only_items = []
    end

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

      list = items.collect { |i| link_to truncate(i.title, :length => max_length), show_resource_path(i), :title => get_object_title(i) }
      list = list + title_only_items.collect { |i| h(truncate(i.title, :length => max_length)) }
      html << list.join(', ')
      if count_hidden_items && !hidden_items.empty?
        text = items.size > 0 ? " and " : ""
        text << "#{hidden_items.size} hidden #{hidden_items.size > 1 ? 'items' : 'item'}"
        html << hidden_items_html(hidden_items, text)
      end

    end
    html.html_safe
  end

  def hidden_items_html hidden_items, text='hidden item'
    html = "<span class='none_text'>#{text}</span>"
    contributor_links = hidden_item_contributor_links hidden_items
    if !contributor_links.empty?
      html << "<span class='none_text'> - Please contact: #{contributor_links.join(', ')}</span>"
    end
    html.html_safe
  end

  def hidden_item_contributor_links hidden_items
    contributor_links = []
    hidden_items = hidden_items.select { |hi| !hi.contributing_user.try(:person).nil? }
    hidden_items.sort! { |a, b| a.contributing_user.person.name <=> b.contributing_user.person.name }
    hidden_items.each do |hi|
      contributor_person = hi.contributing_user.person
      if current_user.try(:person) && hi.can_see_hidden_item?(current_user.person) && contributor_person.can_view?
        contributor_name = contributor_person.name
        contributor_link = "<a href='#{person_path(contributor_person)}'>#{h(contributor_name)}</a>"
        contributor_links << contributor_link if contributor_link && !contributor_links.include?(contributor_link)
      end
    end
    contributor_links
  end

  def tabbar
    Seek::Config.is_virtualliver ? render(:partial=>"general/tabnav_dropdown") : render(:partial=>"general/menutabs")
  end

  #joins the list with seperator and the last item with an 'and'
  def join_with_and list, seperator=", "
    return list.first if list.count==1
    result = ""
    list.each do |item|
      result << item
      unless item==list.last
        if item==list[-2]
          result << " and "
        else
          result << seperator
        end
      end
    end
    result
  end

  def tab_definition(options={})
    options[:gap_before] ||= false
    options[:title] ||= options[:controllers].first.capitalize
    options[:path] ||= eval "#{options[:controllers].first}_path"

    attributes = (options[:controllers].include?(controller.controller_name.to_s) ? ' id="selected_tabnav"' : '')
    attributes += " class='tab_gap_before'" if options[:gap_before]

    link=link_to options[:title], options[:path]
    "<li #{attributes}>#{link}</li>".html_safe
  end

  #Classifies each result item into a hash with the class name as the key.
  #
  #This is to enable the resources to be displayed in the asset tabbed listing by class, or defined by .tab. Items not originating within SEEK are identified by is_external
  def classify_for_tabs result_collection
    results={}

    result_collection.each do |res|
      tab = res.respond_to?(:tab) ? res.tab : res.class.name
      results[tab] = {:items => [], :hidden_count => 0, :is_external=>(res.respond_to?(:is_external_search_result?) && res.is_external_search_result?)} unless results[tab]
      results[tab][:items] << res
    end

    return results
  end

  def new_creatable_javascript
    script="<script type='text/javascript'>\n"
    script << "function newAsset() {\n"
    script << "selected_model=$('new_resource_type').value;\n"
    Seek::Util.user_creatable_types.each do |c|
      name=c.name.underscore
      path = eval "new_#{name}_path"
      data_file_with_sample_path = eval "new_data_file_path(:page_title=>'#{t("data_file")} with Sample Parsing',:is_with_sample=>true)"
      if c==Seek::Util.user_creatable_types.first
        script << "if "
      else
        script << "else if(selected_model == 'data_file_with_sample'){
          \n location.href = '#{data_file_with_sample_path}';\n
        } \n"
        script << "else if "
      end
      script << "(selected_model == '#{name}') {\n location.href = '#{path}';\n }\n"

    end
    script << "}\n"
    script << "</script>"
    script.html_safe
  end

  #selection of assets for new asset gadget
  def new_creatable_selection_list
    creatable_options = Seek::Util.user_creatable_types.collect { |c| [c.name.underscore.humanize, c.name.underscore] }
    creatable_options << ["#{t('data_file')} with sample", "data_file_with_sample"] if Seek::Config.sample_parser_enabled
    creatable_options
  end

  def is_nil_or_empty? thing
    thing.nil? or thing.empty?
  end
  
  def empty_list_li_text list
    return "<li><div class='none_text'> None specified</div></li>".html_safe if is_nil_or_empty?(list)
  end
  
  def text_or_not_specified text, options = {}
    text=text.to_s if text.kind_of?(Numeric)
    if text.nil? or text.chomp.empty?
      not_specified_text||=options[:none_text]
      not_specified_text||="No description specified" if options[:description]==true
      not_specified_text||="Not specified"
      res = "<span class='none_text'>#{not_specified_text}</span>"
    else      
      text.capitalize! if options[:capitalize]            
      res = text.html_safe
      res = white_list(res)
      res = truncate_without_splitting_words(res, options[:length])  if options[:length]
      res = auto_link(res, :all, :rel => 'nofollow') if options[:auto_link]==true  
      res = simple_format(res).html_safe if options[:description]==true || options[:address]==true
      
      res=mail_to(res) if options[:email]==true
      res=link_to(res,res,:popup=>true) if options[:external_link]==true
      res=res+"&nbsp;"+flag_icon(text) if options[:flag]==true
      res = "&nbsp;" + flag_icon(text) + link_to(res,country_path(res)) if options[:link_as_country]==true 
    end
    res.html_safe
  end

  def tooltip_title_attrib(text, delay=200)
    return "header=[] body=[#{text}] cssheader=[boxoverTooltipHeader] cssbody=[boxoverTooltipBody] delay=[#{delay}]"
  end
      
  # text in "caption" will be used to display the item next to the image_tag_for_key;
  # if "caption" is nil, item.name will be used by default
  def list_item_with_icon(icon_type, item, caption, truncate_to, custom_tooltip=nil, size=nil)
    list_item = "<li>"
    if icon_type.downcase == "flag"
      list_item += flag_icon(item.country)
    elsif icon_type == "data_file" || icon_type == "sop"
      list_item += file_type_icon(item)
    else
      list_item += image_tag_for_key(icon_type.downcase, nil, icon_type.camelize, nil, "", false, size)
    end
    item_caption = " " + (caption.blank? ? item.title : caption)
    list_item += link_to truncate(item_caption, :length=>truncate_to), url_for(item), :title => tooltip_title_attrib(custom_tooltip.blank? ? item_caption : custom_tooltip)
    list_item += "</li>"
    
    return list_item.html_safe
  end
  
  
  def contributor(contributor, avatar=false, size=100, you_text=false)
    return jerm_harvester_name unless contributor
    
    if contributor.class.name == "User"
      # this string will output " (you) " for current user next to the display name, when invoked with 'you_text == true'
      you_string = (you_text && logged_in? && user.id == current_user.id) ? "<small style='vertical-align: middle; color: #666666; margin-left: 0.5em;'>(you)</small>" : ""
      contributor_person = contributor.person
      contributor_name = h(contributor_person.name)
      contributor_url = person_path(contributor_person.id)
      contributor_name_link = link_to(contributor_name, contributor_url)
      
      if avatar
        result = avatar(contributor_person, size, false, contributor_url, contributor_name, false)
        result += "<p style='margin: 0; text-align: center;'>#{contributor_name_link}#{you_string}</p>"
        return result.html_safe
      else
        return (contributor_name_link + you_string).html_safe
      end
    else
      return nil
    end
  end
  
  # this helper is to be extended to include many more types of objects that can belong to the
  # user - for example, SOPs and others
  def mine?(thing)
    return false if thing.nil?
    return false unless logged_in?
    
    c_id = current_user.id.to_i
    
    case thing.class.name
    when "Person"
      return (current_user.person.id == thing.id)
    else
      return false
    end
  end
  
  def fast_auto_complete_field(field_id, options={})
    div_id = "#{field_id}_auto_complete"
    url = options.delete(:url) or raise "url required"
    options = options.merge(:tokens => ',', :frequency => 0.01 )
    script = javascript_tag <<-end
    new Ajax.Request('#{url}', {
      method: 'get',
      onSuccess: function(transport) {
        new Autocompleter.Local('#{field_id}', '#{div_id}', eval(transport.responseText), #{options.to_json});
      }
    });
    end
    content_tag 'div', script, :class => 'auto_complete', :id => div_id
  end

  def link_to_draggable(link_name, url, link_options = {}, drag_options = {})
    if !link_options[:id]
      return ":id mandatory"
    end
    
    can_click_var = "can_click_for_#{link_options[:id]}"
    html = javascript_tag("var #{can_click_var} = true;");
    html << link_to(
      link_name,
      url,
      :id => link_options[:id],
      :class => link_options[:class] || "",
      :title => link_options[:title] || "",
      :onclick => "if (!#{can_click_var}) {#{can_click_var}=true;return(false);} else {return true;}",
      :onMouseUp => "setTimeout('#{can_click_var} = true;', 200);")
      html << draggable_element(link_options[:id],
      :revert => drag_options[:revert] || true,
      :ghosting => drag_options[:ghosting] || false,
      :change => "function(element){#{can_click_var} = false;}")
    return html.html_safe
  end

  def page_title controller_name, action_name
    name=PAGE_TITLES[controller_name]
    name ||=""
    name += " (Development)" if Rails.env=="development"
    return "#{Seek::Config.application_title} "+name
  end


  def favourite_group_popup_link_action_new resource_type=nil
    return link_to_remote_redbox("Create new #{t('favourite_group')}",
      { :url => main_app.new_favourite_group_url,
        :failure => "alert('Sorry, an error has occurred.'); RedBox.close();",
        :with => "'resource_type=' + '#{resource_type}'" },
      { #:style => options[:style],
        :id => "create_new_f_group_redbox",
        :onclick => "javascript: currentFavouriteGroupSettings = {};" }#,
      #:alt => "Click to create a new favourite group (opens popup window)",#options[:tooltip_text],
      #:title => tooltip_title_attrib("Opens a popup window, where you can create a new favourite<br/>group, add people to it and set individual access rights.") }  #options[:tooltip_text]
    )
  end
  
  def favourite_group_popup_link_action_edit resource_type=nil
    return link_to_remote_redbox("Edit selected #{t('favourite_group')}",
      { :url => main_app.edit_favourite_group_url,
        :failure => "alert('Sorry, an error has occurred.'); RedBox.close();",
        :with => "'resource_type=' + '#{resource_type}' + '&id=' + selectedFavouriteGroup()" },
      { #:style => options[:style],
        :id => "edit_existing_f_group_redbox",
        :onclick => "javascript: currentFavouriteGroupSettings = {};" } #,
      #:alt => "Click to create a new favourite group (opens popup window)",#options[:tooltip_text],
      #:title => tooltip_title_attrib("Opens a popup window, where you can create a new favourite<br/>group, add people to it and set individual access rights.") }  #options[:tooltip_text]
    )
  end
  
  def workgroup_member_review_popup_link resource_type=nil
    return link_to_remote_redbox("<b>Review members, set individual<br/>permissions and add afterwards</b>".html_safe,
      { :url => main_app.review_work_group_url("type", "id", "access_type"),
        :failure => "alert('Sorry, an error has occurred.'); RedBox.close();",
        :with => "'resource_type=' + '#{resource_type}'" },
      { #:style => options[:style],
        :id => "review_work_group_redbox" } #,
      #:alt => "Click to create a new favourite group (opens popup window)",#options[:tooltip_text],
      #:title => tooltip_title_attrib("Opens a popup window, where you can create a new favourite<br/>group, add people to it and set individual access rights.") }  #options[:tooltip_text]
    )
  end
  
  # the parameter must be the *standard* name of the whitelist or blacklist (depending on the link that needs to be produced)
  # (standard names are defined in FavouriteGroup model)
  def whitelist_blacklist_edit_popup_link(f_group_name)
    return link_to_remote_redbox("edit", 
      { :url => edit_favourite_group_url,
        :failure => "alert('Sorry, an error has occurred.'); RedBox.close();" },
      { #:style => options[:style],
        :id => "#{f_group_name}_edit_redbox",
        :onclick => "javascript: currentFavouriteGroupSettings = {};" } #,
      #:alt => "Click to create a new favourite group (opens popup window)",#options[:tooltip_text],
      #:title => tooltip_title_attrib("Opens a popup window, where you can create a new favourite<br/>group, add people to it and set individual access rights.") }  #options[:tooltip_text]
    )
  end

  def preview_permission_popup_link resource
    resource_name = resource.class.name.underscore
    resource_id = resource.id
    url = preview_permissions_policies_path
    is_new_file = resource.new_record?
    contributor_id = resource.contributing_user.try(:id)
    return link_to_remote_redbox("preview permission",
      { :url => url ,
        :failure => "alert('Sorry, an error has occurred.'); RedBox.close();",
        :with => "'sharing_scope=' + selectedSharingScope() + '&access_type=' + selectedAccessType(selectedSharingScope())
        + '&project_ids=' + getProjectIds('#{resource_name}') + '&project_access_type=' + $F('sharing_your_proj_access_type')
        + '&contributor_types=' + $F('sharing_permissions_contributor_types') + '&contributor_values=' + $F('sharing_permissions_values')
        + '&creators=' + encodeURIComponent(getCreators()) + '&contributor_id=' + '#{contributor_id}' + '&resource_name=' + '#{resource_name}' + '&resource_id=' + '#{resource_id}' + '&is_new_file=' + '#{is_new_file}'"},
      { :id => 'preview_permission',
        :style => 'display:none'
      }
    )
  end
  #Return whether or not to hide contact details from this user
  #Current decided by Seek::Config.hide_details_enabled in config.rb
  #Defaults to false
  def hide_contact_details?
    #hide for non-login and non-project-member
    if !logged_in? or !current_user.person.member?
      return true
    else
      Seek::Config.hide_details_enabled
    end
  end

  # Finn's truncate method. Doesn't split up words, tries to get as close to length as possible
  def truncate_without_splitting_words(text, length=50)
    truncated_result = ""
    remaining_length = length
    stop = false
    truncated = false
    #lines
    text.split("\n").each do |l|
      #words
      l.split(" ").each do |w|
        #If we're going to go over the length, and we've not already
        if (remaining_length - w.length) <= 0 && !stop
          truncated = true
          stop = true
          #Decide if adding or leaving out the last word puts us closer to the desired length
          if (remaining_length-w.length).abs < remaining_length.abs
            truncated_result += (w + " ")
          end
        elsif !stop
          truncated_result += (w + " ")
          remaining_length -= (w.length + 1)
        end
      end
      truncated_result += "\n"
    end    
    #Need some kind of whitespace before elipses or auto-link breaks
    html = truncated_result.strip + (truncated ? "\n..." : "")
    html.html_safe
  end    
  
  def get_object_title(item)
    return h(item.title)
  end

  def can_manage_announcements?
    return admin_logged_in?
  end

  def show_or_hide_block visible=true
    html = "display:" + (visible ? 'block' : 'none')
    html.html_safe
  end

  def toggle_appear_javascript block_id
    "Effect.toggle('#{block_id}','slide',{duration:0.5})".html_safe
  end



  def set_parameters_for_sharing_form object=nil
    object ||= eval "@#{controller_name.singularize}"
    policy = nil
    policy_type = ""

    # obtain a policy to use
    if object
      if object.instance_of? Project
        if object.default_policy
          policy = object.default_policy
          policy_type ="project"
        else
          policy = Policy.default
          policy_type = "system"
        end
      elsif (policy = object.policy)
        # object exists and has a policy associated with it - normal case
        policy_type = "asset"
      end
    end

    unless policy
      policy = Policy.default
      policy_type = "system"
    end

    # set the parameters
    # ..from policy
    @policy = policy
    @policy_type = policy_type
    @sharing_mode = policy.sharing_scope
    @access_mode = policy.access_type
    @use_custom_sharing = !policy.permissions.empty?
    @use_whitelist = (policy.use_whitelist == true || policy.use_whitelist == 1)
    @use_blacklist = (policy.use_blacklist == true || policy.use_blacklist == 1)

    # ..other
    @resource_type = text_for_resource object
    @favourite_groups = current_user.favourite_groups
    @resource = object

    @all_people_as_json = Person.get_all_as_json

    @enable_black_white_listing = @resource.nil? || (@resource.respond_to?(:contributor) and !@resource.contributor.nil?)
  end

  def folding_box id, title, options = nil
    render :partial => 'assets/folding_box', :locals =>
        {:fold_id => id,
         :fold_title => title,
         :contents => options[:contents],
         :hidden => options[:hidden]}
  end

  def resource_tab_item_name resource_type,pluralize=true
    resource_type = resource_type.singularize
    if resource_type == "Speciman"
      result = t('biosamples.sample_parent_term')
    elsif resource_type == "Assay"
      result = t('assays.assay')
    else
      translated_resource_type = translate_resource_type(resource_type)
      result = translated_resource_type.include?("translation missing") ? resource_type : translated_resource_type
    end
    pluralize ? result.pluralize : result
  end

  def internationalized_resource_name resource_type,pluralize=true
    resource_type = resource_type.singularize
    if resource_type == "Speciman"
      result = t('biosamples.sample_parent_term')
    elsif resource_type == "Assay"
      result = t('assays.assay')
    elsif resource_type == "TavernaPlayer::Run"
      result = "Run"
    else
      translated_resource_type = translate_resource_type(resource_type)
      result = translated_resource_type.include?("translation missing") ? resource_type : translated_resource_type
    end
    pluralize ? result.pluralize : result
  end

  def translate_resource_type resource_type
    t("#{resource_type.underscore}")
  end

  def add_return_to_search
    referer = request.headers["Referer"].try(:normalize_trailing_slash)
    search_path = main_app.search_url.normalize_trailing_slash
    root_path = main_app.root_url.normalize_trailing_slash
    request_uri = request.fullpath.try(:normalize_trailing_slash)
    if !request_uri.include?(root_path)
      request_uri = root_path.chop + request_uri
    end

    if referer == search_path && referer != request_uri && request_uri != root_path
      javascript_tag "
        if (window.history.length > 1){
          var a = document.createElement('a');
          a.onclick = function(){ window.history.back(); };
          a.onmouseover = function(){ this.style.cursor='pointer'; }
          a.appendChild(document.createTextNode('Return to search'));
          a.style.textDecoration='underline';
          document.getElementById('return_to_search').appendChild(a);
        }
      "
      #link_to_function 'Return to search', "window.history.back();"
    end
  end

  def no_deletion_explanation_message(clz)
    no_deletion_explanation_messages[clz] || "You are unable to delete this #{clz.name}. It might be published"
  end

  def no_deletion_explanation_messages
    {Assay=>"You cannot delete this #{I18n.t('assays.assay')}. It might be published or it has items associated with it.",
     Study=>"You cannot delete this #{I18n.t('study')}. It might be published or it has #{I18n.t('assays.assay').pluralize} associated with it.",
     Investigation=>"You cannot delete this #{I18n.t('investigation')}. It might be published or it has #{I18n.t('study').pluralize} associated with it." ,
     Strain=>"You cannot delete this Strain. It might be published or it has #{I18n.t('biosamples.sample_parent_term').pluralize}/Samples associated with it or you are not authorized.",
     Specimen=>"You cannot delete this #{I18n.t 'biosamples.sample_parent_term'}. It might be published or it has Samples associated with it or you are not authorized.",
     Sample=>"You cannot delete this Sample. It might be published or it has #{I18n.t('assays.assay').pluralize} associated with it or you are not authorized.",
     Project=>"You cannot delete this #{I18n.t 'project'}. It may have people associated with it.",
     Institution=>"You cannot delete this Institution. It may have people associated with it."
    }
  end


  
  def unable_to_delete_text model_item
    no_deletion_explanation_message(model_item.class).html_safe
  end


  #returns a new instance of the string describing a resource type, or nil if it is not applicable
  def instance_of_resource_type resource_type
    resource = nil
    begin
      resource_class = resource_type.classify.constantize unless resource_type.nil?
      resource = resource_class.send(:new) if !resource_class.nil? && resource_class.respond_to?(:new)
    rescue NameError=>e
      logger.error("Unable to find constant for resource type #{resource_type}")
    end
    resource
  end

  def klass_from_controller controller_name
    controller_name.singularize.camelize.constantize
  end

  def describe_visibility(model)
    text = '<strong>Visibility:</strong> '

    if model.policy.sharing_scope == Policy::PRIVATE
      css_class = 'private'
      text << "Private "
      text << "with some exceptions " unless model.policy.permissions.empty?
      text << image('lock', :style => 'vertical-align: middle')
    elsif model.policy.sharing_scope == Policy::ALL_SYSMO_USERS && model.policy.access_type == Policy::NO_ACCESS
      css_class = 'group'
      text << "Only visible to members of "
      text << model.policy.permissions.select {|p| p.contributor_type == 'Project'}.map {|p| p.contributor.title}.to_sentence
    elsif model.policy.sharing_scope == Policy::EVERYONE
      css_class = 'public'
      text << "Public #{image('world', :style => 'vertical-align: middle')}"
    end

    "<span class='visibility #{css_class}'>#{text}</span>".html_safe
  end

  private  
  PAGE_TITLES={"home"=>"Home", "projects"=>I18n.t('project').pluralize,"institutions"=>"Institutions", "people"=>"People", "sessions"=>"Login","users"=>"Signup","search"=>"Search",
               "assays"=>I18n.t('assays.assay').pluralize.capitalize,"sops"=>I18n.t('sop').pluralize,"models"=>I18n.t('model').pluralize,"data_files"=>I18n.t('data_file').pluralize,
               "publications"=>"Publications","investigations"=>I18n.t('investigation').pluralize,"studies"=>I18n.t('study').pluralize,
               "specimens"=>I18n.t('biosamples.sample_parent_term').pluralize,"samples"=>"Samples","strains"=>"Strains","organisms"=>"Organisms","biosamples"=>"Biosamples",
               "presentations"=>I18n.t('presentation').pluralize,"programmes"=>I18n.t('programme').pluralize,"events"=>I18n.t('event').pluralize,"help_documents"=>"Help"}
end

class ApplicationFormBuilder< ActionView::Helpers::FormBuilder
  def fancy_multiselect association, options = {}
    @template.fancy_multiselect object, association, options
  end

  def subform_delete_link(link_text='remove', link_options = {}, hidden_field_options = {})
    hidden_field(:_destroy, hidden_field_options) + @template.link_to_function(link_text, "$(this).previous().value = '1';$(this).up().hide();", link_options)
  end
end

ActionView::Base.default_form_builder = ApplicationFormBuilder
