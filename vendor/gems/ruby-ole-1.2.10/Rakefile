require 'rake/rdoctask'
require 'rake/testtask'
require 'rake/packagetask'
require 'rake/gempackagetask'

require 'rbconfig'
require 'fileutils'

$:.unshift 'lib'

require 'ole/storage'

PKG_NAME = 'ruby-ole'
PKG_VERSION = Ole::Storage::VERSION

task :default => [:test]

Rake::TestTask.new do |t|
	t.test_files = FileList["test/test_*.rb"]
	t.warning = true
	t.verbose = true
end

begin
	require 'rcov/rcovtask'
	# NOTE: this will not do anything until you add some tests
	desc "Create a cross-referenced code coverage report"
	Rcov::RcovTask.new do |t|
		t.test_files = FileList['test/test*.rb']
		t.ruby_opts << "-Ilib" # in order to use this rcov
		t.rcov_opts << "--xrefs"  # comment to disable cross-references
		t.verbose = true
	end
rescue LoadError
	# Rcov not available
end

Rake::RDocTask.new do |t|
	t.rdoc_dir = 'doc'
	t.rdoc_files.include 'lib/**/*.rb'
	t.rdoc_files.include 'README', 'ChangeLog'
	t.title    = "#{PKG_NAME} documentation"
	t.options += %w[--line-numbers --inline-source --tab-width 2]
	t.main	   = 'README'
end

spec = Gem::Specification.new do |s|
	s.name = PKG_NAME
	s.version = PKG_VERSION
	s.summary = %q{Ruby OLE library.}
	s.description = %q{A library for easy read/write access to OLE compound documents for Ruby.}
	s.authors = ['Charles Lowe']
	s.email = %q{aquasync@gmail.com}
	s.homepage = %q{http://code.google.com/p/ruby-ole}
	s.rubyforge_project = %q{ruby-ole}

	s.executables = ['oletool']
	s.files  = ['README', 'Rakefile', 'ChangeLog', 'data/propids.yaml']
	s.files += FileList['lib/**/*.rb']
	s.files += FileList['test/test_*.rb', 'test/*.doc']
	s.files += FileList['test/oleWithDirs.ole', 'test/test_SummaryInformation']
	s.files += FileList['bin/*']
	s.test_files = FileList['test/test_*.rb']

	s.has_rdoc = true
	s.extra_rdoc_files = ['README', 'ChangeLog']
	s.rdoc_options += [
		'--main', 'README',
		'--title', "#{PKG_NAME} documentation",
		'--tab-width', '2'
	]
end

Rake::GemPackageTask.new(spec) do |t|
	t.gem_spec = spec
	t.need_tar = false
	t.need_zip = false
	t.package_dir = 'build'
end

desc 'Run various benchmarks'
task :benchmark do
	require 'benchmark'
	require 'tempfile'
	require 'ole/file_system'

	# should probably add some read benchmarks too
	def write_benchmark opts={}
		files, size = opts[:files], opts[:size]
		block_size = opts[:block_size] || 100_000
		block = 0.chr * block_size
		blocks, remaining = size.divmod block_size
		remaining = 0.chr * remaining
		Tempfile.open 'ole_storage_benchmark' do |temp|
			Ole::Storage.open temp do |ole|
				files.times do |i|
					ole.file.open "file_#{i}", 'w' do |f|
						blocks.times { f.write block }
						f.write remaining
					end
				end
			end
		end
	end

	Benchmark.bm do |bm|
		bm.report 'write_1mb_1x5' do
			5.times { write_benchmark :files => 1, :size => 1_000_000 }
		end

		bm.report 'write_1mb_2x5' do
			5.times { write_benchmark :files => 1_000, :size => 1_000 }
		end
	end
end

