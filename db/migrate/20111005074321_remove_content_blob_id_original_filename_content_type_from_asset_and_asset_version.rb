ASSET_ARRAY=[['model_id', 'Model', 'models', 'model_versions'], ['sop_id', 'Sop', 'sops', 'sop_versions'], ['data_file_id', 'DataFile', 'data_files', 'data_file_versions'], ['presentation_id', 'Presentation', 'presentations', 'presentation_versions']]

class RemoveContentBlobIdOriginalFilenameContentTypeFromAssetAndAssetVersion < ActiveRecord::Migration
  def self.up
    #remove original_filename,content_types in assets table and asset_versions table
    ASSET_ARRAY.each do |asset|
      if found_in_content_blobs(asset[0], asset[1], asset[3])
        remove_column asset[2].to_sym, :original_filename, :content_type, :content_blob_id
        remove_column asset[3].to_sym, :original_filename, :content_type, :content_blob_id
      end
    end
  end

  def self.down
    #add original_filename,content_types in assets table and asset_versions table
    ASSET_ARRAY.each do |asset|
      add_column asset[2].to_sym, :original_filename, :string
      add_column asset[2].to_sym, :content_type, :string
      add_column asset[2].to_sym, :content_blob_id, :integer
      add_column asset[3].to_sym, :original_filename, :string
      add_column asset[3].to_sym, :content_type, :string
      add_column asset[3].to_sym, :content_blob_id, :integer
    end
  end

  def self.found_in_content_blobs asset_id_name, asset_type, asset_versions
    execute("SELECT id,#{asset_id_name},version,original_filename,content_type FROM #{asset_versions}").each do |asset_version|
      unless execute("SELECT * FROM content_blobs WHERE id=#{asset_version[0]} AND asset_type='#{asset_type}' AND asset_version=#{asset_version[2]}  AND original_filename=#{quote(asset_version[3])} AND content_type=#{quote(asset_version[4])} ").blank?
        return true
      else
        return false
      end
    end
  end
end
