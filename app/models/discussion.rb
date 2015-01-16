class Discussion < ActiveRecord::Base
  acts_as_commentable
  acts_as_taggable
  acts_as_votable
  belongs_to :user
  
  validates :question, :presence => true
  has_many :like_votes, :conditions => [ "vote_flag = ?", 'true' ], :dependent => :destroy, :class_name => 'Vote',:foreign_key => "votable_id"
  has_many :dislike_votes, :conditions => [ "vote_flag = ?", 'false' ], :dependent => :destroy, :class_name => 'Vote',:foreign_key => "votable_id"

  after_save :update_badge

  def self.get_discussions(tagger_id, tagger_type, taggable_type)
    @discussions = []
    Tagging.where("taggable_type = '#{taggable_type}' and tagger_id = '#{tagger_id}' and tagger_type = '#{tagger_type}'").find(:all).each do |tag|
      discussion = Discussion.find_by_id(tag.taggable_id)
      @discussions << discussion unless discussion.blank?
    end
    return (@discussions.sort_by &:created_at).reverse
  end
  def self.log_discussion_activity(current_user, discussion, action,refer)
     @activity = Activity.new
     @user = UserProfile.find_by_user_id(current_user.id)
     @activity.user_id = current_user.id
     @activity.secondary_subject_type = refer.class.to_s
     @activity.subject_type = action
     @activity.secondary_subject_id = refer.id
     unless @user.blank?
       @activity.action = "<a href='/profile/#{@user.user_id}/#{@user.display_name}' style='font-weight:normal;'>#{@user.display_name}</a> #{action.downcase} #{discussion.question}.".html_safe
     else
       @activity.action = "#{action.downcase} #{discussion.question}."
     end
     @activity.save!
  end

  def self.check_like(current_user,discussion)
    if current_user
      like_discussion = Vote.find(:first,:conditions=>["votable_id = ? AND votable_type = '#{discussion.class.to_s}' AND voter_id = ? AND voter_type = 'User'",discussion.id,current_user.id])
      unless like_discussion.blank?
        return true
      else
        return false
      end
    end
  end

  def self.activity_thumb(discussion)
    @tagging = discussion.taggings.first
    if @tagging.tagger_type == "Movie"
      @movie = Movie.find_by_id(@tagging.tagger_id)
      image = @movie.banner_image_thumb
    else
      @celebrity = Celebrity.find_by_id(@tagging.tagger_id)
      image = @celebrity.thumb_image
    end
    return image
  end
  
  def self.activity_item(discussion)
    @tagging = discussion.taggings.first
    @refer = ""
    unless @tagging.blank?
      if @tagging.tagger_type == "Movie"
        @refer = Movie.find_by_id(@tagging.tagger_id)
      else
        @refer = Celebrity.find_by_id(@tagging.tagger_id)
      end
    end
    return @refer
  end
  private
  def update_badge
     @user_badge =  UserBadge.new
     @user_badge.add_badge_points(self.user_id)
  end

end
