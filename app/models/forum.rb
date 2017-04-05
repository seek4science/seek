class Forum < ActiveRecord::Base
  acts_as_list

  validates_presence_of :name

  has_many :moderatorships, :dependent => :destroy
  has_many :moderators, :through => :moderatorships, :source => :user

  has_many :topics, -> { order('sticky DESC, replied_at DESC') }, :dependent => :destroy
  has_one  :recent_topic, -> { order('sticky DESC, replied_at DESC') }, :class_name => 'Topic'

  # this is used to see if a forum is "fresh"... we can't use topics because it puts
  # stickies first even if they are not the most recently modified
  has_many :recent_topics, -> { order('replied_at DESC') }, :class_name => 'Topic'
  has_one  :recent_topic,  -> { order('replied_at DESC') }, :class_name => 'Topic'

  has_many :posts,     -> { order("#{Post.table_name}.created_at DESC") }, :dependent => :destroy
  has_one  :recent_post, -> { order("#{Post.table_name}.created_at DESC") }, :class_name => 'Post'

  format_attribute :description
  
  # retrieves forums ordered by position
  def self.find_ordered(options = {})
    options = options.update(:order => 'position')
    where(options[:conditions] || '').order(options[:order]).limit(options[:limit])
  end
end
