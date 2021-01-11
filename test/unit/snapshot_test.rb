require 'test_helper'

class SnapshotTest < ActiveSupport::TestCase
  include MockHelper

  fixtures :investigations

  setup do
    contributor = Factory(:person)
    User.current_user = contributor.user

    @investigation = Factory(:investigation, title: 'i1', description: 'not blank',
                                             policy: Factory(:downloadable_public_policy), contributor:contributor)
    @study = Factory(:study, title: 's1', investigation: @investigation, contributor: @investigation.contributor,
                             policy: Factory(:downloadable_public_policy))
    @assay = Factory(:assay, title: 'a1', study: @study, contributor: @investigation.contributor,
                             policy: Factory(:downloadable_public_policy))
    @assay2 = Factory(:assay, title: 'a2', study: @study, contributor: @investigation.contributor,
                              policy: Factory(:downloadable_public_policy))
    @data_file = Factory(:data_file, title: 'df1', contributor: @investigation.contributor,
                                     content_blob: Factory(:doc_content_blob, original_filename: 'word.doc'),
                                     policy: Factory(:downloadable_public_policy))
    @publication = Factory(:publication, title: 'p1', contributor: @investigation.contributor,
                                         policy: Factory(:downloadable_public_policy))

    @assay.associate(@data_file)
    @assay2.associate(@data_file)
    Factory(:relationship, subject: @assay, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: @publication)
  end

  test 'snapshot number correctly set' do
    s1 = @investigation.create_snapshot
    s2 = @investigation.create_snapshot

    assert_equal 1, s1.snapshot_number
    assert_equal 2, s2.snapshot_number
  end

  test 'sha1 and md5 checksum' do
    s1 = @investigation.create_snapshot
    refute_nil s1.md5sum
    refute_nil s1.sha1sum
    assert_equal s1.content_blob.md5sum, s1.md5sum
    assert_equal s1.content_blob.sha1sum, s1.sha1sum

    assert_match(/\b([a-f0-9]{40})\b/, s1.sha1sum)
  end

  test 'can access snapshot metadata' do
    snapshot = @investigation.create_snapshot

    assert snapshot.metadata.is_a?(Hash)
    assert_equal @investigation.title, snapshot.metadata['title']
  end

  test 'can fetch by snapshot number' do
    s1 = @investigation.create_snapshot
    s2 = @investigation.create_snapshot
    s3 = @investigation.create_snapshot

    assert_equal 3, @investigation.snapshots.count
    assert_equal s2, @investigation.snapshot(2)
    assert_equal s3, @investigation.snapshot(3)
    assert_equal s1, @investigation.snapshot(1)
  end

  test 'snapshot captures state' do
    old_title = @investigation.title
    old_description = @investigation.description
    snapshot = @investigation.create_snapshot

    @investigation.update_attributes(title: 'New title', description: 'New description')

    assert_equal 'New title', @investigation.title
    assert_equal 'New description', @investigation.description
    assert_equal old_title, snapshot.title
    assert_equal old_description, snapshot.description
  end

  test 'generates sensible DOI' do
    snapshot = @investigation.create_snapshot

    assert_equal "#{Seek::Config.doi_prefix}/#{Seek::Config.doi_suffix}.investigation.#{@investigation.id}.#{snapshot.snapshot_number}", snapshot.suggested_doi
  end

  test 'generates valid DataCite metadata' do
    types = [@investigation.create_snapshot, @study.create_snapshot, @assay.create_snapshot]

    types.each do |type|
      assert type.datacite_metadata.validate, "#{type.class.name} did not generate valid metadata."
    end
  end

  test 'creates DOI via datacite' do
    datacite_mock

    snapshot = @investigation.create_snapshot

    res = snapshot.mint_doi
    assert res
    assert_equal snapshot.suggested_doi, snapshot.doi
    assert_empty snapshot.errors
  end

  test 'doi identifier' do
    datacite_mock

    snapshot = @investigation.create_snapshot
    doi = snapshot.mint_doi
    assert_equal "https://doi.org/#{doi}", snapshot.doi_identifier
  end

  test 'doi identifiers' do
    datacite_mock
    dois = []

    snapshot = @investigation.create_snapshot
    dois << snapshot.mint_doi
    @investigation.create_snapshot # one without a doi
    snapshot = @investigation.create_snapshot
    dois << snapshot.mint_doi

    identifiers = dois.collect{|doi| "https://doi.org/#{doi}"}

    @investigation.reload
    assert_equal 3,@investigation.snapshots.count
    assert_equal identifiers.sort, @investigation.doi_identifiers

  end

  test 'logs when minting DOI' do
    datacite_mock

    snapshot = @investigation.create_snapshot

    assert_equal 0, snapshot.doi_logs.count

    assert_difference('AssetDoiLog.count', 1) do
      snapshot.mint_doi
    end

    assert_equal 1, snapshot.doi_logs.count
    log = snapshot.doi_logs.last
    assert_equal AssetDoiLog::MINT, log.action
    assert_equal log.asset_type, snapshot.resource.class.name
    assert_equal log.asset_id, snapshot.resource.id
    assert_equal log.asset_version, snapshot.snapshot_number
  end

  test "doesn't create DOI if already minted" do
    datacite_mock

    snapshot = @investigation.create_snapshot
    snapshot.doi = '123'

    res = snapshot.mint_doi
    assert !res
    assert_equal '123', snapshot.doi
    assert_not_empty snapshot.errors
  end

  test 'has_doi?' do
    datacite_mock
    refute @investigation.has_doi?
    s1 = @investigation.create_snapshot
    @investigation.reload
    refute @investigation.has_doi?
    s1.update_attribute(:doi,'10.9999/seek.investigation.1.1')
    assert @investigation.has_doi?

    refute @study.has_doi?
    s1 = @study.create_snapshot
    @study.reload
    refute @study.has_doi?
    s1.update_attribute(:doi,'10.9999/seek.study.1.1')
    assert @study.has_doi?

    refute @assay.has_doi?
    s1 = @assay.create_snapshot
    @assay.reload
    refute @assay.has_doi?
    s1.update_attribute(:doi,'10.9999/seek.assay.1.1')
    assert @assay.has_doi?
  end

  test 'exports to Zenodo' do
    zenodo_mock

    snapshot = @investigation.create_snapshot
    snapshot.doi = '123'
    snapshot.save

    assert_nil snapshot.zenodo_deposition_id

    res = snapshot.export_to_zenodo(MockHelper::ZENODO_ACCESS_TOKEN)

    assert res
    assert_not_nil snapshot.zenodo_deposition_id
    assert_empty snapshot.errors
  end

  test 'publishes to Zenodo' do
    zenodo_mock

    snapshot = @investigation.create_snapshot
    snapshot.doi = '123'
    snapshot.save
    snapshot.export_to_zenodo(MockHelper::ZENODO_ACCESS_TOKEN)

    assert_nil snapshot.zenodo_record_url

    res = snapshot.publish_in_zenodo(MockHelper::ZENODO_ACCESS_TOKEN)

    assert res
    assert_not_nil snapshot.zenodo_record_url
    assert_empty snapshot.errors
  end

  test "doesn't export to Zenodo if already exported" do
    zenodo_mock

    snapshot = @investigation.create_snapshot
    snapshot.zenodo_deposition_id = 123
    snapshot.save

    res = snapshot.export_to_zenodo(MockHelper::ZENODO_ACCESS_TOKEN)

    assert !res
    assert_equal 123, snapshot.zenodo_deposition_id
    assert_not_empty snapshot.errors
  end

  test "doesn't publish to Zenodo if not exported first" do
    zenodo_mock

    snapshot = @investigation.create_snapshot
    snapshot.doi = '123'
    snapshot.save

    res = snapshot.publish_in_zenodo(MockHelper::ZENODO_ACCESS_TOKEN)

    assert !res
    assert_nil snapshot.zenodo_record_url
    assert_not_empty snapshot.errors
  end

  test 'study snapshot' do
    snapshot = @study.create_snapshot

    assert_equal 's1', snapshot.title
    assert_equal 2, snapshot.metadata['assays'].count
    assert_equal 2, snapshot.metadata['assays'].find { |a| a['title'] == 'a1' }['assets'].count
    assert_equal 1, snapshot.metadata['assays'].find { |a| a['title'] == 'a2' }['assets'].count

    titles = extract_keys(snapshot.metadata, 'title')
    assert_not_includes titles, 'i1'
    assert_includes titles, 's1'
    assert_includes titles, 'a1'
    assert_includes titles, 'a2'
    assert_includes titles, 'df1'
    assert_includes titles, 'p1'
  end

  test 'assay snapshot' do

    snapshot = @assay.create_snapshot

    assert_equal 'a1', snapshot.title
    assert_equal 2, snapshot.metadata['assets'].count

    titles = extract_keys(snapshot.metadata, 'title')
    assert_not_includes titles, 'i1'
    assert_not_includes titles, 's1'
    assert_not_includes titles, 'a2'
    assert_includes titles, 'a1'
    assert_includes titles, 'df1'
    assert_includes titles, 'p1'
  end

  test 're-indexes parent model when DOI created' do
    snapshot = @assay.create_snapshot

    assert_difference('ReindexingQueue.count', 1) do
      snapshot.doi = '10.5072/test'
      snapshot.save
    end

    reindex_job = ReindexingQueue.last

    assert_equal snapshot.resource_type, reindex_job.item_type
    assert_equal snapshot.resource_id, reindex_job.item_id
  end

  test 'snapshots destroyed with parent object' do
    snapshot1 = @study.create_snapshot
    snapshot2 = @study.create_snapshot

    assert_difference('Snapshot.count', -2) do
      disable_authorization_checks { @study.destroy }
    end

    assert snapshot1.destroyed?
    assert snapshot2.destroyed?
  end

  private

  def extract_keys(o, key)
    results = []
    if o.is_a?(Hash)
      results << o[key] if o[key]
      results += o.map { |_k, v| extract_keys(v, key) }
    elsif o.is_a?(Array)
      results += o.map { |v| extract_keys(v, key) }
    end

    results.flatten
  end
end
