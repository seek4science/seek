require 'test/unit'
require 'yaml'
require 'app_version'

class VersionTest < Test::Unit::TestCase

  def setup
    @version = Version.new
    @version.major = 1
    @version.minor = 2
    @version.patch = 3
    @version.milestone = 4
    @version.build = 500
    @version.branch = 'master'
    @version.committer = 'coder'
    @version.build_date = Date.civil(2008, 10, 27)
  end

  def test_load_from_file
    version = Version.load 'test/version.yml'
    assert_equal @version, version
  end

  def test_create_from_string
    version = Version.parse '1.2.3 M4 (500) of master by coder on 2008-10-27'
    assert_equal @version, version
    
    version = Version.parse '1.2.3 M4 (500)'
    @version.branch = nil
    @version.committer = nil
    @version.build_date = nil
    assert_equal @version, version

    version = Version.parse '1.2.3 (500)'
    @version.milestone = nil
    @version.branch = nil
    @version.committer = nil
    @version.build_date = nil
    assert_equal @version, version

    version = Version.parse '1.2 (500)'
    @version.patch = nil
    @version.branch = nil
    @version.committer = nil
    @version.build_date = nil
    assert_equal @version, version

    version = Version.parse '1.2'
    @version.milestone = nil
    @version.build = nil
    @version.branch = nil
    @version.committer = nil
    @version.build_date = nil
    assert_equal @version, version

    version = Version.parse '1.2.1'
    @version.patch = 1
    @version.branch = nil
    @version.committer = nil
    @version.build_date = nil
    assert_equal @version, version

    version = Version.parse '2007.200.10 M9 (6) of branch by coder on 2008-10-27'
    @version.major = 2007
    @version.minor = 200
    @version.patch = 10
    @version.milestone = 9
    @version.build = 6
    @version.branch = 'branch'
    @version.committer = 'coder'
    @version.build_date = Date.civil(2008, 10, 31)
    assert_raises(ArgumentError) { Version.parse 'This is not a valid version' }
  end

  def test_create_from_int_hash_with_symbol_keys
    version = Version.new :major => 1, 
      :minor => 2, 
      :patch => 3, 
      :milestone => 4, 
      :build => 500, 
      :branch => 'master', 
      :committer => 'coder', 
      :build_date => Date.civil(2008, 10, 27)
    assert_equal @version, version
  end

  def test_create_from_int_hash_with_string_keys
    version = Version.new 'major' => 1, 
      'minor' => 2, 
      'patch' => 3, 
      'milestone' => 4, 
      'build' => 500,
      'branch' => 'master',
      'committer' => 'coder',
      'build_date' => '2008-10-27'
    assert_equal @version, version
  end

  def test_create_from_string_hash_with_symbol_keys
    version = Version.new :major => '1', 
      :minor => '2', 
      :patch => '3', 
      :milestone => '4', 
      :build => '500',
      :branch => 'master', 
      :committer => 'coder', 
      :build_date => '2008-10-27'
    assert_equal @version, version
  end

  def test_create_from_string_hash_with_string_keys
    version = Version.new 'major' => '1', 
      'minor' => '2', 
      'patch' => '3', 
      'milestone' => '4', 
      'build' => '500',
      'branch' => 'master',
      'committer' => 'coder',
      'build_date' => '2008-10-27'
    assert_equal @version, version
  end

  def test_create_from_hash_with_invalid_date
    # note - Date.parse will make heroic efforts to understand the date text.
    version = Version.new :major => '1', 
      :minor => '2', 
      :patch => '3', 
      :milestone => '4', 
      :build => '500',
      :branch => 'master', 
      :committer => 'coder', 
      :build_date => '12wtf34'
    assert_not_equal @version, version
  end

  def test_should_raise_when_major_is_missing
    assert_raises(ArgumentError) {
      Version.new :minor => 2, :milestone => 3, :build => 400
    }
  end

  def test_should_raise_when_minor_is_missing
    assert_raises(ArgumentError) {
      Version.new :major => 1, :milestone => 3, :build => 400
    }
  end

  def test_create_without_optional_parameters
    version = Version.new :major => 1, :minor => 2

    @version.patch = nil
    @version.milestone = nil
    @version.build = nil
    @version.branch = nil
    @version.committer = nil
    @version.build_date = nil
    assert_equal @version, version    
  end

  def test_create_with_0
    version = Version.new :major => 1,
								          :minor => 2,
								          :patch => 0,
								          :milestone => 0,
								          :build => 100

		assert_equal 0, version.patch
		assert_equal 0, version.milestone		
  end

  def test_create_with_nil
    version = Version.new :major => 1,
								          :minor => 2,
								          :patch => nil,
								          :milestone => nil,
								          :build => 100,
								          :branch => nil,
								          :committer => nil,
								          :build_date => nil

		assert_equal nil, version.patch
		assert_equal nil, version.milestone
		assert_equal nil, version.branch
		assert_equal nil, version.committer
		assert_equal nil, version.build_date
  end

  def test_create_with_empty_string
    version = Version.new :major => 1,
								          :minor => 2,
								          :patch => '',
								          :milestone => '',
								          :build => 100,
								          :branch => '',
								          :committer => '',
								          :build_date => ''

		assert_equal nil, version.patch
		assert_equal nil, version.milestone		
		assert_equal nil, version.branch
		assert_equal nil, version.committer
		assert_equal nil, version.build_date
  end

  def test_to_s
    assert_equal '1.2.3 M4 (500) of master by coder on 2008-10-27', @version.to_s
  end

  def test_to_s_with_no_milestone
    @version.milestone = nil
    assert_equal '1.2.3 (500) of master by coder on 2008-10-27', @version.to_s
  end

  def test_to_s_with_no_build
    @version.build = nil
    assert_equal '1.2.3 M4 of master by coder on 2008-10-27', @version.to_s
  end

  def test_to_s_with_no_patch
    @version.patch = nil
    assert_equal '1.2 M4 (500) of master by coder on 2008-10-27', @version.to_s
  end

  def test_to_s_with_no_build_or_milestone
    @version.milestone = nil
    @version.build = nil
    assert_equal '1.2.3 of master by coder on 2008-10-27', @version.to_s
  end

  def test_to_s_with_no_branch
    @version.branch = nil
    assert_equal '1.2.3 M4 (500) by coder on 2008-10-27', @version.to_s
  end

  def test_to_s_with_no_committer
    @version.committer = nil
    assert_equal '1.2.3 M4 (500) of master on 2008-10-27', @version.to_s
  end

  def test_to_s_with_no_build_date
    @version.build_date = nil
    assert_equal '1.2.3 M4 (500) of master by coder', @version.to_s
  end

  def test_to_s_with_no_branch_or_committer
    @version.branch = nil
    @version.committer = nil
    assert_equal '1.2.3 M4 (500) on 2008-10-27', @version.to_s
  end

  def test_to_s_with_no_committer_or_build_date
    @version.committer = nil
    @version.build_date = nil
    assert_equal '1.2.3 M4 (500) of master', @version.to_s
  end

  def test_to_s_with_no_build_date_or_committer_or_build_date
    @version.branch = nil
    @version.committer = nil
    @version.build_date = nil
    assert_equal '1.2.3 M4 (500)', @version.to_s
  end

end
