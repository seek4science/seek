require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase

  test 'persistent_resource_id' do
    assay = Factory(:assay)
    html = persistent_resource_id(assay)
    blocks = Nokogiri::HTML::DocumentFragment.parse(html).children.first.children
    # should be something like
    # <p class="id">
    #   <label>SEEK ID: </label>
    #   <a href="http://localhost:3000/assays/1035386651">http://localhost:3000/assays/1035386651</a>
    # </p>
    assert_equal 'strong', blocks.first.name
    assert_match(/SEEK ID/, blocks.first.children.first.content)
    assert_equal 'a', blocks.last.name
    assert_match(/http:\/\/localhost:3000\/assays\/#{assay.id}/, blocks.last['href'])
    assert_match(/http:\/\/localhost:3000\/assays\/#{assay.id}/, blocks.last.children.first.content)

    versioned_sop = Factory(:sop_version)
    html = persistent_resource_id(versioned_sop)
    blocks = Nokogiri::HTML::DocumentFragment.parse(html).children.first.children
    # should be something like
    # <p class="id">
    #   <label>SEEK ID: </label>
    #   <a href="http://localhost:3000/sops/1055250457?version=2">http://localhost:3000/sops/1055250457?version=2</a>
    # </p>
    assert_equal 'strong', blocks.first.name
    assert_match(/SEEK ID/, blocks.first.children.first.content)
    assert_equal 'a', blocks.last.name
    assert_match(/http:\/\/localhost:3000\/sops\/#{versioned_sop.parent.id}\?version=#{versioned_sop.version}/, blocks.last['href'])
    assert_match(/http:\/\/localhost:3000\/sops\/#{versioned_sop.parent.id}\?version=#{versioned_sop.version}/, blocks.last.children.first.content)

    # handles sub uri
    with_config_value(:site_base_host, 'http://seek.org/fish') do
      html = persistent_resource_id(assay)
      blocks = Nokogiri::HTML::DocumentFragment.parse(html).children.first.children
      assert_equal 'strong', blocks.first.name
      assert_match(/SEEK ID/, blocks.first.children.first.content)
      assert_equal 'a', blocks.last.name
      assert_match(/http:\/\/seek.org\/fish\/assays\/#{assay.id}/, blocks.last['href'])
      assert_match(/http:\/\/seek.org\/fish\/assays\/#{assay.id}/, blocks.last.children.first.content)

      html = persistent_resource_id(versioned_sop)
      blocks = Nokogiri::HTML::DocumentFragment.parse(html).children.first.children
      assert_equal 'strong', blocks.first.name
      assert_match(/SEEK ID/, blocks.first.children.first.content)
      assert_equal 'a', blocks.last.name
      assert_match(/http:\/\/seek.org\/fish\/sops\/#{versioned_sop.parent.id}\?version=#{versioned_sop.version}/, blocks.last['href'])
      assert_match(/http:\/\/seek.org\/fish\/sops\/#{versioned_sop.parent.id}\?version=#{versioned_sop.version}/, blocks.last.children.first.content)
    end

  end

  def test_join_with_and
    assert_equal 'a, b and c', join_with_and(%w[a b c])
    assert_equal 'a', join_with_and(['a'])
    assert_equal 'a, b, c and d', join_with_and(%w[a b c d])
    assert_equal 'a and b', join_with_and(%w[a b])
    assert_equal 'a: b: c and d', join_with_and(%w[a b c d], ': ')
  end

  test 'instance of resource_type' do
    m = instance_of_resource_type('model')
    assert m.is_a?(Model)
    assert m.new_record?

    p = instance_of_resource_type('Presentation')
    assert p.is_a?(Presentation)
    assert p.new_record?

    assert_nil instance_of_resource_type(nil)
    assert_nil instance_of_resource_type('mushypeas')
    assert_nil instance_of_resource_type({})
  end

  test 'force to treat 1 Jan as year only' do
    date = Date.new(2012, 1, 1)
    text = date_as_string(date, false, true)
    assert_equal '2012', text

    date = Date.new(2012, 2, 1)
    text = date_as_string(date, false, true)
    assert_equal '1st Feb 2012', text

    date = Date.new(2012, 1, 2)
    text = date_as_string(date, false, true)
    assert_equal '2nd Jan 2012', text
  end

  test 'seek stylesheet tag' do
    with_config_value :css_appended, 'fish' do
      with_config_value :css_prepended, 'apple' do
        tags = seek_stylesheet_tags 'carrot'
        assert_includes tags, '<link rel="stylesheet" media="screen" href="/stylesheets/prepended/apple.css" />'
        assert_includes tags, '<link rel="stylesheet" media="screen" href="/stylesheets/carrot.css" />'
        assert_includes tags, '<link rel="stylesheet" media="screen" href="/stylesheets/appended/fish.css" />'
        assert tags.index('fish.css') > tags.index('carrot.css')
        assert tags.index('carrot.css') > tags.index('apple.css')
        refute_equal 0, tags.index('apple.css')
      end
    end
  end

  test 'seek javascript tag' do
    with_config_value :javascript_appended, 'fish' do
      with_config_value :javascript_prepended, 'apple' do
        tags = seek_javascript_tags 'carrot'
        assert_includes tags, '<script src="/javascripts/prepended/apple.js"></script>'
        assert_includes tags, '<script src="/javascripts/carrot.js"></script>'
        assert_includes tags, '<script src="/javascripts/appended/fish.js"></script>'
        assert tags.index('fish.js') > tags.index('carrot.js')
        assert tags.index('carrot.js') > tags.index('apple.js')
        refute_equal 0, tags.index('apple.js')
      end
    end
  end

  test 'should handle nil date' do
    text = date_as_string(nil)
    assert_equal "<span class='none_text'>No date defined</span>", text

    text = date_as_string(nil, false, true)
    assert_equal "<span class='none_text'>No date defined</span>", text

    text = date_as_string(nil, true, true)
    assert_equal "<span class='none_text'>No date defined</span>", text
  end

  test 'showing local time instead of GMT/UTC for date_as_string' do
    sop = Factory(:sop)
    created_at = sop.created_at

    assert created_at.utc?
    assert created_at.gmt?

    local_created_at = created_at.localtime
    assert !local_created_at.utc?
    assert !local_created_at.gmt?

    assert date_as_string(created_at, true).include?(local_created_at.strftime('%H:%M'))
  end

  test 'date_as_string with Date or DateTime' do
    date = DateTime.parse('2011-10-28')
    assert_equal '28th Oct 2011', date_as_string(date)

    date = Date.new(2011, 10, 28)
    assert_equal '28th Oct 2011', date_as_string(date)

    date = Time.parse('2011-10-28')
    assert_equal '28th Oct 2011', date_as_string(date)
  end

  test 'date_as_string with nil date' do
    assert_equal "<span class='none_text'>No date defined</span>", date_as_string(nil)
  end

  test 'resource tab title' do
    assert_equal 'EBI Biomodels', internationalized_resource_name('EBI Biomodels', true)
    assert_equal 'Database', internationalized_resource_name('Database', false)
    assert_equal I18n.t('model').pluralize, internationalized_resource_name('Model')
    assert_equal I18n.t('data_file').pluralize, internationalized_resource_name('DataFile')
    assert_equal I18n.t('data_file').pluralize, internationalized_resource_name('DataFiles')
    assert_equal I18n.t('data_file'), internationalized_resource_name('DataFile', false)
    assert_equal I18n.t('sop').pluralize, internationalized_resource_name('SOP')
    assert_equal I18n.t('sop').pluralize, internationalized_resource_name('Sop')
    assert_equal I18n.t('sop'), internationalized_resource_name('Sop', false)
  end

  test 'using_docker?' do
    path = Seek::Docker::FLAG_FILE_PATH
    assert_equal path, File.join(Rails.root, 'config', 'using-docker')
    begin
      refute File.exist?(path)
      refute using_docker?
      FileUtils.touch(path)
      assert using_docker?
    rescue
      raise e
    ensure
      File.delete(path)
      refute File.exist?(path)
    end
  end

  test 'show form manage attributes' do
    @controller.action_name = 'edit'
    refute show_form_manage_specific_attributes?

    @controller.action_name = 'update'
    refute show_form_manage_specific_attributes?

    @controller.action_name = 'new'
    assert show_form_manage_specific_attributes?

    @controller.action_name = 'manage'
    assert show_form_manage_specific_attributes?

    @controller.action_name = 'create'
    assert show_form_manage_specific_attributes?
  end

  test 'pending_project_join_request?' do
    person1 = Factory(:project_administrator)
    project1 = person1.projects.first

    # person2 is a project admin, and also a member but not an admin of the project with a log pending
    person2 = Factory(:project_administrator)
    person2.add_to_project_and_institution(project1,Factory(:institution))
    person2.save!

    person3 = Factory(:person)

    log = ProjectMembershipMessageLog.log_request(sender:Factory(:person), project:project1, institution:Factory(:institution))

    User.with_current_user(person3.user) do
      refute pending_project_join_request?
    end

    User.with_current_user(person2.user) do
      refute pending_project_join_request?
    end

    User.with_current_user(person1.user) do
      assert pending_project_join_request?
      log.respond('Done')
      refute pending_project_join_request?
    end

  end

  test 'pending project creation request?' do
    admin = Factory(:admin)
    prog_admin = Factory(:programme_administrator)
    programme = prog_admin.programmes.first
    person = Factory(:person)
    unregistered_user = Factory(:brand_new_user)
    assert_nil unregistered_user.person
    institution = Factory(:institution)
    project = Project.new(title:'new project')

    MessageLog.delete_all
    # creating just a project, admins notified
    ProjectCreationMessageLog.log_request(sender:person, project:project, institution:institution)
    User.with_current_user(person.user) do
      refute pending_project_creation_request?
    end
    User.with_current_user(prog_admin.user) do
      refute pending_project_creation_request?
    end
    User.with_current_user(admin.user) do
      assert pending_project_creation_request?
    end
    User.with_current_user(nil) do
      refute pending_project_creation_request?
    end
    User.with_current_user(unregistered_user) do
      refute pending_project_creation_request?
    end

    # creating a project with a plain programme - prog admins notified
    MessageLog.delete_all
    ProjectCreationMessageLog.log_request(sender:person, programme:programme, project:project, institution:institution)
    User.with_current_user(person.user) do
      refute pending_project_creation_request?
    end
    User.with_current_user(prog_admin.user) do
      assert pending_project_creation_request?
    end
    User.with_current_user(admin.user) do
      refute pending_project_creation_request?
    end
    User.with_current_user(nil) do
      refute pending_project_creation_request?
    end
    User.with_current_user(unregistered_user) do
      refute pending_project_creation_request?
    end

    # creating a project with a managed programme - prog admins and admins notified
    MessageLog.delete_all
    ProjectCreationMessageLog.log_request(sender:person, programme:programme, project:project, institution:institution)
    with_config_value(:managed_programme_id, programme.id) do
      assert programme.site_managed?
      User.with_current_user(person.user) do
        refute pending_project_creation_request?
      end
      User.with_current_user(prog_admin.user) do
        assert pending_project_creation_request?
      end
      User.with_current_user(admin.user) do
        assert pending_project_creation_request?
      end
      User.with_current_user(nil) do
        refute pending_project_creation_request?
      end
      User.with_current_user(unregistered_user) do
        refute pending_project_creation_request?
      end
    end

    # new programme, admins notified
    MessageLog.delete_all
    ProjectCreationMessageLog.log_request(sender:person, programme:Programme.new(title: 'new'), project:project, institution:institution)
    User.with_current_user(person.user) do
      refute pending_project_creation_request?
    end
    User.with_current_user(prog_admin.user) do
      refute pending_project_creation_request?
    end
    User.with_current_user(admin.user) do
      assert pending_project_creation_request?
    end
    User.with_current_user(nil) do
      refute pending_project_creation_request?
    end
    User.with_current_user(unregistered_user) do
      refute pending_project_creation_request?
    end
    
  end
  
end
