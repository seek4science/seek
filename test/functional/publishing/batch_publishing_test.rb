require 'test_helper'

class BatchPublishingTest < ActionController::TestCase

  tests DataFilesController

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:datafile_owner)
    @object=data_files(:picture)
  end
end