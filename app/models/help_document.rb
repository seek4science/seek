require 'RedCloth'

class HelpDocument < ActiveRecord::Base
  
  validates_presence_of :title, :identifier
  validates_uniqueness_of :identifier  
  validates_format_of :identifier, :with => /\A[a-z0-9][-a-z0-9]*\Z/, :message => "is invalid. Please only use lower-case alphanumeric characters and hyphens."
  
  has_many :attachments, :class_name => "HelpAttachment", :dependent => :destroy
  has_many :images, :class_name => "HelpImage", :dependent => :destroy
  
  def body_html
    doc = self.body
    #substitute "[identifier]" for links to help docs
    doc = doc.gsub(/\[([-a-zA-Z0-9]+)\]/) {|match| HelpDocument.friendly_redcloth_link($1)}
    #redcloth-ify
    doc = RedCloth.new(doc, [ :hard_breaks ])
    return doc.to_html
  end

  def to_param
    "#{identifier.parameterize}"
  end
  
  def self.friendly_redcloth_link(identifier)
    doc = HelpDocument.find_by_identifier(identifier.downcase)
    unless doc.nil?
      return "\"#{doc.title}\"" + ":" + "/help/" + doc.to_param
    else
      return ""
    end    
  end  
end