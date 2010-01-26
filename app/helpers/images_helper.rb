# To change this template, choose Tools | Templates
# and open the template in the editor.

module ImagesHelper

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
      img = image_tag "/images/crystal_project/32x32/apps/kwikdisk.png",
            :alt => alt,
            :class=>"avatar framed"
    when "investigation"
      img = image_tag "/images/crystal_project/32x32/actions/search.png",
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

  def expand_image(margin_left="0.3em")
    image_tag "folds/unfold.png", :style => "margin-left: #{margin_left}; vertical-align: middle;", :alt => 'Expand', :title=>tooltip_title_attrib("Expand for more details")
  end

  def collapse_image(margin_left="0.3em")
    image_tag "folds/fold.png", :style => "margin-left: #{margin_left}; vertical-align: middle;", :alt => 'Collapse', :title=>tooltip_title_attrib("Collapse the details")
  end

  def image method,options={}
    image_tag(method_to_icon_filename(method),options)
  end
    
end
