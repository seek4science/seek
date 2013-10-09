class WorkflowCategory < ActiveRecord::Base
  TAXONOMIC_REFINEMENT = 'Taxonomic Refinement'
  ENM = 'Ecological Niche Modelling'
  METAGENOMICS = 'Metagenomics'
  PHYLOGENETICS = 'Phylogenetics'
  POPULATION_MODELLING = 'Population Modelling'
  ECOSYSTEM_MODELLING = 'Ecosystem Modelling'
  OTHER = 'Other'

end