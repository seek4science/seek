module Jerm
  #Defaults to returning a Seek::RemoteDownloader, unless specifed otherwise in config/downloaders.yml
  #If a different type of downloader is required, then an entry should be put into downloaders.yml with the project name (lower case and with underscores) as the key,
  # and the classname as the value. e.g. to use a XDownloader for BaCell-SysMo, add ba_cell_sys_mo: XDownloader
  class DownloaderFactory

    #defaults to the Seek::RemoteDownloader, unless otherwise defined in the downloaders.yml
    def self.create project_name
      configpath=File.join(File.dirname(__FILE__),"config/downloaders.yml")
      config=YAML::load_file(configpath)
      downloader_class=config[project_key(project_name)] if config
      downloader_class ? Jerm.const_get(downloader_class).new : Seek::RemoteDownloader.new
    end

    def self.project_key project_name
      clean_project_name=project_name.gsub("-","")
      return clean_project_name.underscore
    end

  end
end