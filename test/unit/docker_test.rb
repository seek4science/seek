require 'test_helper'

class DockerTest < ActiveSupport::TestCase
  test 'using docker?' do
    path = Seek::Docker::FLAG_FILE_PATH
    assert_equal path, File.join(Rails.root, 'config', 'using-docker')
    begin
      refute File.exist?(path)
      refute Seek::Docker.using_docker?
      FileUtils.touch(path)
      assert Seek::Docker.using_docker?
    rescue
      raise e
    ensure
      File.delete(path)
      refute File.exist?(path)
    end
  end
end
