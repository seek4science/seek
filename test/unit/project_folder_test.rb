require 'test_helper'

class ProjectFolderTest < ActiveSupport::TestCase
  test 'validation' do
    pf = ProjectFolder.new
    assert !pf.valid?
    pf.project = FactoryBot.create :project
    assert !pf.valid?
    pf.title = 'fred'
    assert pf.valid?
    pf.project = nil
    assert !pf.valid?
  end

  test 'destroy' do
    contributor = FactoryBot.create(:person)
    p = contributor.projects.first
    pf = FactoryBot.create :project_folder, project: p

    child = pf.add_child('fred')
    inner_child = child.add_child('frog')

    pf.reload
    assets = [FactoryBot.create(:sop, projects: [p], contributor:contributor), FactoryBot.create(:data_file, projects: [p], contributor:contributor), FactoryBot.create(:model, projects: [p], contributor:contributor)]
    assets2 = [FactoryBot.create(:sop, projects: [p], contributor:contributor), FactoryBot.create(:model, projects: [p], contributor:contributor)]
    assets3 = [FactoryBot.create(:sop, projects: [p], contributor:contributor), FactoryBot.create(:presentation, projects: [p], contributor:contributor)]
    all_assets = assets | assets2 | assets3

    # this needs creating after the assets, otherwise they will be automatically added to it when created!
    unsorted_folder = FactoryBot.create :project_folder, project: p, incoming: true
    assert unsorted_folder.assets.empty?

    disable_authorization_checks do
      pf.add_assets(assets)
      child.add_assets(assets2)
      inner_child.add_assets(assets3)
    end

    assert_difference('ProjectFolder.count', -3) do
      assert_no_difference('ProjectFolderAsset.count') do
        pf.destroy
      end
    end

    p.reload
    unsorted_folder.reload
    assert_equal 1, ProjectFolder.where(project_id: p.id).count
    assert_equal unsorted_folder, ProjectFolder.where(project_id: p.id).first
    assert_equal all_assets.count, unsorted_folder.assets.count
    assert_equal all_assets.sort_by(&:title), unsorted_folder.assets.sort_by(&:title)
  end

  test 'dont move assets if folder being destroyed is incoming' do
    contributor = FactoryBot.create(:person)
    p = contributor.projects.first
    assets = [FactoryBot.create(:sop, projects: [p], contributor:contributor), FactoryBot.create(:data_file, projects: [p], contributor:contributor), FactoryBot.create(:model, projects: [p], contributor:contributor)]
    incoming = FactoryBot.create :project_folder, project: p, incoming: true

    disable_authorization_checks do
      assert_difference('ProjectFolderAsset.count', 3) do
        incoming.add_assets(assets)
      end
    end

    assert_difference('ProjectFolder.count', -1) do
      assert_difference('ProjectFolderAsset.count', -3) do
        incoming.destroy
      end
    end

    assert ProjectFolder.where(project_id: p.id).empty?
  end

  test 'add child' do
    pf = FactoryBot.create :project_folder
    new_child = nil
    assert_difference('ProjectFolder.count') do
      new_child = pf.add_child 'fish'
      pf.save!
    end

    pf.reload
    assert_equal 1, pf.children.count
    assert_equal new_child, pf.children.first
    assert_equal pf.project, pf.children.first.project
    assert_equal pf, pf.children.first.parent
    assert_equal 'fish', pf.children.first.title
    assert pf.children.first.editable?
    assert !pf.children.first.incoming?
  end

  test 'adding children' do
    pf = FactoryBot.create :project_folder

    pf2 = ProjectFolder.new title: 'one'
    pf3 = ProjectFolder.new title: 'two'

    pf.children << pf2
    pf.children << pf3
    assert_equal pf, pf2.parent
    assert_equal pf.project, pf2.project
    assert_equal pf, pf3.parent
    assert_equal pf.project, pf3.project

    pf.save!

    pf.reload

    assert_equal 2, pf.children.count
    assert_equal pf.project, pf.children[0].project
    assert_equal pf.project, pf.children[1].project

    assert_equal pf, pf.children[0].parent
    assert_equal pf, pf.children[1].parent

    assert_equal 'one', pf.children[0].title
    assert_equal 'two', pf.children[1].title
  end

  test 'root folders' do
    project = FactoryBot.create :project
    assert ProjectFolder.root_folders(project).empty?
    root1 = nil
    root2 = nil
    assert_difference('ProjectFolder.count', 10) do
      root1 = FactoryBot.create :project_folder, project: project
      root2 = FactoryBot.create :project_folder, project: project
      root1.children << FactoryBot.create(:project_folder, project: project)
      root1.children << FactoryBot.create(:project_folder, project: project)
      root1.children << FactoryBot.create(:project_folder, project: project)
      root1.children.first.children << FactoryBot.create(:project_folder, project: project)
      root2.children << FactoryBot.create(:project_folder, project: project)
      root1.children.first.children << FactoryBot.create(:project_folder, project: project)
      root1.children.first.children << FactoryBot.create(:project_folder, project: project)
      root1.children.first.children << FactoryBot.create(:project_folder, project: project)
    end

    roots = ProjectFolder.root_folders project
    assert_equal 2, roots.count
    assert roots.include?(root1)
    assert roots.include?(root2)
  end

  test 'initialise defaults' do
    project = FactoryBot.create :project
    default_file = File.join Rails.root, 'test', 'fixtures', 'files', 'default_project_folders'

    root_folders = nil
    assert_difference('ProjectFolder.count', 7) do
      root_folders = ProjectFolder.initialize_default_folders project, default_file
    end

    assert_equal 3, root_folders.count
    first_root = root_folders.first
    assert_equal 'data files', first_root.title
    assert first_root.editable?
    assert !first_root.incoming?
    assert first_root.deletable?
    assert_equal 1, first_root.children.count
    assert_equal 'raw data files', first_root.children.first.title
    assert_equal 0, first_root.children.first.children.count

    second_root = root_folders[1]
    assert_equal 'models', second_root.title
    assert second_root.editable?
    assert !second_root.incoming?
    assert !second_root.deletable?
    assert_equal 2, second_root.children.count
    assert_equal 'copasi', second_root.children.first.title
    assert_equal 'sbml', second_root.children[1].title

    assert_equal 1, second_root.children[1].children.count
    assert_equal 'in development', second_root.children[1].children.first.title

    third_root = root_folders[2]
    assert !third_root.editable?
    assert third_root.incoming?
    assert third_root.deletable?
    assert 'Unsorted items', third_root.title

    # don't check the actual contents from the real file, but check it works sanely and exists
    project2 = FactoryBot.create :project
    root_folders = ProjectFolder.initialize_default_folders project2
    assert !root_folders.empty?

    # check exception raised if folders already exist
    folder = FactoryBot.create :project_folder
    assert_raise Exception do
      ProjectFolder.initialize_default_folders folder.project
    end
  end

  test 'cannot destroy if not deletable' do
    folder = FactoryBot.create :project_folder, deletable: false
    contributor = FactoryBot.create(:person,project:folder.project)
    sop = FactoryBot.create :sop, projects: [folder.project], policy: FactoryBot.create(:public_policy), contributor:contributor
    folder.add_assets(sop)
    incoming_folder = FactoryBot.create :project_folder, project: folder.project, incoming: true
    assert_no_difference('ProjectFolder.count') do
      assert_no_difference('ProjectFolderAsset.count') do
        assert !folder.destroy
      end
    end
    # also check that callback to move items is also not called
    folder.reload
    incoming_folder.reload

    assert_equal [sop], folder.assets
    assert incoming_folder.assets.empty?
  end

  test 'unsorted items folder' do
    project = FactoryBot.create :project
    default_file = File.join Rails.root, 'test', 'fixtures', 'files', 'default_project_folders'

    ProjectFolder.initialize_default_folders project, default_file

    folder = ProjectFolder.new_items_folder project
    assert !folder.editable
    assert_equal project, folder.project
    assert_equal 'Unsorted items', folder.title
    assert folder.incoming?
  end

  test 'authorized_assets' do
    user = FactoryBot.create :user
    project = user.person.projects.first
    another_user = FactoryBot.create(:person,project:project).user
    model = FactoryBot.create :model, projects: [project], policy: FactoryBot.create(:public_policy),contributor:user.person
    hidden_model = FactoryBot.create :model, projects: [project], policy: FactoryBot.create(:private_policy),contributor:another_user.person
    viewable_sop = FactoryBot.create :sop, projects: [project], policy: FactoryBot.create(:all_sysmo_viewable_policy),contributor:user.person
    folder = FactoryBot.create :project_folder, project: project

    disable_authorization_checks do
      folder.add_assets([model, hidden_model, viewable_sop])
      folder.save!
    end
    User.with_current_user(user) do
      auth_assets = folder.authorized_assets
      assert_equal 2, auth_assets.count
      assert auth_assets.include?(model)
      assert auth_assets.include?(viewable_sop)
    end
  end

  test 'label' do
    user = FactoryBot.create :user
    project = user.person.projects.first
    pf1 = ProjectFolder.new title: 'one', project: project
    assets = (0...3).to_a.collect { FactoryBot.create :sop, projects: [project], policy: FactoryBot.create(:public_policy), contributor:user.person }
    pf1.add_assets assets
    assert_equal 'one (3)', pf1.label
  end

  test 'add assets' do
    user = FactoryBot.create :user
    project = user.person.projects.first

    pf1 = ProjectFolder.new title: 'one', project: project
    model = FactoryBot.create :model, policy: FactoryBot.create(:public_policy), contributor:user.person, projects:[project]
    sop = FactoryBot.create :sop, projects: [project], policy: FactoryBot.create(:public_policy), contributor:user.person
    pf1.add_assets model
    pf1.add_assets [sop]
    pf1.reload
    assert_equal [model, sop], pf1.assets
  end

  test 'move asset' do
    person = FactoryBot.create :person
    project = person.projects.first

    pf1 = ProjectFolder.new title: 'one', project: project
    pf2 = ProjectFolder.new title: 'two', project: project
    model = FactoryBot.create :model, projects: [project], policy: FactoryBot.create(:public_policy), contributor:person
    disable_authorization_checks do
      pf1.add_assets model
    end

    pf2.move_assets model, pf1
    model.reload
    pf1.reload
    pf2.reload
    model.reload
    assert_equal [pf2], model.folders
    assert_equal [], pf1.assets
    assert_equal [model], pf2.assets

    # nothing happens if the destination folder doesn't match source
    project2 = FactoryBot.create(:project)
    pf1 = ProjectFolder.new title: 'one', project: project
    pf2 = ProjectFolder.new title: 'two', project: project2
    person.add_to_project_and_institution(project2,person.institutions.first)
    model = FactoryBot.create :model, projects: [project, project2], policy: FactoryBot.create(:public_policy), contributor: person
    disable_authorization_checks do
      pf1.add_assets model
    end

    pf2.move_assets model, pf1
    assert_equal [pf1], model.folders
    assert_equal [model], pf1.assets
    assert_equal [], pf2.assets
  end
end
