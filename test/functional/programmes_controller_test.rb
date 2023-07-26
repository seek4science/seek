require 'test_helper'

class ProgrammesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  include ActionView::Helpers::NumberHelper

  include RdfTestCases

  def rdf_test_object
    login_as(FactoryBot.create(:admin))
    FactoryBot.create(:programme)
  end

  # for now just admins can create programmes, later we will change this
  test 'new page accessible admin' do
    login_as(FactoryBot.create(:admin))
    get :new
    assert_response :success
  end

  test 'new page works even when no programme-less projects' do
    programme = FactoryBot.create(:programme)
    admin = FactoryBot.create(:admin, project:programme.projects.first)

    Project.without_programme.delete_all

    login_as(admin)
    get :new
    assert_response :success
  end

  test 'new page accessible to non admin' do
    login_as(FactoryBot.create(:person))
    get :new
    assert_response :success
  end

  test 'new page accessible to projectless user' do
    p = FactoryBot.create(:person_not_in_project)
    login_as(p)
    assert p.projects.empty?
    get :new
    assert_response :success
  end

  test 'new page not accessible to logged out user' do
    get :new
    assert_redirected_to login_path
  end

  test 'only admin can destroy' do
    login_as(FactoryBot.create(:person))
    prog = FactoryBot.create(:programme)
    proj = prog.projects.first
    refute_nil proj
    assert_equal prog, proj.programme
    assert_no_difference('Programme.count') do
      delete :destroy, params: { id: prog.id }
    end
    refute_nil flash[:error]
    assert_redirected_to prog
    proj.reload
    assert_equal prog, proj.programme
  end

  test 'programme admin can destroy when no projects' do
    programme_administrator = FactoryBot.create(:programme_administrator)
    login_as(programme_administrator)
    programme = programme_administrator.programmes.first

    refute_empty programme.projects
    assert programme_administrator.is_programme_administrator?(programme)

    refute programme.can_delete?

    assert_no_difference('Programme.count') do
      assert_no_difference('Role.count') do
        delete :destroy, params: { id: programme.id }
      end
    end
    refute_nil flash[:error]

    programme.projects = []
    programme.save!
    assert programme_administrator.is_programme_administrator?(programme)

    assert programme.can_delete?

    assert_difference('Programme.count', -1) do
      assert_difference('Role.count',-1) do
        delete :destroy, params: { id: programme.id }
      end
    end
    assert_redirected_to programmes_path
  end

  test 'destroy' do
    login_as(FactoryBot.create(:admin))
    prog = FactoryBot.create(:programme, projects:[])
    assert prog.can_delete?
    assert_difference('Programme.count', -1) do
      delete :destroy, params: { id: prog.id }
    end
    assert_redirected_to programmes_path

  end

  test 'admin can update' do
    login_as(FactoryBot.create(:admin))
    prog = FactoryBot.create(:programme, description: 'ggggg')
    put :update, params: { id: prog, programme: { title: 'fish' } }
    prog = assigns(:programme)
    refute_nil prog
    assert_redirected_to prog
    assert_equal 'fish', prog.title
    assert_equal 'ggggg', prog.description
  end

  test 'programme administrator can update' do
    person = FactoryBot.create(:person)
    login_as(person)
    prog = FactoryBot.create(:programme, description: 'ggggg')
    person.is_programme_administrator = true, prog
    disable_authorization_checks { person.save! }
    put :update, params: { id: prog, programme: { title: 'fish' } }
    prog = assigns(:programme)
    refute_nil prog
    assert_redirected_to prog
    assert_equal 'fish', prog.title
    assert_equal 'ggggg', prog.description
  end

  test 'normal user cannot update' do
    login_as(FactoryBot.create(:person))
    prog = FactoryBot.create(:programme, description: 'ggggg', title: 'eeeee')
    put :update, params: { id: prog, programme: { title: 'fish' } }
    assert_redirected_to prog
    assert_equal 'eeeee', prog.title
    assert_equal 'ggggg', prog.description
  end

  test 'set programme administrators at creation' do
    creator = FactoryBot.create(:person)
    login_as(creator)
    person = FactoryBot.create(:person)
    person2 = FactoryBot.create(:person)
    refute person.is_programme_administrator_of_any_programme?
    assert_difference('Role.count', 3) do # Should include creator
      assert_difference('Programme.count', 1) do
        post :create, params: { programme: { programme_administrator_ids: [person.id, person2.id], title: 'programme xxxyxxx2' } }
      end
    end

    assert prog = assigns(:programme)
    assert creator.is_programme_administrator?(prog)
    assert creator.is_programme_administrator_of_any_programme?
    assert creator.has_role?('programme_administrator')
    assert person.is_programme_administrator?(prog)
    assert person.is_programme_administrator_of_any_programme?
    assert person.has_role?('programme_administrator')
    assert person2.is_programme_administrator?(prog)
    assert person2.is_programme_administrator_of_any_programme?
    assert person2.has_role?('programme_administrator')
  end

  test 'admin sets themself as programme administrator at creation' do
    admin = FactoryBot.create(:admin)
    login_as(admin)
    refute admin.is_programme_administrator_of_any_programme?
    assert_difference('Programme.count', 1) do
      assert_difference('Role.count', 1) do
        post :create, params: { programme: { programme_administrator_ids: [admin.id], title: 'programme xxxyxxx1' } }
      end
    end

    assert prog = assigns(:programme)
    admin.reload

    assert admin.is_programme_administrator?(prog)
    assert admin.is_programme_administrator_of_any_programme?
    assert admin.has_role?('programme_administrator')
  end

  test 'programme administrator can add new administrators, but not remove themself' do
    pa = FactoryBot.create(:programme_administrator)
    login_as(pa)
    prog = pa.programmes.first
    p1 = FactoryBot.create(:person)
    p2 = FactoryBot.create(:person)
    p3 = FactoryBot.create(:person)

    assert pa.is_programme_administrator?(prog)
    refute p1.is_programme_administrator?(prog)
    refute p2.is_programme_administrator?(prog)
    refute p3.is_programme_administrator?(prog)

    ids = [p1.id, p2.id]
    put :update, params: { id: prog, programme: { programme_administrator_ids: ids } }

    assert_redirected_to prog

    pa.reload
    p1.reload
    p2.reload
    p3.reload

    assert pa.is_programme_administrator?(prog)
    assert p1.is_programme_administrator?(prog)
    assert p2.is_programme_administrator?(prog)
    refute p3.is_programme_administrator?(prog)

    assert p1.is_programme_administrator_of_any_programme?
    assert p1.has_role?('programme_administrator')
  end

  test 'admin can add new administrators, and not remove themself' do
    admin = FactoryBot.create(:programme_administrator)
    admin.is_admin = true
    disable_authorization_checks { admin.save! }
    login_as(admin)
    prog = admin.programmes.first
    p1 = FactoryBot.create(:person)
    p2 = FactoryBot.create(:person)
    p3 = FactoryBot.create(:person)

    assert admin.is_programme_administrator?(prog)
    refute p1.is_programme_administrator?(prog)
    refute p2.is_programme_administrator?(prog)
    refute p3.is_programme_administrator?(prog)

    ids = [p1.id, p2.id]
    put :update, params: { id: prog, programme: { programme_administrator_ids: ids } }

    assert_redirected_to prog

    admin.reload
    p1.reload
    p2.reload
    p3.reload

    refute admin.is_programme_administrator?(prog)
    assert p1.is_programme_administrator?(prog)
    assert p2.is_programme_administrator?(prog)
    refute p3.is_programme_administrator?(prog)
  end

  test 'edit page accessible to admin' do
    login_as(FactoryBot.create(:admin))
    p = FactoryBot.create(:programme)
    FactoryBot.create(:avatar, owner: p)
    get :edit, params: { id: p }
    assert_response :success
  end

  test 'edit page not accessible to user' do
    login_as(FactoryBot.create(:person))
    p = FactoryBot.create(:programme)
    get :edit, params: { id: p }
    assert_redirected_to p
    refute_nil flash[:error]
  end

  test 'edit page accessible to programme_administrator' do
    person = FactoryBot.create(:person)
    login_as(person)
    p = FactoryBot.create(:programme)
    person.is_programme_administrator = true, p
    disable_authorization_checks { person.save! }
    get :edit, params: { id: p }
    assert_response :success
  end

  test 'should show index' do
    p = FactoryBot.create(:programme, projects: [FactoryBot.create(:project), FactoryBot.create(:project)])
    avatar = FactoryBot.create(:avatar, owner: p)
    p.avatar = avatar
    disable_authorization_checks { p.save! }
    FactoryBot.create(:programme)

    get :index
    assert_response :success
  end

  test 'index should not show inactivated except for admin and programme admin' do
    login_as(FactoryBot.create(:admin))
    programme_admin = FactoryBot.create(:person)
    p1 = FactoryBot.create(:programme, title: 'activated programme')
    p2 = FactoryBot.create(:programme, title: 'not activated programme')
    p2.is_activated = false
    p2.save!

    p3 = FactoryBot.create(:programme, title: 'not activated or with programme administrator')
    p3.is_activated = false
    p3.save!

    programme_admin.is_programme_administrator = true, p2
    programme_admin.save!
    programme_admin = Person.find(programme_admin.id)

    assert p1.is_activated?
    refute p2.is_activated?
    refute p3.is_activated?

    refute programme_admin.is_programme_administrator?(p1)
    assert programme_admin.is_programme_administrator?(p2)
    refute programme_admin.is_programme_administrator?(p3)

    assert_includes programme_admin.administered_programmes, p2

    logout

    get :index
    assert_response :success
    assert_select 'a[href=?]', programme_path(p1), text: p1.title, count: 1
    assert_select 'a[href=?]', programme_path(p2), text: p2.title, count: 0
    assert_select 'a[href=?]', programme_path(p3), text: p3.title, count: 0
    assert_equal 1, assigns(:programmes).count

    login_as(FactoryBot.create(:person))
    get :index
    assert_response :success
    assert_select 'a[href=?]', programme_path(p1), text: p1.title, count: 1
    assert_select 'a[href=?]', programme_path(p2), text: p2.title, count: 0
    assert_select 'a[href=?]', programme_path(p3), text: p3.title, count: 0
    assert_equal 1, assigns(:programmes).count
    logout

    login_as(FactoryBot.create(:admin))
    get :index
    assert_response :success
    assert_select 'a[href=?]', programme_path(p1), text: p1.title, count: 1
    assert_select 'a[href=?]', programme_path(p2), text: p2.title, count: 1
    assert_select 'a[href=?]', programme_path(p3), text: p3.title, count: 1
    assert_equal 3, assigns(:programmes).count
    logout

    login_as(programme_admin)
    get :index
    assert_response :success
    assert_select 'a[href=?]', programme_path(p1), text: p1.title, count: 1
    assert_select 'a[href=?]', programme_path(p2), text: p2.title, count: 1
    assert_select 'a[href=?]', programme_path(p3), text: p3.title, count: 0
    assert_equal 2, assigns(:programmes).count
    logout
  end

  test 'should get show' do
    p = FactoryBot.create(:programme, projects: [FactoryBot.create(:project), FactoryBot.create(:project)])
    avatar = FactoryBot.create(:avatar, owner: p)
    p.avatar = avatar
    disable_authorization_checks { p.save! }

    get :show, params: { id: p }
    assert_response :success
  end

  test 'update to default avatar' do
    p = FactoryBot.create(:programme, projects: [FactoryBot.create(:project), FactoryBot.create(:project)])
    avatar = FactoryBot.create(:avatar, owner: p)
    p.avatar = avatar
    disable_authorization_checks { p.save! }
    login_as(FactoryBot.create(:admin))
    put :update, params: { id: p, programme: { avatar_id: '0' } }
    prog = assigns(:programme)
    refute_nil prog
    assert_nil prog.avatar
  end

  test 'can be disabled' do
    p = FactoryBot.create(:programme, projects: [FactoryBot.create(:project), FactoryBot.create(:project)])
    with_config_value :programmes_enabled, false do
      get :show, params: { id: p }
      assert_redirected_to :root
      refute_nil flash[:error]
    end
  end

  test 'user can create programme, and becomes programme administrator' do
    p = FactoryBot.create(:person)
    login_as(p)
    with_config_value(:email_enabled, true) do
      assert_difference('Programme.count') do
        assert_enqueued_emails(1) do # activation email
          post :create, params: { programme: { title: 'A programme', funding_codes: ['','aaa','bbb'], web_page: '', description: '', funding_details: '' } }
        end
      end
    end
    prog = assigns(:programme)
    assert_empty prog.errors
    assert_redirected_to prog
    p.reload
    assert p.is_programme_administrator?(prog)
    assert_equal 2, prog.funding_codes.length
    assert_includes prog.funding_codes, 'aaa'
    assert_includes prog.funding_codes, 'bbb'
  end

  test "admin doesn't become programme administrator by default" do
    p = FactoryBot.create(:admin)
    login_as(p)
    with_config_value(:email_enabled, true) do
      assert_difference('Programme.count') do
        assert_no_enqueued_emails do # no email for admin creation
          post :create, params: { programme: { title: 'A programme' } }
        end
      end
    end
    prog = assigns(:programme)
    assert_redirected_to prog
    p.reload
    refute p.is_programme_administrator?(prog)
  end

  test 'logged out user cannot create' do
    assert_no_difference('Programme.count') do
      post :create, params: { programme: { title: 'A programme' } }
    end
    assert_redirected_to login_path
  end

  test 'activation review available to admin' do
    programme = FactoryBot.create(:programme)
    programme.is_activated = false
    disable_authorization_checks { programme.save! }
    refute programme.is_activated?
    login_as(FactoryBot.create(:admin))
    get :activation_review, params: { id: programme }
    assert_response :success
    assert_nil flash[:error]
  end

  test 'activation review not available none admin' do
    person = FactoryBot.create(:programme_administrator)
    programme = person.programmes.first
    programme.is_activated = false
    disable_authorization_checks { programme.save! }
    refute programme.is_activated?
    login_as(person)
    get :activation_review, params: { id: programme }
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test 'activation review not available if active' do
    programme = FactoryBot.create(:programme)
    login_as(FactoryBot.create(:admin))
    programme.activate
    assert programme.is_activated?
    get :activation_review, params: { id: programme }
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test 'accept_activation' do
    programme_administrator = FactoryBot.create(:programme_administrator)
    programme = programme_administrator.programmes.first
    programme.is_activated = false
    disable_authorization_checks { programme.save! }
    refute programme.is_activated?
    login_as(FactoryBot.create(:admin))

    with_config_value(:email_enabled, true) do
      assert_enqueued_emails(1) do
        put :accept_activation, params: { id: programme }
      end
    end

    assert_redirected_to programme
    refute_nil flash[:notice]
    assert_nil flash[:error]
    programme.reload
    assert programme.is_activated?
  end

  test 'no accept_activation for none admin' do
    programme_administrator = FactoryBot.create(:programme_administrator)
    programme = programme_administrator.programmes.first
    programme.is_activated = false
    disable_authorization_checks { programme.save! }
    refute programme.is_activated?
    login_as(programme_administrator)

    with_config_value(:email_enabled, true) do
      assert_no_enqueued_emails do
        put :accept_activation, params: { id: programme }
      end
    end

    assert_redirected_to :root
    assert_nil flash[:notice]
    refute_nil flash[:error]
    programme.reload
    refute programme.is_activated?
  end

  test 'no accept_activation for not activated' do
    programme_administrator = FactoryBot.create(:programme_administrator)
    programme = programme_administrator.programmes.first

    assert programme.is_activated?
    login_as(FactoryBot.create(:admin))

    with_config_value(:email_enabled, true) do
      assert_no_enqueued_emails do
        put :accept_activation, params: { id: programme }
      end
    end

    assert_redirected_to :root
    assert_nil flash[:notice]
    refute_nil flash[:error]
    programme.reload
    assert programme.is_activated?
  end

  test 'reject activation confirmation' do
    programme_administrator = FactoryBot.create(:programme_administrator)
    programme = programme_administrator.programmes.first
    programme.is_activated = false
    disable_authorization_checks { programme.save! }
    refute programme.is_activated?
    login_as(FactoryBot.create(:admin))

    get :reject_activation_confirmation, params: { id: programme }
    assert_response :success
    assert assigns(:programme)
  end

  test 'no reject activation confirmation for already activated' do
    programme_administrator = FactoryBot.create(:programme_administrator)
    programme = programme_administrator.programmes.first

    assert programme.is_activated?
    login_as(FactoryBot.create(:admin))

    get :reject_activation_confirmation, params: { id: programme }
    assert_redirected_to :root
    assert_nil flash[:notice]
    refute_nil flash[:error]
  end

  test 'no reject activation confirmation for none admin' do
    programme_administrator = FactoryBot.create(:programme_administrator)
    programme = programme_administrator.programmes.first
    programme.is_activated = false
    disable_authorization_checks { programme.save! }
    refute programme.is_activated?
    login_as(programme_administrator)

    get :reject_activation_confirmation, params: { id: programme }
    assert_redirected_to :root
    assert_nil flash[:notice]
    refute_nil flash[:error]
  end

  test 'reject_activation' do
    programme_administrator = FactoryBot.create(:programme_administrator)
    programme = programme_administrator.programmes.first
    programme.is_activated = false
    disable_authorization_checks { programme.save! }
    refute programme.is_activated?
    login_as(FactoryBot.create(:admin))

    with_config_value(:email_enabled, true) do
      assert_enqueued_emails(1) do
        put :reject_activation, params: { id: programme, programme: { activation_rejection_reason: 'rejection reason' } }
      end
    end

    assert_redirected_to programme
    refute_nil flash[:notice]
    assert_nil flash[:error]
    programme.reload
    refute programme.is_activated?
    assert_equal 'rejection reason', programme.activation_rejection_reason
  end

  test 'no reject activation for none admin' do
    programme_administrator = FactoryBot.create(:programme_administrator)
    programme = programme_administrator.programmes.first
    programme.is_activated = false
    disable_authorization_checks { programme.save! }
    refute programme.is_activated?
    login_as(programme_administrator)

    with_config_value(:email_enabled, true) do
      assert_no_enqueued_emails do
        put :reject_activation, params: { id: programme, programme: { activation_rejection_reason: 'rejection reason' } }
      end
    end

    assert_redirected_to :root
    assert_nil flash[:notice]
    refute_nil flash[:error]
    programme.reload
    refute programme.is_activated?
    assert_nil programme.activation_rejection_reason
  end

  test 'no reject_activation for not activated' do
    programme_administrator = FactoryBot.create(:programme_administrator)
    programme = programme_administrator.programmes.first

    assert programme.is_activated?
    login_as(FactoryBot.create(:admin))

    with_config_value(:email_enabled, true) do
      assert_no_enqueued_emails do
        put :reject_activation, params: { id: programme, programme: { activation_rejection_reason: 'rejection reason' } }
      end
    end

    assert_redirected_to :root
    assert_nil flash[:notice]
    refute_nil flash[:error]
    programme.reload
    assert programme.is_activated?
    assert_nil programme.activation_rejection_reason
  end

  test 'none activated programme only available to administrators' do
    programme_administrator = FactoryBot.create(:programme_administrator)
    programme = programme_administrator.programmes.first
    programme.is_activated = false
    disable_authorization_checks { programme.save! }
    refute programme.is_activated?

    get :show, params: { id: programme }
    assert_redirected_to :root
    refute_nil flash[:error]
    clear_flash(:error)

    login_as(programme_administrator)
    get :show, params: { id: programme }
    assert_response :success
    assert_nil flash[:error]
    logout
    clear_flash(:error)

    login_as(FactoryBot.create(:admin))
    get :show, params: { id: programme }
    assert_response :success
    assert_nil flash[:error]
    logout
    clear_flash(:error)

    login_as(FactoryBot.create(:person))
    get :show, params: { id: programme }
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test 'awaiting activation' do
    login_as(FactoryBot.create(:admin))
    Programme.destroy_all
    prog_not_activated = FactoryBot.create(:programme)
    prog_not_activated.is_activated = false
    prog_not_activated.save!

    prog_rejected = FactoryBot.create(:programme)
    prog_rejected.is_activated = false
    prog_rejected.activation_rejection_reason = 'xxx'
    prog_rejected.save!

    prog_normal = FactoryBot.create(:programme)

    refute prog_not_activated.is_activated?
    refute prog_rejected.is_activated?
    assert prog_normal.is_activated?

    refute prog_not_activated.rejected?
    assert prog_rejected.rejected?
    refute prog_normal.rejected?

    get :awaiting_activation
    assert_response :success

    assert_includes assigns(:not_activated), prog_not_activated
    refute_includes assigns(:not_activated), prog_rejected
    refute_includes assigns(:not_activated), prog_normal

    assert_includes assigns(:rejected), prog_rejected
    refute_includes assigns(:rejected), prog_not_activated
    refute_includes assigns(:rejected), prog_normal
  end

  test 'awaiting for activation blocked for none admin' do
    programme_administrator = FactoryBot.create(:programme_administrator)
    normal = FactoryBot.create(:person)

    login_as(programme_administrator)
    get :awaiting_activation
    assert_redirected_to :root
    refute_nil flash[:error]
    logout
    clear_flash(:error)

    login_as(normal)
    get :awaiting_activation
    assert_redirected_to :root
    refute_nil flash[:error]
    logout
    clear_flash(:error)
  end

  test 'can get storage usage' do
    programme_administrator = FactoryBot.create(:programme_administrator)
    programme = programme_administrator.programmes.first
    data_file = FactoryBot.create(:data_file, project_ids: [programme.projects.first.id])
    size = data_file.content_blob.file_size
    assert size > 0

    login_as(programme_administrator)
    get :storage_report, params: { id: programme.id }

    assert_response :success
    assert_nil flash[:error]
    assert_select 'strong', text: number_to_human_size(size)
  end

  test 'non admin cannot get storage usage' do
    programme_administrator = FactoryBot.create(:programme_administrator)
    normal = FactoryBot.create(:person)
    programme = programme_administrator.programmes.first

    login_as(normal)
    get :storage_report, params: { id: programme.id }
    assert_redirected_to programme_path(programme)
    refute_nil flash[:error]
  end

  test 'storage usage list limits to first 10' do
    programme_administrator = FactoryBot.create(:programme_administrator)
    programme = programme_administrator.programmes.first
    12.times do
      project = FactoryBot.create(:project, programme: programme)
      FactoryBot.create(:data_file, project_ids: [project.id])
    end

    project_count = programme.projects.count
    size = programme.projects.last.data_files.first.content_blob.file_size
    total_size = size * 12

    login_as(programme_administrator)
    get :storage_report, params: { id: programme.id }

    assert_response :success
    assert_nil flash[:error]
    assert_select 'strong', text: number_to_human_size(total_size)
    assert_select 'ul.collapsed li.hidden-item', count: (project_count - 10)
  end

  test 'admin can add and remove funding codes' do
    login_as(FactoryBot.create(:admin))
    prog = FactoryBot.create(:programme)

    assert_difference('Annotation.count', 2) do
      put :update, params: { id: prog, programme: { funding_codes: ['1234','abcd'] } }
    end

    assert_redirected_to prog

    assert_equal 2, assigns(:programme).funding_codes.length
    assert_includes assigns(:programme).funding_codes, '1234'
    assert_includes assigns(:programme).funding_codes, 'abcd'

    assert_difference('Annotation.count', -2) do
      put :update, params: { id: prog, programme: { funding_codes: [''] } }
    end

    assert_redirected_to prog

    assert_equal 0, assigns(:programme).funding_codes.length
  end

  test 'should create with discussion link' do
    person = FactoryBot.create(:admin)
    login_as(person)
    assert_difference('AssetLink.discussion.count') do
      assert_difference('Programme.count') do
        post :create, params: { programme: { title: 'test',
                                             programme_administrator_ids: [person.id],
                                         discussion_links_attributes: [{url: "http://www.slack.com/"}]}}
      end
    end
    programme = assigns(:programme)
    assert_equal 'http://www.slack.com/', programme.discussion_links.first.url
    assert_equal AssetLink::DISCUSSION, programme.discussion_links.first.link_type
  end

  test 'should show discussion link' do
    disc_link = FactoryBot.create(:discussion_link)
    programme = FactoryBot.create(:programme)
    programme.discussion_links = [disc_link]
    get :show, params: { id: programme }
    assert_response :success
    assert_select 'div.panel-heading', text: /Discussion Channel/, count: 1
  end

  test 'should update node with discussion link' do
    person = FactoryBot.create(:admin)
    login_as(person)
    programme = FactoryBot.create(:programme)
    programme.programme_administrator_ids = [person.id]
    assert_nil programme.discussion_links.first
    assert_difference('AssetLink.discussion.count') do
      # assert_difference('ActivityLog.count') do
        put :update, params: { id: programme.id, programme: { discussion_links_attributes: [{url: "http://www.slack.com/"}] } }
      # end
    end
    assert_redirected_to programme_path(assigns(:programme))
    assert_equal 'http://www.slack.com/', programme.discussion_links.first.url
  end

  test 'should destroy related assetlink when the discussion link is removed ' do
    person = FactoryBot.create(:admin)
    login_as(person)
    asset_link = FactoryBot.create(:discussion_link)
    programme = FactoryBot.create(:programme)
    programme.programme_administrator_ids = [person.id]
    programme.discussion_links = [asset_link]
    assert_difference('AssetLink.discussion.count', -1) do
      put :update, params: { id: programme.id, programme: { discussion_links_attributes:[{id:asset_link.id, _destroy:'1'}] } }
    end
    assert_redirected_to programme_path(programme = assigns(:programme))
    assert_empty programme.discussion_links
  end

  test 'hide open for projects if disabled' do
    person = FactoryBot.create(:admin)
    login_as(person)
    programme = FactoryBot.create(:programme)
    programme.programme_administrator_ids = [person.id]
    programme.save!
    with_config_value :programmes_open_for_projects_enabled, false do
      get :new
      assert_response :success
      assert_select 'input#programme_open_for_projects', count: 0

      get :edit, params: {id: programme}
      assert_response :success
      assert_select 'input#programme_open_for_projects', count: 0
    end
  end

  test 'sample type programmes through nested routing' do
    assert_routing 'sample_types/2/programmes', controller: 'programmes', action: 'index', sample_type_id: '2'
    programme = FactoryBot.create(:programme)
    programme2 = FactoryBot.create(:programme, projects: [FactoryBot.create(:project)])
    sample_type = FactoryBot.create(:patient_sample_type, projects:[programme.projects.first])

    get :index, params: { sample_type_id: sample_type.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', programme_path(programme), text: programme.title
      assert_select 'a[href=?]', programme_path(programme2), text: programme2.title, count: 0
    end
  end

  test 'people programmes through nested routing' do
    assert_routing 'people/2/programmes', controller: 'programmes', action: 'index', person_id: '2'
    admin = FactoryBot.create(:admin)
    person = FactoryBot.create(:programme_administrator)
    programme = person.programmes.first
    project = FactoryBot.create(:project)
    person.add_to_project_and_institution(project, FactoryBot.create(:institution))
    programme2 = FactoryBot.create(:programme, projects: [project])
    programme3 = FactoryBot.create(:programme)
    person.save!
    person.reload
    assert_equal [programme, programme2], person.related_programmes

    get :index, params: { person_id: person.id }
    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', programme_path(programme), text: programme.title
      assert_select 'a[href=?]', programme_path(programme2), text: programme2.title
      assert_select 'a[href=?]', programme_path(programme3), text: programme3.title, count: 0
    end

    # inactive should be hidden from non admins
    programme.update_column(:is_activated, false)

    get :index, params: { person_id: person.id }
    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', programme_path(programme), text: programme.title, count: 0
      assert_select 'a[href=?]', programme_path(programme2), text: programme2.title
      assert_select 'a[href=?]', programme_path(programme3), text: programme3.title, count: 0
    end

    login_as(person)
    get :index, params: { person_id: person.id }
    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', programme_path(programme), text: programme.title
      assert_select 'a[href=?]', programme_path(programme2), text: programme2.title
      assert_select 'a[href=?]', programme_path(programme3), text: programme3.title, count: 0
    end

    login_as(admin)
    get :index, params: { person_id: person.id }
    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', programme_path(programme), text: programme.title
      assert_select 'a[href=?]', programme_path(programme2), text: programme2.title
      assert_select 'a[href=?]', programme_path(programme3), text: programme3.title, count: 0
    end
  end

  test 'Empty programmes should show programme administrators as related people' do
    person1 = FactoryBot.create(:programme_administrator_not_in_project)
    person2 = FactoryBot.create(:programme_administrator_not_in_project)
    prog1 = FactoryBot.create(:min_programme, programme_administrators: [person1, person2])

    assert person1.projects.empty?

    get :show, params: { id: prog1.id }
    assert_response :success

    assert_select 'h2', text: /Related items/i
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item' do
        assert_select 'div.list_item_title' do
          assert_select 'a[href=?]', person_path(person1), text: person1.title
          assert_select 'a[href=?]', person_path(person2), text: person2.title
        end
      end
    end
  end
end
