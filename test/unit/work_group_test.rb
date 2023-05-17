require 'test_helper'

class WorkGroupTest < ActiveSupport::TestCase
  def setup
    @person = FactoryBot.create(:person)
    @wg = @person.projects.first.work_groups.first
  end

  def test_people
    wg = assert_equal [@person], @wg.people
  end

  def test_can_destroy_with_people
    refute @wg.people.empty?

    assert_difference('WorkGroup.count',-1) do
      @wg.destroy
    end
  end

  def test_can_destroy_with_no_people
    @wg.people = []
    assert @wg.people.empty?
    assert_difference('WorkGroup.count',-1) do
      @wg.destroy
    end
  end

  def test_description
    proj = @wg.project
    inst = @wg.institution
    assert_equal "#{proj.title} at #{inst.title}", @wg.description
  end
end
