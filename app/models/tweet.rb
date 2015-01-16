class Tweet < ActiveRecord::Base
  require 'nokogiri'
  require 'open-uri'
  require 'addressable/uri'
  require 'net/http'


  belongs_to :user
  belongs_to :movie

  scope :latest, order('tweeted_on desc nulls last')
  scope :reviews, where(:interest => false)
  scope :interests, where(:interest => true)
  scope :pos_or_neg, where("review = ? or review = ? ", 'pos', 'neg')
  scope :neu_or_ign, where("review = ? or review = ? ", 'neu', 'ign')
  scope :todays_tweets, where(:tweeted_on => (Date.today.beginning_of_day)..Date.today.end_of_day)
  scope :tweets_this_week, where("tweeted_on <= ? and tweeted_on >= ?",DateTime.now.end_of_week,DateTime.now.beginning_of_week)
  scope :tweets_prev_week, where("tweeted_on <= ? and tweeted_on >= ?",DateTime.now.beginning_of_week - 2,DateTime.now.beginning_of_week-9)
  acts_as_commentable
  acts_as_votable
  has_many :like_votes, :conditions => [ "vote_flag = ?", 'true' ], :dependent => :destroy, :class_name => 'Vote',:foreign_key => "votable_id"
  has_many :dislike_votes, :conditions => [ "vote_flag = ?", 'false' ], :dependent => :destroy, :class_name => 'Vote',:foreign_key => "votable_id"

  def self.fetch_tweets
    last_tweet = Tweet.last
    search = Twitter::Search.new
    Movie.name_without_dictionary_word.name_is_not_blank.latest.limit(6).each do |movie|
      if last_tweet.blank?
        Tweet.tweet_pagination(search.containing("#{movie.name}").per_page(100), movie)
        Tweet.tweet_pagination(search.containing("#{movie.alias_name}").per_page(100), movie)
      else
        Tweet.tweet_pagination(search.containing("#{movie.name}").since_date("#{last_tweet.created_at.to_date.to_s}").per_page(100), movie)
        Tweet.tweet_pagination(search.containing("#{movie.alias_name}").since_date("#{last_tweet.created_at.to_date.to_s}").per_page(100), movie)
      end
      search.clear
    end # all movies end
  end # def end

  def self.fetch_tweets_for_all_movies
    last_tweet = Tweet.last

    words = {}
    File.open("/usr/share/dict/words") do |file|
      file.each do |line|
        words[line.strip] = true
      end
    end
    search = Twitter::Search.new
    Movie.name_without_dictionary_word.name_is_not_blank.latest.each do |movie|
      if Tweet.where(:movie_id => movie.id).blank? and !words[movie.name.downcase]
        Tweet.tweet_pagination(search.phrase(" " + movie.name + " ").per_page(100).no_retweets.language("en"), movie)
      elsif Tweet.where(:movie_id => movie.id).count < 100 and !words[movie.name.downcase]
        Tweet.tweet_pagination(search.phrase(" " + movie.name + " ").per_page(100 - Tweet.where(:movie_id => movie.id).count ).no_retweets.language("en"), movie)
      end
      search.clear
    end # all movies end
  end # def end

  def self.tweet_classify(movie)
   if movie.release_date.blank?
          tweet_percent = movie.tweets.interests.pos_or_neg.blank? ? 0 : ((100 * movie.tweets.reviews.pos_or_neg.select("SUM(rating) as total").first.total.to_i) / movie.tweets.reviews.pos_or_neg.count)  rescue 0
          movie.update_attributes(:tweets_count => movie.tweets.interests.pos_or_neg.count,:user_percent => tweet_percent)
   elsif  movie.release_date <= Date.today
          tweet_percent = movie.tweets.reviews.pos_or_neg.blank? ? 0 : ((100 * movie.tweets.reviews.pos_or_neg.select("SUM(rating) as total").first.total.to_i) / movie.tweets.reviews.pos_or_neg.count)  rescue 0
          movie.update_attributes(:tweets_count => movie.tweets.reviews.pos_or_neg.count,:user_percent => tweet_percent)
   else
          tweet_percent = movie.tweets.interests.pos_or_neg.blank? ? 0 : ((100 * movie.tweets.interests.pos_or_neg.select("SUM(rating) as total").first.total.to_i) / movie.tweets.interests.pos_or_neg.count)  rescue 0
          movie.update_attributes(:tweets_count => movie.tweets.interests.pos_or_neg.count,:user_percent => tweet_percent)
   end
  end

  def self.tweet_pagination(search, movie)
    search.each do |tweet|
      Tweet.create_tweet(tweet, movie)
    end
  #  if search.next_page? # only 100 tweet created so this one commented
   #   search.fetch_next_page
    #  Tweet.tweet_pagination(search, movie)
  #  else
    #  search.fetch_next_page
    #  search.each do |tweet|
    #    Tweet.create_tweet(tweet, movie)
    #  end
   # end

  end


  def self.create_tweet(tweet, movie)
    movie_tweet = { :content => tweet.text, :twitter_id => tweet.from_user_id, :tweeted_on => tweet.created_at, :twitter_screen_name => tweet.from_user, :tweet_id => tweet.id.to_s }
    user_profile = UserProfile.find_by_twitter_screen_name(tweet.from_user)
    if user_profile
      movie_tweet[:user_id] = user_profile.user_id
    end

    if (!movie.release_date.blank? && tweet.created_at.to_date < movie.release_date.to_date)
      movie_tweet[:interest] = true
    end
    unless movie.tweets.collect(&:tweet_id).include?(tweet.id.to_s)
      tw = movie.tweets.create(movie_tweet)
      #Activity.log_activity(tw, movie, 'twitted', user_profile.user_id) if user_profile
    end
  end

  def self.fetch_tweet_for_movie(movie)
     search = Twitter::Search.new
     last_tweet = movie.tweets.last rescue nil
     if last_tweet.blank?
       Tweet.tweet_pagination(search.containing("#{movie.name}").per_page(100), movie)
     else
       Tweet.tweet_pagination(search.containing("#{movie.name}").since_date("#{last_tweet.created_at.to_date.to_s}").per_page(100), movie)
     end
     search.clear
  end

  def self.delete_neu_or_ign_tweets
    Tweet.neu_or_ign.each do |tweet|
      TweetIgnNeu.create(tweet.attributes.except("id", "updated_at", "created_at"))
      tweet.destroy
    end
  end

  def self.get_celeb_tweet_realtime(screen_name)
    message = ""
    fetch_url = "https://api.twitter.com/1/statuses/user_timeline.json?include_rts=true&screen_name=#{screen_name}&count=1"
    doc = Nokogiri::HTML(open(URI.parse(URI.encode(fetch_url))))
    data = JSON.parse(doc)
    data.each do |p|
      #message =  p["text"]
      message = p
    end
    return message
  end
  def self.daemon_15_hours
    while true do
      Tweet.tweet_daemon_coming_soon
      sleep 54000
    end
  end
  
  def self.daemon_3_hours
    while true do
      Tweet.tweet_daemon
      CelebTweet.get_celeb_tweets
      sleep 10800
    end
  end
  
  def self.tweet_daemon
    while true do
      Movie.name_is_not_blank.each do |movie|
        begin
          puts movie.name
          start_time = Time.now
          if movie.dictionary_word
            fetch_tweets_dictionary(movie)
          else
            fetch_tweets_non_dictionary(movie)
          end
          end_time = Time.now
          if (end_time - start_time).round < 20
            sleep (20 - (end_time - start_time).round)
          end
        rescue
          puts "Emergency"
          next
        end
        tweet_classify(movie)
        Movie.update_one_movie_percentage(movie)
      end
      break
    end
  end

  def self.tweet_daemon_coming_soon
    while true do
      Movie.name_is_not_blank.comming_soon_movies.latest.each do |movie|
        begin
          puts movie.name
          start_time = Time.now
          if movie.dictionary_word
            fetch_tweets_dictionary(movie)
          else
            fetch_tweets_non_dictionary(movie)
          end
          end_time = Time.now
          if (end_time - start_time).round < 30
            sleep (30 - (end_time - start_time).round)
          end
        rescue
          puts "Emergency"
          next
        end
        tweet_classify(movie)
        Movie.update_one_movie_percentage(movie)
      end
      break
    end
  end

  
  def self.fetch_tweets_non_dictionary(movie)
    latest_tweet = movie.tweets.last
    search = Twitter::Search.new
    movie_name = movie.name.gsub(/ /,'').gsub(/\(.*\)/, "")
    alias_names = movie.alias_name.split(",")
    if latest_tweet.blank?
      Tweet.tweet_pagination(search.phrase(" " + "#{movie_name}" + " ").not_containing("http://").no_retweets.language("en").per_page(80),movie)
      if !alias_names.blank?
        alias_names.each do |alias_name|
          Tweet.tweet_pagination(search.phrase(" " + "#{alias_name}" + " ").not_containing("http://").no_retweets.language("en").per_page(80),movie)
        end
      end
    else
      if true
        Tweet.tweet_pagination(search.phrase(" " + "#{movie_name}" + " ").not_containing("http://").since_date("#{latest_tweet.tweeted_on.to_date.to_s}").no_retweets.language("en").per_page(80),movie)
        if !alias_names.blank?
          alias_names.each do |alias_name|
            Tweet.tweet_pagination(search.phrase(" " + "#{alias_name}" + " ").not_containing("http://").since_date("#{latest_tweet.tweeted_on.to_date.to_s}").no_retweets.language("en").per_page(80),movie)
          end
        end
      end
    end
    search.clear
  end
  
  def self.fetch_tweets_dictionary(movie)
    latest_tweet = movie.tweets.last
    search = Twitter::Search.new
    movie_name = movie.name.gsub(/ /,'').gsub(/\(.*\)/, "")
    actor_name = movie.actors.blank? ? "" : movie.actors.first.celebrity.name
    second_actor = movie.actors.blank? ? "" : movie.actors[1].blank? ? "" :  movie.actors[1].celebrity.name
    puts second_actor
    if movie.release_date > Date.today
      name = "#{movie_name} #{actor_name} OR #{movie_name} #{second_actor}"
    else
      name = "##{movie_name}"
    end
    alias_names= movie.alias_name.split(",")
    if latest_tweet.blank?
      Tweet.tweet_pagination(search.hashtag("#{name}").not_containing("http://").no_retweets.language("en").per_page(10),movie)
      if !alias_names.blank?
        alias_names.each do |alias_name|
          Tweet.tweet_pagination(search.hashtag("#{alias_name.gsub(/ /,'')}").not_containing("http://").no_retweets.language("en").per_page(100),movie)
        end
      end
    else
      if true
        Tweet.tweet_pagination(search.hashtag("#{name}").not_containing("http://").since_date("#{latest_tweet.created_at.to_date.to_s}").no_retweets.language("en").per_page(10),movie)
        if !alias_names.blank?
          alias_names.each do |alias_name|
            Tweet.tweet_pagination(search.hashtag("#{alias_name.gsub(/ /,'')}").not_containing("http://").since_date("#{latest_tweet.created_at.to_date.to_s}").no_retweets.language("en").per_page(10),movie)
          end
        end
      end
    end
    search.clear
  end
  
  def self.test
    puts "testing for (year)".gsub(/\(.*\)/, "")
  end
end
