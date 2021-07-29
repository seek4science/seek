require 'rubygems'
require 'zip'

module Ena
  class EnaClient
    def generate_ena_tsv sample_types
      tsv_files = []
      sample_types.each do |st|
        atrs = st.sample_attributes
        row = atrs.map(&:title).join("\t") + "\n"
        # s.samples.map{|item| item.map{|val| atrs.map{|atr| item.get_attribute_value(atr) }.join("\t") }.join("\n") }
        st.samples.each do |s|
          atrs.each{ |atr| row << "#{s.get_attribute_value(atr)}\t" }
          row << "\n"
        end
        tsv_files << file_name = "#{Time.now.to_f}_#{st.title}.tsv"
        File.write(File.join(tmp_zip_file_dir, file_name), row)
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
