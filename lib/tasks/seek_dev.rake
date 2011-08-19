require 'rubygems'
require 'rake'
require 'active_record/fixtures'

namespace :seek_dev do
  desc 'A simple task for quickly setting up a project and institution, and assigned the first user to it. This is useful for quickly setting up the database when testing. Need to create a default user before running this task'
  task(:default_membership=>:environment) do
    p=Person.first
    raise Exception.new "Need to register a person first" if p.nil? || p.user.nil?

    User.with_current_user p.user do
      project=Project.new :title=>"Project X"
      institution=Institution.new :title=>"The Institute"
      project.save!
      institution.projects << project
      institution.save!
      p.update_attributes({"work_group_ids"=>["#{project.work_groups.first.id}"]})
    end
    
  end
end