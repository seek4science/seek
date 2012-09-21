# Install hook code here
require 'rubygems'
dest_file = File.expand_path(File.join(File.dirname(__FILE__),'..','..','..', "script", 'convert_office_nailgun'))
src_file = File.join('lib','generator' ,'convert_office_nailgun')
FileUtils.cp_r(src_file, dest_file)
File.chmod(0755,dest_file)
