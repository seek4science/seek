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
      FileUtils.copy filename,"/tmp/fish.zip"
    end

  end

  test "generate for investigation no file" do
    file = Seek::ResearchObjects::Generator.instance.generate(investigation)
    refute_nil file
    assert File.exist?(file)
  end

  def investigation
    stub_request(:head, "http://www.abc.com/").to_return(:status=>200,:headers=>{'Content-Type' => 'text/html'})

    asset1 = Factory(:assay_asset,:asset=>Factory(:data_file,:policy=>Factory(:public_policy)))
    asset2 = Factory(:assay_asset,:asset=>Factory(:sop,:policy=>Factory(:public_policy)))
    asset3 = Factory(:assay_asset,:asset=>Factory(:model,:policy=>Factory(:public_policy)))
    asset4 = Factory(:assay_asset,:asset=>Factory(:url_sop,:policy=>Factory(:public_policy)))

    inv = Factory(:investigation,:policy=>Factory(:public_policy))
    study = Factory(:study,:policy=>Factory(:public_policy),:investigation=>inv)

    assay = Factory(:experimental_assay,
                    :assay_assets=>[asset1,asset2,asset3,asset4],
                    :policy=>Factory(:public_policy),
                    :study=>study)
    inv
  end

end