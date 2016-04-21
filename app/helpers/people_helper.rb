module PeopleHelper

  def can_create_profiles?
    Person.can_create?
  end

  def contact_details_warning_message
    msg = "This information is only visible to other people whom you share a #{t('project')}"
    msg << " or #{t('programme')}" if Seek::Config.programmes_enabled
    msg << "."
    msg
  end

  def person_list_item_extra_details? person
    !(person.projects.empty? and person.institutions.empty?)  
  end

  #tag for displaying an image if person that has no user associated - but is only displayed if the current user is an admin
  def no_user_for_admins_img person
    if (!person.user && admin_logged_in?)
      return image_tag_for_key("no_user",nil,"No associated user",nil,"")
    end
  end

  def seek_role_icons person, size = 32
    icons = ''
    person.roles.each do |role|
      icons << image("#{role}", :size => "#{size}x#{size}", :alt=>"#{role}",
                     'data-tooltip' => tooltip(role.humanize), :style=>"vertical-align: middle")
    end
    icons.html_safe
  end

  def orcid_identifier person
    uri = person.orcid_uri
    unless uri.blank?
      uri = link_to(uri,uri,:target=>"_blank").html_safe
    end
    uri.blank? ? text_or_not_specified(uri) : uri
  end

  def discipline_list person
    unless person.disciplines.empty?
      text=""
      person.disciplines.each do |d|
        text += link_to(h(d.title),people_path(:discipline_id=>d.id))
        text += ", " unless person.disciplines.last==d
      end
    else
      text="<span class='none_text'>None specified</span>"
    end
    return text.html_safe
  end

  def project_position_list person
    unless person.project_positions.empty?
      text=""
      person.project_positions.each do |r|
        text += link_to(h(r.title),people_path(:project_position_id=>r.id))
        text += ", " unless person.project_positions.last==r
      end
    else
      text="<span class='none_text'>None specified</span>"
    end
    return text.html_safe
  end

  def admin_defined_project_roles_hash
    roles = Seek::Roles::ProjectRelatedRoles.role_names.map do |role|
      [role,t(role)]
    end
    roles = Hash[roles]

    roles.delete("pal") unless admin_logged_in?
    roles
  end

  #Return whether or not to hide contact details from this user
  #Current decided by Seek::Config.hide_details_enabled or
  # is hidden if the current person doesn't share the same programme as the person being viewed
  def hide_contact_details? displayed_person_or_project
    return true if Seek::Config.hide_details_enabled || !logged_in?
    !current_user.person.shares_project_or_programme?(displayed_person_or_project)
  end

end
