class ModelsController < ApplicationController

  before_filter :login_required
  before_filter :set_path

  class UploadedFile
    attr_accessor :name, :content_type, :data

    def uploaded_file=(file_field)
      self.name = base_part_of(file_field.original_filename)
      self.content_type = file_field.content_type.chomp
      self.data = file_field.read
    end

    def base_part_of(file_name)
      File.basename(file_name).gsub(/[^\w._-]/, '')
    end
  end


  def index
    @file=UploadedFile
  end

  def evaluate
    @path='/home/sowen/Desktop/curien.xml'
  end

  def set_path
    @path='/home/sowen/Desktop/curien.xml'
  end

  def upload_file

    @file = UploadedFile.new
    @file.uploaded_file=params[:file][:uploaded_file]
    filename=@file.name
    path="/tmp/"+filename

    puts "Storing to:"+path

    File.open(path, "wb") { |f| f.write(@file.data)}
    @path=path
  end

end
