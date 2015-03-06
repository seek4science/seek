require 'test_helper'

class GeneratorTest < ActiveSupport::TestCase

  test "generate for investigation" do
    User.current_user = Factory(:person).user
    filename = "robundle.zip"

    Dir.mktmpdir do |dir|
      filename = File.join(dir,filename)
      open(filename,"w+") do |f|
        f2 = Seek::ResearchObjects::Generator.instance.generate(investigation,f)
        assert_equal f,f2
      end
      assert File.exist?(filename)
    end
  end

  test "generate for investigation no file" do
    inv = investigation
    file = Seek::ResearchObjects::Generator.instance.generate(inv)
    refute_nil file
    assert File.exist?(file)
    check_contents(file,inv)
  end



  private

  def check_contents file,inv
    assert File.exist?(file)
    assert_equal Seek::ResearchObjects::Generator::DEFAULT_FILENAME,File.basename(file.path)
    paths = Zip::File.open(file) do |zip_file|
      zip_file.collect do |entry|
        entry.name
      end
    end
    inv.studies.each do |study|
      assert_include paths, "investigations/#{inv.id}/studies/#{study.id}/metadata.rdf"
      assert_include paths, "investigations/#{inv.id}/studies/#{study.id}/metadata.json"
      study.assays.each do |assay|
        assert_include paths, "investigations/#{inv.id}/studies/#{study.id}/assays/#{assay.id}/metadata.rdf"
        assert_include paths, "investigations/#{inv.id}/studies/#{study.id}/assays/#{assay.id}/metadata.json"
      end
    end
    assets = inv.assets
    assert_equal 6,assets.count
    assets.each do |asset|
      assert_include paths,"#{asset.class.name.underscore.pluralize}/#{asset.id}/metadata.json"
      assert_include paths,"#{asset.class.name.underscore.pluralize}/#{asset.id}/metadata.rdf"
    end

    #simple check for assets contents, using model with image to check the image is there
    assert_include paths,"models/#{@assay_asset5.asset.id}/cronwright.xml"
    assert_include paths,"models/#{@assay_asset5.asset.id}/file_picture.png"

    #and a model with 2 files
    assert_include paths,"models/#{@assay_asset6.asset.id}/cronwright.xml"
    assert_include paths,"models/#{@assay_asset6.asset.id}/rightfield.xls"

    #and finally the RO specific files
    assert_include paths,"mimetype"
    assert_include paths,".ro/manifest.json"

  end

  def investigation
    stub_request(:head, "http://www.abc.com/").to_return(:status=>200,:headers=>{'Content-Type' => 'text/html'})

    assay_asset1 = Factory(:assay_asset,:asset=>Factory(:data_file,:policy=>Factory(:public_policy)))
    assay_asset2 = Factory(:assay_asset,:asset=>Factory(:sop,:policy=>Factory(:public_policy)))
    assay_asset3 = Factory(:assay_asset,:asset=>Factory(:model,:policy=>Factory(:public_policy)))
    assay_asset4 = Factory(:assay_asset,:asset=>Factory(:url_sop,:policy=>Factory(:public_policy)))
    @assay_asset5 = Factory(:assay_asset,:asset=>Factory(:model_with_image,:policy=>Factory(:public_policy)))
    @assay_asset6 = Factory(:assay_asset,:asset=>Factory(:model_2_files,:policy=>Factory(:public_policy)))

    @assay_asset5.asset.save! #this seems to be required to save the model_image and record its association.

    inv = Factory(:investigation,:policy=>Factory(:public_policy))
    study = Factory(:study,:policy=>Factory(:public_policy),:investigation=>inv)

    Factory(:experimental_assay,
                    :assay_assets=>[assay_asset1,assay_asset2,assay_asset3,assay_asset4],
                    :policy=>Factory(:public_policy),
                    :study=>study)

    Factory(:experimental_assay,
            :assay_assets=>[@assay_asset5,@assay_asset6],
            :policy=>Factory(:public_policy),
            :study=>study)
    inv
  end

end