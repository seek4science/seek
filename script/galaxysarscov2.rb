require 'rubygems'
require 'rest-client'
require 'json'
require 'git'
require 'ro_crate_ruby'
require 'rails/all'
require 'pathname'
Dir[File.join(File.dirname(__FILE__), '..', 'lib', 'ro_crate', '*')].each {|file| require File.expand_path(file) }
Dir[File.join(File.dirname(__FILE__), '..', 'lib', 'seek', 'workflow_extractors', '*')].each {|file| require File.expand_path(file) }
github = RestClient::Resource.new('https://api.github.com')
seek = RestClient::Resource.new('http://localhost:3000')
GIT_REPO = 'https://github.com/galaxyproject/SARS-CoV-2'
GIT_DESTINATION = '/tmp/galaxy-sars-cov-2/'
CRATE_DESTINATION = File.expand_path(File.join(File.dirname(__FILE__), '..', 'crates', 'sarscov2'))
FileUtils.mkdir_p(CRATE_DESTINATION)
GALAXY_LANGUAGE_META = Seek::WorkflowExtractors::Galaxy.ro_crate_metadata
PREVIEW_TEMPLATE = File.read(File.join(File.dirname(__FILE__), 'preview.html.erb'))

repo = 'SARS-CoV-2'
full_dest_path = File.expand_path(GIT_DESTINATION)
if !File.exist?(full_dest_path)
  puts "  Cloning: #{repo}"
  git = Git.clone(GIT_REPO, repo, path: GIT_DESTINATION)
  dir = git.dir.path
else
  puts "  Not cloning, directory exists: #{full_dest_path}"
  dir = File.join(full_dest_path, repo)
end

crates = []
['genomics'].each do |subdir|
  workflow_dir = File.join(dir, subdir)
  root_path = Pathname.new(dir)
  deps = File.join(workflow_dir, 'deploy', 'all_covid_tools.yaml')
  Dir.chdir(workflow_dir) do
    Dir.glob('**/*.ga').each do |item|
      puts "  Making RO Crate..."
      crate = ROCrate::WorkflowCrate.new
      # Add the workflow
      wf_id = File.basename(item).chomp('.ga')
      wf = crate.add_file(item, "#{wf_id}.ga", entity_class: ROCrate::Workflow)
      wf.programming_language = ROCrate::ContextualEntity.new(crate, 'galaxy', GALAXY_LANGUAGE_META)
      galaxy = JSON.parse(File.read(item))
      wf.name = galaxy['name']
      wf.content_size = File.size(item)
      crate.name = wf.name
      crate.url = GIT_REPO + "/blob/master/#{subdir}/#{item}"
      crate.main_workflow = wf
      # Add dependencies file
      dep_file = crate.add_file(deps)
      wf['dependencies'] = dep_file.reference

      # Add the diagram, readme tec.
      info_root = File.join(workflow_dir, wf_id)
      Dir.glob(File.join(info_root, '*')).each do |info_file|
        if info_file.end_with?("_wf.png")
          wdf = ROCrate::WorkflowDiagram.new(crate, info_file, File.basename(info_file))
          wdf.content_size = File.size(info_file)
          crate.main_workflow.diagram = wdf
        else
          crate.add_file(info_file)
        end
      end

      crate.preview.template = PREVIEW_TEMPLATE

      crate_path = File.join(CRATE_DESTINATION, "ro-crate-#{item.gsub('/', '-').gsub('.', '-')}.crate.zip")
      f = File.new(crate_path, 'w')
      puts "  Written to: #{crate_path}"
      ROCrate::Writer.new(crate).write_zip(f)
      crates << File.expand_path(crate_path)
    end
  end
end

puts crates.inspect
