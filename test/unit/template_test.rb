require 'test_helper'

class TemplateTest < ActiveSupport::TestCase

  def setup
    @person = FactoryBot.create(:person)
    @project = @person.projects.first
    @project_ids = [@project.id]
  end

  test 'validation' do
    template = Template.new(title: 'Test', project_ids: @project_ids, policy: FactoryBot.create(:private_policy))
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

end
