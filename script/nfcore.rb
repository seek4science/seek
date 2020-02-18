require 'rest-client'
require 'json'

github = RestClient::Resource.new('http://api.github.com')
seek = RestClient::Resource.new('http://localhost:3000')

puts "Project ID:"
project_id = gets.chomp
puts "Token: "
token = gets.chomp

puts "Querying nf-core repos"
repos = JSON.parse(github['users/nf-core/repos'].get.body)
nextflow_repos = repos.select do |repo|
  repo['language'] == 'Nextflow'
end

puts "Querying existing workflows in SEEK"
workflows = JSON.parse(seek['projects/1/workflows.json'].get(authorization: "Token #{token}").body)
existing_workflows = workflows['data'].map do |w|
  w['attributes']['title']
end

to_register = {}
puts "Checking nf-core repos"
nextflow_repos.each do |repo|
  begin
    # test if nextflow.config exists
    github["repos/nf-core/#{repo['name']}/contents/nextflow.config"].head
    to_register[repo['full_name']] = "https://github.com/nf-core/#{repo['name']}/blob/master/nextflow.config"
    sleep 1
  rescue RestClient::NotFound
    puts "No nextflow.config found in #{repo['full_name']}"
  end
end

puts to_register.to_json

to_register.each do |name, url|
  if existing_workflows.include?(name)
    puts "Already registered: #{name}"
    next
  end
  puts "Registering: #{name}"
  template = {
      data: {
          type: "workflows",
          attributes: {
              title: name,
              workflow_class: {
                  key: "Nextflow"
              },
              content_blobs: [
                  {
                      url: url
                  }
              ],
              policy: {
                  access: "download",
                  permissions: [
                      {
                          resource: {
                              id: project_id.to_s,
                              type: "projects"
                          },
                          access: "edit"
                      }
                  ]
              }
          },
          relationships: {
              projects: {
                  data: [
                      {
                          id: project_id.to_s,
                          type: "projects"
                      }
                  ]
              }
          }
      }
  }

  seek['workflows'].post(template.to_json, content_type: :json, accept: :json, authorization: "Token #{token}")
end
