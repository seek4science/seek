require 'test_helper'

class DataFilesAndModelsSeederTest < ActiveSupport::TestCase
  def setup
    User.current_user = nil
    @admin_person = FactoryBot.create(:admin, first_name: 'Admin', last_name: 'Person')
    @guest_person = FactoryBot.create(:person, first_name: 'Guest', last_name: 'User')
    @project = @guest_person.projects.first
    @exp_assay = FactoryBot.create(:experimental_assay, contributor: @guest_person)
    @model_assay = FactoryBot.create(:modelling_assay, contributor: @guest_person)
    @seed_data_dir = File.join(Rails.root, 'db', 'seeds', 'example_data')
  end

  def teardown
    User.current_user = nil
  end

  test 'seeds data files' do
    seeder = Seek::ExampleData::DataFilesAndModelsSeeder.new(
      @project, @guest_person, @admin_person, @exp_assay, @model_assay, @seed_data_dir
    )
    result = nil
    assert_difference('DataFile.count', 2) do
      result = seeder.seed
      assert_includes result.keys, :data_file1
      assert_includes result.keys, :data_file2
      assert_not_nil result[:data_file1]
      assert_not_nil result[:data_file2]
    end
    df1 = result[:data_file1].reload
    assert_equal 'ValidationReference.xlsx', df1.content_blob.original_filename
    assert df1.content_blob.file_exists?
    assert_equal 'Metabolite concentrations during reconstituted enzyme incubation', df1.title
    assert_equal 'The purified enzymes, PGK, GAPDH, TPI and FBPAase were incubated at 70 C en conversion of 3PG to F6P was followed.',
                 df1.description
    assert_equal @project, df1.projects.first
    assert_equal @guest_person, df1.contributor
    assert_nil df1.license
    assert_equal [@guest_person], df1.creators
    assert_nil df1.other_creators
    assert_empty df1.tags

    df2 = result[:data_file2].reload
    assert_equal 'combinedPlot.jpg', df2.content_blob.original_filename
    assert df2.content_blob.file_exists?
    assert_equal 'Model simulation and Exp data for reconstituted system', df2.title
    assert_equal 'Experimental data for the reconstituted system are plotted together with the model prediction.',
                 df2.description
    assert_equal @project, df2.projects.first
    assert_equal @guest_person, df2.contributor
    assert_equal 'CC-BY-SA-4.0', df2.license
    assert_equal [@admin_person], df2.creators
    assert_equal 'Person A, Person B', df2.other_creators
    assert_equal %w[metabolism modelling gluconeogenesis], df2.tags
  end

  test 'seeds model' do
    seeder = Seek::ExampleData::DataFilesAndModelsSeeder.new(
      @project, @guest_person, @admin_person, @exp_assay, @model_assay, @seed_data_dir
    )
    result = nil
    assert_difference('Model.count', 1) do
      result = seeder.seed
      assert_includes result.keys, :model
      assert_not_nil result[:model]
    end
    model = result[:model].reload

    assert_equal 'Mathematical model for the combined four enzyme system', model.title
    assert_equal 'The PGK, GAPDH, TPI and FBPAase were modelled together using the individual rate equations. Closed system.',
                 model.description
    assert_equal @project, model.projects.first
    assert_equal @guest_person, model.contributor
    assert_equal 6, model.content_blobs.count
    file_names = %w[ssolfGluconeogenesisOpenAnn.dat ssolfGluconeogenesisOpenAnn.xml ssolfGluconeogenesisOpenAnn.xml
                    ssolfGluconeogenesisAnn.xml ssolfGluconeogenesisClosed.xml ssolfGluconeogenesis.xml]
    assert_equal file_names, model.content_blobs.map(&:original_filename)
    assert model.content_blobs.all?(&:file_exists?)
  end

  test 'seeds SOP' do
    seeder = Seek::ExampleData::DataFilesAndModelsSeeder.new(
      @project, @guest_person, @admin_person, @exp_assay, @model_assay, @seed_data_dir
    )
    result = nil
    assert_difference('Sop.count', 1) do
      result = seeder.seed
      assert_includes result.keys, :sop
      assert_not_nil result[:sop]
    end
    sop = result[:sop].reload

    assert_equal 'Reconstituted Enzyme System Protocol', sop.title
    assert_equal 'Standard operating procedure for reconstituting the gluconeogenic enzyme system from Sulfolobus solfataricus to study metabolic pathway efficiency at high temperatures.',
                 sop.description
    assert_equal @project, sop.projects.first
    assert_equal @guest_person, sop.contributor
    assert_equal 'test_sop.txt', sop.content_blob.original_filename
    assert sop.content_blob.file_exists?
    assert_equal %w[protocol enzymology thermophile], sop.tags
    assert_equal 'CC-BY-SA-4.0', sop.license
  end
end
