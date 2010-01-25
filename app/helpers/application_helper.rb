# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include TagsHelper

  #List of creatable model classes
  def creatable_classes
    #FIXME: make these discovered automatically.
    #FIXME: very bad method name
    [Model,DataFile,Sop,Study,Assay,Investigation]

  end

  def tag_cloud(tags, classes)
    max_count = tags.sort_by(&:total).last.total.to_f

    tags.each do |tag|
      index = ((tag.total / max_count) * (classes.size - 1)).round
      yield tag, classes[index]
    end
  end

  #returns true if the current user is associated with a profile that is marked as a PAL
  def current_user_is_pal?
    current_user && current_user.person && current_user.person.is_pal?
  end

  #Classifies each result item into a hash with the class name as the key.
  #
  #This is to enable the resources to be displayed in the asset tabbed listing by class
  def classify_for_tabs result_collection
    results={}

    result_collection.each do |res|
      results[res.class.name] = [] unless results[res.class.name]
      results[res.class.name] << res
    end

    return results
  end

  #selection of assets for new asset gadget
  def new_creatable_selection
    select_tag :new_asset_type,options_for_select(creatable_classes.collect{|c| [c.name.underscore.humanize,c.name.underscore] })
  end
  
  def is_nil_or_empty? thing
    thing.nil? or thing.empty?
  end
  
  def empty_list_li_text list
    return "<li><div class='none_text'> None specified</div></li>" if is_nil_or_empty?(list)
  end  

  def model_title_or_not_specified model
    text=model.nil? ? nil : model.title
    text_or_not_specified text,:capitalize=>true    
  end
  
  def text_or_not_specified text, options = {}    
    if text.nil? or text.chomp.empty?
      not_specified_text="Not specified"
      not_specified_text="No description set" if options[:description]==true
      res = "<span class='none_text'>#{not_specified_text}</span>"
    else      
      text.capitalize! if options[:capitalize]            
      res=text
      res = white_list(res)
      res = truncate_without_splitting_words(res, options[:length])  if options[:length]
      res = auto_link(res, :all, :rel => 'nofollow') if options[:auto_link]==true  
      res = simple_format(res) if options[:description]==true || options[:address]==true
      
      res=mail_to(res) if options[:email]==true
      res=link_to(res,res,:popup=>true) if options[:external_link]==true
      res=res+"&nbsp;"+flag_icon(text) if options[:flag]==true
      res = "&nbsp;" + flag_icon(text) + link_to(res,country_path(res)) if options[:link_as_country]==true 
    end
    return res
  end
  
  def tooltip_title_attrib(text, delay=200)
    return "header=[] body=[#{text}] cssheader=[boxoverTooltipHeader] cssbody=[boxoverTooltipBody] delay=[#{delay}]"
  end
  
  def expand_image(margin_left="0.3em")
    image_tag "folds/unfold.png", :style => "margin-left: #{margin_left}; vertical-align: middle;", :alt => 'Expand', :title=>tooltip_title_attrib("Expand for more details")
  end
  
  def collapse_image(margin_left="0.3em")
    image_tag "folds/fold.png", :style => "margin-left: #{margin_left}; vertical-align: middle;", :alt => 'Collapse', :title=>tooltip_title_attrib("Collapse the details")
  end

  def image method,options={}
    image_tag(method_to_icon_filename(method),options)
  end

  def info_icon_with_tooltip(info_text, delay=200)
    return image("info",
              :title => tooltip_title_attrib(info_text, delay),
              :style => "vertical-align:middle;")
  end

  
  def icon(method, url=nil, alt=nil, url_options={}, label=method.humanize, remote=false)

    if (label == 'Destroy')
      label = 'Delete';
    end

    return nil unless (filename = method_to_icon_filename(method.downcase))
    
    image_options = alt ? { :alt => alt } : { :alt => method.humanize }
    img_tag = image_tag(filename, image_options)
    
    inner = img_tag;
    inner = "#{img_tag} #{label}" unless label == nil

    if (url)
      if (remote)
        inner = link_to_remote(inner, url, url_options);
      else
        inner = link_to(inner, url, url_options)
      end
    end

    return '<span class="icon">' + inner + '</span>';
  end
  
  def method_to_icon_filename(method)
    case (method.to_s)
    when "refresh"
      return "famfamfam_silk/arrow_refresh_small.png"
    when "arrow_up"
      return "famfamfam_silk/arrow_up.png"
    when "arrow_down"
      return "famfamfam_silk/arrow_down.png"
    when "arrow_right", "next"
      return "famfamfam_silk/arrow_right.png"
    when "arrow_left", "back"
      return "famfamfam_silk/arrow_left.png"  
    when "new"
      return "famfamfam_silk/add.png"
    when "download"
      return "redmond_studio/arrow-down_16.png"
    when "show"
      return "famfamfam_silk/zoom.png"
    when "edit"
      return "famfamfam_silk/page_white_edit.png"
    when "edit-off"
      return "stop_edit.png"
    when "manage"
      return "famfamfam_silk/wrench.png"
    when "destroy"
      return "famfamfam_silk/cross.png"
    when "tag"
      return "famfamfam_silk/tag_blue.png"
    when "favourite"
      return "famfamfam_silk/star.png"
    when "comment"
      return "famfamfam_silk/comment.png"
    when "comments"
      return "famfamfam_silk/comments.png"
    when "info"
      return "famfamfam_silk/information.png"
    when "help"
      return "famfamfam_silk/help.png"
    when "confirm"
      return "famfamfam_silk/accept.png"
    when "reject"
      return "famfamfam_silk/cancel.png"
    when "user", "person"
      return "famfamfam_silk/user.png"
    when "user-invite"
      return "famfamfam_silk/user_add.png"
    when "avatar"
      return "famfamfam_silk/picture.png"
    when "avatars"
      return "famfamfam_silk/photos.png"
    when "save"
      return "famfamfam_silk/save.png"
    when "message"
      return "famfamfam_silk/email.png"
    when "message_read"
      return "famfamfam_silk/email_open.png"
    when "reply"
      return "famfamfam_silk/email_go.png"
    when "message_delete"
      return "famfamfam_silk/email_delete.png"  
    when "messages_outbox"
      return "famfamfam_silk/email_go.png"
    when "file"
      return "redmond_studio/documents_16.png"
    when "logout"
      return "famfamfam_silk/door_out.png"
    when "login"
      return "famfamfam_silk/door_in.png"
    when "picture"
      return "famfamfam_silk/picture.png"
    when "pictures"
      return "famfamfam_silk/photos.png"
    when "profile"
      return "famfamfam_silk/user_suit.png"
    when "history"
      return "famfamfam_silk/time.png"   
    when "news"
      return "famfamfam_silk/newspaper.png"    
    when "view-all"
      return "famfamfam_silk/table_go.png"
    when "announcement"
      return "famfamfam_silk/transmit.png"
    when "denied"
      return "famfamfam_silk/exclamation.png"
    when "institution"
      return "famfamfam_silk/house.png"
    when "project"
      return "famfamfam_silk/report.png"
    when "tick"
      return "famfamfam_silk/tick.png"
    when "lock"
      return "famfamfam_silk/lock.png"
    when "no_user"
      return "famfamfam_silk/link_break.png"
    when "sop"
      return "famfamfam_silk/page.png"
    when "sops"
      return "famfamfam_silk/page_copy.png"
    when "model"
      return "famfamfam_silk/calculator.png"
    when "models"
      return "famfamfam_silk/calculator.png"
    when "data_file","data_files"
      return "famfamfam_silk/database.png"
    when "study"
      return "famfamfam_silk/page.png"
    when "execute"
      return "famfamfam_silk/lightning.png"
    when "warning"
      return "famfamfam_silk/error.png"
    when "error"
      return "famfamfam_silk/exclamation.png"
    when "feedback"
      return "famfamfam_silk/email.png"
    when "spinner"
      return "ajax-loader.gif"
    when "large-spinner"
      return "ajax-loader-large.gif"
    when "current"
      return "famfamfam_silk/bullet_green.png"
    when "expand"
      "folds/fold.png"
    when "collapse"
      "folds/unfold.png"
    when "pal"
      "pal.png"
    when "admin"
      "admin.png"
    when "pdf_file"
      return "file_icons/small/pdf.png"
    when "xls_file"
      return "file_icons/small/xls.png"
    when "doc_file"
      return "file_icons/small/doc.png"
    when "misc_file"
      return "file_icons/small/genericBlue.png"
    when "ppt_file"
      return "file_icons/small/ppt.png"
    else
      return nil
    end
  end
  
  
  def help_icon(text, delay=200, extra_style="")
    image_tag method_to_icon_filename("help"), :alt=>"help", :title=>tooltip_title_attrib(text,delay), :style => "vertical-align: middle;#{extra_style}"
  end
  
  def flag_icon(country, text=country, margin_right='0.3em')
    return '' if country.nil? or country.empty?
    
    code = ''
    
    if country.downcase == "great britain"
      code = "gb"
    elsif ["england", "wales", "scotland"].include?(country.downcase)
      code = country
    elsif country.length > 2
      code = CountryCodes.code(country)
    else
      code = country if CountryCodes.valid_code?(country)
    end
    
    unless code.nil? or code.empty?
      return image_tag("famfamfam_flags/#{code.downcase}.png",
        :title => "header=[] body=[<b>Location: </b>#{text}] cssheader=[boxoverTooltipHeader] cssbody=[boxoverTooltipBody] delay=[200]",
        :style => "vertical-align:middle; margin-right: #{margin_right};")
    else
      return ''
    end
  end
  
  # text in "caption" will be used to display the item next to the icon;
  # if "caption" is nil, item.name will be used by default
  def list_item_with_icon(icon_type, item, caption, truncate_to, custom_tooltip=nil)
    list_item = "<li>"
    
    if icon_type.downcase == "flag"
      list_item += flag_icon(item.country)
    elsif icon_type == "data_file" || icon_type == "sop"
      list_item += file_type_icon(item)
    else
      list_item += icon(icon_type.downcase, nil, icon_type.camelize, nil, "")
    end
    item_caption = " " + h(caption.blank? ? item.name : caption)
    list_item += link_to truncate(item_caption, :length=>truncate_to), url_for(item), :title => tooltip_title_attrib(custom_tooltip.blank? ? item_caption : custom_tooltip)
    list_item += "</li>"
    
    return list_item
  end
  
  
  def contributor(contributor, avatar=false, size=100, you_text=false)
    return nil unless contributor
    
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
        return result
      else
        return (contributor_name_link + you_string)
      end
      # other types might be supported
      # elsif contributortype.to_s == "Network"
      #network = Network.find(:first, :select => "id, title", :conditions => ["id = ?", contributorid])
      #return nil unless network
      #
      #return title(network)
    else
      return nil
    end
  end

  
  
  
  # A generic method to produce avatars for entities of all kinds.
  #
  # Parameters:
  # 1) object - the instance of the object which requires the avatar;
  # 2) size - size of the square are, where the avatar will reside (the aspect ratio of the picture is preserved by ImageMagick);
  # 3) return_image_tag_only - produces only the <img /> tag; the picture won't be linked to anywhere; no 'alt' / 'title' attributes;
  # 4) url - when the avatar is clicked, this is the url to redirect to; by default - the url of the "object";
  # 5) alt - text to show as 'alt' / 'tooltip'; by default "name" attribute of the "object"; when empty string - nothing is shown;
  # 6) "show_tooltip" - when set to true, text in "alt" get shown as tooltip; otherwise put in "alt" attribute
  def avatar(object, size=200, return_image_tag_only=false, url=nil, alt=nil, show_tooltip=true)
    alternative = ""
    title = get_object_title(object)
    if show_tooltip
      tooltip_text = (alt.nil? ? h(title) : alt)
    else
      alternative = (alt.nil? ? h(title) : alt) 
    end
    
    case object.class.name.downcase
    when "person", "institution", "project"
      if object.avatar_selected?
        img = image_tag avatar_url(object, object.avatar_id, size), :alt=> alternative, :class => 'framed'
      else
        img = null_avatar(object.class.name, size, alternative)
      end
    when "datafile", "sop"
      img = image_tag file_type_icon_url(object),
            :alt => alt,
            :class=> "avatar framed"
    when "model"
      img = image_tag "/images/famfamfam_silk/bricks.png",
            :alt => alt,
            :class=>"avatar framed"
    when "investigation"
      img = image_tag "/images/famfamfam_silk/magnifier.png",
            :alt => alt,
            :class=>"avatar framed"
    when "study"
      img = image_tag "/images/famfamfam_silk/book_open.png",
            :alt => alt,
            :class=>"avatar framed"

    when "assay"
      img = image_tag "/images/famfamfam_silk/report.png",
            :alt => alt,
            :class => "avatar framed"
    end
    
    # if the image of the avatar needs to be linked not to the url of the object, return only the image tag
    if return_image_tag_only
      return img
    else 
      unless url
        url = eval("#{object.class.name.downcase}_url(#{object.id})")
      end
      
      return link_to(img, url, :title => tooltip_title_attrib(tooltip_text))
    end
  end
  
  def avatar_url(avatar_for_instance, avatar_id, size=nil)
    basic_url = eval("#{avatar_for_instance.class.name.downcase}_avatar_path(#{avatar_for_instance.id}, #{avatar_id})")
    
    if size
      basic_url += "?size=#{size}"
      basic_url += "x#{size}" if size.kind_of?(Numeric)
    end
    
    return basic_url
  end
  
  def null_avatar(object_class_name, size=200, alt="Anonymous", onclick_options="")
    case object_class_name.downcase
    when "person"
      avatar_filename = "avatar.png"
    when "institution"
      avatar_filename = "institution_64x64.png"
    when "project"
      avatar_filename = "project_64x64.png"
    when "datafile"
      avatar_filename = "data_file.png"
    when "model"
      avatar_filename = "model.png"
    when "sop"
      avatar_filename = "sop.png"
    end
    
    image_tag avatar_filename,
      :alt => alt,
      :size => "#{size}x#{size}",
      :class => 'framed',
      :onclick => onclick_options
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
      :ghosting => drag_options[:ghosting] || true,
      :change => "function(element){#{can_click_var} = false;}")
    return html
  end

  def page_title controller_name, action_name
    name=PAGE_TITLES[controller_name]
    name ||=""
    name += " (Development)" if RAILS_ENV=="development"
    return "Sysmo SEEK&nbsp;"+name
  end

  def admin_email_links
    admins=User.admins
    result=""
    admins.each do |u|
      result << mail_to(u.person.email,u.person.name)
      result << ", " unless admins.last==u
    end
    return result    
  end

  # http://www.igvita.com/blog/2006/09/10/faster-pagination-in-rails/
  def windowed_pagination_links(pagingEnum, options)
    link_to_current_page = options[:link_to_current_page]
    always_show_anchors = options[:always_show_anchors]
    padding = options[:window_size]

    current_page = pagingEnum.page
    html = ''

    #Calculate the window start and end pages
    padding = padding < 0 ? 0 : padding
    first = pagingEnum.page_exists?(current_page  - padding) ? current_page - padding : 1
    last = pagingEnum.page_exists?(current_page + padding) ? current_page + padding : pagingEnum.last_page

    # Print start page if anchors are enabled
    html << yield(1) if always_show_anchors and not first == 1

    # Print window pages
    first.upto(last) do |page|
      (current_page == page && !link_to_current_page) ? html << page : html << yield(page)
    end

    # Print end page if anchors are enabled
    html << yield(pagingEnum.last_page) if always_show_anchors and not last == pagingEnum.last_page
    html
  end

  def show_tag?(tag)
    tag.taggings.size>1 || (tag.taggings.size==1 && tag.taggings[0].taggable_id)
  end

  def link_for_tag tag, options={}
    link=people_url
    length=options[:truncate_length]
    length||=150
    if (options[:type]==:expertise)
      link=people_url(:expertise=>tag.name)
    end
    if (options[:type]==:tools)
      link=people_url(:tools=>tag.name)
    end
    if (options[:type]==:organisms)
      link=projects_url(:organisms=>tag.name)
    end
    link = show_tag_url(tag)
    link_to h(truncate(tag.name,:length=>length)), link, :class=>options[:class],:id=>options[:id],:style=>options[:style],:title=>tooltip_title_attrib(tag.name)
  end

  def list_item_tags_list tags,options={}
    tags.map do |t|
      divider=tags.last==t ? "" : "<span class='spacer'>,</span> "
      link_for_tag(t,options)+divider
    end
  end

  def favourite_group_popup_link_action_new
    return link_to_remote_redbox("Create new favourite group", 
      { :url => new_favourite_group_url,
        :failure => "alert('Sorry, an error has occurred.'); RedBox.close();" },
      { #:style => options[:style],
        :id => "create_new_f_group_redbox",
        :onclick => "javascript: currentFavouriteGroupSettings = {};" }#,
      #:alt => "Click to create a new favourite group (opens popup window)",#options[:tooltip_text],
      #:title => tooltip_title_attrib("Opens a popup window, where you can create a new favourite<br/>group, add people to it and set individual access rights.") }  #options[:tooltip_text]
    )
  end
  
  def favourite_group_popup_link_action_edit
    return link_to_remote_redbox("Edit selected favourite group", 
      { :url => edit_favourite_group_url,
        :failure => "alert('Sorry, an error has occurred.'); RedBox.close();" },
      { #:style => options[:style],
        :id => "edit_existing_f_group_redbox",
        :onclick => "javascript: currentFavouriteGroupSettings = {};" } #,
      #:alt => "Click to create a new favourite group (opens popup window)",#options[:tooltip_text],
      #:title => tooltip_title_attrib("Opens a popup window, where you can create a new favourite<br/>group, add people to it and set individual access rights.") }  #options[:tooltip_text]
    )
  end
  
  def workgroup_member_review_popup_link
    return link_to_remote_redbox("<b>Review members, set individual<br/>permissions and add afterwards</b>", 
      { :url => review_work_group_url("type", "id", "access_type"),
        :failure => "alert('Sorry, an error has occurred.'); RedBox.close();" },
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
  
  #Return whether or not to hide contact details from this user
  #Current decided by HIDE_DETAILS flag in environment_local.rb
  #Defaults to false
  def hide_contact_details?
    (defined? HIDE_DETAILS) ? HIDE_DETAILS : false
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
    truncated_result.strip + (truncated ? "\n..." : "")
  end  

  def file_type_icon(item)
    url = file_type_icon_url(item)
    image_tag url, :class => "icon"
  end

  def file_type_icon_url(item)
    url = ""
    case item.content_type
      when "application/vnd.ms-excel"
        url = method_to_icon_filename "xls_file"
      when "application/vnd.ms-powerpoint"
        url = method_to_icon_filename "ppt_file"
      when "application/pdf"
        url = method_to_icon_filename "pdf_file"
      when "application/msword"
        url = method_to_icon_filename "doc_file"
      else
        case item.original_filename[-4,4].gsub(".","")
          when "docx","doc"
            url = method_to_icon_filename "doc_file"   
          when "xls"
            url = method_to_icon_filename "xls_file"
          when "ppt"
            url = method_to_icon_filename "ppt_file"
          when "pdf"
            url = method_to_icon_filename "pdf_file"
          else
           url = method_to_icon_filename "misc_file"
        end
    end
    return url
  end
  
  def get_object_title(item)
    title = ""
    if ["Person", "Institution", "Project"].include? item.class.name
      title = h(item.name)          
    else
      title = h(item.title)
    end
    return title
  end

  def fav_icon_image_path
    image_path "favicon.png"
  end
  
  private  
  PAGE_TITLES={"home"=>"Home", "projects"=>"Projects","institutions"=>"Institutions", "people"=>"People", "sessions"=>"Login","users"=>"Signup","search"=>"Search","experiments"=>"Experiments","sops"=>"Sops","models"=>"Models","data_files"=>"Data"}
  
end
