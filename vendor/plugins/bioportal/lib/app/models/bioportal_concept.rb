# To change this template, choose Tools | Templates
# and open the template in the editor.

class BioportalConcept < ActiveRecord::Base
  belongs_to :conceptable,:polymorphic=>true
end
