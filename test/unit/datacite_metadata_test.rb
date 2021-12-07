require 'test_helper'

class DataciteMetadataTest < ActiveSupport::TestCase
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

  test 'generates valid DataCite metadata' do
    types = [@investigation.create_snapshot, @study.create_snapshot, @assay.create_snapshot,
             Factory(:data_file, policy: Factory(:public_policy)).latest_version,
             Factory(:model, policy: Factory(:public_policy)).latest_version,
             Factory(:sop, policy: Factory(:public_policy)).latest_version,
             Factory(:workflow, policy: Factory(:public_policy)).latest_version,
             Factory(:document, policy: Factory(:public_policy)).latest_version]

    types.each do |type|
      assert type.datacite_metadata.validate, "#{type.class.name} did not generate valid metadata."
    end
  end

  test 'DataCite resource types' do
    thing = @investigation.create_snapshot
    assert_equal 'Investigation', thing.datacite_resource_type
    assert_equal 'Collection', thing.datacite_resource_type_general

    thing = @study.create_snapshot
    assert_equal 'Study', thing.datacite_resource_type
    assert_equal 'Collection', thing.datacite_resource_type_general

    thing = @assay.create_snapshot
    assert_equal 'Assay', thing.datacite_resource_type
    assert_equal 'Collection', thing.datacite_resource_type_general

    thing = Factory(:data_file, policy: Factory(:public_policy)).latest_version
    assert_equal 'Dataset', thing.datacite_resource_type
    assert_equal 'Dataset', thing.datacite_resource_type_general

    thing = Factory(:model, policy: Factory(:public_policy)).latest_version
    assert_equal 'Model', thing.datacite_resource_type
    assert_equal 'Model', thing.datacite_resource_type_general

    thing = Factory(:sop, policy: Factory(:public_policy)).latest_version
    assert_equal 'SOP', thing.datacite_resource_type
    assert_equal 'Text', thing.datacite_resource_type_general

    thing = Factory(:workflow, policy: Factory(:public_policy)).latest_version
    assert_equal 'Workflow', thing.datacite_resource_type
    assert_equal 'Workflow', thing.datacite_resource_type_general

    thing = Factory(:document, policy: Factory(:public_policy)).latest_version
    assert_equal 'Document', thing.datacite_resource_type
    assert_equal 'Text', thing.datacite_resource_type_general
  end

  test 'DataCite metadata' do
    someone = Factory(:person, first_name: 'Jane', last_name: 'Bloggs')
    thing = Factory(:data_file, policy: Factory(:public_policy),
                    title: 'The title',
                    description: 'The description',
                    creators: [someone],
                    contributor: Factory(:person, first_name: 'Joe', last_name: 'Bloggs', orcid: 'https://orcid.org/0000-0002-1694-233X')
    ).latest_version
    thing.assets_creators.create!(given_name: 'Phil', family_name: 'Collins', orcid: 'https://orcid.org/0000-0002-1694-233X')

    metadata = thing.datacite_metadata
    xml = metadata.build
    parsed = Nokogiri::XML.parse(xml)
    assert_equal 'http://datacite.org/schema/kernel-4', parsed.namespaces['xmlns']
    assert_equal 'http://www.w3.org/2001/XMLSchema-instance', parsed.namespaces['xmlns:xsi']
    assert_equal 'http://datacite.org/schema/kernel-4 http://schema.datacite.org/meta/kernel-4.3/metadata.xsd', parsed.xpath('//xmlns:resource/@xsi:schemaLocation').first.text
    resource =  parsed.xpath('//xmlns:resource').first
    assert_equal 'The title', resource.xpath('./xmlns:titles/xmlns:title').first.text
    assert_equal 'The description', resource.xpath('./xmlns:descriptions/xmlns:description').first.text
    assert_equal 2, resource.xpath('./xmlns:creators/xmlns:creator').length
    phil = parsed.xpath("//xmlns:resource/xmlns:creators/xmlns:creator[xmlns:creatorName/text()='Collins, Phil']").first
    jane = parsed.xpath("//xmlns:resource/xmlns:creators/xmlns:creator[xmlns:creatorName/text()='Bloggs, Jane']").first
    assert_equal 'Collins, Phil', phil.xpath('./xmlns:creatorName').first.text
    assert_equal 'https://orcid.org/0000-0002-1694-233X', phil.xpath('./xmlns:nameIdentifier').first.text
    assert_equal 'Bloggs, Jane', jane.xpath('./xmlns:creatorName').first.text
    assert_nil jane.xpath('./xmlns:nameIdentifier').first
    assert_equal 'ORCID', resource.xpath('./xmlns:creators/xmlns:creator/xmlns:nameIdentifier/@nameIdentifierScheme').first.text
    assert_equal 'https://orcid.org', resource.xpath('./xmlns:creators/xmlns:creator/xmlns:nameIdentifier/@schemeURI').first.text
    assert_equal thing.created_at.year.to_s, resource.xpath('./xmlns:publicationYear').first.text
    assert_equal Seek::Config.instance_name, resource.xpath('./xmlns:publisher').first.text
    assert_equal 'Dataset', resource.xpath('./xmlns:resourceType').first.text
    assert_equal 'Dataset', resource.xpath('./xmlns:resourceType/@resourceTypeGeneral').first.text
  end
end
