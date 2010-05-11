class HelpDocument < ActiveRecord::Base
  
  validates_presence_of :title, :identifier
  validates_uniqueness_of :identifier
  
  def body_html
    doc = auto_link(self.body) { |text| truncate(text, 50) }
    doc = RedCloth.new(doc, [ :hard_breaks ])
    return doc.to_html
  end
  
  def to_param
    "#{id}-#{identifier.parameterize}"
  end
  
end