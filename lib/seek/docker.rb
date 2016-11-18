module Seek
  #simple utility to get information specific to Docker
  class Docker

    FLAG_FILE_PATH=File.join(Rails.root,'config','using-docker')

    # detects if running in a Docker container
    def self.using_docker?
      File.exist?(FLAG_FILE_PATH)
    end

  end
end