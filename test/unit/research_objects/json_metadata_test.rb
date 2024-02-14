require 'test_helper'

class JsonMetaTest < ActiveSupport::TestCase
  test 'metadata contents' do
    contributor = FactoryBot.create(:person, orcid: '0000-0002-1694-233X')
    item = FactoryBot.create(:model_with_image, description: 'model with an image', policy: FactoryBot.create(:public_policy), contributor: contributor)
    json = Seek::ResearchObjects::JsonMetadata.instance.metadata_content(item)
    json = JSON.parse(json)

    assert_equal item.id, json['id']
    assert_equal item.title, json['title']
    assert_equal 'model with an image', json['description']
    assert_equal 1, json['version']
    json_contributor = json['contributor']
    assert_equal contributor.name, json_contributor['name']
    assert_equal "http://localhost:3000/people/#{contributor.id}", json_contributor['uri']
    assert_equal 'https://orcid.org/0000-0002-1694-233X', json_contributor['orcid']

    assert_equal ["models/#{item.ro_package_path_id_fragment}/cronwright.xml", "models/#{item.ro_package_path_id_fragment}/file_picture.png"], json['contains'].sort
  end

  test 'metadata contents for assay' do
    contributor = FactoryBot.create(:person, orcid: '0000-0002-1694-233X')
    item = FactoryBot.create(:experimental_assay, description: 'my ro assay', policy: FactoryBot.create(:public_policy), contributor: contributor)
    json = Seek::ResearchObjects::JsonMetadata.instance.metadata_content(item)
    json = JSON.parse(json)

    assert_equal item.id, json['id']
    assert_equal item.title, json['title']
    assert_equal 'my ro assay', json['description']

    assert_equal 'http://jermontology.org/ontology/JERMOntology#Experimental_assay_type', json['assay_type_uri']
    assert_equal 'http://jermontology.org/ontology/JERMOntology#Technology_type', json['technology_type_uri']

    json_contributor = json['contributor']
    assert_equal contributor.name, json_contributor['name']
    assert_equal "http://localhost:3000/people/#{contributor.id}", json_contributor['uri']
    assert_equal 'https://orcid.org/0000-0002-1694-233X', json_contributor['orcid']
  end

  test 'metadata contents for publication' do
    item = FactoryBot.create :publication, doi: '10.1111/ecog.01552', pubmed_id: nil
    json = Seek::ResearchObjects::JsonMetadata.instance.metadata_content(item)
    json = JSON.parse(json)

    assert_equal item.id, json['id']
    assert_equal item.title, json['title']
    assert_empty json['contains']

    assert_equal '10.1111/ecog.01552', json['doi']
    assert_equal 'https://doi.org/10.1111/ecog.01552', json['doi_uri']
    assert_nil json['pubmed_id']
    assert_nil json['pubmed_uri']

    item = FactoryBot.create :publication, doi: nil, pubmed_id: '4'
    json = Seek::ResearchObjects::JsonMetadata.instance.metadata_content(item)
    json = JSON.parse(json)

    assert_equal item.id, json['id']
    assert_equal item.title, json['title']

    assert_equal 4, json['pubmed_id']
    assert_equal 'https://www.ncbi.nlm.nih.gov/pubmed/4', json['pubmed_uri']
    assert_nil json['doi']
    assert_nil json['doi_uri']
  end

  test 'should not encode filename in encodes block if it has a space' do
    item = FactoryBot.create :data_file, content_blob: FactoryBot.create(:content_blob, original_filename: 'file with space.xls'), policy: FactoryBot.create(:public_policy)
    json = Seek::ResearchObjects::JsonMetadata.instance.metadata_content(item)
    json = JSON.parse(json)
    filename = json['contains'].first
    assert_equal "data_files/#{item.ro_package_path_id_fragment}/file with space.xls", filename
  end
end
