class FacebookFeed < ActiveRecord::Base
  belongs_to :user
  belongs_to :movie, :counter_cache => true
  has_many :activities, :as => :subject , :dependent => :destroy

  scope :like_name, lambda{|name| where("value like ? ", "#{name}%") }
  scope :by_fb_item_id, lambda{|item_id| where(:fb_item_id => item_id) }
  scope :by_fbid, lambda{|fbid| where(:fbid => fbid) }
  scope :friends_ids, lambda{|ids| where("fbid in (?)", ids) }
  scope :movie_page_id, lambda{|page_id| where("fb_item_id = ?", page_id) }
  scope :latest,  order('posted_on desc nulls last')
  scope :posts, where('feed_type = ? or feed_type = ?', 'public_post', 'friends_post')
  scope :friend_likes, where('feed_type = ? or feed_type = ?', 'friend_likes', 'likes')
  scope :all_posts, where('feed_type = ? or feed_type = ?', 'friends_post', 'public_post')
  scope :todays, where(:created_at => (Date.today.beginning_of_day)..Date.today.end_of_day)
  scope :this_week, where(:created_at => ((Date.today-7).beginning_of_day)..Date.today.end_of_day)


  def self.fetch_all_post_for_movie(movie)
    posts = Mogli::Model::search("#{movie.name}", nil, {:type => 'post', :limit => 400})
    FacebookFeed.create_facebook_feed(posts, movie) # create facebook posts
    while !posts.next_url.blank?  # fetch next method in mogli client append the data to same array so we check untill next url blank
      additional_posts = posts.fetch_next # retuns the pagnation post from next url
      FacebookFeed.create_facebook_feed(additional_posts, movie)
    end
  end

  def self.create_facebook_feed(array, movie)
    array.each do |post|
      if post.type == "status"
        begin
          FacebookFeed.create_facebook_post(post, movie, post.from)
          User.pull_comments(post, movie) #check for comments is present
        rescue
          # this for any errors
        end
      end
    end
  end


  def self.fetch_facebook_feeds_for_users
    UserToken.where("provider = ?", 'facebook').each do |ut|
     ut.user.fetch_from_news_feed
   end
  end

  def self.fetch_facebook_friends_for_facebook_user
    #UserToken.where("provider = ?", 'facebook').each do |ut|
    #  ut.user.fetch_all_facebook_friends
   #end
  end

  def self.create_activity_for_week
     FacebookFeed.this_week.each do |post|
       action = case post.feed_type
       when 'public_post','friends_post'
         'said'
       when 'friend_likes', 'likes'
         'liked'
       end
       Activity.create_log_for_each_friend(post, post.movie, action, post.fbid, post.facebook_name)
     end
  end

  def self.create_facebook_post(post, movie, facebook_user)
    #check for both movie name and alias name
    if (FacebookFeed.present_or_not(post.message, movie.name) || FacebookFeed.present_or_not(post.name, movie.name) ||
        FacebookFeed.present_or_not(post.caption, movie.name) || FacebookFeed.present_or_not(post.link, movie.name) ||
        FacebookFeed.present_or_not(post.picture, movie.name) || FacebookFeed.present_or_not(post.message, movie.alias_name) ||
        FacebookFeed.present_or_not(post.name, movie.alias_name) || FacebookFeed.present_or_not(post.caption, movie.alias_name) ||
        FacebookFeed.present_or_not(post.link, movie.alias_name) || FacebookFeed.present_or_not(post.picture, movie.alias_name) )
       if movie.facebook_feeds.find_by_fb_item_id(post.id.to_s).blank?
         fb_feed = FacebookFeed.create!(:feed_type => 'friends_post', :value => post.message.strip, :fbid => facebook_user.id, :fb_item_id => post.id, :movie_id => movie.id,:facebook_name => facebook_user.name.strip, :posted_on => post.created_time.to_date)
         Activity.create_log_for_each_friend(fb_feed, movie, 'said', facebook_user.id, facebook_user.name.strip)
       end
    end
  end

  def self.create_facebook_post_from_comment(comment, movie, facebook_user)
    #check for both movie name and alias name
    if FacebookFeed.present_or_not(comment.message, movie.name) || FacebookFeed.present_or_not(comment.message, movie.alias_name)
      if movie.facebook_feeds.find_by_fb_item_id(comment.id.to_s).blank?
         fb_feed = FacebookFeed.create!(:feed_type => 'friends_post', :value => comment.message.strip, :fbid => facebook_user.id, :fb_item_id => comment.id, :movie_id => movie.id,:facebook_name => facebook_user.name.strip, :posted_on => comment.created_time.to_date)
         Activity.create_log_for_each_friend(fb_feed, movie, 'said', facebook_user.id, facebook_user.name.strip)
       end
    end
  end


  def self.present_or_not(message, q)
    # check specified string present in message
     !q.blank? && !message.blank? && !message.insert(0, ' ').concat(' ').downcase.gsub(/[^0-9A-Za-z]/, ' ').squeeze(" ")[" #{q.downcase} ".gsub(/[^0-9A-Za-z]/, ' ').squeeze(" ").to_s].blank?
  end


end

