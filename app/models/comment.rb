class Comment < ActiveRecord::Base
  include ActsAsCommentable::Comment
  has_ancestry
  belongs_to :commentable, :polymorphic => true

  belongs_to :user
  belongs_to :movie
  belongs_to :celebrity
  default_scope :order => 'created_at DESC'
  validates :comment , :presence => true
  scope :to_level, where('ancestry IS NULL')

  after_save :update_badge

  #after_create :log_activity
  #after_save :post_to_wall
  #after_save :post_to_twitter

  # NOTE: install the acts_as_votable plugin if you
  # want user to vote on the quality of comments.
  #acts_as_voteable


  def log_activity
    #Activity.log_activity(self, self.commentable, 'commented',  self.user_id)
    if self.user.facebook_omniauth
      Activity.create_log_for_each_friend(self, self.commentable, 'commented on' , self.user.facebook_omniauth.uid, self.user.display_name)
    end
  end

  def post_to_wall
    if self.user.user_profile &&  self.user.user_profile.post_to_social_media && self.user.facebook_omniauth
      begin
        client = Koala::Facebook::GraphAPI.new(self.user.facebook_token)
        client.put_wall_post({:message => "#{SITE_URL}/movies/#{self.commentable.permalink}' \n #{self.comment}" , :picture => "http://muvi.com/images/logo_in.png", :action_links => [{:text =>  "See Muvi Comment", :href => "#{SITE_URL}/movies/#{self.commentable.permalink}"}]})
      rescue Koala::Facebook::OAuthException
        #getting this strange exception. (#506) Duplicate status message
        #TODO handle this exception
      end
    end
  end

  def post_to_twitter
    if self.user.user_profile && self.user.user_profile.post_to_social_media && self.user.twitter_omniauth
      begin
        self.user.twitter.update("#{self.comment}")
      rescue Twitter::Unauthorized
      end
    end
  end

  private
  def update_badge
     @user_badge =  UserBadge.new
     @user_badge.add_badge_points(self.user_id)
  end

end
