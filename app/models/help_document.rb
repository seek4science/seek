class HelpDocument < ActiveRecord::Base
  
  validates_presence_of :title, :identifier
  validates_uniqueness_of :identifier
  has_many :attachments, :class_name => "HelpAttachment", :dependent => :destroy
  has_many :images, :class_name => "HelpImage", :dependent => :destroy
  
  attr_protected :identifier
  
  def body_html
    doc = self.body
    #substitute "[identifier]" for links to help docs
    doc = doc.gsub(/\[([-a-zA-Z0-9]+)\]/) {|match| HelpDocument.friendly_redcloth_link($1)}
    #redcloth-ify
    doc = RedCloth.new(doc, [ :hard_breaks ])
    return doc.to_html
  end
  
  def to_param
    "#{id}-#{identifier.parameterize}"
  end
  
  def self.friendly_redcloth_link(identifier)
    doc = HelpDocument.find_by_identifier(identifier)
    unless doc.nil?
      return "\"#{doc.title}\"" + ":" + "/help/" + doc.to_param
    else
      return ""
    end    
  end  
end