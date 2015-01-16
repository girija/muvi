class Celebrity < ActiveRecord::Base
  require 'arel'
  require 'open-uri'
  require 'nokogiri'
  #include MixinSitemap

  $config = YAML.load_file(File.join(File.dirname(__FILE__), '../../config/database.yml'))
  self.establish_connection  $config["muvi_extract"]
  set_table_name 'celebrities'
  set_primary_key :id
  acts_as_commentable
  acts_as_followable

  validates_uniqueness_of :name
  has_permalink [:name], :update => true
 
  #has_attached_file :profile_picture, :styles => { :thumb=> "45x45#", :small  => "130x200#" }
  #has_attached_file :profile_picture,
  #            :styles => { :thumb=> "45x45#", :small  => "130x200#" },
  #            :storage => :s3,
  #            :s3_credentials => File.expand_path('config/s3.yml', Rails.root),
  #            :s3_permissions => 'public-read',
  #            :path => "public/system/:attachment/:id/:style/:basename.:extension",
  #            :convert_options => { :all => '-limit memory 64mb -limit map 128mb' }

  has_attached_file :profile_picture,
              :styles => {:thumb=> "35x35#", :medium  => "130x200#", :standard => "185x"},
              :storage => :s3,
              :s3_credentials => File.expand_path('config/s3.yml', Rails.root),
              :s3_permissions => 'public-read',
              :path => "public/system/:attachment/:id/:style/:basename.:extension",
              :convert_options => { :all => '-limit memory 64mb -limit map 128mb' }

  def to_param
    permalink
  end

  #after_save :create_sitemap

  searchable do
    text :name
  end

  serialize :celebrity_type
  has_many :celeb_tweets, :dependent => :destroy
  has_many :celebrity_tweets, :conditions => [ "fan_tweet = ?", 'false' ], :dependent => :destroy, :class_name => 'CelebTweet', :order => "tweeted_on desc"

  has_many :movie_casts, :dependent => :destroy
  has_many :not_fans, :conditions => [ "is_fan = ?", 'false' ], :dependent => :destroy, :class_name => 'Fan'
  has_many :fans, :conditions => [ "is_fan = ?", 'true' ], :dependent => :destroy
#  has_many :tweets, :dependent => :destroy
  has_many :activities , :conditions => [ "secondary_subject_type = ?", 'Celebrity' ], :dependent => :destroy,:foreign_key => "secondary_subject_id"
  has_one :celebrity_meta_detail, :dependent => :destroy
  has_many :taggings, :conditions => {:taggable_type => "Discussion",:tagger_type => "Celebrity"},:foreign_key => "tagger_id"
  has_many :discussions ,:through => :taggings

  scope :order_by_name, order('name asc nulls last')
  scope :find_using_id, lambda {|perm| where("permalink = ?", perm)}
  scope :top1_list, where(:cell_rank => 1)
  scope :twitter_present, where('twitterid IS NOT null')
  scope :name_without_dictionary_word, where("is_dictionary_word = ?", false)
  scope :name_is_not_blank, where("name IS NOT NULL")
  scope :diff_score_nonzero, where("diff_score > 0")
  scope :bday_celebrity, where("(extract(day from birthdate) = extract(day from now())) and (extract(month from birthdate) = extract(month from now()))")

  accepts_nested_attributes_for :celebrity_meta_detail,  :allow_destroy => true

  def self.find_for_sitemap
    find(:all, :order => "id")
  end
  
  def self.get_fans_connection(user,celebrity_id, is_fan)
    fans = []
    @connections = User.get_user_connections(user)
    @connections.each do |user_id|
      user = User.find_by_id(user_id)
      if user
        fan = Fan.find_by_celebrity_id_and_user_id_and_is_fan(celebrity_id,user.id,is_fan)
        if fan
          fans <<  fan
        end
      end
    end
    return fans
  end

  def create_sitemap
    if Sitemap.delay.create!
      system("s3cmd sync --acl-public public/sitemap.xml s3://#{BUCKET}/public/sitemap.xml")
    end
  end

  def self.option_list
    list ||= self.order_by_name.all.collect{|cl| [cl.name, cl.id] }
  end

  def get_celebrity_poster(celebrity_id)
    poster_id = ""
    poster = ""
    tagging = Tagging.find(:all, :conditions => ["tagger_id = ? and tagger_type = ? and taggable_type = ?",movie_id, "Celebrity", "Poster"], :select => "taggable_id")
    unless tagging.blank?
      tagging.each do |t|
        if poster_id.blank?
          poster_id = t.taggable_id
        else
          poster_id = poster_id.to_s + "," + t.taggable_id.to_s
        end
      end
    end
    poster = Tagging.where("taggable_id IN (#{poster_id})").find(:all, :conditions => ["tagger_type = 'Profile'"], :select => "taggable_id", :order => ["id desc"]).first unless poster_id.blank?
    unless poster.blank?
      return poster.taggable_id
    else
      return false
    end
  end


  def image
    if self.profile_picture_file_name.blank? or self.profile_picture_file_name.nil?
      poster = Poster.check_for_default_poster(self.id, "Celebrity", "Poster", "profilepic")
      if poster != false
        poster_image = Poster.where("id IN (#{poster})").find(:all, :conditions => ["rank = 1"], :order => ["id desc"]).first
        unless poster_image.blank?
          unless poster_image.poster_file_name.blank?
            return "/system/posters/#{poster_image.id}/medium/#{poster_image.poster_file_name.gsub(" ", "%20")}"
          else
              return '/images/no-image.png'
          end
        else
          return '/images/no-image.png'
        end       
      else
        return '/images/no-image.png'
      end
    else
      url = URI.parse(POSTER_URL + "/system/profile_pictures/#{self.id}/small/#{self.profile_picture_file_name.gsub(" ", "%20")}")
      req = Net::HTTP::Get.new(url.path)
      result = Net::HTTP.start(url.host, url.port) { |http| http.get(url.path) }
      if result.code == "200"
        return "/system/profile_pictures/#{self.id}/small/#{self.profile_picture_file_name.gsub(" ", "%20")}"
      else
        return "/system/profile_pictures/#{self.id}/medium/#{self.profile_picture_file_name.gsub(" ", "%20")}"
      end
    end
  end


  def image_old
    poster = Poster.check_for_default_poster(self.id, "Celebrity", "Poster", "profilepic")
    if poster == false
      #self.profile_picture_file_name.blank?? '/images/no-image.png' : self.profile_picture.url(:small).gsub(" ", "%20").to_s
      self.profile_picture_file_name.blank?? '/images/no-image.png' : "/system/profile_pictures/#{self.id}/small/#{self.profile_picture_file_name.gsub(" ", "%20")}"
    else
      poster_image = Poster.where("id IN (#{poster})").find(:all, :conditions => ["rank = 1"], :order => ["id desc"]).first
      unless poster_image.blank?
        unless poster_image.poster_file_name.blank?
          return "/system/posters/#{poster_image.id}/medium/#{poster_image.poster_file_name.gsub(" ", "%20")}"
        else
            return '/images/no-image.png'
        end
      else
        #self.profile_picture_file_name.blank?? '/images/no-image.png' : self.profile_picture.url(:small).gsub(" ", "%20").to_s
        self.profile_picture_file_name.blank?? '/images/no-image.png' : "/system/profile_pictures/#{self.id}/small/#{self.profile_picture_file_name.gsub(" ", "%20")}"
      end
    end
  end

  def medium_image
    poster = Poster.check_for_default_poster(self.id, "Celebrity", "Poster", "profilepic")
    if poster == false
      #self.profile_picture_file_name.blank?? '/images/no-image.png' : self.profile_picture.url(:small).gsub(" ", "%20").to_s
      self.profile_picture_file_name.blank?? '/images/no-image.png' : "/system/profile_pictures/#{self.id}/small/#{self.profile_picture_file_name.gsub(" ", "%20")}"
    else
      poster_image = Poster.where("id IN (#{poster})").find(:all, :conditions => ["rank = 1"], :order => ["id desc"]).first
      unless poster_image.blank?
        unless poster_image.poster_file_name.blank?
          return "/system/posters/#{poster_image.id}/medium/#{poster_image.poster_file_name.gsub(" ", "%20")}"
        else
            return '/images/no-image.png'
        end
      else
        #self.profile_picture_file_name.blank?? '/images/no-image.png' : self.profile_picture.url(:small).gsub(" ", "%20").to_s
        self.profile_picture_file_name.blank?? '/images/no-image.png' : "/system/profile_pictures/#{self.id}/small/#{self.profile_picture_file_name.gsub(" ", "%20")}"

      end
    end
  end

  def thumb_image
    if self.profile_picture_file_name.blank? or self.profile_picture_file_name.nil?
      poster = Poster.check_for_default_poster(self.id, "Celebrity", "Poster", "profilepic")
      if poster != false
        poster_image = Poster.where("id IN (#{poster})").find(:all, :conditions => ["rank = 1"], :order => ["id desc"]).first
        unless poster_image.blank?
          unless poster_image.poster_file_name.blank?
            return "/system/posters/#{poster_image.id}/thumb/#{poster_image.poster_file_name.gsub(" ", "%20")}"
          else
            return '/images/no-image.png'
          end
        else
          return '/images/no-image.png'
        end
      else
        return '/images/no-image.png'
      end
    else
      return "/system/profile_pictures/#{self.id}/thumb/#{self.profile_picture_file_name.gsub(" ", "%20")}"
    end
  end

  def thumb_image_old
    poster = Poster.check_for_default_poster(self.id, "Celebrity", "Poster", "profilepic")
    if poster == false
      #self.profile_picture_file_name.blank?? '/images/no-image.png' : self.profile_picture.url(:thumb).gsub(" ", "%20").to_s
      self.profile_picture_file_name.blank?? '/images/no-image.png' : "/system/profile_pictures/#{self.id}/thumb/#{self.profile_picture_file_name.gsub(" ", "%20")}"
    else
      poster_image = Poster.where("id IN (#{poster})").find(:all, :conditions => ["rank = 1"], :order => ["id desc"]).first
      unless poster_image.blank?
        unless poster_image.poster_file_name.blank?
          return "/system/posters/#{poster_image.id}/thumb/#{poster_image.poster_file_name.gsub(" ", "%20")}"
        else
            return '/images/no-image.png'
        end
      else
        #self.profile_picture_file_name.blank?? '/images/no-image.png' : self.profile_picture.url(:thumb).gsub(" ", "%20").to_s
        self.profile_picture_file_name.blank?? '/images/no-image.png' : "/system/profile_pictures/#{self.id}/thumb/#{self.profile_picture_file_name.gsub(" ", "%20")}"
      end
    end
  end

  def large_image
    poster = Poster.check_for_default_poster(self.id, "Celebrity", "Poster", "profilepic")
    if poster == false
      #self.profile_picture_file_name.blank?? '/images/no-image.png' : self.profile_picture.url(:original).gsub(" ", "%20").to_s
      self.profile_picture_file_name.blank?? '/images/no-image.png' : "/system/profile_pictures/#{self.id}/original/#{self.profile_picture_file_name.gsub(" ", "%20")}"
    else
      poster_image = Poster.where("id IN (#{poster})").find(:all, :conditions => ["rank = 1"], :order => ["id desc"]).first
      unless poster_image.blank?
        unless poster_image.poster_file_name.blank?
          return "/system/posters/#{poster_image.id}/original/#{poster_image.poster_file_name.gsub(" ", "%20")}"
        else
            return '/images/no-image.png'
        end
      else
        #self.profile_picture_file_name.blank?? '/images/no-image.png' : self.profile_picture.url(:original).gsub(" ", "%20").to_s
        self.profile_picture_file_name.blank?? '/images/no-image.png' : "/system/profile_pictures/#{self.id}/original/#{self.profile_picture_file_name.gsub(" ", "%20")}"
      end
    end
  end

  def crop_large_image
    poster = Poster.check_for_default_poster(self.id, "Celebrity", "Poster", "profilepic")
    if poster == false
      #self.profile_picture_file_name.blank?? '/images/no-image.png' : self.profile_picture.url(:original).gsub(" ", "%20").to_s
      self.profile_picture_file_name.blank?? '/images/no-image.png' : "/system/profile_pictures/#{self.id}/original/#{self.profile_picture_file_name.gsub(" ", "%20")}"
    else
      poster_image = Poster.where("id IN (#{poster})").find(:all, :conditions => ["rank = 1"], :order => ["id desc"]).first
      unless poster_image.blank?
        unless poster_image.poster_file_name.blank?
          return "/system/posters/#{poster_image.id}/crop_original/#{poster_image.poster_file_name.gsub(" ", "%20")}"
        else
            return '/images/no-image.png'
        end
      else
        #self.profile_picture_file_name.blank?? '/images/no-image.png' : self.profile_picture.url(:original).gsub(" ", "%20").to_s
        self.profile_picture_file_name.blank?? '/images/no-image.png' : "/system/profile_pictures/#{self.id}/original/#{self.profile_picture_file_name.gsub(" ", "%20")}"
      end
    end
  end

  def self.fan_from_friends(celebrity,current_user)
    @fan = []
    unless current_user.blank?
      @user = User.find(current_user.id)
      @user.facebook_friends.each do |friend|
        celebrity.fans.find(:all,:conditions => ["user_id != ? AND user_id = ? and is_fan = true", current_user.id, friend.user_id]).each do |fan|
          @fan << fan.user.image
        end
      end
    end
    return @fan
  end
 
  def self.total_fan(celebrity)
    @total_fan = Fan.find(:all, :select => ["id"],  :conditions => ["celebrity_id = ?",celebrity])  
    return @total_fan.size
  end

  def self.get_top_costars(celebrity)
    top_costarts = MovieCast.find_by_sql("select celebrity_id, count(*) from movie_casts where celebrity_id != #{celebrity.id} and movie_id in (select movie_id from movie_casts where celebrity_id = #{celebrity.id}) and cast_type = 'actor' group by celebrity_id order by count desc limit 5;")
    return top_costarts
  end

  def self.get_top_buzz(celebrity)
    buzz_query = "((select 'celebrity_tweet' as model, content,rating,review,twitter_screen_name as twitter_name,tweeted_on from celeb_tweets tweets WHERE  tweets.curated = 'f'  AND (tweets.review = 'pos' or tweets.review = 'neg' ) AND (tweets.celebrity_id = #{celebrity.id})) order by id desc, twitter_name asc limit 6) as temp"
    top_buzz = ActiveRecord::Base.connection.select_rows("select * from #{buzz_query}")
    return top_buzz
  end

  def self.get_celebrities_buzz
    #celebeiry = Celebrity.find(:all)
    celebeiry = Celebrity.find(:all, :conditions => ["cell_rank = 1"])
    @celeb_id = ""
    unless celebeiry.blank?
      celebeiry.each do |celeb|
        if @celeb_id.blank?
          @celeb_id = celeb.id.to_s
        else
          @celeb_id = @celeb_id.to_s + ","+ celeb.id.to_s
        end
      end
    end
    celebrity_tweet = "((select 'celebrity_tweet' as model, content,rating,review,twitter_screen_name as twitter_name,tweeted_on, celebrity_id  from celeb_tweets tweets WHERE  tweets.fan_tweet = 'f') order by tweeted_on desc limit 4) as temp"
    celebrity_tweet = ActiveRecord::Base.connection.select_rows("select * from #{celebrity_tweet}")
    return celebrity_tweet
  end 

  def self.get_users_tweet
    #celebeiry = Celebrity.find(:all)
    celebeiry = Celebrity.find(:all, :conditions => ["cell_rank = 1"])
    @celeb_id = ""
    unless celebeiry.blank?
      celebeiry.each do |celeb|
        if @celeb_id.blank?
          @celeb_id = celeb.id.to_s
        else
          @celeb_id = @celeb_id.to_s + ","+ celeb.id.to_s
        end
      end
    end
    user_tweet = "((select 'celebrity_tweet' as model, content,rating,review,twitter_screen_name as twitter_name,tweeted_on from celeb_tweets tweets WHERE  tweets.fan_tweet = 't') order by tweeted_on desc limit 4) as temp"
    user_tweet = ActiveRecord::Base.connection.select_rows("select * from #{user_tweet}")
    return user_tweet
  end


  def self.celebrities_buzz
    tweet = []
    @celeb_tweet_id = HomePageSetting.where("page_no = 1 and item_id = 7 and subject_type_id = 2").find(:all)
    unless @celeb_tweet_id.blank?
      @celeb_tweet_id.each do |celeb|
        celeb_tweet = CelebTweet.where("celebrity_id = #{celeb.subject_id} and fan_tweet = 'f'").find(:first, :select => ["twitter_screen_name"], :order => ["created_at desc"])
        tweet << Tweet.get_celeb_tweet_realtime(celeb_tweet.twitter_screen_name)        
      end
    end
    return tweet
  end

  def self.user_tweet
    #celebrity_tweet = ""
    @celeb_tweet_id = HomePageSetting.where("page_no = 1 and item_id = 7 and subject_type_id = 2").find(:all)
    unless @celeb_tweet_id.blank?
      @cleb_id = ""
      @celeb_tweet_id.each do |celeb|
        if @cleb_id.blank?
          @cleb_id = celeb.subject_id
        else
          @cleb_id = @cleb_id.to_s + celeb.subject_id.to_s
        end
      end
      unless @celeb_id.blank?
        user_tweet_query = "((select 'celebrity_tweet' as model, content,rating,review,twitter_screen_name as twitter_name,tweeted_on from celeb_tweets tweets WHERE  tweets.fan_tweet = 't' and celebrity_id IN (#{@celeb_id})) order by tweeted_on desc limit 3) as temp"
        user_tweet = ActiveRecord::Base.connection.select_rows("select * from #{user_tweet_query}")
      end
    end
    return user_tweet
  end

  def self.get_top_crews(celebrity)
    top_crews = MovieCast.find_by_sql("select celebrity_id, count(*) from movie_casts where celebrity_id != #{celebrity.id} and movie_id in (select movie_id from movie_casts where celebrity_id = #{celebrity.id}) and cast_type != 'actor' group by celebrity_id order by count desc limit 4;")
    return top_crews
  end
 def self.all_popularity
   Celebrity.where("wiki_link like '%wikipedia%' and wiki_link not like '%redlink=1%'").each do |celebrity|
     puts celebrity.name
     celebrity.update_popularity(celebrity)
   end
 end

 def update_popularity(celebrity)
       #popularity_percent = celebrity.celeb_tweets.fan_tweets.tweets_prev_week.pos_or_neg.blank? ? 0 : celebrity.celeb_tweets.fan_tweets.tweets_prev_week.pos_or_neg.count < 100 ? celebrity.celeb_tweets.fan_tweets.tweets_prev_week.pos_or_neg.count : ((100 * celebrity.celeb_tweets.fan_tweets.tweets_prev_week.pos_or_neg.select("SUM(rating) as total").first.total.to_i) / celebrity.celeb_tweets.fan_tweets.tweets_prev_week.pos_or_neg.count)  rescue 0
       max_views = Celebrity.maximum("wiki_views")
       delta = max_views < 100 ? 1 : max_views < 1000 ? 10 : max_views < 10000 ? 100 : max_views < 100000 ? 1000 : max_views < 1000000 ? 10000 : 100000
       popularity_percent = celebrity.wiki_views == 0 ? 0 : 100 - ((max_views - celebrity.wiki_views)/delta) unless celebrity.wiki_views.nil?
       if popularity_percent.nil? or popularity_percent > 0
         puts popularity_percent
         celebrity.update_attribute('popularity',  popularity_percent) unless celebrity.popularity == popularity_percent
       end
 end


  def self.latest_celeb_trailer
    @celeb_latest_trailers = []
    @celeb_trailers = Tagging.find(:all, :select => ["t2.tagger_id"], :joins => ["inner join taggings t2 on taggings.taggable_id = t2.taggable_id"], :conditions => ["t2.taggable_type='Video' and t2.tagger_type='Celebrity' and taggings.tagger_type='trailer'"],:order => ["t2.created_at desc"],:limit => 30)
    unless @celeb_trailers.blank?
      @celeb_trailers.each do |tr|
        @celeb = Celebrity.find_by_id(tr.tagger_id)
        unless @celeb.blank?
          if @celeb_latest_trailers.size == 12
            break
          else
            if @celeb_latest_trailers.include?(@celeb) == false
              @celeb_latest_trailers << @celeb
            end
          end
        end
      end
    end
    return @celeb_latest_trailers
  end

  def self.latest_celeb_pictures
    @celeb_latest_pictures = []
    @celeb_pictures =  Tagging.find(:all, :select => ["t2.tagger_id"], :joins => ["inner join taggings t2 on taggings.taggable_id = t2.taggable_id"], :conditions => ["t2.taggable_type='Poster' and t2.tagger_type='Celebrity' and t2.tagger_id IS NOT NULL and lower(taggings.tagger_type)='poster'"], :group => ["t2.tagger_id, t2.tagger_type, t2.created_at"], :order => ["t2.created_at desc"],:limit => 30)

    #Tagging.where("t2.taggable_type = 'Poster'").find(:all, :select => ["t2.tagger_id, t2.tagger_type"], :joins => ["inner join taggings t2 on taggings.taggable_id = t2.taggable_id"], :conditions => ["lower(taggings.tagger_type)='poster' and t2.tagger_id IS NOT NULL and t2.tagger_type='Celebrity'"], :group => ["t2.tagger_id, t2.tagger_type, t2.created_at"], :order => ["t2.created_at desc"],:limit => 30)
    unless @celeb_pictures.blank?
      @celeb_pictures.each do |pic|
        @name = ""
        @name = Celebrity.find_by_id(pic.tagger_id)

        unless @name.blank?
          if @celeb_latest_pictures.size == 12
            break
          else
            if @celeb_latest_pictures.include?(@name) == false
              @celeb_latest_pictures << @name
            end
          end
        end
      end
    end
    return @celeb_latest_pictures
  end

  def self.fetch_wiki(wiki_url, year, month, day)
    wiki_url = wiki_url.split('/')[-1]
    wiki = ActiveSupport::JSON.decode(open("http://stats.grok.se/json/en/#{year}#{month}/#{URI.escape(wiki_url).to_s}"))
    return wiki["daily_views"].as_json["#{year}-#{month}-#{day}"]
  end
  def self.wikiviews_extract()
    time = Date.today - 1.day
    Celebrity.where("wiki_link like '%wikipedia%' and wiki_link not like '%redlink=1%'").each do |celebrity|
        wk_count=fetch_wiki(URI.escape(celebrity.wiki_link),time.strftime("%Y").to_s, time.strftime("%m").to_s, time.strftime("%d").to_s)
        celebrity.update_attribute(:wiki_views, wk_count)
        puts celebrity.name
    end
  end
  
  def self.upcoming_movies(celebrity)
    @movie = []
    @movie_blank_release = []

    celebrity.movie_casts.find(:all,:select => ["movie_id"], :conditions => ["movie_id IS NOT NULL"], :group => ["movie_id"], :order => ["movie_id asc"]).each do |mov_cast|
      @movie_release = mov_cast.movie
      unless @movie_release.blank?
        if !@movie_release.release_date.blank? and @movie_release.release_date > Date.today
          @movie << @movie_release
        elsif @movie_release.release_date.blank?
          @movie_blank_release << @movie_release
        end
      end
    end
    @movie.uniq
    unless @movie.blank?
      @movie.sort!{|a,b| (a.release_date).strftime("%Y-%m-%d") <=> (b.release_date).strftime("%Y-%m-%d")}
    end
    @movie = @movie | @movie_blank_release
    return @movie
  end

  def self.top_rated_movies(celebrity)
    @top_movie = []
    celebrity.movie_casts.find(:all,:select => ["movie_id"], :conditions => ["movie_id IS NOT NULL"], :group => ["movie_id"]).each do |mov_cast|
         @movie_release = mov_cast.movie
         unless @movie_release.blank?
          if !@movie_release.release_date.blank? and !@movie_release.release_date.nil? and @movie_release.release_date <= Date.today
            @top_movie << @movie_release
          end
        end
    end

    unless @top_movie.blank?
      @top_movie.uniq
      begin
        @top_movie.sort!{|b,a| a.muvimeter <=> b.muvimeter }
      rescue
      end
    end
    return @top_movie
  end
end

