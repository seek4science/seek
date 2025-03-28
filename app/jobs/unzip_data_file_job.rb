class UnzipDataFileJob < TaskJob
    queue_as QueueNames::DATAFILES
  
    attr_reader :unzipper
    def perform(data_file)
      @unzipper = Seek::DataFiles::Unzipper.new(data_file)
      @unzipper.clear
      @unzipper.unzip
    end
  
    def task
      arguments[0].unzip_task
    end
  
    def handle_error(exception)
      super
      @unzipper.clear if @unzipper
    end

    def timelimit
      2.hours
    end

  end
  