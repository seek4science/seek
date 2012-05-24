
class DataFileWithSample < ActiveRecord::Base

  set_table_name :data_files

  def self.user_creatable?
    true
  end

end