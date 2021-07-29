require 'rubygems'
require 'zip'
require 'uuid'

module Seek
  module Ena
    class EnaClient
      def generate_ena_tsv sample_types_title_array
        sample_types = SampleType.where(title: sample_types_title_array)
        tsv_files = []
        sample_types.each do |sample_type|
          attributes = sample_type.sample_attributes
          csv_data = ""
          attributes.each do |atr|
            csv_data << "#{atr.title}\t"
          end
          file_name = "#{Time.now.to_f}_#{sample_type.title}.tsv"
          file_path = File.join(tmp_zip_file_dir, file_name)
          File.write(file_path, csv_data)
          tsv_files << file_name
        end
        { files: tsv_files }
      end
      
      def zip_files(input_filenames)
        zipfile_name = File.join(tmp_zip_file_dir, "#{Time.now.to_f}_ena_export.zip")
        Zip::File.open(zipfile_name, create: true) do |zipfile|
          input_filenames.each do |filename|
            zipfile.add(filename, File.join(tmp_zip_file_dir, filename))
          end
        end
        zipfile_name
      end 

      private 

      def tmp_zip_file_dir
        dir = if Rails.env.test?
                File.join(Dir.tmpdir, 'seek-tmp', 'zip-files')
              else
                File.join(Rails.root, 'tmp', 'zip-files')
              end
        FileUtils.mkdir_p dir unless File.exist?(dir)
        dir
      end
      
    end
  end
end