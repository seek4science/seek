class IsaTag < ApplicationRecord
  has_many :template_attributes, inverse_of: :isa_tag
end
