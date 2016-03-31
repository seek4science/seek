require 'test_helper'

class ProgrammesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper
  include ActionView::Helpers::NumberHelper

  #this is needed to ensure the first user exists as admin, to stop it being automatically created as no fixtures are used.
  def setup
    Factory(:admin)
  end

  #for now just admins can create programmes, later we will change this
  test "new page accessible admin" do
    login_as(Factory(:admin))
    get :new
    assert_response :success
  end

  test "new page works even when no programme-less projects" do
    programme = Factory(:programme)
    work_group = Factory(:work_group, :project => programme.projects.first)
    admin = Factory(:admin, :group_memberships => [Factory(:group_membership, :work_group => work_group)])

    Project.without_programme.delete_all

    login_as(admin)
    get :new
    assert_response :success
  end

  test "new page accessible to non admin" do
    login_as(Factory(:person))
    get :new
    assert_response :success
  end

  test "new page accessible to projectless user" do
    p = Factory(:person_not_in_project)
    login_as(p)
    assert p.projects.empty?
    get :new
    assert_response :success
  end

  test "new page not accessible to logged out user" do
    get :new
    assert_redirected_to :root
  end

  test "only admin can destroy" do
    login_as(Factory(:person))
    prog = Factory(:programme)
    proj = prog.projects.first
    refute_nil proj
    assert_equal prog,proj.programme
    assert_no_difference("Programme.count") do
      delete :destroy,:id=>prog.id
    end
    refute_nil flash[:error]
    assert_redirected_to prog
    proj.reload
    assert_equal prog,proj.programme
  end

  test "destroy" do
    login_as(Factory(:admin))
    prog = Factory(:programme)
    proj = prog.projects.first
    refute_nil proj
    assert_equal prog,proj.programme
    assert_difference("Programme.count",-1) do
      delete :destroy,:id=>prog.id
    end
    assert_redirected_to programmes_path
    proj.reload
    assert_nil proj.programme
    assert_nil proj.programme_id
  end

  test "admin can update" do
    login_as(Factory(:admin))
    prog = Factory(:programme,:description=>"ggggg")
    put :update, :id=>prog, :programme=>{:title=>"fish"}
    prog = assigns(:programme)
    refute_nil prog
    assert_redirected_to prog
    assert_equal "fish",prog.title
    assert_equal "ggggg",prog.description
  end

  test "programme administrator can update" do
    person = Factory(:person)
    login_as(person)
    prog = Factory(:programme,:description=>"ggggg")
    person.is_programme_administrator=true,prog
    disable_authorization_checks{person.save!}
    put :update, :id=>prog, :programme=>{:title=>"fish"}
    prog = assigns(:programme)
    refute_nil prog
    assert_redirected_to prog
    assert_equal "fish",prog.title
    assert_equal "ggggg",prog.description
  end

  test "normal user cannot update" do
    login_as(Factory(:person))
    prog = Factory(:programme,:description=>"ggggg",:title=>"eeeee")
    put :update, :id=>prog, :programme=>{:title=>"fish"}
    assert_redirected_to prog
    assert_equal "eeeee",prog.title
    assert_equal "ggggg",prog.description
  end

  test "set programme administrator at creation" do
    admin = Factory(:admin)
    login_as(admin)
    person = Factory(:person)
    refute person.is_programme_administrator_of_any_programme?
    assert_difference('Programme.count',1) do
      assert_difference('AdminDefinedRoleProgramme.count',1) do
        post :create, :programme=>{:administrator_ids=>[person.id],:title=>"programme xxxyxxx2"}
      end
    end

    assert prog=assigns(:programme)
    person.reload
    assert person.is_programme_administrator?(prog)
    assert person.is_programme_administrator_of_any_programme?
    assert person.has_role?('programme_administrator')
    assert person.roles_mask & Seek::Roles::Roles.instance.mask_for_role('programme_administrator')

  end

  test "admin sets themself as programme administrator at creation" do
    admin = Factory(:admin)
    login_as(admin)
    refute admin.is_programme_administrator_of_any_programme?
    assert_difference('Programme.count',1) do
      assert_difference('AdminDefinedRoleProgramme.count',1) do
        post :create, :programme=>{:administrator_ids=>[admin.id],:title=>"programme xxxyxxx1"}
      end
    end

    assert prog=assigns(:programme)
    admin.reload

    assert admin.is_programme_administrator?(prog)
    assert admin.is_programme_administrator_of_any_programme?
    assert admin.has_role?('programme_administrator')
    assert admin.roles_mask & Seek::Roles::Roles.instance.mask_for_role('programme_administrator')

  end

  test "programme administrator can add new administrators, but not remove themself" do
    pa = Factory(:programme_administrator)
    login_as(pa)
    prog = pa.programmes.first
    p1 = Factory(:person)
    p2 = Factory(:person)
    p3 = Factory(:person)

    assert pa.is_programme_administrator?(prog)
    refute p1.is_programme_administrator?(prog)
    refute p2.is_programme_administrator?(prog)
    refute p3.is_programme_administrator?(prog)

    ids = [p1.id,p2.id].join(",")
    put :update, :id=>prog,:programme=>{:administrator_ids=>ids}

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
    assert p1.roles_mask & Seek::Roles::Roles.instance.mask_for_role('programme_administrator')

  end

  test "admin can add new administrators, and not remove themself" do
    admin = Factory(:programme_administrator)
    admin.is_admin=true
    disable_authorization_checks{admin.save!}
    login_as(admin)
    prog = admin.programmes.first
    p1 = Factory(:person)
    p2 = Factory(:person)
    p3 = Factory(:person)

    assert admin.is_programme_administrator?(prog)
    refute p1.is_programme_administrator?(prog)
    refute p2.is_programme_administrator?(prog)
    refute p3.is_programme_administrator?(prog)

    ids = [p1.id,p2.id].join(",")
    put :update, :id=>prog,:programme=>{:administrator_ids=>ids}

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

  test "edit page accessible to admin" do
    login_as(Factory(:admin))
    p = Factory(:programme)
    Factory(:avatar,:owner=>p)
    get :edit, :id=>p
    assert_response :success
  end

  test "edit page not accessible to user" do
    login_as(Factory(:person))
    p = Factory(:programme)
    get :edit, :id=>p
    assert_redirected_to p
    refute_nil flash[:error]
  end

  test "edit page accessible to programme_administrator" do
    person = Factory(:person)
    login_as(person)
    p = Factory(:programme)
    person.is_programme_administrator=true,p
    disable_authorization_checks{person.save!}
    get :edit, :id=>p
    assert_response :success
  end

  test "should show index" do
    p = Factory(:programme,:projects=>[Factory(:project),Factory(:project)])
    avatar = Factory(:avatar,:owner=>p)
    p.avatar = avatar
    disable_authorization_checks{p.save!}
    Factory(:programme)

    get :index
    assert_response :success
  end

  test "index should not show inactivated except for admin and programme admin" do
    login_as(Factory(:admin))
    programme_admin = Factory(:person)
    p1 = Factory(:programme,title:'activated programme')
    p2 = Factory(:programme,title:'not activated programme')
    p2.is_activated=false
    p2.save!

    p3 = Factory(:programme,title:'not activated or with programme administrator')
    p3.is_activated=false
    p3.save!

    programme_admin.is_programme_administrator=true,p2
    programme_admin.save!
    programme_admin = Person.find(programme_admin.id)

    assert p1.is_activated?
    refute p2.is_activated?
    refute p3.is_activated?

    refute programme_admin.is_programme_administrator?(p1)
    assert programme_admin.is_programme_administrator?(p2)
    refute programme_admin.is_programme_administrator?(p3)

    assert_includes programme_admin.administered_programmes,p2

    logout

    get :index
    assert_response :success
    assert_select "a[href=?]",programme_path(p1),text:p1.title,count:1
    assert_select "a[href=?]",programme_path(p2),text:p2.title,count:0
    assert_select "a[href=?]",programme_path(p3),text:p3.title,count:0

    login_as(Factory(:person))
    get :index
    assert_response :success
    assert_select "a[href=?]",programme_path(p1),text:p1.title,count:1
    assert_select "a[href=?]",programme_path(p2),text:p2.title,count:0
    assert_select "a[href=?]",programme_path(p3),text:p3.title,count:0
    logout

    login_as(Factory(:admin))
    get :index
    assert_response :success
    assert_select "a[href=?]",programme_path(p1),text:p1.title,count:1
    assert_select "a[href=?]",programme_path(p2),text:p2.title,count:1
    assert_select "a[href=?]",programme_path(p3),text:p3.title,count:1
    logout

    login_as(programme_admin)
    get :index
    assert_response :success
    assert_select "a[href=?]",programme_path(p1),text:p1.title,count:1
    assert_select "a[href=?]",programme_path(p2),text:p2.title,count:1
    assert_select "a[href=?]",programme_path(p3),text:p3.title,count:0
    logout


  end

  test "should get show" do
    p = Factory(:programme,:projects=>[Factory(:project),Factory(:project)])
    avatar = Factory(:avatar,:owner=>p)
    p.avatar = avatar
    disable_authorization_checks{p.save!}

    get :show,:id=>p
    assert_response :success
  end

  test "update to default avatar" do
    p = Factory(:programme,:projects=>[Factory(:project),Factory(:project)])
    avatar = Factory(:avatar,:owner=>p)
    p.avatar = avatar
    disable_authorization_checks{p.save!}
    login_as(Factory(:admin))
    put :update, :id=>p, :programme=>{:avatar_id=>"0"}
    prog = assigns(:programme)
    refute_nil prog
    assert_nil prog.avatar
  end

  test "can be disabled" do
    p = Factory(:programme,:projects=>[Factory(:project),Factory(:project)])
    with_config_value :programmes_enabled,false do
      get :show,:id=>p
      assert_redirected_to :root
      refute_nil flash[:error]
    end
  end

  test "non admin cannot spawn" do
    login_as(Factory(:person))
    prog = Factory(:programme)
    get :initiate_spawn_project,:id=>prog
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test "initiate_spawn_project" do
    login_as(Factory(:admin))
    prog = Factory(:programme)
    proj1 = Factory(:project,:programme=>prog)
    proj2 = Factory(:project, :programme=>nil)
    proj3 = Factory(:project,:programme=>Factory(:programme))
    get :initiate_spawn_project,:id=>prog
    assert_response :success
    assigned_prog = assigns(:programme)
    projects = assigns(:available_projects)
    assert_equal prog,assigned_prog
    refute_includes projects, proj1
    assert_includes projects,proj2
    assert_includes projects,proj3
  end

  test "spawn project" do
    proj = Factory(:project)
    prog = Factory(:programme)
    login_as(Factory(:admin))
    assert_difference("Project.count",1) do
      post :spawn_project, :id=>prog.id,:project=>{:title=>"cheese",:description=>"mmmmmm",:web_page=>"http://google.com",:ancestor_id=>proj.id}
    end
    new_proj = assigns(:project)
    refute_nil new_proj

    assert_redirected_to project_path(new_proj)
    assert_equal prog,new_proj.programme
    assert_equal "cheese",new_proj.title
    assert_equal "mmmmmm",new_proj.description
    assert_equal "http://google.com",new_proj.web_page

    refute_nil flash[:notice]

    ancestor = assigns(:ancestor_project)
    assert_equal proj,ancestor
  end

  test "non admin cannot spawn project" do
    proj = Factory(:project)
    prog = Factory(:programme)
    login_as(Factory(:person))
    assert_no_difference("Project.count") do
      post :spawn_project, :id=>prog.id,:project=>{:title=>"cheese",:description=>"mmmmmm",:web_page=>"http://google.com",:ancestor_id=>proj.id}
    end
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test "spawn project failed" do
    proj = Factory(:project)
    prog = Factory(:programme)
    login_as(Factory(:admin))
    #invalid title
    assert_no_difference("Project.count") do
      post :spawn_project, :id=>prog.id,:project=>{:title=>"",:description=>"mmmmmm",:web_page=>"http://google.com",:ancestor_id=>proj.id}
    end
    new_proj = assigns(:project)
    refute new_proj.valid?
    assert_response :success
    ancestor = assigns(:ancestor_project)
    assert_equal proj,ancestor
    assert_select "#errorExplanation" do
      assert_select "li",:text=>/Title can.*t be blank/,:count=>1
    end
  end

  test "user can create programme, and becomes programme administrator" do
    p = Factory(:person)
    login_as(p)
    assert_difference("Programme.count") do
      assert_difference("Delayed::Job.where(\"handler LIKE '%Delayed::PerformableMailer%'\").count", 1) do #activation email
        post :create, :programme=>{:title=>"A programme"}
      end
    end
    prog = assigns(:programme)
    assert_redirected_to prog
    p.reload
    assert p.is_programme_administrator?(prog)
  end

  test "admin doesn't become programme administrator by default" do
    p = Factory(:admin)
    login_as(p)
    assert_difference("Programme.count") do
      assert_no_difference("Delayed::Job.where(\"handler LIKE '%Delayed::PerformableMailer%'\").count") do #no email for admin creation
        post :create, :programme=>{:title=>"A programme"}
      end
    end
    prog = assigns(:programme)
    assert_redirected_to prog
    p.reload
    refute p.is_programme_administrator?(prog)
  end

  test "logged out user cannot create" do
    assert_no_difference("Programme.count") do
      post :create, :programme=>{:title=>"A programme"}
    end
    assert_redirected_to :root
  end

  test "activation review available to admin" do
    programme = Factory(:programme)
    programme.is_activated=false
    disable_authorization_checks{programme.save!}
    refute programme.is_activated?
    login_as(Factory(:admin))
    get :activation_review,:id=>programme
    assert_response :success
    assert_nil flash[:error]
  end

  test "activation review not available none admin" do
    person = Factory(:programme_administrator)
    programme = person.programmes.first
    programme.is_activated=false
    disable_authorization_checks{programme.save!}
    refute programme.is_activated?
    login_as(person)
    get :activation_review,:id=>programme
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test "activation review not available if active" do
    programme = Factory(:programme)
    login_as(Factory(:admin))
    programme.activate
    assert programme.is_activated?
    get :activation_review,:id=>programme
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test 'accept_activation' do
    programme_administrator = Factory(:programme_administrator)
    programme = programme_administrator.programmes.first
    programme.is_activated=false
    disable_authorization_checks{programme.save!}
    refute programme.is_activated?
    login_as(Factory(:admin))

    assert_difference("Delayed::Job.where(\"handler LIKE '%Delayed::PerformableMailer%'\").count", 1) do
      put :accept_activation, :id=>programme
    end

    assert_redirected_to programme
    refute_nil flash[:notice]
    assert_nil flash[:error]
    programme.reload
    assert programme.is_activated?
  end

  test 'no accept_activation for none admin' do
    programme_administrator = Factory(:programme_administrator)
    programme = programme_administrator.programmes.first
    programme.is_activated=false
    disable_authorization_checks{programme.save!}
    refute programme.is_activated?
    login_as(programme_administrator)

    assert_no_difference("Delayed::Job.where(\"handler LIKE '%Delayed::PerformableMailer%'\").count") do
      put :accept_activation, :id=>programme
    end

    assert_redirected_to :root
    assert_nil flash[:notice]
    refute_nil flash[:error]
    programme.reload
    refute programme.is_activated?
  end

  test 'no accept_activation for not activated' do
    programme_administrator = Factory(:programme_administrator)
    programme = programme_administrator.programmes.first

    assert programme.is_activated?
    login_as(Factory(:admin))

    assert_no_difference("Delayed::Job.where(\"handler LIKE '%Delayed::PerformableMailer%'\").count") do
      put :accept_activation, :id=>programme
    end

    assert_redirected_to :root
    assert_nil flash[:notice]
    refute_nil flash[:error]
    programme.reload
    assert programme.is_activated?
  end

  test 'reject activation confirmation' do
    programme_administrator = Factory(:programme_administrator)
    programme = programme_administrator.programmes.first
    programme.is_activated=false
    disable_authorization_checks{programme.save!}
    refute programme.is_activated?
    login_as(Factory(:admin))

    get :reject_activation_confirmation, :id=>programme
    assert_response :success
    assert assigns(:programme)

  end

  test 'no reject activation confirmation for already activated' do
    programme_administrator = Factory(:programme_administrator)
    programme = programme_administrator.programmes.first

    assert programme.is_activated?
    login_as(Factory(:admin))

    get :reject_activation_confirmation, :id=>programme
    assert_redirected_to :root
    assert_nil flash[:notice]
    refute_nil flash[:error]

  end

  test 'no reject activation confirmation for none admin' do
    programme_administrator = Factory(:programme_administrator)
    programme = programme_administrator.programmes.first
    programme.is_activated=false
    disable_authorization_checks{programme.save!}
    refute programme.is_activated?
    login_as(programme_administrator)

    get :reject_activation_confirmation, :id=>programme
    assert_redirected_to :root
    assert_nil flash[:notice]
    refute_nil flash[:error]

  end

  test 'reject_activation' do
    programme_administrator = Factory(:programme_administrator)
    programme = programme_administrator.programmes.first
    programme.is_activated=false
    disable_authorization_checks{programme.save!}
    refute programme.is_activated?
    login_as(Factory(:admin))

    assert_difference("Delayed::Job.where(\"handler LIKE '%Delayed::PerformableMailer%'\").count", 1) do
      put :reject_activation, :id=>programme, :programme=>{activation_rejection_reason:'rejection reason'}
    end

    assert_redirected_to programme
    refute_nil flash[:notice]
    assert_nil flash[:error]
    programme.reload
    refute programme.is_activated?
    assert_equal 'rejection reason',programme.activation_rejection_reason
  end

  test 'no reject activation for none admin' do
    programme_administrator = Factory(:programme_administrator)
    programme = programme_administrator.programmes.first
    programme.is_activated=false
    disable_authorization_checks{programme.save!}
    refute programme.is_activated?
    login_as(programme_administrator)

    assert_no_difference("Delayed::Job.where(\"handler LIKE '%Delayed::PerformableMailer%'\").count") do
      put :reject_activation, :id=>programme, :programme=>{activation_rejection_reason:'rejection reason'}
    end

    assert_redirected_to :root
    assert_nil flash[:notice]
    refute_nil flash[:error]
    programme.reload
    refute programme.is_activated?
    assert_nil programme.activation_rejection_reason
  end

  test 'no reject_activation for not activated' do
    programme_administrator = Factory(:programme_administrator)
    programme = programme_administrator.programmes.first

    assert programme.is_activated?
    login_as(Factory(:admin))

    assert_no_difference("Delayed::Job.where(\"handler LIKE '%Delayed::PerformableMailer%'\").count") do
      put :reject_activation, :id=>programme, :programme=>{activation_rejection_reason:'rejection reason'}
    end

    assert_redirected_to :root
    assert_nil flash[:notice]
    refute_nil flash[:error]
    programme.reload
    assert programme.is_activated?
    assert_nil programme.activation_rejection_reason
  end

  test 'none activated programme only available to administrators' do
    programme_administrator = Factory(:programme_administrator)
    programme = programme_administrator.programmes.first
    programme.is_activated=false
    disable_authorization_checks{programme.save!}
    refute programme.is_activated?

    get :show, :id=>programme
    assert_redirected_to :root
    refute_nil flash[:error]
    flash[:error]=nil

    login_as(programme_administrator)
    get :show, :id=>programme
    assert_response :success
    assert_nil flash[:error]
    logout
    flash[:error]=nil

    login_as(Factory(:admin))
    get :show, :id=>programme
    assert_response :success
    assert_nil flash[:error]
    logout
    flash[:error]=nil

    login_as(Factory(:person))
    get :show, :id=>programme
    assert_redirected_to :root
    refute_nil flash[:error]

  end

  test 'awaiting activation' do
    login_as(Factory(:admin))
    Programme.destroy_all
    prog_not_activated = Factory(:programme)
    prog_not_activated.is_activated=false
    prog_not_activated.save!

    prog_rejected = Factory(:programme)
    prog_rejected.is_activated=false
    prog_rejected.activation_rejection_reason = 'xxx'
    prog_rejected.save!

    prog_normal = Factory(:programme)

    refute prog_not_activated.is_activated?
    refute prog_rejected.is_activated?
    assert prog_normal.is_activated?

    refute prog_not_activated.rejected?
    assert prog_rejected.rejected?
    refute prog_normal.rejected?

    get :awaiting_activation
    assert_response :success

    assert_includes assigns(:not_activated),prog_not_activated
    refute_includes assigns(:not_activated),prog_rejected
    refute_includes assigns(:not_activated),prog_normal

    assert_includes assigns(:rejected),prog_rejected
    refute_includes assigns(:rejected),prog_not_activated
    refute_includes assigns(:rejected),prog_normal

  end

  test 'awaiting for activation blocked for none admin' do
    programme_administrator = Factory(:programme_administrator)
    normal = Factory(:person)

    login_as(programme_administrator)
    get :awaiting_activation
    assert_redirected_to :root
    refute_nil flash[:error]
    logout
    flash[:error]=nil

    login_as(normal)
    get :awaiting_activation
    assert_redirected_to :root
    refute_nil flash[:error]
    logout
    flash[:error]=nil
  end

  test 'can get storage usage' do
    programme_administrator = Factory(:programme_administrator)
    programme = programme_administrator.programmes.first
    data_file = Factory(:data_file, :project_ids => [programme.projects.first.id])
    size = data_file.content_blob.file_size
    assert size > 0

    login_as(programme_administrator)
    get :storage_report, id: programme.id

    assert_response :success
    assert_nil flash[:error]
    assert_select 'strong', text: number_to_human_size(size)
  end

  test 'non admin cannot get storage usage' do
    programme_administrator = Factory(:programme_administrator)
    normal = Factory(:person)
    programme = programme_administrator.programmes.first

    login_as(normal)
    get :storage_report, id: programme.id
    assert_redirected_to programme_path(programme)
    refute_nil flash[:error]
  end

  test "admin can add and remove funding codes" do
    login_as(Factory(:admin))
    prog = Factory(:programme)

    assert_difference('Annotation.count', 2) do
      put :update, id: prog, programme: { funding_codes: '1234,abcd' }
    end

    assert_redirected_to prog

    assert_equal 2, assigns(:programme).funding_codes.length
    assert_includes assigns(:programme).funding_codes, '1234'
    assert_includes assigns(:programme).funding_codes, 'abcd'

    assert_difference('Annotation.count', -2) do
      put :update, id: prog, programme: { funding_codes: '' }
    end

    assert_redirected_to prog

    assert_equal 0, assigns(:programme).funding_codes.length
  end


end
