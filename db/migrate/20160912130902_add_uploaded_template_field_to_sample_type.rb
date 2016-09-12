class AddUploadedTemplateFieldToSampleType < ActiveRecord::Migration
  def change
    add_column :sample_types,:uploaded_template,:boolean,:default=>false
  end
end
