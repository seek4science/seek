require 'rubygems'
require 'rest-client'
require 'json'
require 'git'
require 'ro_crate_ruby'
Dir[File.join(File.dirname(__FILE__), '..', 'lib', 'ro_crate', '*')].each {|file| require File.expand_path(file) }

github = RestClient::Resource.new('http://api.github.com')
seek = RestClient::Resource.new('http://localhost:3000')
NF_CORE_USER = 'nf-core'
GIT_DESTINATION = '/tmp/nfcore/'

# puts "Project ID:"
# project_id = gets.chomp
# puts "Token: "
# token = gets.chomp

puts "Querying nf-core repos"
repos = JSON.parse(github["users/#{NF_CORE_USER}/repos"].get.body)
nextflow_repos = repos.select do |repo|
  repo['language'] == 'Nextflow'
end
#
# puts "Querying existing workflows in SEEK"
# workflows = JSON.parse(seek['projects/1/workflows.json'].get(authorization: "Token #{token}").body)
# existing_workflows = workflows['data'].map do |w|
#   w['attributes']['title']
# end

to_register = []
puts "Checking #{NF_CORE_USER} repos"
nextflow_repos.each do |repo|
  begin
    # test if nextflow.config exists
    github["repos/#{NF_CORE_USER}/#{repo['name']}/contents/nextflow.config"].head
    to_register.push(repo['full_name'])
    sleep 1
  rescue RestClient::NotFound
    puts "No nextflow.config found in #{repo['full_name']}"
  end
end

puts "nf-core repos to register: #{to_register.inspect}"

#to_register = ["nf-core/ampliseq", "nf-core/atacseq", "nf-core/bacass"]

to_register.each do |repo|
  full_dest_path = File.expand_path(File.join(GIT_DESTINATION, repo))
  if !File.exist?(full_dest_path)
    puts "  Cloning: #{repo}"
    git = Git.clone("https://github.com/#{repo}", repo, path: GIT_DESTINATION)
    dir = git.dir.path
  else
    puts "  Not cloning, directory exists: #{full_dest_path}"
    dir = full_dest_path
  end
  puts "  Making RO Crate..."
  crate = ROCrate::WorkflowCrate.new
  Dir.chdir(dir) do
    Dir.glob('*').each do |item|
      if item == 'main.nf'
        wf = crate.add_file('main.nf', 'main.nf', entity_class: ROCrate::Workflow)
        crate.main_workflow = wf
      elsif File.directory?(item)
        crate.add_directory(item, item)
      else
        crate.add_file(item, item)
      end
    end
  end
  f = File.new("ro-crate-#{repo.gsub('/', '-')}.zip", 'w')
  puts "  Written to: #{File.expand_path(f)}"
  ROCrate::Writer.new(crate).write_zip(f)
end

#
# to_register.each do |name, url|
#   if existing_workflows.include?(name)
#     puts "Already registered: #{name}"
#     next
#   end
#   puts "Registering: #{name}"
#   template = {
#       data: {
#           type: "workflows",
#           attributes: {
#               title: name,
#               workflow_class: {
#                   key: "Nextflow"
#               },
#               content_blobs: [
#                   {
#                       url: url
#                   }
#               ],
#               policy: {
#                   access: "download",
#                   permissions: [
#                       {
#                           resource: {
#                               id: project_id.to_s,
#                               type: "projects"
#                           },
#                           access: "edit"
#                       }
#                   ]
#               }
#           },
#           relationships: {
#               projects: {
#                   data: [
#                       {
#                           id: project_id.to_s,
#                           type: "projects"
#                       }
#                   ]
#               }
#           }
#       }
#   }
#
#   seek['workflows'].post(template.to_json, content_type: :json, accept: :json, authorization: "Token #{token}")
# end
