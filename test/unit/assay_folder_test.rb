require 'test_helper'

class AssayFolderTest < ActiveSupport::TestCase

  def setup
    @user = Factory :user
    User.current_user = @user
    @project = @user.person.projects.first
  end

  test "assay folders" do
    public_assay = Factory(:experimental_assay,:policy=>Factory(:public_policy))
    viewable_assay = Factory(:experimental_assay,:policy=>Factory(:publicly_viewable_policy))
    private_assay  = Factory(:experimental_assay,:policy=>Factory(:private_policy))
    my_private_assay  = Factory(:experimental_assay,:contributor=>@user.person,:policy=>Factory(:private_policy))

    [public_assay,viewable_assay,private_assay,my_private_assay].each do |a|
      a.study.investigation.projects=[@project]
      a.study.investigation.save!
    end

    assert public_assay.can_edit?
    assert !private_assay.can_edit?

    folders = Seek::AssayFolder.assay_folders(@project)
    assert_equal 2,folders.count
    assert_equal [my_private_assay,public_assay].sort_by(&:id),folders.collect{|f| f.assay}.sort_by(&:id)

  end

  test "authorized assets" do
      assay = Factory(:experimental_assay,:contributor=>@user.person,:policy=>Factory(:public_policy))
      sop = Factory :sop,:policy=>Factory(:public_policy)
      private_sop = Factory :sop,:policy=>Factory(:private_policy)
      project = assay.projects.first
      assay.relate(sop)
      assay.relate(private_sop)
      folder = Seek::AssayFolder.new assay,project
      assert_equal [sop],folder.authorized_assets
  end

  test "initialise assay folder" do
    assay = Factory(:experimental_assay,:policy=>Factory(:public_policy))
    folder = Seek::AssayFolder.new assay,assay.projects.first

    assert_equal assay,folder.assay
    assert_equal assay.title, folder.title
    assert_equal assay.description, folder.description
    assert_equal "#{assay.title} (0)",folder.label
    assert_equal assay.projects.first,folder.project
    assert !folder.deletable?
    assert !folder.editable?
    assert !folder.incoming?
    assert_equal "Assay_#{assay.id}",folder.id
    assert_equal [],folder.children
    assert_nil folder.parent

  end

  test "invalid project" do
    assay = Factory(:experimental_assay,:policy=>Factory(:public_policy))
    assert_raise Exception do
      folder = Seek::AssayFolder.new assay,Factory(:project)
    end
  end

end