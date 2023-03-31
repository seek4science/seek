require 'test_helper'

class InternationalizationTest < ActiveSupport::TestCase

  include AuthenticatedTestHelper
  
  setup do
    @original_load_path = I18n.load_path
    apply_overrides
  end

  teardown do
    reset_translations
  end

  test 'assay' do
    assert_equal 'Assay_test', (I18n.t 'assay')
    assert_equal 'Assay', (I18n.t 'assays.assay')
    assert_equal 'Experimental assay', (I18n.t 'assays.experimental_assay')
    assert_equal 'Modelling analysis', (I18n.t 'assays.modelling_analysis')
  end

  test 'sop' do
    assert_equal 'SOP_test', (I18n.t 'sop')
  end

  test 'presentation' do
    assert_equal 'Presentation_test', (I18n.t 'presentation')
  end

  test 'data file' do
    assert_equal 'Data file_test', (I18n.t 'data_file')
  end

  test 'investigation' do
    assert_equal 'Investigation_test', (I18n.t 'investigation')
  end

  test 'study' do
    assert_equal 'Study_test', (I18n.t 'study')
  end

  test 'model' do
    assert_equal 'Model_test', (I18n.t 'model')
  end

  test 'event' do
    assert_equal 'Event_test', (I18n.t 'event')
  end

  test 'project' do
    assert_equal 'Project_test', (I18n.t 'project')
  end

  test 'institution' do
    assert_equal 'Institution_test', (I18n.t 'institution')
  end

  test 'person' do
    assert_equal 'Person_test', (I18n.t 'person')
  end

  test 'workflow' do
    assert_equal 'Workflow_test', (I18n.t 'workflow')
  end

  test 'publication' do
    assert_equal 'Publication_test', (I18n.t 'publication')
  end

  test 'document' do
    assert_equal 'Document_test', (I18n.t 'document')
  end

  test 'file_template' do
    assert_equal 'File Template_test', (I18n.t 'file_template')
  end

  test 'collection' do
    assert_equal 'Collection_test', (I18n.t 'collection')
  end

  test 'sample' do
    assert_equal 'Sample_test', (I18n.t 'sample')
  end

  test 'template' do
    assert_equal 'Template_test', (I18n.t 'template')
  end

  test 'sample_type' do
    assert_equal 'Sample type_test', (I18n.t 'sample_type')
  end

  test 'strain' do
    assert_equal 'Strain_test', (I18n.t 'strain')
  end

  test 'organism' do
    assert_equal 'Organism_test', (I18n.t 'organism')
  end

  
  test "programme active record model" do
    assert I18n.exists?("activerecord.models.programme")
    assert assert_equal "Programme_test", Programme.model_name.human
    assert assert_equal (I18n.t 'programme'), Programme.model_name.human
  end

  test "project active record model" do
    assert I18n.exists?("activerecord.models.project")
    assert assert_equal "Project_test", Project.model_name.human
    assert assert_equal (I18n.t 'project'), Project.model_name.human
  end
  
  test "institution active record model" do
    assert I18n.exists?("activerecord.models.institution")
    assert assert_equal "Institution_test", Institution.model_name.human
    assert assert_equal (I18n.t 'institution'), Institution.model_name.human
  end

  test "person active record model" do
    assert I18n.exists?("activerecord.models.person")
    assert assert_equal "Person_test", Person.model_name.human
    assert assert_equal (I18n.t 'person'), Person.model_name.human
  end
  
 test "investigation active record model" do
    assert I18n.exists?("activerecord.models.investigation")
    assert assert_equal "Investigation_test", Investigation.model_name.human
    assert assert_equal (I18n.t 'investigation'), Investigation.model_name.human
  end

  test "study active record model" do
    assert I18n.exists?("activerecord.models.study")
    assert assert_equal "Study_test", Study.model_name.human
    assert assert_equal (I18n.t 'study'), Study.model_name.human
  end

  test "assay active record model" do
    assert I18n.exists?("activerecord.models.assay")
    assert assert_equal "Assay_test", Assay.model_name.human
    assert assert_equal (I18n.t 'assay'), Assay.model_name.human
  end
     
  test "data_file active record model" do
    assert I18n.exists?("activerecord.models.data_file")
    assert assert_equal "Data file_test", DataFile.model_name.human
    assert assert_equal (I18n.t 'data_file'), DataFile.model_name.human
  end

  test "model active record model" do
    assert I18n.exists?("activerecord.models.model")
    assert assert_equal "Model_test", Model.model_name.human
    assert assert_equal (I18n.t 'model'), Model.model_name.human
  end

  test "sop active record model" do
    assert I18n.exists?("activerecord.models.sop")
    assert assert_equal "SOP_test", Sop.model_name.human
    assert assert_equal (I18n.t 'sop'), Sop.model_name.human
  end
      
  test "workflow active record model" do
    assert I18n.exists?("activerecord.models.workflow")
    assert assert_equal "Workflow_test", Workflow.model_name.human
    assert assert_equal (I18n.t 'workflow'), Workflow.model_name.human
  end

  test "publication active record model" do
    assert I18n.exists?("activerecord.models.publication")
    assert assert_equal "Publication_test", Publication.model_name.human
    assert assert_equal (I18n.t 'publication'), Publication.model_name.human
  end

  test "document active record model" do
    assert I18n.exists?("activerecord.models.document")
    assert assert_equal "Document_test", Document.model_name.human
    assert assert_equal (I18n.t 'document'), Document.model_name.human
  end

  test "file_template active record model" do
    assert I18n.exists?("activerecord.models.file_template")
    assert assert_equal "File Template_test", FileTemplate.model_name.human
    assert assert_equal (I18n.t 'file_template'), FileTemplate.model_name.human
  end

  test "collection active record model" do
    assert I18n.exists?("activerecord.models.collection")
    assert assert_equal "Collection_test", Collection.model_name.human
    assert assert_equal (I18n.t 'collection'), Collection.model_name.human
  end
   
  test "presentation active record model" do
    assert I18n.exists?("activerecord.models.presentation")
    assert assert_equal "Presentation_test", Presentation.model_name.human
    assert assert_equal (I18n.t 'presentation'), Presentation.model_name.human
  end

  test "event active record model" do
    assert I18n.exists?("activerecord.models.event")
    assert assert_equal "Event_test", Event.model_name.human
    assert assert_equal (I18n.t 'event'), Event.model_name.human
  end

  test "sample active record model" do
    assert I18n.exists?("activerecord.models.sample")
    assert assert_equal "Sample_test", Sample.model_name.human
    assert assert_equal (I18n.t 'sample'), Sample.model_name.human
  end
     
  test "template active record model" do
    assert I18n.exists?("activerecord.models.template")
    assert assert_equal "Template_test", Template.model_name.human
    assert assert_equal (I18n.t 'template'), Template.model_name.human
  end

  test "sample_type active record model" do
    assert I18n.exists?("activerecord.models.sample_type")
    assert assert_equal "Sample type_test", SampleType.model_name.human
    assert assert_equal (I18n.t 'sample_type'), SampleType.model_name.human
  end

  test "strain active record model" do
    assert I18n.exists?("activerecord.models.strain")
    assert assert_equal "Strain_test", Strain.model_name.human
    assert assert_equal (I18n.t 'strain'), Strain.model_name.human
  end
   
  test "organism active record model" do
    assert I18n.exists?("activerecord.models.organism")
    assert assert_equal "Organism_test", Organism.model_name.human
    assert assert_equal (I18n.t 'organism'), Organism.model_name.human
  end

  def apply_overrides
    I18n.load_path += Dir[Rails.root.join('test', 'config', 'translation_override.en.yml')]
    I18n.backend.load_translations
  end

  def reset_translations
    I18n.load_path = @original_load_path
    I18n.backend.load_translations
  end
end
