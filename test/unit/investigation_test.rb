require 'test_helper'

class InvestigationTest < ActiveSupport::TestCase
  fixtures :investigations, :projects, :studies, :assays, :assay_assets, :permissions, :policies

  test 'associations' do
    inv = investigations(:metabolomics_investigation)
    assert_equal [projects(:sysmo_project)], inv.projects
    assert inv.studies.include?(studies(:metabolomics_study))
  end

  test 'sort by updated_at' do
    assert_equal Investigation.all.sort_by { |i| i.updated_at.to_i * -1 }, Investigation.all
  end

  test 'publications through the study assays' do
    assay1 = Factory(:assay)
    inv = assay1.investigation
    assay2 = Factory(:assay, contributor: assay1.contributor, study: Factory(:study, contributor: assay1.contributor, investigation: inv))

    pub1 = Factory :publication, title: 'pub 1'
    pub2 = Factory :publication, title: 'pub 2'
    pub3 = Factory :publication, title: 'pub 3'
    Factory :relationship, subject: assay1, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub1
    Factory :relationship, subject: assay1, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub2

    Factory :relationship, subject: assay2, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub2
    Factory :relationship, subject: assay2, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub3

    assert_equal 3, inv.related_publications.size
    assert_equal [pub1, pub2, pub3], inv.related_publications.sort_by(&:id)
  end

  test 'assays through association' do
    inv = investigations(:metabolomics_investigation)
    assays = inv.assays
    assert_not_nil assays
    assert_equal 3, assays.size
    assert assays.include?(assays(:metabolomics_assay))
    assert assays.include?(assays(:metabolomics_assay2))
    assert assays.include?(assays(:metabolomics_assay3))
  end

  test 'to_rdf' do
    object = Factory(:investigation, description: 'Big investigation')
    FactoryGirl.create_list(:study, 2, contributor: object.contributor, investigation: object)
    rdf = object.to_rdf
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 1
      assert_equal RDF::URI.new("http://localhost:3000/investigations/#{object.id}"), reader.statements.first.subject
    end
  end

  test 'to_isatab' do
    skip "this fails because of: isatools error: KeyError('technologyType',)"
    object = Factory(:max_investigation, description: 'Max investigation')
    assay = object.assays.first

    sample = Factory(:sample, policy: Factory(:publicly_viewable_policy))
    patient_sample = Factory(:patient_sample, policy: Factory(:publicly_viewable_policy))

    User.with_current_user(assay.contributor.user) do
      assay.associate(sample)
      assay.associate(patient_sample)
      assay.save!
    end

    the_hash = IsaTabConverter.convert_investigation(object)
    json = JSON.pretty_generate(the_hash)

    # write out to a temporary file
    t = Tempfile.new("test_temp")
    t << json
    t.close

    result = `python script/check-isa.py #{t.path}`

    assert result.blank?, "check-isa.py result was not blank, returned: #{result}"
  end

# the lib/sysmo/title_trimmer mixin should automatically trim the title :before_save
  test 'title trimmed' do
    inv = Factory(:investigation, title: ' Test')
    assert_equal 'Test', inv.title
  end

  test 'validations' do
    inv = Investigation.new(title: 'Test', projects: [projects(:sysmo_project)], policy: Factory(:private_policy))
    assert inv.valid?
    inv.title = ''
    assert !inv.valid?
    inv.title = nil
    assert !inv.valid?

    # do not allow empty projects
    inv.title = 'Test'
    inv.projects = []
    refute inv.valid?

    inv.projects = [projects(:sysmo_project)]
    assert inv.valid?
  end

  test "unauthorized users can't delete" do
    User.with_current_user Factory(:user) do
      investigation = Factory :investigation, policy: Factory(:private_policy)
      assert !investigation.can_delete?(Factory(:user))
    end
  end

  test 'authorized user can delete' do
    User.with_current_user Factory(:user) do
      investigation = Factory :investigation, studies: [], policy: Factory(:private_policy)
      assert investigation.can_delete?(investigation.contributor)
    end
  end

  test 'authorized user cant delete with study' do
    investigation = Factory(:study).investigation
    assert_not_empty investigation.studies
    assert !investigation.can_delete?(investigation.contributor)
  end

  test 'test uuid generated' do
    i = investigations(:metabolomics_investigation)
    assert_nil i.attributes['uuid']
    i.save
    assert_not_nil i.attributes['uuid']
  end

  test "uuid doesn't change" do
    x = investigations(:metabolomics_investigation)
    x.save
    uuid = x.attributes['uuid']
    x.save
    assert_equal x.uuid, uuid
  end

  test 'assets' do
    assay_assets = [Factory(:assay_asset), Factory(:assay_asset)]
    data_files = assay_assets.collect(&:asset)
    inv = Factory(:experimental_assay, assay_assets: assay_assets).investigation
    assert_equal data_files.sort, inv.assets.sort
  end

  test 'can create snapshot of investigation' do
    investigation = Factory(:investigation, policy: Factory(:publicly_viewable_policy))
    Factory(:study, contributor: investigation.contributor)
    snapshot = nil

    assert_difference('Snapshot.count') do
      snapshot = investigation.create_snapshot
    end

    assert_equal 1, investigation.snapshots.count
    assert_equal investigation.title, snapshot.title
  end

  test 'clone with associations' do
    investigation = Factory(:investigation, title: '123', description: 'abc', policy: Factory(:publicly_viewable_policy))
    person = investigation.contributor
    publication = Factory(:publication, contributor: person)

    disable_authorization_checks do
      investigation.publications << publication
    end

    clone = investigation.clone_with_associations

    assert_equal investigation.title, clone.title
    assert_equal investigation.description, clone.description
    assert_equal investigation.projects, clone.projects
    assert_equal BaseSerializer.convert_policy(investigation.policy), BaseSerializer.convert_policy(clone.policy)

    assert_includes clone.publications, publication

    disable_authorization_checks { assert clone.save }
  end

  test 'has deleted contributor?' do
    item = Factory(:investigation,deleted_contributor:'Person:99')
    item.update_column(:contributor_id,nil)
    item2 = Factory(:investigation)
    item2.update_column(:contributor_id,nil)

    assert_nil item.contributor
    assert_nil item2.contributor
    refute_nil item.deleted_contributor
    assert_nil item2.deleted_contributor

    assert item.has_deleted_contributor?
    refute item2.has_deleted_contributor?
  end

  test 'has jerm contributor?' do
    item = Factory(:investigation,deleted_contributor:'Person:99')
    item.update_column(:contributor_id,nil)
    item2 = Factory(:investigation)
    item2.update_column(:contributor_id,nil)

    assert_nil item.contributor
    assert_nil item2.contributor
    refute_nil item.deleted_contributor
    assert_nil item2.deleted_contributor

    refute item.has_jerm_contributor?
    assert item2.has_jerm_contributor?
  end

  test 'custom metadata attribute values for search' do
    item = Factory(:investigation)
    assert_equal [],item.custom_metadata_attribute_values_for_search

    metadata_type = Factory(:simple_investigation_custom_metadata_type)
    item = Factory(:investigation,
                   custom_metadata:CustomMetadata.new(
                     custom_metadata_type: metadata_type,
                     data: { name: 'James', age: '25' }
                   )
    )
    assert_equal ['James','25'].sort, item.custom_metadata_attribute_values_for_search.sort
  end

end
