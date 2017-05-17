class Topic < ActiveRecord::Base
  validates_presence_of :forum, :user_id, :title
  before_create  :set_default_replied_at_and_sticky
  before_update  :check_for_changing_forums
  after_save     :update_forum_counter_cache
  before_destroy :update_post_user_counts
  after_destroy  :update_forum_counter_cache

  belongs_to :forum
  belongs_to :user
  belongs_to :last_post, :class_name => "Post", :foreign_key => 'last_post_id'
  has_many :monitorships
  has_many :monitors, -> { where("#{Monitorship.table_name}.active = ?", true) }, :through => :monitorships, :source => :user

  has_many :posts,     -> { order("#{Post.table_name}.created_at DESC") }, :dependent => :destroy
  has_one  :recent_post, -> { order("#{Post.table_name}.created_at DESC") }, :class_name => 'Post'
  
  has_many :voices, -> { uniq }, :through => :posts, :source => :user
  belongs_to :replied_by_user, :foreign_key => "replied_by", :class_name => "User"

  # attr_accessible :title
  # to help with the create form
  attr_accessor :body
	
	def hit!
    self.class.increment_counter :hits, id
  end

  def sticky?() sticky == 1 end

  def views() hits end

  def paged?() posts_count > Post.per_page end
  
  def last_page
    [(posts_count.to_f / Post.per_page).ceil.to_i, 1].max
  end

  def editable_by?(user)
    user && (user.id == user_id || user.admin? || user.moderator_of?(forum_id))
  end
  
  def update_cached_post_fields(post)
    # these fields are not accessible to mass assignment
    remaining_post = post.frozen? ? recent_post : post
    if remaining_post
      self.class.where(id: id).update_all(replied_at: remaining_post.created_at,
                                          replied_by: remaining_post.user_id,
                                          last_post_id: remaining_post.id,
                                          posts_count: posts.count)
    else
      self.destroy
    end
  end
  
  protected
    def set_default_replied_at_and_sticky
      self.replied_at = Time.now.utc
      self.sticky   ||= 0
    end

    def set_post_forum_id
      Post.where(topic_id: id).update_all(forum_id: forum_id)
    end

    def check_for_changing_forums
      old = Topic.find(id)
      @old_forum_id = old.forum_id if old.forum_id != forum_id
      true
    end
    
    # using count isn't ideal but it gives us correct caches each time
    def update_forum_counter_cache
      forum_conditions = ['topics_count = ?', Topic.where(forum_id: forum_id).count]
      # if the topic moved forums
      if !frozen? && @old_forum_id && @old_forum_id != forum_id
        set_post_forum_id
        Forum.where(id: @old_forum_id).update_all(topics_count: Topic.where(forum_id: @old_forum_id).count,
                                                  posts_count: Post.where(forum_id: @old_forum_id).count)
      end
      # if the topic moved forums or was deleted
      if frozen? || (@old_forum_id && @old_forum_id != forum_id)
        forum_conditions.first << ", posts_count = ?"
        forum_conditions       << Post.where(forum_id: forum_id).count
      end
      # User doesn't have update_posts_count method in SB2, as reported by Ryan
			#@voices.each &:update_posts_count if @voices
      Forum.where(id: forum_id).update_all(forum_conditions)
      @old_forum_id = @voices = nil
    end
    
    def update_post_user_counts
      @voices = voices.to_a
    end
end
