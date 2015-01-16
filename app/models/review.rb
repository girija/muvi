class Review < ActiveRecord::Base
  MAX_RATING = 5
  belongs_to :movie, :counter_cache => true
  belongs_to :user

  acts_as_commentable
  acts_as_votable
  after_create :log_activity
  #after_save :post_to_wall
  after_save :post_to_twitter
  after_create :log_in_activity
  #after_create :create_friend_like
  scope :for_movie, lambda{|movie| where(:movie_id => movie.id)}
  scope :latest, order('created_at desc nulls last')

  def log_in_activity
    movie = Movie.find_by_id(self.movie_id)
    user = User.find(self.user_id)
    activity = Activity.new
    activity.user_id = self.user_id
    activity.secondary_subject_type = "Movie"
    activity.secondary_subject_id = self.movie_id
    activity.subject_type = "Review"
    activity.action = "#{user.display_name} rated <a href='/movies/#{movie.permalink}'>#{movie.name}'>#{movie.name}.</a>"
    activity.save
  end

  def post_to_wall
    if self.user.user_profile &&  self.user.user_profile.post_to_social_media && self.user.facebook_omniauth
      begin
        client = Koala::Facebook::GraphAPI.new(self.user.facebook_token)
        begin
         client.delay.put_wall_post("",{:name => "#{self.user.display_name} rated #{self.movie.name} #{self.rating} stars",:link => "#{SITE_URL}/profile/#{self.user.id}/#{self.user.display_name}",:description => "#{self.description} - #{self.user.display_name}", :picture => "#{SITE_URL}/#{self.movie.banner_image}"},profile_id="#{self.user.facebook_id}")
        rescue
        end
      rescue Koala::Facebook::OAuthException
          # getting this strange exception. (#506) Duplicate status message
          #TODO handle this exception
      end
    end
  end

  def post_to_twitter
    if self.user.user_profile && self.user.user_profile.post_to_social_media && self.user.twitter_omniauth
      begin
          self.user.twitter.update("my review for #{self.movie.name} #{SITE_URL}/movies/#{self.movie.permalink}/reviews/#{self.id}")
      rescue Twitter::Forbidden
      rescue Twitter::Unauthorized
      end
    end
  end

  def log_activity
    #Activity.log_activity(self, self.movie, 'rated',  self.user_id)
    if self.facebook && self.user.facebook_omniauth
      Activity.create_log_for_each_friend(self, self.movie, 'rated' , self.user.facebook_omniauth.uid, self.user.display_name)
    end
  end

  def movie_release_date
    Time.parse(self.movie.release_date.to_s).strftime('%b %d, %Y').to_s rescue ''
  end

#  def create_friend_like
#    if self.rating && self.rating.to_f >= 3.0 && self.user.user_profile && self.user.user_profile.post_to_social_media && self.user.facebook_omniauth
#      fb_user = self.user.facebook_client_user
#      unless fb_user.blank?
#        post = FacebookFeed.create!(:user_id => self.user.id, :feed_type => 'friend_likes', :movie_id => self.movie.id, :value => self.description, :fbid => fb_user.id, :fb_item_id => self.movie.fbpage_id, :posted_on => Date.today.to_date, :facebook_name => fb_user.name)
#        Activity.create_log_for_each_friend(post, self.movie, self.movie.like_or_interest, fb_user.id.to_s,  fb_user.name)
#      end
#    end
#  end



end

