# To change this template, choose Tools | Templates
# and open the template in the editor.

module ImagesHelper

  include Seek::MimeTypes
  
  def info_icon_with_tooltip(info_text, delay=200)
    return image("info",
      :title => tooltip_title_attrib(info_text, delay),
      :style => "vertical-align:middle;")
  end

  #mirrors image_tag but uses a key instead of a source
  def simple_image_tag_for_key key, options={}
    return nil unless (filename = icon_filename_for_key(key.downcase))
    image_tag filename,options
  end

  def image_tag_for_key(key, url=nil, alt=nil, html_options={}, label=key.humanize, remote=false, size=nil)

    label = 'Delete' if label == 'Destroy'
    
    return nil unless (filename = icon_filename_for_key(key.downcase))

    image_options = alt ? { :alt => alt } : { :alt => key.humanize }
    image_options[:size] = "#{size}x#{size}" unless size.blank?
    img_tag = image_tag(filename, image_options)

    inner = img_tag;
    inner = "#{img_tag} #{label}".html_safe unless label.blank?
    
    if (url)
      if (remote==:function)
        inner = link_to_function inner, url, html_options
      elsif (remote)
        inner = link_to(inner, url, html_options.merge(:remote => true))
      else
        inner = link_to(inner, url, html_options)
      end
    end
    
    tag = '<span class="icon">' + inner + '</span>'
    tag.html_safe
  end

  def resource_avatar resource,html_options={}

    if resource.avatar_key
          image_tag(icon_filename_for_key(resource.avatar_key), html_options)
    elsif resource.use_mime_type_for_avatar?
          image_tag(file_type_icon_url(resource), html_options)
    end
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
      when "arrow_down_small"
        "misc_icons/arrow_down_small.png"
      when "bioportal_logo"
      "logos/bioportal_logo.png"
      when "new","add"
      "famfamfam_silk/add.png"
      when "multi_add"
      "famfamfam_silk/table_add.png"
      when "download"
        "crystal_project/16x16/actions/build.png"
      when "big_download"
        "crystal_project/32x32/actions/build.png"
      when "show"
      "famfamfam_silk/zoom.png"
      when "zoom_in"
      "famfamfam_silk/zoom_in.png"
      when "zoom_out"
      "famfamfam_silk/zoom_out.png"
      when "copy"
        "famfamfam_silk/page_copy.png"
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
      "crystal_project/22x22/apps/clean.png"    
      when "lock"
      "famfamfam_silk/lock.png"
      when "open"
      "famfamfam_silk/lock_open.png"
      when "no_user"
      "famfamfam_silk/link_break.png"
      when "sop"
      "famfamfam_silk/page.png"
      when "sops"
      "famfamfam_silk/page_copy.png"
      when "model"
      "crystal_project/32x32/apps/kformula.png"
      when "models"
      "crystal_project/64x64/apps/kformula.png"
      when "data_file","data_files"
      "famfamfam_silk/database.png"
      when "study"
      "famfamfam_silk/page.png"
      when "test"
      "crystal_project/16x16/actions/run.png"
      when "execute"
      "famfamfam_silk/lightning.png"
      when "warning","warn"
      "crystal_project/22x22/apps/alert.png"
      when "skipped"
      "crystal_project/22x22/actions/undo.png"
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
      "famfamfam_silk/rosette.png"
      when "admin"
      "famfamfam_silk/shield.png"
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
      when "xml_file"
      "file_icons/small/xml.png"
      when "zip_file"
      "file_icons/small/zip.png"
      when "jpg_file"
      "file_icons/small/jpg.png"
      when "gif_file"
      "file_icons/small/gif.png"
      when "png_file"
      "file_icons/small/png.png"
      when "jpg_file"
      "file_icons/small/jpg.png"
      when "bmp_file"
      "file_icons/small/bmp.png"
      when "svg_file"
      "file_icons/small/svg.png"
      when "txt_file"
      "file_icons/small/txt.png"
      when "rtf_file"
      "file_icons/small/rtf.png"
      when "html_file"
        "file_icons/small/html.png"
      when "investigation_avatar", "investigation", "investigations"
      "crystal_project/64x64/apps/mydocuments.png"
      when "study_avatar"
      "crystal_project/64x64/apps/package_editors.png"
      when "assay_avatar","assay_experimental_avatar", 'assay'
      "misc_icons/flask3-64x64.png"
      when "assay_modelling_avatar"
      "crystal_project/64x64/filesystems/desktop.png"
      when "model_avatar"
      "crystal_project/64x64/apps/kformula.png"
      when "person_avatar"
      "avatar.png"
      when "jerm_logo"
      "jerm_logo.png"
      when "project_avatar"
      "project_64x64.png"
      when "institution_avatar"
      "institution_64x64.png"
      when "organism_avatar"
      "misc_icons/cell3.png"
      when 'strain_avatar'
        "misc_icons/enterococcus_faecalis64-64.jpg"
      when "publication_avatar", "publication", "publications"
     "crystal_project/64x64/mimetypes/wordprocessing.png"
      when "saved_search_avatar","saved_search"
      "crystal_project/32x32/actions/find.png"
      when "visit_pubmed"
      "famfamfam_silk/page_white_go.png"
      when "markup"
      "famfamfam_silk/page_white_text.png"
      when "atom_feed"
      "misc_icons/feed_icon.png"
      when "impersonate"
      "famfamfam_silk/group_go.png"
      when "partial_world"
        "misc_icons/partial_world.png"
      when "world"
      "famfamfam_silk/world.png"
      when "file_large"
      "crystal_project/32x32/apps/klaptop.png"
      when "internet_large"
      "crystal_project/32x32/devices/Globe2.png"
      when "jws_builder"
        "misc_icons/jws_builder24x24.png"
      when "event_avatar"
        "crystal_project/32x32/apps/vcalendar.png"
      when "specimen_avatar"
        "misc_icons/green_virus-64x64.png"
      when "sample_avatar"
        "misc_icons/sampleBGXblue.png"
      when "specimen", "specimens"
        "misc_icons/green_virus-64x64.png"
      when "publish"
        "famfamfam_silk/world_add.png"
      when "spreadsheet"
      "famfamfam_silk/table.png"
      when "spreadsheet_annotation"
      "famfamfam_silk/tag_blue.png"
      when "spreadsheet_annotation_edit"
      "famfamfam_silk/tag_blue_edit.png"
      when "spreadsheet_annotation_add"
      "famfamfam_silk/tag_blue_add.png"
      when "spreadsheet_annotation_destroy"
      "famfamfam_silk/tag_blue_delete.png"
      when "spreadsheet_export"
      "famfamfam_silk/table_go.png"
      when 'unsubscribe'
        "famfamfam_silk/email_delete.png"
      when 'subscribe'
        "famfamfam_silk/email_add.png"
      when 'presentation_avatar','presentation','presentations'
        "misc_icons/1315482798_presentation-slides.png"
      when 'endnote'
        "famfamfam_silk/script_go.png"
      when 'expand_plus'
        "toggle_expand_64x64.png"
      when 'collapse_minus'
        "toggle_collapse_64x64.png"
      when 'cytoscape_web'
        "famfamfam_silk/chart_line.png"
      when "graph"
        "famfamfam_silk/chart_line.png"
      when "import"
        "famfamfam_silk/page_add.png"
      when "project_manager"
        "famfamfam_silk/medal_gold_1.png"
      when "asset_manager"
        "famfamfam_silk/medal_bronze_3.png"
      when "gatekeeper"
        "famfamfam_silk/medal_silver_2.png"
      when "organise"
        "famfamfam_silk/folder.png"
      when "search"
        "famfamfam_silk/eye.png"
      when "report"
        "famfamfam_silk/report.png"
      when "jws_shadow"
        "jws/shadow2.gif"
      when "home"
        "famfamfam_silk/house.png"
      when "waiting"
        "misc_icons/waiting.png"
    else
      return nil
    end
  end

  def image key,options={}
    image_tag(icon_filename_for_key(key),options)
  end
  
  def help_icon(text, delay=200, extra_style="")
    image("info", :alt=>"help", :title=>tooltip_title_attrib(text,delay), :style => "vertical-align: middle;#{extra_style}")
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
  


    def model_image_url(model_instance, model_image_id, size=nil)
    basic_url = eval("model_model_image_path(#{model_instance.id}, #{model_image_id})")

    if size
      basic_url += "?size=#{size}"
      basic_url += "x#{size}" if size.kind_of?(Numeric)
    end

    return basic_url
    end


  
  def file_type_icon(item)
    url = file_type_icon_url(item)
    image_tag url, :class => "icon"
  end

  def file_type_icon_key(item)
    mime_icon_key item.content_blob.try :content_type
  end

  def file_type_icon_url(item)
    mime_icon_url item.content_blob.try :content_type
  end
  
  def expand_image(margin_left="0.3em")
    image_tag icon_filename_for_key("expand"), :style => "margin-left: #{margin_left}; vertical-align: middle;", :alt => 'Expand', :title=>tooltip_title_attrib("Expand for more details")
  end
  
  def collapse_image(margin_left="0.3em")
    image_tag icon_filename_for_key("collapse"), :style => "margin-left: #{margin_left}; vertical-align: middle;", :alt => 'Collapse', :title=>tooltip_title_attrib("Collapse the details")
  end
  def expand_plus_image(size="18x18")
    image_tag icon_filename_for_key("expand_plus"),:size=>size,:alt => 'Expand', :title=>tooltip_title_attrib("Expand for more details")
  end

  def collapse_minus_image(size="18x18")
    image_tag icon_filename_for_key("collapse_minus"),:size=>size,:alt => 'Collapse', :title=>tooltip_title_attrib("Collapse the details")
  end


  
end
