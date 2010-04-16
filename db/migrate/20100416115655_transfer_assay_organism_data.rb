class TransferAssayOrganismData < ActiveRecord::Migration
  def self.up
    select_all("SELECT id,organism_id,culture_growth_type_id FROM assays").each do |values|
      assay_id=values["id"]
      organism_id=values["organism_id"]
      if (organism_id)
        culture_id=values["culture_growth_type_id"]
        culture_id||="NULL"
        execute("INSERT into assay_organisms (assay_id,organism_id,culture_growth_type_id) VALUES (#{assay_id},#{organism_id},#{culture_id})")
      end      
    end
  end

  def self.down
    execute("DELETE FROM assay_organisms")
  end
end
