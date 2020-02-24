require 'rubygems'
require 'rest-client'
require 'json'
require 'git'
require 'ro_crate_ruby'
require 'rails/all'
require 'pathname'
Dir[File.join(File.dirname(__FILE__), '..', 'lib', 'ro_crate', '*')].each {|file| require File.expand_path(file) }

github = RestClient::Resource.new('http://api.github.com')
seek = RestClient::Resource.new('http://localhost:3000')
GIT_REPO = 'https://github.com/EBI-Metagenomics/workflow-is-cwl'
GIT_DESTINATION = '/tmp/ebi-metagenomics-cwl/'
CWL_LANGUAGE_META =  {
    "@id" => "#cwl",
    "@type" => "ComputerLanguage",
    "name" => "Common Workflow Language",
    "alternateName" => "CWL",
    "identifier" => { "@id" => "https://w3id.org/cwl/v1.0/" },
    "url" => { "@id" => "https://www.commonwl.org/" }
}
PREVIEW_TEMPLATE = File.read(File.join(File.dirname(__FILE__), 'preview.html.erb'))

def get_local_dependencies(hash)
  locs = []

  if hash['location'] && hash['location']
    begin
      if URI(hash['location']).relative?
        locs << hash['location']
      end
    rescue ArgumentError
    end
  end

  if hash['secondaryFiles']
    hash['secondaryFiles'].each do |child|
      locs |= get_local_dependencies(child)
    end
  end

  locs
end

# puts "Project ID:"
# project_id = gets.chomp
# puts "Token: "
# token = gets.chomp

# puts "Querying existing workflows in SEEK"
# workflows = JSON.parse(seek['projects/1/workflows.json'].get(authorization: "Token #{token}").body)
# existing_workflows = workflows['data'].map do |w|
#   w['attributes']['title']
# end
repo = 'ebi-metagenomics-cwl'
full_dest_path = File.expand_path(File.join(GIT_DESTINATION, repo))
if !File.exist?(full_dest_path)
  puts "  Cloning: #{repo}"
  git = Git.clone(GIT_REPO, repo, path: GIT_DESTINATION)
  dir = git.dir.path
else
  puts "  Not cloning, directory exists: #{full_dest_path}"
  dir = full_dest_path
end

workflow_dir = File.join(dir, 'workflows')
root_path = Pathname.new(dir)
crates = []

Dir.chdir(workflow_dir) do
  Dir.glob('*.cwl').each do |item|
    puts "  Discovering dependencies"
    cwl = YAML.load(File.read(item)) rescue {}
    hash = JSON.parse(`cwltool --print-deps #{item}`)
    deps = get_local_dependencies(hash)
    puts "  Making RO Crate..."
    crate = ROCrate::WorkflowCrate.new
    # Add the workflow
    wf = crate.add_file(item, "workflows/#{item}", entity_class: ROCrate::Workflow)
    wf.programming_language = ROCrate::ContextualEntity.new(crate, 'cwl', CWL_LANGUAGE_META)
    wf.name = cwl['label'] if cwl['label']
    wf.content_size = File.size(item)
    crate.name = cwl['label'] if cwl['label']
    crate.license = cwl['s:license'] if cwl['s:license']
    crate.author = cwl['s:author'] if cwl['s:author']
    crate.publisher = cwl['s:copyrightHolder'] if cwl['s:copyrightHolder']
    crate.url = GIT_REPO + "/blob/masterworkflows/#{item}"
    crate.main_workflow = wf
    # Add the diagram
    cwl_viewer_path = "https://view.commonwl.org/graph/svg/github.com/EBI-Metagenomics/workflow-is-cwl/blob/master/workflows/#{item}"
    d = RestClient.get(cwl_viewer_path)
    t = Tempfile.new('diagram.svg')
    t.write(d.body)
    wdf = ROCrate::WorkflowDiagram.new(crate, t.path, 'diagram.svg')
    wdf.content_size = d.size
    crate.main_workflow.diagram = wdf
    # Add any local dependencies
    deps[1..-1].each do |dep|
      full_dep_path = Pathname.new(File.expand_path(File.join(workflow_dir, dep)))
      crate_path = full_dep_path.relative_path_from(root_path).to_s
      f = crate.add_file(full_dep_path, crate_path)
      f.content_size = File.size(full_dep_path)
    end

    crate.preview.template = PREVIEW_TEMPLATE

    f = File.new("ro-crate-#{item.gsub('/', '-').gsub('.', '-')}.crate.zip", 'w')
    puts "  Written to: #{File.expand_path(f)}"
    ROCrate::Writer.new(crate).write_zip(f)
    crates << File.expand_path(f.path)
  end
end

puts crates.inspect
