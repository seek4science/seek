module ProgrammesHelper
  def list_item_programme_attribute(project)
    html = content_tag :p, class: 'list_item_attribute' do
      label = content_tag :b do
        t('programme')
      end
      label + ': ' + programme_link(project)
    end
    html.html_safe
  end

  def programme_administrators_input_box(programme)
    administrators = programme.programme_administrators
    box = ''
    unless User.admin_logged_in?
      administrators.delete(User.current_user.person)
      box << content_tag(:p) do
        "Below you can add or remove additional administrators.
         You cannot remove yourself, to remove yourself first add another administrator and then ask them to remove you.
         This is to protect against a #{t('programme')} having no administrators"
      end
    end
    box << objects_input('programme[administrator_ids]', administrators, typeahead: { values: Person.all.map { |p| { id: p.id, name: p.name, hint: p.typeahead_hint } } })
    box.html_safe
  end

  def programme_administrator_link_list(programme)
    link_list_for_role("#{t('programme')} Administrator", programme.programme_administrators, 'programme')
  end


  def can_create_programmes?
    Programme.can_create?
  end
end
