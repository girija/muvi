class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :database_authenticatable,  :registerable, :timeoutable,
         :recoverable, :rememberable, :trackable, :validatable, :token_authenticatable, :timeout_in => 2.weeks#, :confirmablei, :oauth2_authenticatable
  acts_as_follower
  
# Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :oauth2_token, :user_profile_attributes, :user_tokens_attributes, :film_critic_attributes, :reset_password_token, :facebook_id, :reset_password_sent_at

  before_validation :copy_password

  has_many :facebook_feeds , :dependent => :destroy

  has_one :user_address, :dependent => :destroy

  has_many :all_notification, :dependent => :destroy
  #has_many :facebook_friends, :class_name => 'FacebookFeed', :conditions => {:feed_type => 'friend'}
  has_many :facebook_likes, :class_name => 'FacebookFeed', :conditions => {:feed_type => 'likes'}
  has_many :facebook_friend_likes, :class_name => 'FacebookFeed', :conditions => {:feed_type => 'friend_likes'}
  has_many :facebook_friends_posts, :class_name => 'FacebookFeed', :conditions => {:feed_type => 'friends_post'}

  has_many :reviews, :dependent => :destroy
  #has_many :reviewed_movies, :through => :reviews, :source => :movie, :foreign_key => :movie_id
  has_many :comments, :dependent => :destroy
  has_many :friend_ships, :dependent => :destroy
  has_many :friends, :through => :friend_ships, :class_name => 'User'
  has_many :recommendations, :dependent => :destroy
  has_one :user_profile, :dependent => :destroy
  has_many :user_tokens, :dependent => :destroy
  
  has_one :facebook_omniauth, :class_name => "UserToken", :conditions => { :provider => 'facebook' }
  has_one :twitter_omniauth, :class_name => "UserToken", :conditions => { :provider => 'twitter' }
  has_many :tweets, :dependent => :destroy
  has_many :twitter_friends, :dependent => :destroy
  has_many :facebook_friends, :dependent => :destroy
  has_one :film_critic, :dependent => :destroy
  has_many :fans , :dependent => :destroy
  has_one :user_connection , :dependent => :destroy
  has_one :user_payment_info
  scope :all_without_admin, where(:is_admin => false)
  scope :enabled_users, where(:is_disabled => false)
  accepts_nested_attributes_for :user_profile
  accepts_nested_attributes_for :user_tokens,  :reject_if => proc { |attributes| attributes['uid'].blank? }
  accepts_nested_attributes_for :film_critic

  searchable :if => proc{|user| user.email != '' and user.display_name != ''} do
    text :display_name
  end
  
  def self.get_movie_want_to_see(user,movie_id,is_want_to_see)
    want_to_sees = []
    @connections = User.get_user_connections(user)
    @connections.each do |user_id|
      user = User.find_by_id(user_id)
      want_to_see = WantToSee.find_by_movie_id_and_user_id_and_is_want_to_see(movie_id,user.id,is_want_to_see)
      #want_to_see = WantToSee.find_by_movie_id_and_user_id(movie_id,user.id)
      if want_to_see
        want_to_sees <<  want_to_see
      end
    end
    return want_to_sees
  end
  
  def self.get_movie_reviews_activity(user,movie_id,type)
    reviews = []
    @connections = User.get_user_connections(user)
    @connections.each do |user_id|
      user = User.find_by_id(user_id)
      review = Review.find_by_movie_id_and_user_id(movie_id,user.id)
      if type == "like"
        if review and review.rating and review.rating >= 3.0
          reviews <<  review
        end
      else
        if review and review.rating and review.rating < 3.0
          reviews <<  review
        end
      end
    end
    return reviews
  end

  def copy_password
    #self.password_confirmation = params[:user][:password] unless params[:user][:password].blank?
    self.password_confirmation = self.password unless self.password.blank?
  end

  def facebook_token
    facebook_omniauth.token
  end
  
  def facebook_id_update
    self.update_attribute(:facebook_id,self.facebook_omniauth.uid)
  end

  #Fetching posts, friends and likes for the user
 # def fetch_fb_feeds
 #   unless self.facebook_omniauth.blank?
 #     fb_user = self.facebook_client_user
 #     unless fb_user.blank?
 #       self.fetch_facebook_friends(fb_user) # fetch friends
 #       self.fetch_facebook_posts(fb_user) # fetch posts
 #       self.fetch_facebook_likes(fb_user) # fetch likes
 #       unless fb_user.friends.blank?
 #         fb_user.friends.each do |friend|
 #           self.fetch_facebook_likes(friend) # fetch friends likes
 #           self.fetch_facebook_posts(friend) # fetch friends posts
 #        end
 #       end
 #     end
 #   end
 # end

  # fetch facebook friends for the user
  def fetch_facebook_friends(facebook_user)
    #facebook_user.friends.collect(&:id).each do |friend_id|
    #  unless self.facebook_friends.collect(&:facebook_id).include?(friend_id.to_s)
    #    self.facebook_friends.create!(:facebook_id => friend_id)
    #  end
    #end
  end

  # fetch facebook lieks for the user
  def fetch_facebook_likes(facebook_user)
    facebook_user.likes.each do |friend_like|
      movie = Movie.find_by_fbpage_id(friend_like.id.to_s)
      if movie && movie.facebook_feeds.friend_likes.by_fb_item_id(friend_like.id.to_s).by_fbid(facebook_user.id.to_s).blank?
        post = FacebookFeed.create!(:feed_type => 'friend_likes', :movie_id => movie.id, :value => friend_like.name, :fbid => facebook_user.id, :fb_item_id => friend_like.id, :posted_on => friend_like.created_time.to_date, :facebook_name => facebook_user.name)
        Activity.create_log_for_each_friend(post, movie, 'liked', facebook_user.id.to_s,  facebook_user.name)
      end
    end
  end

  # fetch facebook wall posts for the user
  #def fetch_facebook_posts(facebook_user)
  #  posts = facebook_user.posts # fetch posts
  #  Movie.name_is_not_blank.name_without_dictionary_word.this_year.each do |movie|
  #    posts.each do |post|
  #      FacebookFeed.create_facebook_post(post, movie, facebook_user)
  #      User.pull_comments(post, movie) #check for comments is present
  #    end # each post end
  #  end # movie end
  #end


  #fetch facebook friends
 # def fetch_all_facebook_friends
 #   unless self.facebook_omniauth.blank?
 #     fb_user = self.facebook_client_user
 #     self.fetch_facebook_friends(fb_user) unless fb_user.blank?
 #   end
 # end

  #Initiate the mogli facebook user
 # def facebook_client_user
 #   begin
 #     client = Mogli::Client.new(self.facebook_token)
 #     Mogli::User.find("me", client) rescue nil
 #   rescue  Exception => e
 #      logger.error("Coundn't fetch fb posts for #{self.facebook_token}   #{e.to_s}")
 #     return nil
 #   end
 # end

  def facebook_client_user
    begin
      client = Koala::Facebook::GraphAPI.new(self.facebook_token)
    rescue  Exception => e
       logger.error("Coundn't fetch fb posts for #{self.facebook_token}   #{e.to_s}")
      return client
    end
  end

def fetch_all_facebook_friends
  unless self.facebook_omniauth.blank?
    self.update_attribute(:facebook_id,facebook_omniauth.uid)
    fb_user = self.facebook_client_user
    unless fb_user.blank?
      fb_user.get_connections(fb_user.get_object("me")["id"],"friends").each do |friend|
        puts friend["name"]
        friend_fetched = fb_user.get_object(friend["id"])
        friend_fetched_one = User.find_or_create_muvi_user_facebook(friend_fetched["id"])
          #friend_fetched_one = User.find_by_facebook_id(friend_fetched["id"])
          #profile_fetched = UserProfile.find(:first,:conditions => [':user_id => ?',friend_fetched_one.id])
             profile_fetched = UserProfile.find_or_create_muvi_user_profile_facebook(friend_fetched_one.id)
             profile_fetched.update_attribute(:display_name,friend_fetched["name"])
             profile_fetched.update_attribute(:sex,friend_fetched["gender"])
          friend_fetched_one.update_attribute(:display_name,friend_fetched["name"])
          friend_fetched_one.update_attribute(:gender,friend_fetched["gender"])
          #self.user_connection.add_user_connection(self.id,friend_fetched_one.id)         
          unless self.user_connection.blank?
            self.user_connection.add_user_connection(self.id,friend_fetched_one.id)
          else
            uc = UserConnection.new
            uc.add_user_connection(self.id,friend_fetched_one.id)
          end

          #friend_fetched_one.update_attributes({:display_name => friend_fetched["name"],  :gender => friend_fetched["gender"]}).save(false)
      end
    end
  end
end

def self.find_or_create_muvi_user_facebook(facebk_id)
 if (user = User.find(:first,:conditions => ['facebook_id =?',facebk_id]))
    return user
 else 
    user = User.new
    user.facebook_id = facebk_id
    if user.save(false)
       return user
    else
       return nil
    end
 end
end
   
   

 def fetch_fb_feeds
   self.fetch_all_facebook_friends
 end

 def send_fb_invite(fb_connection)
   fb_user = self.facebook_client_user
   fb_user.put_wall_post("",{:name => "#{self.display_name} wants to connect with you on Muvi." , :link => "http://www.muvi.com/invite/#{self.id}", :description => "#{fb_connection.display_name} build your muvi showcase today and see which muvis and stars your friends are upto.", :picture => "http://muvi.com/images/logo_in.png"}, profile_id="#{fb_connection.facebook_id}")
 end

 def accept_fb_invite(invite_id)
   uc2 = UserConnection.new
   uc2.add_user_connection(self.id,invite_id)
 end

  # fetch facebook wall posts of the friends
  #def fetch_all_posts_for_friends
  #  unless self.facebook_omniauth.blank?
  #    fb_user = self.facebook_client_user
  #    unless fb_user.blank?
  #      unless fb_user.friends.blank?
  #        fb_user.friends.each do |friend|
  #           self.fetch_facebook_posts(friend)
  #        end
  #      end
  #    end
  #  end
  #end

  def fetch_from_news_feed
    unless self.facebook_omniauth.blank?
      fb_user = self.facebook_client_user
      unless fb_user.blank?
        posts = fb_user.home # fetch posts
        Movie.name_is_not_blank.name_without_dictionary_word.this_year.each do |movie|
          posts.each do |post|
            FacebookFeed.create_facebook_post(post, movie, post.from)
            User.pull_comments(post, movie) #check for comments is present
          end # each post end
        end # movie end
      end
    end
  end



  def fetch_from_news_feed_using_query_string
    unless self.facebook_omniauth.blank?
      fb_user = self.facebook_client_user
      unless fb_user.blank?
        client = Mogli::Client.new(self.facebook_token)
        Movie.name_is_not_blank.name_without_dictionary_word.past1month_upcoming_movies.each do |movie|
          begin
            posts = client.get_and_map("me/home?q=#{movie.name.gsub(" ", '%20')}", 'post') # fetch for movie name
            posts.each do |post|
              FacebookFeed.create_facebook_post(post, movie, post.from)
              User.pull_comments(post, movie) #check for comments is present
            end # each post end
          rescue
          end
          unless movie.alias_name.blank?
            begin
              posts = client.get_and_map("me/home?q=#{movie.alias_name.gsub(" ", '%20')}",'post') # fetch posts for movie alias name
              posts.each do |post|
               FacebookFeed.create_facebook_post(post, movie, post.from)
               User.pull_comments(post, movie) #check for comments is present
              end # each post end
             rescue
             end
          end
        end # movie end
      end
    end
  end

  def self.pull_comments(post, movie)
    post.comments.map { |comment|
                           FacebookFeed.create_facebook_post_from_comment(comment, movie, comment.from)
                      } unless  post.comments.blank?
  end


  def fetch_all_facebook_likes(facebook_user)
    self.fetch_facebook_likes(self.facebook_client_user) unless self.facebook_omniauth.blank?
  end

  def password_is_blank?
    self.encrypted_password.blank? && self.password_salt.blank?
  end

  def image
     (self.user_profile.profile_image_file_name.blank?? "/images/no-profile.png" : self.user_profile.profile_image.url(:thumb)) rescue '/images/no-profile.png'
  end

  def reviwed_movie?(movie)
    #reviewed_movies.include?(movie)
   self.reviews.where(:movie_id => movie.id).exists? ? true : false
  end

  def has_user_token?(provider, uid)
    self.user_tokens.where('provider = ? and uid = ? ', provider, uid).exists? ? false : true
  end

  def display_name
    self.user_profile.display_name rescue ''
  end

  def my_rating(movie)
    review = self.reviews.for_movie(movie).first
    review.rating unless review.blank?
  end
  def my_rating_text(movie)
      review =  self.reviews.for_movie(movie).first
      review.description unless review.blank?
  end
  def facebook_friends_ids
    self.facebook_friends.collect(&:facebook_id)
  end

  def create_user_from_omniauth(omniauth)
    self.email = (omniauth['extra']['user_hash']['email'] rescue '' ) if omniauth['provider'] == 'facebook'
    self.confirmation_token = nil
    self.confirmed_at = Time.now
    self.build_user_profile(user_info_from_omniauth(omniauth))
    self.user_tokens.build(hash_from_omniauth(omniauth))
  end

  def twitter
    @twitter_user ||= Twitter::Client.new(:oauth_token => self.twitter_omniauth.token, :oauth_token_secret => self.twitter_omniauth.secret) rescue nil
  end

  def fetch_friends_from_twitter
    twitter.follower_ids.ids.each do |follower_id|
      self.twitter_friends.create(:twitter_id => follower_id, :friend_type => 'followers')
    end
    twitter.friend_ids.ids.each do |friend_id|
      self.twitter_friends.create(:twitter_id => friend_id, :friend_type => 'following')
    end
  end


  def hash_from_omniauth(omniauth)
    { :provider => omniauth['provider'], :uid => omniauth['uid'],
      :token => (omniauth['credentials']['token'] rescue nil), :secret => (omniauth['credentials']['secret'] rescue nil)
    }
  end

  def friends_tweet_for_movie(movie)
    twitter_friends_ids = self.twitter_friends.collect(&:twitter_id)
    return [] if twitter_friends_ids.blank?
    movie.tweets.where('twitter_id in (?)', twitter_friends_ids)
  end

  def friends_post_for_movie(movie)
    return [] if facebook_friends_ids.blank?
    movie.facebook_feeds.posts.latest.where('fbid in (?)', facebook_friends_ids).limit(4) rescue []
  end

  def friends_liked_movie(movie)
     self.facebook_friend_likes.where('fb_item_id = ?', movie.fbpage_id) rescue []
   end

  def create_user_tokens(omniauth)
    self.user_tokens.create!(self.hash_from_omniauth(omniauth) )
    self.update_user_profile(omniauth)
  end

  def update_user_profile(omniauth)
    if self.user_profile.blank?
      UserProfile.create!(user_info_from_omniauth(omniauth).merge!(:user_id => self.id))
      self.reload
    end
    self.user_profile.update_attribute("twitter_screen_name", (omniauth['extra']['user_hash']['screen_name'] rescue '') ) if omniauth['provider'] == "twitter"
    begin
      self.user_profile.update_attributes({:profile_image_url => omniauth['user_info']['image'] }) if self.user_profile.blank? || self.user_profile.profile_image_file_name.blank?
    rescue
    end
  end


  def password_required?
    new_record?
  end

  def self.get_user_connections(user = '')
    user = user != '' ? user : self
    @registered_user = []
    connections = user.user_connection
    unless connections.blank?
      unless connections.connections.blank?
        conn =  ActiveSupport::JSON.decode(connections.connections)
        conn.each do |usr|
          user_profile = UserProfile.find(:first,:conditions => ["user_id = ?",usr])
          unless user_profile.blank?
              if !UserToken.find_by_user_id(usr).blank?
                if usr != user.id
                  @registered_user << usr
                end
              end
           end
        end
      end
    end
    return @registered_user
  end
 def self.get_suggested_user(user)
    @suggested_user = []
    @first_level = get_user_connections(user).sort_by{rand}
    is_done = false
    @first_level.each do |usr|
      tmp_user = User.find(usr)
      get_user_connections(tmp_user).each do |second_level|
        if user.id != second_level
          if @suggested_user.size < 6
            @suggested_user << second_level
            @suggested_user  = @suggested_user - @first_level
          else
            is_done = true
            break
          end
        end
      end
      if is_done == true
        break
      end
    end
    #@suggested_user  = @suggested_user - @first_level
    return @suggested_user.uniq.sort_by{rand}[0..4]
  end

 def self.get_connections_activity(user, limit = 4)
    if user.blank?
      none_activity = ['Comment','Top Ten', 'FacebookFeed','Admin Score']
       Rails.cache.fetch('connections_activity',:expires_in => 60.seconds){Activity.latest_updated.where('secondary_subject_type != ? and subject_type not in (?)', 'Follow', none_activity ).includes(:subject, :secondary_subject).order('created_at DESC').limit(limit).all}
    else
      # Activity.latest_updated.where('user_id in (?) and secondary_subject_type != ? and subject_type != ? and subject_type != ?', User.get_user_connections(user), 'Follow', 'Comment', 'Top Ten').includes(:subject, :secondary_subject).order('created_at DESC').limit(limit).uniq{|e| e.action}
      none_activity = ['Comment','Top Ten', 'FacebookFeed']
      Rails.cache.fetch('connections_activity',:expires_in => 60.seconds){Activity.latest_updated.where('user_id in (?) and secondary_subject_type != ? and subject_type not in (?)', User.get_user_connections(user), 'Follow', none_activity ).includes(:subject, :secondary_subject).order('created_at DESC').limit(limit).all}
    end
  end

  def self.get_activities(user, subject_type='', secondary_subject_type = '')
    @your_connections = User.get_user_connections(user)
    if secondary_subject_type == ''
       Activity.latest_updated.where('user_id in (?)', @your_connections)
    else
      Activity.latest_updated.where('user_id in (?) and subject_type in (?) and secondary_subject_type in (?)', User.get_user_connections(user), subject_type, secondary_subject_type)
    end


   # @last_viewed = Activity.find(:first,:conditions => ["subject_type = ?","Activity"])
    
   # if subject_type == '' and secondary_subject_type == ''
   #   if @last_viewed.blank?
   #     Activity.latest_updated.where('user_id in (?)', User.get_user_connections(user))
   #   else
   #     Activity.latest_updated.where('user_id in (?) and created_at > ?', User.get_user_connections(user), @last_viewed.created_at)
   #   end
 
   # else
   #   if @last_viewed.blank?
   #    Activity.latest_updated.where('user_id in (?) and subject_type in (?) and secondary_subject_type in (?)', User.get_user_connections(user), subject_type, secondary_subject_type)
   #   else
   #     Activity.latest_updated.where('user_id in (?) and subject_type in (?) and secondary_subject_type in (?) and created_at > ?', User.get_user_connections(user), subject_type, secondary_subject_type, @last_viewed.created_at)
   #  end
   # end
  end
 
  def user_image
     unless self.user_profile.blank?
       unless self.user_profile.profile_image_file_name.blank?
         #self.user_profile.profile_image.url(:thumb)
         return "/system/profile_images/#{user_profile.id}/small/#{user_profile.profile_image_file_name}"
       else
         unless self.facebook_id.blank?
           return "http://graph.facebook.com/#{self.facebook_id}/picture"
         else
           return '/images/no-profile.png'
         end
       end
     else
       return '/images/no-profile.png'
     end
  end

  def user_image_for_mobile
     unless self.user_profile.blank?
       unless self.user_profile.profile_image_file_name.blank?
         #self.user_profile.profile_image.url(:thumb)
         #return self.user_profile.profile_image.url(:thumb)
     
         return "#{POSTER_URL}/system/profile_images/#{user_profile.id}/thumb/#{user_profile.profile_image_file_name}"
       else
         unless self.facebook_id.blank?
           #return "http://graph.facebook.com/#{self.facebook_id}/picture"
            return "#{POSTER_URL}/images/no-profile.png"
         else
           return "#{POSTER_URL}/images/no-profile.png"
         end
       end
     else
       return 'http://www.muvi.com/images/no-profile.png'
     end
  end
  def self.post_to_wall(current_user, followed_user)
    if current_user.user_profile &&  current_user.user_profile.post_to_social_media && current_user.facebook_omniauth
      begin
        client = Koala::Facebook::GraphAPI.new(current_user.facebook_token)
        begin
         following_users = UserProfile.find_by_user_id(followed_user)
         client.delay.put_wall_post("",{:name => "#{current_user.display_name} follows  #{followed_users.id}.",:link => "#{SITE_URL}/profile/#{followed_users.id}/#{followed_users.display_name}",:description => "Want to follow?", :picture => "#{SITE_URL}/system/profile_images/#{followed_users.id}/small/#{followed_users.profile_image_file_name.gsub(' ', '%20')}"} , profile_id="#{current_user.facebook_id}")
        rescue
        end
      rescue Koala::Facebook::OAuthException
          # getting this strange exception. (#506) Duplicate status message
          #TODO handle this exception
      end
    end
  end

  protected


  def user_info_from_omniauth(omniauth)
    user_info = { }
    case omniauth['provider']
    when 'facebook'
      user_info[:display_name] = (omniauth['extra']['user_hash']['name'] rescue '')
    when 'twitter'
      user_info[:display_name] = user_info[:twitter_screen_name] = (omniauth['extra']['user_hash']['screen_name'] rescue '')
    end
    user_info[:profile_image_url] = omniauth['user_info']['image'] if self.user_profile.blank? || self.user_profile.profile_image_file_name.blank?
    user_info
  end

  def self.convert_to_seo_url(str)
    return str.downcase.gsub(/\W+/, "-").gsub(/^[-]+|[-]$/,"").strip
  end

  def self.change_pw(email, pw)
    user = User.where(:email => email).first
    if user
      user.password = pw
      user.password_confirmation = pw
      user.save
    end
  end

  def self.update_auth_token
    @user = User.where("authentication_token IS NULL ").find(:all, :order => ["id desc"])
    @user.each do |u|
      u.reset_authentication_token!
      #puts u.id.to_s + "+++"+u.email
    end
  end

  def self.check_valid_email
    user = User.where(last_sign_in_at: 3.months.ago..0.days.from_now).find(:all, :conditions => ["email IS NOT NULL and is_disabled = false"], :order => ["id desc"])
    user.each do|u|
      #begin
	      is_valid = EmailCheck.run("#{u.email}", "info@muvi.com", "muvi.com").valid?

	      if is_valid == false
        	puts "$$$$$$$$$$$"
	        puts u.email
        	puts "is valid: #{is_valid}"

	        ActiveRecord::Base.connection.execute("UPDATE users SET is_disabled = true WHERE id =  #{u.id}")
	      end
      #rescue Exception => err
      #  puts err
      #end

    end
  end

  def self.create_fb_user(fb_id, email)
    #save user
    @u = User.new
    @u.email = email
    @u.facebook_id = fb_id
    #@u.password = params[:password]
    @u.password = "muvimuvi"
    @u.save

    #Save user profile
    doc2 = Net::HTTP.get_response(URI.parse("http://graph.facebook.com/#{fb_id}"))
    data = doc2.body
    result = JSON.parse(data)

    @up = UserProfile.new
    @up.display_name = result["name"]
    @up.user_id = @u.id
    @up.save

  end

  def self.validate_email_id(email, uid)
    is_valid = EmailCheck.run("#{email}", "info@muvi.com", "muvi.com").valid?
    if is_valid == false
      ActiveRecord::Base.connection.execute("UPDATE users SET is_disabled = true WHERE id =  #{uid}")
    end
    #return is_valid
  end

  def self.send_fb_invitation(sender, user_ids, access_token, permalink)
    user_id_arr = user_ids.split(",")
    @oauth = Koala::Facebook::OAuth.new(FACEBOOK_APPID, FACEBOOK_SECRET_KEY, 'http://www.muvi.com') 
    @oauth.url_for_oauth_code(:permissions => "publish_stream")
    access_token = @oauth.get_app_access_token
    graph = Koala::Facebook::API.new(access_token)
    user_id_arr.each do |u|
      #graph.put_connections(u, message)
      #graph.put_connections("#{u}",  "feed", :message => "Invitation to join Muvi.", :link => "http://www.muvi.com/movies/#{permalink}")
      begin
        graph.put_connections("#{sender}",  "feed", :message => "Invitation to muvi", :link => "http://www.muvi.com/movies/#{permalink}", :to => "#{u}")
      rescue
      end
    end
  end
end

