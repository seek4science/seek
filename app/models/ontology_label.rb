class OntologyLabel < ApplicationRecord
    belongs_to :sample_controlled_vocab_term
    validates_presence_of :label
end
