require 'test_helper'

class TemplateTest < ActiveSupport::TestCase

  def setup
    @person = FactoryBot.create(:person)
    @project = @person.projects.first
    @project_ids = [@project.id]
  end

  test 'validation' do
    template = Template.new(title: 'Test', level: 'study source', project_ids: @project_ids, policy: FactoryBot.create(:private_policy))
    assert template.valid?
    template.title = ''
    assert !template.valid?
    template.title = nil
    assert !template.valid?

    # do not allow empty projects
    template.title = 'Test'
    template.projects = []
    refute template.valid?

    template.project_ids = @project_ids
    assert template.valid?
  end

  test 'template level validation' do
    template = FactoryBot.build(:isa_source_template, projects: [@project], contributor: @person)
    assert template.valid?

    # Change the level to an invalid value
    template.level = 'My random template level'
    refute template.valid?
    assert_equal template.errors.map(&:attribute), [:level]
    assert_equal ["is not a valid #{t('template')} level"], template.errors.messages[:level]
  end

end
