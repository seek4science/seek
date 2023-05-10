require 'test_helper'

class StudyTest < ActiveSupport::TestCase
  fixtures :all

  test 'associations' do
    study = studies(:metabolomics_study)
    assert_equal 'A Metabolomics Study', study.title

    assert_not_nil study.assays
    assert_equal 1, study.assays.size
    assert !study.investigation.projects.empty?

    assert study.assays.include?(assays(:metabolomics_assay))

    assert_equal projects(:sysmo_project), study.investigation.projects.first
    assert_equal projects(:sysmo_project), study.projects.first

    assert_equal 'http://jermontology.org/ontology/JERMOntology#Metabolomics', study.assays.first.assay_type_uri
  end

  test 'to_rdf' do
    object = FactoryBot.create(:study, description: 'My famous study')
    FactoryBot.create_list(:assay, 2, contributor: object.contributor, study: object)
    rdf = object.to_rdf
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 1
      assert_equal RDF::URI.new("http://localhost:3000/studies/#{object.id}"), reader.statements.first.subject
    end
  end

  # only authorized people can delete a study, and a study must have no assays
  test 'can delete' do
    project_member = FactoryBot.create(:person)
    another_project_member = FactoryBot.create(:person, project: project_member.projects.first)
    study = FactoryBot.create(:study, contributor: another_project_member)

    assert_empty study.assays
    assert !study.can_delete?(FactoryBot.create(:user))
    assert !study.can_delete?(project_member.user)
    assert study.can_delete?(study.contributor.user)

    study = FactoryBot.create(:assay).study
    assert_not_empty study.assays
    assert !study.can_delete?(study.contributor)
  end

  test 'publications through assays' do
    assay1 = FactoryBot.create(:assay)
    study = assay1.study
    assay2 = FactoryBot.create(:assay, contributor: assay1.contributor, study: study)

    pub1 = FactoryBot.create :publication, title: 'pub 1'
    pub2 = FactoryBot.create :publication, title: 'pub 2'
    pub3 = FactoryBot.create :publication, title: 'pub 3'
    FactoryBot.create :relationship, subject: assay1, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub1
    FactoryBot.create :relationship, subject: assay1, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub2

    FactoryBot.create :relationship, subject: assay2, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub2
    FactoryBot.create :relationship, subject: assay2, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub3

    assay1.reload
    assay2.reload
    assert_equal 2, assay1.publications.size
    assert_equal 2, assay2.publications.size

    assert_equal 2, study.assays.size
    assert_equal 3, study.related_publications.size
    assert_equal [pub1, pub2, pub3], study.related_publications.sort_by(&:id)
  end

  test 'directly associated sops' do
    study = studies(:metabolomics_study)
    study.sop_ids = [FactoryBot.create(:sop).id]
    assert_equal 3, study.related_sops.size
  end

  test 'sops through assays' do
    study = studies(:metabolomics_study)
    assert_equal 2, study.related_sops.size
    assert study.related_sops.include?(sops(:my_first_sop))
    assert study.related_sops.include?(sops(:sop_with_fully_public_policy))

    # study with 2 assays that have overlapping sops. Checks that the sops aren't dupliced.
    study = studies(:study_with_overlapping_assay_sops)
    assert_equal 3, study.related_sops.size
    assert study.related_sops.include?(sops(:my_first_sop))
    assert study.related_sops.include?(sops(:sop_with_fully_public_policy))
    assert study.related_sops.include?(sops(:sop_for_test_with_workgroups))
  end

  test 'project from investigation' do
    study = studies(:metabolomics_study)
    assert_equal projects(:sysmo_project), study.projects.first
    assert_not_nil study.projects.first.title
  end

  test 'title trimmed' do
    s = FactoryBot.create(:study, title: ' title')
    assert_equal('title', s.title)
  end

  test 'validation' do
    s = Study.new(title: 'title', investigation: investigations(:metabolomics_investigation), policy: FactoryBot.create(:private_policy))
    assert s.valid?

    s.title = nil
    assert !s.valid?
    s.title
    assert !s.valid?

    s = Study.new(title: 'title', investigation: investigations(:metabolomics_investigation))
    s.investigation = nil
    assert !s.valid?
  end

  test 'study with 1 assay' do
    study = studies(:study_with_assay_with_public_private_sops_and_datafile)
    assert_equal 1, study.assays.size, 'This study must have only one assay - do not modify its fixture'
  end

  test 'test uuid generated' do
    s = studies(:metabolomics_study)
    assert_nil s.attributes['uuid']
    s.save
    assert_not_nil s.attributes['uuid']
  end

  test "uuid doesn't change" do
    x = studies(:metabolomics_study)
    x.save
    uuid = x.attributes['uuid']
    x.save
    assert_equal x.uuid, uuid
  end

  test 'assets' do
    assay_assets = [FactoryBot.create(:assay_asset), FactoryBot.create(:assay_asset)]
    data_files = assay_assets.collect(&:asset)
    study = FactoryBot.create(:experimental_assay, assay_assets: assay_assets).study
    assert_equal data_files.sort, study.assets.sort
  end

  test 'clone with associations' do
    study = FactoryBot.create(:study, title: '123', description: 'abc', policy: FactoryBot.create(:publicly_viewable_policy))
    person = study.contributor
    publication = FactoryBot.create(:publication, contributor: person)

    disable_authorization_checks do
      study.publications << publication
    end

    clone = study.clone_with_associations

    assert_equal study.title, clone.title
    assert_equal study.description, clone.description
    assert_equal study.projects, clone.projects
    assert_equal BaseSerializer.convert_policy(study.policy), BaseSerializer.convert_policy(clone.policy)

    assert_includes clone.publications, publication

    disable_authorization_checks { assert clone.save }
  end

  test 'has deleted contributor?' do
    item = FactoryBot.create(:study,deleted_contributor:'Person:99')
    item.update_column(:contributor_id,nil)
    item2 = FactoryBot.create(:study)
    item2.update_column(:contributor_id,nil)

    assert_nil item.contributor
    assert_nil item2.contributor
    refute_nil item.deleted_contributor
    assert_nil item2.deleted_contributor

    assert item.has_deleted_contributor?
    refute item2.has_deleted_contributor?
  end

  test 'has jerm contributor?' do
    item = FactoryBot.create(:study,deleted_contributor:'Person:99')
    item.update_column(:contributor_id,nil)
    item2 = FactoryBot.create(:study)
    item2.update_column(:contributor_id,nil)

    assert_nil item.contributor
    assert_nil item2.contributor
    refute_nil item.deleted_contributor
    assert_nil item2.deleted_contributor

    refute item.has_jerm_contributor?
    assert item2.has_jerm_contributor?
  end

  test 'assay positioning' do
    study = FactoryBot.create(:study)
    assay2 = FactoryBot.create(:assay, study: study, position: 2)
    assay3 = FactoryBot.create(:assay, study: study, position: 3)
    assay1 = FactoryBot.create(:assay, study: study, position: 1)
    assay4 = FactoryBot.create(:assay, study: study, position: 4)

    assert_equal [assay1, assay2, assay3, assay4], study.positioned_assays.to_a

    related_items_hash = { 'Assay' => { items: [assay4, assay1, assay2, assay3] } }
    Seek::ListSorter.related_items(related_items_hash)

    assert_equal [assay1, assay2, assay3, assay4], related_items_hash['Assay'][:items]
  end

end
