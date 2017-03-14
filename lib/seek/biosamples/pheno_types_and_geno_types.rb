module Seek
  module Biosamples
    module PhenoTypesAndGenoTypes
      def self.included(base)
        base.has_many :phenotypes
        base.has_many :genotypes
        base.accepts_nested_attributes_for :genotypes, allow_destroy: true
        base.accepts_nested_attributes_for :phenotypes, allow_destroy: true
        base.before_destroy :destroy_genotypes_phenotypes
      end

      def genotype_info
        genotype_detail = []
        genotypes.each do |genotype|
          genotype_detail << genotype.modification.try(:title).to_s + ' ' + genotype.gene.try(:title).to_s if genotype.gene
        end
        genotype_detail = genotype_detail.blank? ? 'wild-type' : genotype_detail.join(';')
        genotype_detail
      end

      def phenotype_info
        phenotype_detail = []
        phenotypes.each do |phenotype|
          phenotype_detail << phenotype.try(:description) unless phenotype.try(:description).blank?
        end
        phenotype_detail = phenotype_detail.blank? ? 'wild-type' : phenotype_detail.join('; ')
        phenotype_detail
      end

      def destroy_genotypes_phenotypes
        genotypes = self.genotypes
        phenotypes = self.phenotypes
        (genotypes | phenotypes).each do |type|
          type.destroy if type.strain == self || type.strain.nil?
        end
      end
    end
  end
end
