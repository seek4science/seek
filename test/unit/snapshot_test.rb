require 'test_helper'

class SnapshotTest < ActiveSupport::TestCase

  include MockHelper

  fixtures :investigations
  
  setup do
    @investigation = Factory(:investigation, :description => 'not blank', :policy => Factory(:publicly_viewable_policy))
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
    assert_equal s1.content_blob.md5sum,s1.md5sum
    assert_equal s1.content_blob.sha1sum,s1.sha1sum

    assert_match /\b([a-f0-9]{40})\b/,s1.sha1sum
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

    @investigation.update_attributes(title: "New title", description: "New description")

    assert_equal "New title", @investigation.title
    assert_equal "New description", @investigation.description
    assert_equal old_title, snapshot.title
    assert_equal old_description, snapshot.description
  end

  test 'generates sensible DOI' do
    snapshot = @investigation.create_snapshot

    assert_equal "#{Seek::Config.doi_prefix}/#{Seek::Config.doi_suffix}.investigation.#{@investigation.id}.#{snapshot.snapshot_number}", snapshot.suggested_doi
  end

  test 'generates valid DataCite metadata' do
    snapshot = @investigation.create_snapshot

    assert snapshot.datacite_metadata.validate
  end

  test 'creates DOI via datacite' do
    datacite_mock

    snapshot = @investigation.create_snapshot

    res = snapshot.mint_doi
    assert res
    assert_equal snapshot.suggested_doi, snapshot.doi
    assert_empty snapshot.errors
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

  test "exports to Zenodo" do
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

  test "publishes to Zenodo" do
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

  test "doesn't export to Zenodo if no DOI" do
    zenodo_mock

    snapshot = @investigation.create_snapshot

    res = snapshot.export_to_zenodo(MockHelper::ZENODO_ACCESS_TOKEN)

    assert !res
    assert_nil snapshot.zenodo_deposition_id
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

end
