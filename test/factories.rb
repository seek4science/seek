require_relative './factories_helper.rb'

include FactoriesHelper

FactoryBot.define do
  trait :with_project_contributor do
    contributor { nil }
    after(:build) do |resource|
      if resource.contributor.nil?
        if resource.projects.none?
          resource.projects = [FactoryBot.create(:project)]
        end
        resource.contributor = FactoryBot.create(:person, project: resource.projects.first)
      elsif resource.projects.none?
        resource.projects = [resource.contributor.projects.first]
      end
    end
  end
end

FactoryBot.class_eval do
  def self.create *args
    disable_authorization_checks { super(*args) }
  end

  def self.build *args
    disable_authorization_checks { super(*args) }
  end
end

# These are misc factories that didn't warrant having their own file. For multiple factories of the same type, look in
#  the factories directory.

FactoryBot.define do
  factory(:saved_search) do
    search_query { 'cheese' }
    search_type { 'All' }
    user { build(:user) }
    include_external_search { false }
  end

  factory(:activity_log) do
    action { 'create' }
    association :activity_loggable, factory: :data_file
    controller_name { 'data_files' }
    association :culprit, factory: :user
  end

  factory(:unit) do
    symbol { 'g' }
    sequence(:order) { |n| n }
  end

  factory(:project_folder) do
    association :project, factory: :project
    sequence(:title) { |n| "project folder #{n}" }
  end

  factory(:openbis_endpoint) do
    sequence(:as_endpoint) { |nr| "https://openbis-api.fair-dom.org/openbis/openbis#{nr}" }
    sequence(:dss_endpoint) { |nr| "https://openbis-api.fair-dom.org/datastore_server#{nr}" }
    sequence(:web_endpoint) { |nr| "https://openbis-api.fair-dom.org/openbis#{nr}" }
    username { 'apiuser' }
    password { 'apiuser' }
    is_test { false }
    # sequence(:space_perm_id) { |nr| "API-SPACE#{nr}" }
    sequence(:space_perm_id) { |_nr| 'API-SPACE' }
    association :project, factory: :project
  end

  factory :openbis_zample,  class: Seek::Openbis::Zample do
    json = JSON.parse(
      '
{"identifier":"\/API-SPACE\/TZ3","modificationDate":"2017-10-02 18:09:34.311665","registerator":"apiuser",
"code":"TZ3","modifier":"apiuser","permId":"20171002172111346-37",
"registrationDate":"2017-10-02 16:21:11.346421","datasets":["20171002172401546-38","20171002190934144-40",
"20171004182824553-41"]
,"sample_type":{"code":"TZ_FAIR_ASSAY","description":"For testing sample\/assay mapping with full metadata"},
"properties":{"DESCRIPTION":"Testing sample assay with a dataset. Zielu","NAME":"Tomek First"},"tags":[]}
'
    )

    initialize_with { Seek::Openbis::Zample.new(FactoryBot.create(:openbis_endpoint)).populate_from_json(json) }
    # skipping save as not implemented
    to_create { |instance| instance }
  end
end
