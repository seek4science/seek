# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include TagsHelper
  
  def is_nil_or_empty? thing
    thing.nil? or thing.empty?
  end
  
  def empty_list_li_text list
    return "<li><div class='none_text'> None specified</div></li>" if is_nil_or_empty?(list)
  end
  
  def text_or_not_specified text, options = {}
    if text.nil? or text.empty?
      not_specified_text="Not specified"
      not_specified_text="No description set" if options[:description]==true
      res = "<span class='none_text'>#{not_specified_text}</span>"
    else
      res = h(text)
      res = simple_format(res) if options[:description]==true
      res=mail_to(res) if options[:email]==true
      res=link_to(res,res,:popup=>true) if options[:external_link]==true
      res=res+"&nbsp;"+flag_icon(text) if options[:flag]==true
    end
    return res
  end
  
  def tooltip_title_attrib(text, delay=200)
    return "header=[] body=[#{text}] cssheader=[boxoverTooltipHeader] cssbody=[boxoverTooltipBody] delay=[#{delay}]"
  end
  
  def expand_image(margin_left="0.3em")
    image_tag "folds/unfold.png", :style => "margin-left: #{margin_left}; vertical-align: middle;", :alt => 'Expand', :title=>tooltip_title_attrib("Expand for more details")
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
    when "new"
      return "redmond_studio/add_16.png"
    when "download"
      return "redmond_studio/arrow-down_16.png"
    when "show"
      return "famfamfam_silk/zoom.png"
    when "edit"
      return "famfamfam_silk/pencil.png"
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
    when "user"
      return "famfamfam_silk/user.png"
    when "user-invite"
      return "famfamfam_silk/user_add.png"
    when "avatar"
      return "famfamfam_silk/picture.png"
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
    when "feedback"
      return "famfamfam_silk/user_comment.png"
    when "view-all"
      return "famfamfam_silk/table_go.png"
    when "announcement"
      return "famfamfam_silk/transmit.png"
    when "denied"
      return "famfamfam_silk/exclamation.png"
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
    
    #puts "code = " + code
    
    unless code.nil? or code.empty?
      return image_tag("famfamfam_flags/#{code.downcase}.png",
        :title => "header=[] body=[<b>Location: </b>#{text}] cssheader=[boxoverTooltipHeader] cssbody=[boxoverTooltipBody] delay=[200]",
        :style => "vertical-align:middle; margin-right: #{margin_right};")
    else
      return ''
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
    if show_tooltip
      tooltip_text = (alt.nil? ? h(object.name) : alt)
    else
      alternative = (alt.nil? ? h(object.name) : alt) 
    end
    
    case object.class.name.downcase
      when "person"
        # TEMP CODE: LINES IN THE FOLLOWING BLOCK WILL GET UNCOMMENTED, WHEN THE AVATAR UPLOAD WILL BE IMPLEMENTED
        #if person.avatar?
        #  img = image_tag avatar_url(person.picture_id, size), :title => alt, :class => 'framed'
        #else
          img = null_avatar(object.class.name, size, alternative)
        #end
        # END OF TEMP CODE
      when "institution"
        # TEMP CODE: LINES IN THE FOLLOWING BLOCK WILL GET UNCOMMENTED, WHEN THE AVATAR UPLOAD WILL BE IMPLEMENTED
        #if person.avatar?
        #  img = image_tag avatar_url(person.picture_id, size), :title => alt, :class => 'framed'
        #else
          img = null_avatar(object.class.name, size, alternative)
        #end
        # END OF TEMP CODE
      when "project"
        # TEMP CODE: LINES IN THE FOLLOWING BLOCK WILL GET UNCOMMENTED, WHEN THE AVATAR UPLOAD WILL BE IMPLEMENTED
        #if person.avatar?
        #  img = image_tag avatar_url(person.picture_id, size), :title => alt, :class => 'framed'
        #else
          img = null_avatar(object.class.name, size, alternative)
        #end
        # END OF TEMP CODE
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
  
  # TEMP COMMENT: will be fixed and put in use, when the avatar upload feature is implemented
  #def avatar_url(picture_id, size=200)
  #  url_for(:controller => 'pictures',
  #          :action => 'show',
  #          :id => picture_id,
  #          :size => "#{size}x#{size}")
  #end
  # END OF TEMP COMMENT
  
  def null_avatar(object_class_name, size=200, alt="Anonymous")
    case object_class_name.downcase
      when "person"
        avatar_filename = "avatar.png"
      when "institution"
        avatar_filename = "institution_64x64.png"
      when "project"
        avatar_filename = "project_64x64.png"
    end
    
    image_tag avatar_filename,
              :alt => alt, 
              :size => "#{size}x#{size}",
              :class => 'framed'
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
    return html
  end

  
end
