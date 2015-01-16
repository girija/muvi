class CelebTweet < ActiveRecord::Base
  require 'open-uri'
  require 'addressable/uri'
  require 'net/http'
  require 'rubygems'
  #require 'stemmer'
  #require 'classifier'

  belongs_to :user
  belongs_to :celebrity
  has_many :like_votes, :conditions => [ "vote_flag = ?", 'true' ], :dependent => :destroy, :class_name => 'Vote',:foreign_key => "votable_id"
  has_many :dislike_votes, :conditions => [ "vote_flag = ?", 'false' ], :dependent => :destroy, :class_name => 'Vote',:foreign_key => "votable_id"

  scope :todays_tweets, where(:created_at => (Date.today.beginning_of_day)..Date.today.end_of_day)
  scope :latest, order('tweeted_on desc nulls last')
  scope :unclassified, where(:review => 'f', :fan_tweet => 't')
  scope :created_6_hours_ago, where("tweets.created_at < ?",6.hour.ago)
  scope :fan_tweets, where(:fan_tweet => true)
  scope :from_celebs, where(:fan_tweet => false)
  scope :pos_or_neg, where("review = ? or review = ? ", 'pos', 'neg')
  scope :neu_or_ign, where("review = ? or review = ? ", 'neu', 'ign')
  scope :curated_tweets, where(:curated => true)
  scope :tweets_this_week, where("tweeted_on <= ? and tweeted_on >= ?",DateTime.now.end_of_week,DateTime.now.beginning_of_week)
  scope :tweets_prev_week, where("tweeted_on <= ? and tweeted_on >= ?",DateTime.now.beginning_of_week,DateTime.now.beginning_of_week-7)

  acts_as_commentable
  acts_as_votable
  def self.fetch_celebrity_tweets(celebrity)
    latest_tweet = celebrity.celeb_tweets.from_celebs.last
    search = Twitter::Search.new
    if !celebrity.twitterid.blank?
      if latest_tweet.blank?
        tweet_pagination(search.from("#{celebrity.twitterid}").language("en").per_page(100),celebrity,false)
      else
        if true
          tweet_pagination(search.from("#{celebrity.twitterid}").language("en").since_date("#{latest_tweet.tweeted_on.to_date.to_s}").per_page(100),celebrity,false)
        end
      end
    end
    search.clear
  end

  def self.fetch_fan_tweets(celebrity)
    latest_tweet = celebrity.celeb_tweets.fan_tweets.last
    search = Twitter::Search.new
    if latest_tweet.blank?
      tweet_pagination(search.phrase(" "+"#{celebrity.name}"+" ").language("en").per_page(100),celebrity,true)
      if !celebrity.alias_name.blank?
        alias_names = celebrity.alias_name.split(",")
        alias_names.each do |alias_name|
          tweet_pagination(search.phrase(" " + "#{alias_name}" + " ").not_containing("http://").language("en").per_page(100),celebrity)
        end
      end
    else
      if true
        tweet_pagination(search.phrase(" "+"#{celebrity.name}"+" ").language("en").since_date("#{latest_tweet.tweeted_on.to_date.to_s}").per_page(100),celebrity,true)
        if !alias_names.blank?
          alias_names.each do |alias_name|
            tweet_pagination(search.phrase(" " + "#{alias_name}" + " ").not_containing("http://").since_date("#{latest_tweet.tweeted_on.to_date.to_s}").language("en").per_page(100),celebrity)
          end
        end
      end
    end
    search.clear
    #tweet_classify(celebrity)
  end
  
  def self.tweet_pagination(search,celebrity,fan)
    if fan
      search.each do |tweet|
        if /(Fuck|fuck|pic |pics |Pic |Pics|t.co|Law|summon|Engineering|blonde|Blu-ray|link|nline|buy|Buy|download|Download|google|Goole|Facebook|Breaking|breaking|dvd|lcd|CD|DVD|LCD|pirate|legal|torrent|.zip|mp3|raaga|Mp3|TVD|XviD|Megavideo|megavideo|NowPlaying|volunta|click|oooo|nowplaying|launch|yeah|chuddam|News|news|Abe |file|suit)/.match(tweet.text)
          next
        else
          create_tweet(tweet,celebrity,fan)
        end
      end
      while search.next_page? # only 100 tweet created so this one commented
        search.fetch_next_page
        search.each do |tweet|
          if /(Fuck|fuck|Law|summon|pic |pics |Pic |Pics|t.co|Engineering|blonde|Blu-ray|link|nline|buy|Buy|download|Download|google|Goole|Facebook|Breaking|breaking|dvd|lcd|CD|DVD|LCD|pirate|legal|torrent|.zip|mp3|raaga|Mp3|TVD|XviD|Megavideo|megavideo|NowPlaying|volunta|click|oooo|nowplaying|launch|yeah|chuddam|News|news|Abe |file|suit)/.match(tweet.text)
            next
          else
            create_tweet(tweet,celebrity,fan)
          end
        end
      end
    else
      search.each do |tweet|
        create_tweet(tweet,celebrity,fan)
      end
      while search.next_page?
        search.fetch_next_page
        search.each do |tweet|
          create_tweet(tweet,celebrity,fan)
        end
      end
    end
    latest_tweet = celebrity.celebrity_tweets.limit(1)
    refer_tag = Tag.find_by_name(celebrity.name)
    if refer_tag.blank?
      refer_tag = Tag.create(:name => celebrity.name)
    end
    Tagging.create(:tag_id => refer_tag.id, :taggable_id => latest_tweet.id,:taggable_type => "Tweet",:tagger_id => celebrity.id, :tagger_type =>  "Celebrity",:context => "tags")
  end
  
  def self.create_tweet(tweet,celebrity,fan)
    if fan
      celebrity_tweet = { :content => tweet.text, :twitter_id => tweet.from_user_id, :tweeted_on => tweet.created_at, :twitter_screen_name => tweet.from_user, :tweet_id => tweet.id.to_s, :celebrity_id => celebrity.id }
    else
      celebrity_tweet = { :content => tweet.text, :twitter_id => tweet.from_user_id, :tweeted_on => tweet.created_at, :twitter_screen_name => tweet.from_user, :tweet_id => tweet.id.to_s,:celebrity_id => celebrity.id, :fan_tweet => false }
    end
    unless celebrity.celeb_tweets.collect(&:tweet_id).include?(tweet.id.to_s)
      celebrity.celeb_tweets.create(celebrity_tweet)
    end
  end

  #def self.initialize_classifier
    #positive = YAML::load_file("#{RAILS_ROOT}/config/pos.yml")
    #negative = YAML::load_file("#{RAILS_ROOT}/config/neg.yml")
    #neutral = YAML::load_file("#{RAILS_ROOT}/config/neg.yml")
    #ignore = YAML::load_file("#{RAILS_ROOT}/config/ign.yml")
    #@classifier = Classifier::Bayes.new(:categories => ['Positive','Negative'])
    #positive.each { |boo| @classifier.train_positive boo }
    #negative.each { |good_one| @classifier.train_negative good_one }
    #neutral.each { |neutral_stuff|  @classifier.train_neutral neutral_stuff }
    #ignore.each { |ignore_stuff| @classifier.train_ignore ignore_stuff }
    #@classifier.remove_stemmer
  #end
  
  #def self.tweet_senti(tweet)
    #senti =  @classifier.classify tweet.content
    #return senti
  #end

  #def self.tweet_classify(celebrity)
    #CelebTweet.initialize_classifier
    #celebrity.celeb_tweets.unclassified.each do |tweet|
      #if tweet_senti(tweet) == 'Positive'
        #tweet.update_attributes(:review => 'pos',:rating => 1)
      #elsif tweet_senti(tweet) == 'Negative'
        #tweet.update_attributes(:review => 'neg',:rating => 0)
      #elsif tweet_senti(tweet) == 'Neutral'
        #tweet.update_attributes(:review => 'neu', :rating => nil)
      #end
    #end
  #end

  def self.get_fan_tweets
    Celebrity.name_without_dictionary_word.name_is_not_blank.each do |celebrity|
      begin
        puts celebrity.name
        start_time = Time.now
        fetch_fan_tweets(celebrity)
        end_time = Time.now
        if (end_time - start_time).round < 30
          sleep (30 - (end_time - start_time).round)
        end
        Celebrity.update_popularity(celebrity)
      rescue
        next
      end
    end
  end

  def self.get_celeb_tweets
    Celebrity.twitter_present.find(:all).each do |celebrity|
      begin
        puts celebrity.name
        start_time = Time.now
        fetch_celebrity_tweets(celebrity)
        end_time = Time.now

        if (end_time - start_time).round < 20
          sleep (20 - (end_time - start_time).round)
        end

      rescue
        next
      end
    end
  end

end
