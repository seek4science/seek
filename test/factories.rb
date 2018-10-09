require_relative './upload_helper.rb'
require_relative './password_helper.rb'

include UploadHelper
include PasswordHelper

FactoryGirl.define do
  trait :with_project_contributor do
    contributor { nil }
    after_build do |resource|
      if resource.contributor.nil?
        if resource.projects.none?
          resource.projects = [Factory(:project)]
        end
        resource.contributor = Factory(:person, project: resource.projects.first)
      elsif resource.projects.none?
        resource.projects = [resource.contributor.projects.first]
      end
    end
  end
end

FactoryGirl.class_eval do
  unless FactoryGirl.respond_to?(:create_with_privileged_mode) # Sometimes this gets executed twice and causes an infinite loop!
    def self.create_with_privileged_mode *args
      disable_authorization_checks {create_without_privileged_mode(*args)}
    end

    def self.build_with_privileged_mode *args
      disable_authorization_checks {build_without_privileged_mode(*args)}
    end

    class_alias_method_chain :create, :privileged_mode
    class_alias_method_chain :build, :privileged_mode
  end
end

# These are misc factories that didn't warrant having their own file. For multiple factories of the same type, look in
#  the factories directory.

Factory.define(:saved_search) do |f|
  f.search_query 'cheese'
  f.search_type 'All'
  f.user factory: :user
  f.include_external_search false
end

Factory.define(:activity_log) do |f|
  f.action 'create'
  f.association :activity_loggable, factory: :data_file
  f.controller_name 'data_files'
  f.association :culprit, factory: :user
end

Factory.define(:unit) do |f|
  f.symbol 'g'
  f.sequence(:order) { |n| n }
end

Factory.define :project_folder do |f|
  f.association :project, factory: :project
  f.sequence(:title) { |n| "project folder #{n}" }
end

Factory.define(:openbis_endpoint) do |f|
  f.as_endpoint 'https://openbis-api.fair-dom.org/openbis/openbis'
  f.dss_endpoint 'https://openbis-api.fair-dom.org/datastore_server'
  f.web_endpoint 'https://openbis-api.fair-dom.org/openbis'
  f.username 'apiuser'
  f.password 'apiuser'
  f.space_perm_id 'API-SPACE'
  f.association :project, factory: :project
end
