targetTemplateDir = File.join(RAILS_ROOT, 'lib/templates')

targetTemplateFile = File.join(RAILS_ROOT, 'lib/templates/version.yml.erb')
targetConfigSampleFile = File.join(RAILS_ROOT, '/config/version.yml')
targetTemplateSampleFile = File.join(RAILS_ROOT, 'lib/templates/version.yml')

if File.exist?(targetTemplateFile)          then FileUtils.rm( targetTemplateFile, :verbose => true) end
if File.exist?(targetConfigSampleFile)      then FileUtils.rm( targetConfigSampleFile, :verbose => true) end
if File.exist?(targetTemplateSampleFile)    then FileUtils.rm( targetTemplateSampleFile, :verbose => true) end

if Dir.entries( targetTemplateDir ).entries.length == 2 then FileUtils.rmdir( targetTemplateDir, :verbose => true ) end
