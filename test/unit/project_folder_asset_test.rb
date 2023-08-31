require 'test_helper'

class ProjectFolderAssetTest < ActiveSupport::TestCase
  test 'associations' do
    pf = FactoryBot.create :project_folder
    person = FactoryBot.create(:person,project:pf.project)
    sop = FactoryBot.create :sop, policy: FactoryBot.create(:public_policy), projects: [pf.project], contributor:person
    pfa = ProjectFolderAsset.create asset: sop, project_folder: pf
    pfa.save!
    pfa.reload
    assert_equal sop, pfa.asset
    assert_equal pf, pfa.project_folder

    pf.reload
    assert_equal 1, pf.assets.count
    assert pf.assets.include?(sop)
    sop.reload
    assert_equal 1, sop.folders.count
    assert sop.folders.include?(pf)
  end

  test 'dependents destroyed' do
    pf = FactoryBot.create :project_folder
    person = FactoryBot.create(:person,project:pf.project)
    sop = FactoryBot.create :sop, policy: FactoryBot.create(:public_policy), projects: [pf.project], contributor: person
    pfa = ProjectFolderAsset.create asset: sop, project_folder: pf

    assert_difference('ProjectFolderAsset.count', -1) do
      sop.destroy
      assert_nil ProjectFolderAsset.find_by_id(pfa.id)
    end

    pf = FactoryBot.create :project_folder
    person = FactoryBot.create(:person,project:pf.project)
    sop = FactoryBot.create :sop, policy: FactoryBot.create(:public_policy), projects: [pf.project], contributor:person
    pfa = ProjectFolderAsset.create asset: sop, project_folder: pf

    assert_difference('ProjectFolderAsset.count', -1) do
      pf.destroy
      assert_nil ProjectFolderAsset.find_by_id(pfa.id)
    end
  end

  test 'assets added to default folder upon creation' do
    pf = FactoryBot.create :project_folder, title: 'Unsorted items', editable: false, incoming: true
    pf2 = FactoryBot.create :project_folder, title: 'Unsorted items', editable: false, incoming: true

    person = FactoryBot.create(:person,project: pf.project)
    person.add_to_project_and_institution(pf2.project, person.institutions.first)

    model = FactoryBot.build :model, projects: [pf.project, pf2.project], policy: FactoryBot.create(:public_policy), contributor: person

    model.save!

    pf.reload
    model.reload
    assert_equal 1, pf.assets.count
    assert_equal 1, pf.assets.count
    assert pf.assets.include?(model)
    assert pf2.assets.include?(model)
    assert_equal 2, model.folders.count
    assert model.folders.include?(pf)
    assert model.folders.include?(pf2)
  end

  test 'validations' do
    pfa = ProjectFolderAsset.new
    pf = FactoryBot.create :project_folder
    person = FactoryBot.create(:person, project: pf.project)
    model = FactoryBot.create :model, policy: FactoryBot.create(:public_policy), projects: [pf.project], contributor: person

    assert !pfa.valid?

    # must have asset and folder
    pfa.asset = model
    assert !pfa.valid?
    pfa.project_folder = pf
    assert pfa.valid?
    pfa.asset = nil
    assert !pfa.valid?

    # asset must belong in same project as folder
    pfa.asset = model
    assert pfa.valid?
    person.add_to_project_and_institution(FactoryBot.create(:project),person.institutions.first)
    pfa.asset = FactoryBot.create :model, policy: FactoryBot.create(:public_policy), projects: person.projects, contributor: person
    assert pfa.valid?

    other_person = FactoryBot.create(:person)
    pfa.asset = FactoryBot.create :model, policy: FactoryBot.create(:public_policy), projects: other_person.projects,contributor: other_person
    assert !pfa.valid?

    # final check for save
    pfa.asset = model
    assert pfa.save
  end

  test 'assign existing assets to folders' do

    proj = FactoryBot.create :project
    contributor = FactoryBot.create(:person,project:proj)

    old_sop = FactoryBot.create :sop, policy: FactoryBot.create(:public_policy), projects: [proj], contributor:contributor
    old_model = FactoryBot.create :model, policy: FactoryBot.create(:public_policy), projects: [proj], contributor:contributor
    old_presentation = FactoryBot.create :presentation, policy: FactoryBot.create(:public_policy), projects: [proj], contributor:contributor
    old_publication = FactoryBot.create :publication, policy: FactoryBot.create(:public_policy), projects: [proj], contributor:contributor
    old_datafile = FactoryBot.create :data_file, policy: FactoryBot.create(:public_policy), projects: [proj], contributor:contributor
    old_private_datafile = FactoryBot.create :data_file, policy: FactoryBot.create(:private_policy), projects: [proj], contributor:contributor
    old_datafile_other_proj = FactoryBot.create :model, policy: FactoryBot.create(:public_policy), contributor:FactoryBot.create(:person)

    pf = FactoryBot.create :project_folder, project: proj
    pf_incoming = FactoryBot.create :project_folder, project: pf.project, title: 'New items', incoming: true
    already_assigned_sop = FactoryBot.create :sop, policy: FactoryBot.create(:public_policy), projects: [proj], contributor:contributor
    pf.add_assets already_assigned_sop

    ProjectFolderAsset.assign_existing_assets(proj)
    pf.reload
    pf_incoming.reload

    assert_equal 1, pf.assets.count
    assert pf.assets.include?(already_assigned_sop)

    assert_equal 7, pf_incoming.assets.count
    assert pf_incoming.assets.include?(old_sop)
    assert pf_incoming.assets.include?(old_model)
    assert pf_incoming.assets.include?(old_presentation)
    assert pf_incoming.assets.include?(old_publication)
    assert pf_incoming.assets.include?(old_datafile)
    assert pf_incoming.assets.include?(old_private_datafile)
    assert !pf_incoming.assets.include?(old_datafile_other_proj)
  end
end
