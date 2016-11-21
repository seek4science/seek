require 'test_helper'

class JsonMetaTest < ActiveSupport::TestCase

  test "metadata contents" do
    contributor = Factory(:person,:orcid=>"0000-0002-1694-233X")
    item = Factory(:model_with_image,:description=>"model with an image",:policy=>Factory(:public_policy),:contributor=>contributor)
    json = Seek::ResearchObjects::JSONMetadata.instance.metadata_content(item)
    json = JSON.parse(json)

    assert_equal item.id,json["id"]
    assert_equal item.title,json["title"]
    assert_equal "model with an image",json["description"]
    assert_equal 1,json["version"]
    json_contributor = json["contributor"]
    assert_equal contributor.name,json_contributor["name"]
    assert_equal "http://localhost:3000/people/#{contributor.id}",json_contributor["uri"]
    assert_equal "http://orcid.org/0000-0002-1694-233X",json_contributor["orcid"]

    assert_equal ["models/#{item.ro_package_path_id_fragment}/cronwright.xml", "models/#{item.ro_package_path_id_fragment}/file_picture.png"],json["contains"].sort
  end

  test "metadata contents for assay" do
    contributor = Factory(:person,:orcid=>"0000-0002-1694-233X")
    item = Factory(:experimental_assay,:description=>"my ro assay",:policy=>Factory(:public_policy),:contributor=>contributor)
    json = Seek::ResearchObjects::JSONMetadata.instance.metadata_content(item)
    json = JSON.parse(json)

    assert_equal item.id,json["id"]
    assert_equal item.title,json["title"]
    assert_equal "my ro assay",json["description"]

    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Experimental_assay_type",json["assay_type_uri"]
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Technology_type",json["technology_type_uri"]

    json_contributor = json["contributor"]
    assert_equal contributor.name,json_contributor["name"]
    assert_equal "http://localhost:3000/people/#{contributor.id}",json_contributor["uri"]
    assert_equal "http://orcid.org/0000-0002-1694-233X",json_contributor["orcid"]
  end

  test "metadata contents for publication" do
    item = Factory :publication, :doi=>"10.111.1.1", :pubmed_id=>nil
    json = Seek::ResearchObjects::JSONMetadata.instance.metadata_content(item)
    json = JSON.parse(json)

    assert_equal item.id,json["id"]
    assert_equal item.title,json["title"]
    assert_empty json["contains"]

    assert_equal "10.111.1.1",json["doi"]
    assert_equal "https://dx.doi.org/10.111.1.1",json["doi_uri"]
    assert_nil json["pubmed_id"]
    assert_nil json["pubmed_uri"]

    item = Factory :publication, :doi=>nil, :pubmed_id=>"4"
    json = Seek::ResearchObjects::JSONMetadata.instance.metadata_content(item)
    json = JSON.parse(json)

    assert_equal item.id,json["id"]
    assert_equal item.title,json["title"]

    assert_equal 4,json["pubmed_id"]
    assert_equal "https://www.ncbi.nlm.nih.gov/pubmed/4",json["pubmed_uri"]
    assert_nil json["doi"]
    assert_nil json["doi_uri"]
  end

  test "should not encode filename in encodes block if it has a space" do
    item = Factory :data_file,content_blobs:[Factory(:content_blob,:original_filename=>"file with space.xls")],:policy=>Factory(:public_policy)
    json = Seek::ResearchObjects::JSONMetadata.instance.metadata_content(item)
    json = JSON.parse(json)
    filename = json["contains"].first
    assert_equal "data_files/#{item.ro_package_path_id_fragment}/file with space.xls",filename
  end

end