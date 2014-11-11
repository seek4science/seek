require 'test_helper'

class ProgrammeTest < ActiveSupport::TestCase

  test "uuid" do
    p = Programme.new :title=>"fish"
    assert_nil p.attributes["uuid"]
    p.save!
    refute_nil p.attributes["uuid"]
    uuid = p.uuid
    p.title="frog"
    p.save!
    assert_equal uuid,p.uuid
  end

  test "validation" do
    p = Programme.new
    refute p.valid?
    p.title="frog"
    assert p.valid?
    p.save!

    #title must be unique
    p2 = Programme.new :title=>p.title
    refute p2.valid?
    p2.title="sdfsdfsdf"
    assert p2.valid?
  end

  test "factory" do
    p = Factory :programme
    refute_nil p.title
    refute_nil p.uuid
    refute_empty p.projects
  end

  test "people via projects" do
    person1 = Factory :person
    person2 = Factory :person
    person3 = Factory :person
    assert_equal 1,person1.projects.size
    assert_equal 1,person2.projects.size
    projects = person1.projects | person2.projects
    prog = Factory :programme,:projects=>projects
    assert_equal 2,prog.projects.size
    peeps = prog.people
    assert_equal 2,peeps.size
    assert_includes peeps,person1
    assert_includes peeps,person2
    refute_includes peeps,person3
  end

  test "institutions via projects" do

    person1 = Factory :person
    person2 = Factory :person
    person3 = Factory :person

    projects = person1.projects | person2.projects
    prog = Factory :programme,:projects=>projects
    assert_equal 2,prog.projects.size
    inst = prog.institutions
    assert_equal 2,inst.size
    assert_includes inst,person1.institutions.first
    assert_includes inst,person2.institutions.first
    refute_includes inst,person3.institutions.first

  end

  test "can be edited by" do
    #for now programmes can only be created and editing by an admin
    person = Factory(:person)
    admin = Factory(:admin)
    programme = Factory(:programme)
    assert programme.can_be_edited_by?(admin)
    refute programme.can_be_edited_by?(person)
    refute programme.can_be_edited_by?(nil)
  end

  test "disassociate projects on destroy" do
    programme = Factory(:programme)
    project = programme.projects.first
    assert_equal programme.id,project.programme_id
    programme.destroy
    project.reload
    assert_nil project.programme_id
  end


end
