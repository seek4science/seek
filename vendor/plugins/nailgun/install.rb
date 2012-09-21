# Install hook code here
require 'rubygems'
dest_file = File.expand_path(File.join(File.dirname(__FILE__),'..','..','..', "script", 'nailgun'))
src_file = File.join('lib','generator' ,'nailgun')
FileUtils.cp_r(src_file, dest_file)
File.chmod(0755,dest_file)
