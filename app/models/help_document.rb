require 'RedCloth'

class HelpDocument < ActiveRecord::Base
  validates_presence_of :title, :identifier
  validates_uniqueness_of :identifier
  validates :identifier, format: { with: /\A[a-z0-9][-a-z0-9]*\Z/ ,message: 'is invalid. Please only use lower-case alphanumeric characters and hyphens.'}

  has_many :attachments, class_name: 'HelpAttachment', dependent: :destroy
  has_many :images, class_name: 'HelpImage', dependent: :destroy

  def body_html
    doc = body
    # substitute "[identifier]" for links to help docs
    doc = doc.gsub(/\[([-a-zA-Z0-9]+)\]/) { |_match| HelpDocument.friendly_redcloth_link(Regexp.last_match(1)) }
    # redcloth-ify
    doc = RedCloth.new(doc, [:hard_breaks])
    doc.to_html.html_safe
  end

  def to_param
    "#{identifier.parameterize}"
  end

  def self.friendly_redcloth_link(identifier)
    doc = HelpDocument.find_by_identifier(identifier.downcase)
    unless doc.nil?
      return ("\"#{doc.title}\"" + ':' + '/help/' + doc.to_param).html_safe
    else
      return ''
    end
  end
end
