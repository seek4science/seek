require 'rubygems'
require 'zip'

module Ena
  class EnaClient
    def generate_ena_tsv pid
      sample_types = SampleType.where(id: [1, 2, 3, 5])
      if !sample_types.any?
        return nil
      end

      tsv_files = []
      folder = UUID.generate
      dir = File.join(tmp_zip_file_dir, folder)
      FileUtils.mkdir_p dir unless File.exist?(dir)

      sample_types.each do |st|
        atrs = st.sample_attributes
        row = atrs.map(&:title).join("\t")
        # s.samples.map{|item| item.map{|val| atrs.map{|atr| item.get_attribute_value(atr) }.join("\t") }.join("\n") }
        samples = Project.find(pid).samples.where(sample_type_id:st.id)
        samples.authorized_for('view').each do |s|
          row << "\n"
          row <<  atrs.map{ |atr| "#{s.get_attribute_value(atr)}" }.join("\t")
        end
        tsv_files << file_name = "#{st.title}.tsv"
        File.write(File.join(tmp_zip_file_dir, folder, file_name), row)
      end
      zip_files(tsv_files, folder)
    end
    
    def zip_files(input_filenames, folder)
      base_folder = File.join(tmp_zip_file_dir, folder)
      zipfile_name = File.join(tmp_zip_file_dir, "ena_export_#{UUID.generate}.zip")
      Zip::File.open(zipfile_name, create: true) do |zipfile|
        input_filenames.each do |filename|
          zipfile.add(filename, File.join(base_folder, filename))
        end
      end
      # clean_up base_folder
      zipfile_name
    end 

    private 

    def clean_up folder
      FileUtils.rm_r(folder)
    end
    
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
