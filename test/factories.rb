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
  f.sequence(:as_endpoint) { |nr| "https://openbis-api.fair-dom.org/openbis/openbis#{nr}" }
  f.sequence(:dss_endpoint) { |nr| "https://openbis-api.fair-dom.org/datastore_server#{nr}" }
  f.sequence(:web_endpoint) { |nr| "https://openbis-api.fair-dom.org/openbis#{nr}" }
  f.username 'apiuser'
  f.password 'apiuser'
  #f.sequence(:space_perm_id) { |nr| "API-SPACE#{nr}" }
  f.sequence(:space_perm_id) { |nr| "API-SPACE" }
  f.association :project, factory: :project
end

FactoryGirl.define do
  factory :openbis_zample,  class: Seek::Openbis::Zample do

    json = JSON.parse(
        '
{"identifier":"\/API-SPACE\/TZ3","modificationDate":"2017-10-02 18:09:34.311665","registerator":"apiuser",
"code":"TZ3","modifier":"apiuser","permId":"20171002172111346-37",
"registrationDate":"2017-10-02 16:21:11.346421","datasets":["20171002172401546-38","20171002190934144-40","20171004182824553-41"]
,"sample_type":{"code":"TZ_FAIR_ASSAY","description":"For testing sample\/assay mapping with full metadata"},"properties":{"DESCRIPTION":"Testing sample assay with a dataset. Zielu","NAME":"Tomek First"},"tags":[]}
'
    )

    initialize_with { Seek::Openbis::Zample.new(Factory :openbis_endpoint).populate_from_json(json) }
    # skipping save as not implemented
    to_create { |instance| instance }
  end
end
