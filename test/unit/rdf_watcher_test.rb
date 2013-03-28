require 'test_helper'

class RdfWatcherTest  < ActiveSupport::TestCase

  class TestRdfWatcher < Seek::Rdf::RdfWatcher
    public :is_private?
  end

  def setup
    @watcher = TestRdfWatcher.new
  end


  test "is_private" do

    assert @watcher.is_private?("private/fish")
    assert !@watcher.is_private?("public/fish")

    #assume private unless base path is public
    assert @watcher.is_private?("pubic/fish")
  end

end