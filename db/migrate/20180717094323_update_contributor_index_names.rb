class UpdateContributorIndexNames < ActiveRecord::Migration
  def change
    ['data_files','model_versions','models','publications','sop_versions','sops'].each do |t|
      rename_index t, "index_#{t}_on_contributor_id_and_contributor_type","index_#{t}_on_contributor"
    end


    ['documents','document_versions'].each do |t|
      rename_index t, "index_#{t}_on_contributor_type_and_contributor_id","index_#{t}_on_contributor"
    end

  end
end
