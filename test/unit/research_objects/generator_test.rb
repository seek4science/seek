require 'test_helper'

class GeneratorTest < ActiveSupport::TestCase

  test 'generate for investigation' do
    filename = 'robundle.zip'

    Dir.mktmpdir do |dir|
      filename = File.join(dir, filename)
      open(filename, 'w+') do |f|
        inv = investigation
        f2 = Seek::ResearchObjects::Generator.new(inv).generate(f)
        assert_equal f, f2
        check_contents(f2, inv)
      end
    end
  end

  test 'generate for investigation no file' do
    inv = investigation
    file = Seek::ResearchObjects::Generator.new(inv).generate
    refute_nil file
    check_contents(file, inv)
    assert_equal Seek::ResearchObjects::Generator::DEFAULT_FILENAME, File.basename(file.path)
  end

  test 'generate for investigation with duplicate files' do
    inv = investigation
    model = FactoryBot.create(:model, policy: FactoryBot.create(:public_policy))
    disable_authorization_checks do
      model.content_blobs << FactoryBot.create(:doc_content_blob, original_filename: 'xxx.txt')
      model.content_blobs << FactoryBot.create(:doc_content_blob, original_filename: 'xxx.txt')
      model.content_blobs << FactoryBot.create(:doc_content_blob, original_filename: 'xxx.txt')
      model.save!
      inv.assays.last.associate(model)
    end
    inv.reload
    file = Seek::ResearchObjects::Generator.new(inv).generate
    paths = Zip::File.open(file) do |zip_file|
      zip_file.collect(&:name)
    end
    assert_includes paths, "models/#{model.ro_package_path_id_fragment}/xxx.txt"
    assert_includes paths, "models/#{model.ro_package_path_id_fragment}/1-xxx.txt"
    assert_includes paths, "models/#{model.ro_package_path_id_fragment}/2-xxx.txt"
  end

  test 'generate assay with a sample' do
    assay = FactoryBot.create(:assay,policy:FactoryBot.create(:public_policy))
    sample = FactoryBot.create(:sample,policy:FactoryBot.create(:public_policy))
    AssayAsset.create assay: assay, asset: sample, direction: AssayAsset::Direction::INCOMING
    assay.reload
    assert_equal [sample],assay.samples
    file = Seek::ResearchObjects::Generator.new(assay).generate
  end

  private

  def check_contents(file, inv)
    assert File.exist?(file)
    paths = Zip::File.open(file) do |zip_file|
      zip_file.collect(&:name)
    end
    inv.studies.each do |study|
      assert_includes paths, "#{study.research_object_package_path}metadata.rdf"
      assert_includes paths, "#{study.research_object_package_path}metadata.json"
      study.assays.each do |assay|
        assert_includes paths, "#{assay.research_object_package_path}metadata.rdf"
        assert_includes paths, "#{assay.research_object_package_path}metadata.json"
      end
    end
    assets = inv.assets
    assert_equal 7, assets.count
    assets.each do |asset|
      assert_includes paths, "#{asset.research_object_package_path}metadata.json"
      assert_includes paths, "#{asset.research_object_package_path}metadata.json"
    end

    # simple check for assets contents, using model with image to check the image is there
    assert_includes paths, "models/#{@assay_asset5.asset.ro_package_path_id_fragment}/cronwright.xml"
    assert_includes paths, "models/#{@assay_asset5.asset.ro_package_path_id_fragment}/file_picture.png"

    # and a model with 2 files
    assert_includes paths, "models/#{@assay_asset6.asset.ro_package_path_id_fragment}/cronwright.xml"
    assert_includes paths, "models/#{@assay_asset6.asset.ro_package_path_id_fragment}/rightfield.xls"

    # and finally the RO specific files
    assert_includes paths, 'mimetype'
    assert_includes paths, '.ro/manifest.json'
  end

  def investigation
    stub_request(:head, 'http://www.abc.com/').to_return(status: 200, headers: { 'Content-Type' => 'text/html' })

    assay_asset1 = FactoryBot.create(:assay_asset, asset: FactoryBot.create(:data_file, policy: FactoryBot.create(:public_policy)))
    assay_asset2 = FactoryBot.create(:assay_asset, asset: FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy)))
    assay_asset3 = FactoryBot.create(:assay_asset, asset: FactoryBot.create(:model, policy: FactoryBot.create(:public_policy)))
    assay_asset4 = FactoryBot.create(:assay_asset, asset: FactoryBot.create(:url_sop, policy: FactoryBot.create(:public_policy)))
    @assay_asset5 = FactoryBot.create(:assay_asset, asset: FactoryBot.create(:model_with_image, policy: FactoryBot.create(:public_policy)))
    @assay_asset6 = FactoryBot.create(:assay_asset, asset: FactoryBot.create(:model_2_files, policy: FactoryBot.create(:public_policy)))

    @assay_asset5.asset.save! # this seems to be required to save the model_image and record its association.

    contributor = FactoryBot.create(:person)

    inv = FactoryBot.create(:investigation, policy: FactoryBot.create(:public_policy),contributor:contributor)
    study = FactoryBot.create(:study, policy: FactoryBot.create(:public_policy), investigation: inv, contributor:contributor)

    expassay = FactoryBot.create(:modelling_assay,
                       assay_assets: [assay_asset1, assay_asset2, assay_asset3, assay_asset4],
                       policy: FactoryBot.create(:public_policy),
                       study: study,
                       contributor:contributor)

    FactoryBot.create :relationship, subject: expassay, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: FactoryBot.create(:publication)

    FactoryBot.create(:modelling_assay,
            assay_assets: [@assay_asset5, @assay_asset6],
            policy: FactoryBot.create(:public_policy),
            study: study,
            contributor:contributor)
    inv
  end
end
