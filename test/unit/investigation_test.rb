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
    assay1 = Factory :assay
    assay2 = Factory :assay

    pub1 = Factory :publication, title: 'pub 1'
    pub2 = Factory :publication, title: 'pub 2'
    pub3 = Factory :publication, title: 'pub 3'
    Factory :relationship, subject: assay1, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub1
    Factory :relationship, subject: assay1, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub2

    Factory :relationship, subject: assay2, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub2
    Factory :relationship, subject: assay2, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub3

    inv = Factory(:investigation, studies: [Factory(:study, assays: [assay1]), Factory(:study, assays: [assay2])])

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
    object = Factory :investigation, description: 'Big investigation', studies: [Factory(:study), Factory(:study)]
    rdf = object.to_rdf
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 1
      assert_equal RDF::URI.new("http://localhost:3000/investigations/#{object.id}"), reader.statements.first.subject
    end
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
    investigation = Factory :investigation, studies: [Factory(:study)], contributor: Factory(:user)
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
    investigation = Factory(:investigation, policy: Factory(:publicly_viewable_policy), studies: [Factory(:study)], contributor: Factory(:user))
    snapshot = nil

    assert_difference('Snapshot.count') do
      snapshot = investigation.create_snapshot
    end

    assert_equal 1, investigation.snapshots.count
    assert_equal investigation.title, snapshot.title
  end
end
