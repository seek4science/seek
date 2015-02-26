require 'test_helper'
class GeneratorTest < ActiveSupport::TestCase

  test "generate for investigation" do
    User.current_user = Factory(:person).user
    filename = "robundle.zip"
    inv = Factory(:experimental_assay,:assay_assets=>[Factory(:assay_asset),Factory(:assay_asset)]).investigation
    Dir.mktmpdir do |dir|
      filename = File.join(dir,filename)
      open(filename,"w+") do |f|
        f2 = Seek::ResearchObjects::Generator.instance.generate(inv,f)
        assert_equal f,f2
      end
      assert File.exist?(filename)
      FileUtils.copy filename,"/tmp/fish.zip"
    end

  end

  test "generate for investigation no file" do
    inv = Factory(:experimental_assay,:assay_assets=>[Factory(:assay_asset),Factory(:assay_asset)]).investigation
    file = Seek::ResearchObjects::Generator.instance.generate(inv)
    refute_nil file
    assert File.exist?(file)
  end

end