# To change this template, choose Tools | Templates
# and open the template in the editor.

module ImagesHelper

  def info_icon_with_tooltip(info_text, delay=200)
    return image("info",
      :title => tooltip_title_attrib(info_text, delay),
      :style => "vertical-align:middle;")
  end

  def image_tag_for_key(key, url=nil, alt=nil, url_options={}, label=key.humanize, remote=false)

    if (label == 'Destroy')
      label = 'Delete';
    end

    return nil unless (filename = icon_filename_for_key(key.downcase))

    image_options = alt ? { :alt => alt } : { :alt => key.humanize }
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

  def icon_filename_for_key(key)
    case (key.to_s)
    when "refresh"
      "famfamfam_silk/arrow_refresh_small.png"
    when "arrow_up"
      "famfamfam_silk/arrow_up.png"
    when "arrow_down"
      "famfamfam_silk/arrow_down.png"
    when "arrow_right", "next"
      "famfamfam_silk/arrow_right.png"
    when "arrow_left", "back"
      "famfamfam_silk/arrow_left.png"
    when "new"
      "famfamfam_silk/add.png"
    when "download"
      "redmond_studio/arrow-down_16.png"
    when "show"
      "famfamfam_silk/zoom.png"
    when "edit"
      "famfamfam_silk/page_white_edit.png"
    when "edit-off"
      "stop_edit.png"
    when "manage"
      "famfamfam_silk/wrench.png"
    when "destroy"
      "famfamfam_silk/cross.png"
    when "tag"
      "famfamfam_silk/tag_blue.png"
    when "favourite"
      "famfamfam_silk/star.png"
    when "comment"
      "famfamfam_silk/comment.png"
    when "comments"
      "famfamfam_silk/comments.png"
    when "info"
      "famfamfam_silk/information.png"
    when "help"
      "famfamfam_silk/help.png"
    when "confirm"
      "famfamfam_silk/accept.png"
    when "reject"
      "famfamfam_silk/cancel.png"
    when "user", "person"
      "famfamfam_silk/user.png"
    when "user-invite"
      "famfamfam_silk/user_add.png"
    when "avatar"
      "famfamfam_silk/picture.png"
    when "avatars"
      "famfamfam_silk/photos.png"
    when "save"
      "famfamfam_silk/save.png"
    when "message"
      "famfamfam_silk/email.png"
    when "message_read"
      "famfamfam_silk/email_open.png"
    when "reply"
      "famfamfam_silk/email_go.png"
    when "message_delete"
      "famfamfam_silk/email_delete.png"
    when "messages_outbox"
      "famfamfam_silk/email_go.png"
    when "file"
      "redmond_studio/documents_16.png"
    when "logout"
      "famfamfam_silk/door_out.png"
    when "login"
      "famfamfam_silk/door_in.png"
    when "picture"
      "famfamfam_silk/picture.png"
    when "pictures"
      "famfamfam_silk/photos.png"
    when "profile"
      "famfamfam_silk/user_suit.png"
    when "history"
      "famfamfam_silk/time.png"
    when "news"
      "famfamfam_silk/newspaper.png"
    when "view-all"
      "famfamfam_silk/table_go.png"
    when "announcement"
      "famfamfam_silk/transmit.png"
    when "denied"
      "famfamfam_silk/exclamation.png"
    when "institution"
      "famfamfam_silk/house.png"
    when "project"
      "famfamfam_silk/report.png"
    when "tick"
      "famfamfam_silk/tick.png"
    when "lock"
      "famfamfam_silk/lock.png"
    when "no_user"
      "famfamfam_silk/link_break.png"
    when "sop"
      "famfamfam_silk/page.png"
    when "sops"
      "famfamfam_silk/page_copy.png"
    when "model"
      "famfamfam_silk/calculator.png"
    when "models"
      "famfamfam_silk/calculator.png"
    when "data_file","data_files"
      "famfamfam_silk/database.png"
    when "study"
      "famfamfam_silk/page.png"
    when "execute"
      "famfamfam_silk/lightning.png"
    when "warning"
      "famfamfam_silk/error.png"
    when "error"
      "famfamfam_silk/exclamation.png"
    when "feedback"
      "famfamfam_silk/email.png"
    when "spinner"
      "ajax-loader.gif"
    when "large-spinner"
      "ajax-loader-large.gif"
    when "current"
      "famfamfam_silk/bullet_green.png"
    when "collapse"
      "folds/fold.png"
    when "expand"
      "folds/unfold.png"
    when "pal"
      "pal.png"
    when "admin"
      "admin.png"
    when "pdf_file"
      "file_icons/small/pdf.png"
    when "xls_file"
      "file_icons/small/xls.png"
    when "doc_file"
      "file_icons/small/doc.png"
    when "misc_file"
      "file_icons/small/genericBlue.png"
    when "ppt_file"
      "file_icons/small/ppt.png"
    when "investigation_avatar"
      "crystal_project/32x32/actions/search.png"
    when "model_avatar"
      "crystal_project/32x32/apps/kwikdisk.png"
    when "study_avatar"
      "famfamfam_silk/book_open.png"
    when "assay_avatar"
      "famfamfam_silk/report.png"
    when "person_avatar"
      "avatar.png"
    when "project_avatar"
      "project_64x64.png"
    when "institution_avatar"
      "institution_64x64.png"
    when "saved_search"
      "crystal_project/32x32/actions/find.png"
    else
      return nil
    end
  end

  def help_icon(text, delay=200, extra_style="")
    image_tag icon_filename_for_key("help"), :alt=>"help", :title=>tooltip_title_attrib(text,delay), :style => "vertical-align: middle;#{extra_style}"
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

  # A generic key to produce avatars for entities of all kinds.
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
        img = default_avatar(object.class.name, size, alternative)
      end
    when "datafile", "sop"
      img = image_tag file_type_icon_url(object),
        :alt => alt,
        :class=> "avatar framed"
    when "model"
      img = image "model_avatar",
        {:alt => alt,
        :class=>"avatar framed"}
    when "investigation"
      img = image "investigation_avatar",
        {:alt => alt,
        :class=>"avatar framed"}
    when "study"
      img = image "study_avatar",
        {:alt => alt,
        :class=>"avatar framed"}

    when "assay"
      img = image "assay_avatar",
        {:alt => alt,
        :class => "avatar framed"}
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

  def default_avatar(object_class_name, size=200, alt="Anonymous", onclick_options="")
    avatar_filename=icon_filename_for_key("#{object_class_name.downcase}_avatar")
    
    image_tag avatar_filename,
      :alt => alt,
      :size => "#{size}x#{size}",
      :class => 'framed',
      :onclick => onclick_options
  end

  def file_type_icon(item)
    url = file_type_icon_url(item)
    image_tag url, :class => "icon"
  end

  def file_type_icon_url(item)
    url = ""
    case item.content_type
      when "application/vnd.ms-excel"
        url = icon_filename_for_key "xls_file"
      when "application/vnd.ms-powerpoint"
        url = icon_filename_for_key "ppt_file"
      when "application/pdf"
        url = icon_filename_for_key "pdf_file"
      when "application/msword"
        url = icon_filename_for_key "doc_file"
      else
        case item.original_filename[-4,4].gsub(".","")
          when "docx","doc"
            url = icon_filename_for_key "doc_file"
          when "xls"
            url = icon_filename_for_key "xls_file"
          when "ppt"
            url = icon_filename_for_key "ppt_file"
          when "pdf"
            url = icon_filename_for_key "pdf_file"
          else
           url = icon_filename_for_key "misc_file"
        end
    end
    return url
  end

  def expand_image(margin_left="0.3em")
    image_tag icon_filename_for_key("expand"), :style => "margin-left: #{margin_left}; vertical-align: middle;", :alt => 'Expand', :title=>tooltip_title_attrib("Expand for more details")
  end

  def collapse_image(margin_left="0.3em")
    image_tag icon_filename_for_key("collapse"), :style => "margin-left: #{margin_left}; vertical-align: middle;", :alt => 'Collapse', :title=>tooltip_title_attrib("Collapse the details")
  end

  def image key,options={}
    image_tag(icon_filename_for_key(key),options)
  end
    
end
