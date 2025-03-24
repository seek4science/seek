class AddAllowCvFreeTextToAttributes < ActiveRecord::Migration[6.1]
  def change
    add_column :sample_attributes, :allow_cv_free_text, :boolean, default: false
    add_column :template_attributes, :allow_cv_free_text, :boolean, default: false
    add_column :extended_metadata_attributes, :allow_cv_free_text, :boolean, default: false
  end
end
