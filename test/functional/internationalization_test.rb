require 'test_helper'

class InternationalizationTest < ActionController::TestCase

  include AuthenticatedTestHelper

  include ErrorMessagesHelper
  include ActionView::Helpers::FormHelper
  
  setup do
    @original_load_path = I18n.load_path
    apply_overrides
  end

  teardown do
    reset_translations
  end

  test 'error message helper uses localized model name' do
    @controller = ProjectsController.new

    login_as(FactoryBot.create(:admin))

    p = Project.create()
    p.title = nil

    error = error_messages_for p

    assert_equal "<div id=\"error_explanation\" class=\"error_explanation\"><h2>1 error prohibited this project test from being saved</h2><p>There were problems with the following fields:</p><ul><li>Title can&#39;t be blank</li></ul></div>", error
  end

  test 'projects need to exist for an Investigation translated' do
    @controller = InvestigationsController.new

    login_as(FactoryBot.create(:admin))

    p = Investigation.create()

    assert !p.valid?

    assert_equal 'Projects_test_attr can\'t be blank', p.errors.objects.first.full_message
  end

  test 'Investigation need to exist for a Study translated' do
    @controller = StudiesController.new

    login_as(FactoryBot.create(:admin))

    p = Study.create()
    p.title = "An study without investigation"

    assert !p.valid?

    assert_equal 'Investigation_test is blank or invalid', p.errors.objects.first.full_message
  end

  test 'Study need to exist for an assay translated' do
    @controller = AssaysController.new

    login_as(FactoryBot.create(:admin))

    p = Assay.create()
    FactoryBot.create(:experimental_assay_class)
    p.assay_class = AssayClass.experimental
    p.title = "An assay without study"

    assert !p.valid?

    assert_equal 'Study_test must be selected and valid', p.errors.objects.first.full_message
  end

  test 'projects need to exist for a data_file translated' do
    @controller = DataFilesController.new

    login_as(FactoryBot.create(:admin))

    p = DataFile.create()

    assert !p.valid?

    assert_equal 'Projects_test_attr can\'t be blank', p.errors.objects.first.full_message
  end

  
  test 'projects need to exist for a model translated' do
    @controller = ModelsController.new

    login_as(FactoryBot.create(:admin))

    p = Model.create()

    assert !p.valid?

    assert_equal 'Projects_test_attr can\'t be blank', p.errors.objects.first.full_message
  end

  test 'projects need to exist for a SOP translated' do
    @controller = SopsController.new

    login_as(FactoryBot.create(:admin))

    p = Sop.create()

    assert !p.valid?

    assert_equal 'Projects_test_attr can\'t be blank', p.errors.objects.first.full_message
  end

  test 'projects need to exist for a publication translated' do
    @controller = PublicationsController.new

    login_as(FactoryBot.create(:admin))

    p = Publication.create()

    assert !p.valid?

    assert_equal 'Projects_test_attr can\'t be blank', p.errors.objects.first.full_message
  end
  
  test 'projects need to exist for a document translated' do
    @controller = DocumentsController.new

    login_as(FactoryBot.create(:admin))

    p = Document.create()

    assert !p.valid?

    assert_equal 'Projects_test_attr can\'t be blank', p.errors.objects.first.full_message
  end

  test 'projects need to exist for a file template translated' do
    @controller = FileTemplatesController.new

    login_as(FactoryBot.create(:admin))

    p = FileTemplate.create()

    assert !p.valid?

    assert_equal 'Projects_test_attr can\'t be blank', p.errors.objects.first.full_message
  end

  test 'projects need to exist for a collection translated' do
    @controller = CollectionsController.new

    login_as(FactoryBot.create(:admin))

    p = Collection.create()

    assert !p.valid?

    assert_equal 'Projects_test_attr can\'t be blank', p.errors.objects.first.full_message
  end

  test 'projects need to exist for a presentation translated' do
    @controller = PresentationsController.new

    login_as(FactoryBot.create(:admin))

    p = Presentation.create()
    p.title = "A presentation without project"

    assert !p.valid?

    assert_equal 'Projects_test_attr can\'t be blank', p.errors.objects.first.full_message
  end

  test 'projects need to exist for an event translated' do
    @controller = EventsController.new

    login_as(FactoryBot.create(:admin))

    p = Event.create()
    p.title = "An event without project"

    assert !p.valid?

    assert_equal 'Projects_test_attr can\'t be blank', p.errors.objects.first.full_message
  end

  test 'projects need to exist for a sample translated' do
    @controller = SamplesController.new

    login_as(FactoryBot.create(:admin))

    p = Sample.create()
    p.title = "A sample without project"

    assert !p.valid?

    assert_equal 'Projects_test_attr can\'t be blank', p.errors.objects.first.full_message
  end

  test 'projects need to exist for a template translated' do
    @controller = TemplatesController.new

    login_as(FactoryBot.create(:admin))

    p = Template.create()
    p.title = "A template without project"

    assert !p.valid?

    assert_equal 'Projects_test_attr can\'t be blank', p.errors.objects.first.full_message
  end

  test 'projects need to exist for a sample type translated' do
    @controller = SampleTypesController.new

    login_as(FactoryBot.create(:admin))

    p = SampleType.create()
    p.title = "A sample type without project"

    assert !p.valid?

    assert_equal 'Projects_test_attr can\'t be blank', p.errors.objects.first.full_message
  end

  test 'organism and projects need to exist for a strain translated' do
    @controller = StrainsController.new

    login_as(FactoryBot.create(:admin))

    p = Strain.create()
    p.title = "A Strain without project"

    assert !p.valid?

    assert_equal 'Organism_test can\'t be blank', p.errors.objects.first.full_message
    assert_equal 'Projects_test_attr can\'t be blank', p.errors.objects[1].full_message
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
