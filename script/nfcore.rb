require 'rubygems'
require 'rest-client'
require 'json'
require 'git'
require 'ro_crate_ruby'
require 'rails/all'
require 'pathname'
Dir[File.join(File.dirname(__FILE__), '..', 'lib', 'ro_crate', '*')].each {|file| require File.expand_path(file) }
Dir[File.join(File.dirname(__FILE__), '..', 'lib', 'seek', 'workflow_extractors', '*')].each {|file| require File.expand_path(file) }
# gh_client_id = ENV['GH_SCRAPER_CLIENT_ID']
# gh_client_secret = ENV['GH_SCRAPER_CLIENT_SECRET']
# auth = gh_client_id && gh_client_secret ? { user: gh_client_id, password: gh_client_secret } : {}
# puts auth.inspect
auth = {}
github = RestClient::Resource.new('https://api.github.com', auth)
seek = RestClient::Resource.new('http://localhost:3000')
NF_CORE_USER = 'nf-core'
GIT_DESTINATION = '/tmp/nfcore/'
CRATE_DESTINATION = File.expand_path(File.join(File.dirname(__FILE__), '..', 'crates', 'nfcore'))
FileUtils.mkdir_p(CRATE_DESTINATION)
NF_LANGUAGE_META = Seek::WorkflowExtractors::Nextflow.ro_crate_metadata
PREVIEW_TEMPLATE = File.read(File.join(File.dirname(__FILE__), 'preview.html.erb'))

def cached(name)
  cache_path = File.join(CRATE_DESTINATION, 'cache')
  FileUtils.mkdir_p(cache_path)
  path = File.expand_path(File.join(cache_path, name.gsub('/', '-')))
  if File.exist?(path)
    File.read(path)
  else
    File.write(path, yield)
    File.read(path)
  end
end

# puts "Project ID:"
# project_id = gets.chomp
# puts "Token: "
# token = gets.chomp

puts "Querying nf-core repos"
repos = JSON.parse(cached('repo-list.json') { github["users/#{NF_CORE_USER}/repos"].get.body })
nextflow_repos = repos.select do |repo|
  repo['language'] == 'Nextflow'
end
#
# puts "Querying existing workflows in SEEK"
# workflows = JSON.parse(seek['projects/1/workflows.json'].get(authorization: "Token #{token}").body)
# existing_workflows = workflows['data'].map do |w|
#   w['attributes']['title']
# end
#
# to_register = []
# puts "Checking #{NF_CORE_USER} repos"
# nextflow_repos.each do |repo|
#   sleep 1
#   begin
#     # test if nextflow.config exists
#     github["repos/#{NF_CORE_USER}/#{repo['name']}/contents/nextflow.config"].head
#     to_register.push(repo['full_name'])
#     sleep 1
#   rescue RestClient::NotFound
#     puts "No nextflow.config found in #{repo['full_name']}"
#   end
# end
#
# puts "nf-core repos to register: #{to_register.inspect}"

to_register = ["nf-core/ampliseq", "nf-core/atacseq", "nf-core/bacass", "nf-core/bactmap", "nf-core/bcellmagic", "nf-core/cageseq", "nf-core/chipseq", "nf-core/clinvap", "nf-core/configs", "nf-core/crisprvar", "nf-core/ddamsproteomics", "nf-core/deepvariant", "nf-core/denovohybrid", "nf-core/diaproteomics", "nf-core/eager", "nf-core/exoseq", "nf-core/guideseq", "nf-core/hlatyping", "nf-core/kmermaid", "nf-core/lncpipe", "nf-core/mag", "nf-core/methylseq", "nf-core/mhcquant"]
crates = []
to_register.each do |repo|
  r = github["repos/#{repo}/topics"]
  puts r.inspect
  topics_json = cached("#{repo}-topics.json") { r.get(accept: 'application/vnd.github.mercy-preview+json')&.body }
  topics = JSON.parse(topics_json)&.[]('names') || []
  topics -= ['nextflow', 'workflow', 'pipeline']
  sleep 1

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
    manifest = {}
    if File.exist?('nextflow.config')
      extractor = Seek::WorkflowExtractors::Nextflow.new(File.open('nextflow.config'))
      manifest = extractor.manifest
      crate.name = manifest['name'] if manifest['name']
      crate.description = manifest['description'] if manifest['description']
      crate.author = manifest['author'] if manifest['author']
      crate.url = manifest['homePage'] ? manifest['homePage'] : "https://github.com/#{repo}"
      crate['keywords'] = topics.join(', ') if topics.any?
    end
    Dir.glob('*').each do |item|
      if item == 'main.nf'
        wf = crate.add_file('main.nf', 'main.nf', entity_class: ROCrate::Workflow)
        nf = NF_LANGUAGE_META
        nf.merge('softwareVersion' => manifest['nextflowVersion']) if manifest['nextflowVersion']
        wf.programming_language = ROCrate::ContextualEntity.new(crate, 'nextflow', nf)
        wf.content_size = File.size(item)
        crate.main_workflow = wf
      elsif File.directory?(item)
        crate.add_directory(item, item)
      else
        f = crate.add_file(item, item)
        f.content_size = File.size(item)
      end
    end
  end

  crate.preview.template = PREVIEW_TEMPLATE

  crate_path = File.join(CRATE_DESTINATION, "ro-crate-#{repo.gsub('/', '-')}.crate.zip")
  f = File.new(crate_path, 'w')
  puts "  Written to: #{crate_path}"
  ROCrate::Writer.new(crate).write_zip(f)
  crates << File.expand_path(crate_path)
end

puts crates.inspect

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
