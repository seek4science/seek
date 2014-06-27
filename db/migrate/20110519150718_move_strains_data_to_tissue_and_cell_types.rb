class MoveStrainsDataToTissueAndCellTypes < ActiveRecord::Migration


  def self.up

    execute("SELECT id,title, created_at, updated_at  FROM strains").each do |strain|
      begin
      execute("INSERT into tissue_and_cell_types(id,title,created_at,updated_at) VALUES('#{strain[0]}','#{strain[1]}','#{strain[2]}','#{strain[3]}') ")
      rescue
        raise
        end
    end
    execute("SELECT id, strain_id FROM assay_organisms").each do |assay_organism|
       id,strain_id = *assay_organism
       execute("UPDATE assay_organisms SET tissue_and_cell_type_id = #{strain_id} WHERE id=#{id}")
       execute("UPDATE assay_organisms SET strain_id = NULL WHERE id=#{id}")
    end
    execute("DELETE FROM strains")


  end

  def self.down
    execute("SELECT id ,title, created_at, updated_at FROM tissue_and_cell_types").each do |t|
       begin
       execute("INSERT into strains(title,created_at,updated_at) VALUES('#{t[0]}','#{t[1]}','#{t[2]}','#{t[3]}') ")
       rescue
        raise  ActiveRecord::IrreversibleMigration
       end
    end

    execute("SELECT id, tissue_and_cell_type_id FROM assay_organisms").each do |assay_organism|
       id,tissue_and_cell_type_id = *assay_organism
       execute("UPDATE assay_organisms SET strain_id = #{tissue_and_cell_type_id} WHERE id=#{id}")
       execute("UPDATE assay_organisms SET tissue_and_cell_type_id = NULL WHERE id=#{id}")
    end

    execute("DELETE FROM tissue_and_cell_types")

  end
end
