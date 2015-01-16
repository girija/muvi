class Movie < ActiveRecord::Base
  require 'arel'
  require 'open-uri'
  require 'nokogiri'

  #include MixinSitemap

  #TODO: setting-up external database. This works but doesn't look nice. try using some plugin.
  $config = YAML.load_file(File.join(File.dirname(__FILE__), '../../config/database.yml'))
  self.establish_connection  $config["muvi_extract"]
  set_table_name 'films'
  set_primary_key :id
  acts_as_commentable
  # has_friendly_id :name
  has_permalink [:name]#, :update => true
  
  #has_attached_file :poster, :styles => { :thumb=> "35x35#", :medium  => "130x200#" },
  #              :url => "/system/:attachment/:id/:style/:filename",
  #              :path => ":rails_root/public/system/:attachment/:id/:style/:basename.:extension"

  #has_attached_file :poster
  #has_attached_file :trailer

  def to_param
    permalink
  end
  serialize :genre
  
  searchable do
    text :name
  end

  after_save :check_name_is_blank
  #after_save :if_name_is_dictionary_word
  #after_save :create_sitemap

  has_many :activities , :conditions => [ "secondary_subject_type = ?", 'Movie'], :dependent => :destroy,:foreign_key => "secondary_subject_id"
  has_many :not_want_to_sees , :conditions => [ "is_want_to_see = ?", 'false' ], :dependent => :destroy, :class_name => 'WantToSee'
  has_many :want_to_sees , :conditions => [ "is_want_to_see = ?", 'true' ], :dependent => :destroy
  has_many :reviews , :dependent => :destroy
  has_many :reviwers, :through => :reviews, :source => :user
  has_many :recommendations, :dependent => :destroy
  has_many :tweets, :dependent => :destroy
  has_many :facebook_feeds, :dependent => :destroy
  has_many :critics_reviews, :dependent => :destroy
  has_one :meta_detail, :dependent => :destroy
  #has_one :movie_stream,:conditions => ["studio_user_id IS NULL AND (studio_user_id NOT IN ('52') OR youtube IS NOT NULL)"], :dependent => :destroy
  
  #has_many :video, :dependent => :destroy
  has_many :movie_casts, :order => "id asc", :dependent => :destroy
  #has_many :poster, :dependent => :destroy
  #to do better way .

  has_many :actors,  :class_name => 'MovieCast', :conditions => { "cast_type" => "actor" }, :order => "id asc"
  has_many :crew_members,  :class_name => 'MovieCast', :conditions => [ "cast_type != ?", 'actor' ]
#  has_many :producers,  :class_name => 'MovieCast', :conditions => { "cast_type" => "producer" }
 # has_many :musics,  :class_name => 'MovieCast', :conditions => { "cast_type" => "musics" }
 # has_many :writers,  :class_name => 'MovieCast', :conditions => { "cast_type" => "writer" }
 # has_many :cinematographers,  :class_name => 'MovieCast', :conditions => { "cast_type" => "cinematographer" }
 # has_many :distributors,  :class_name => 'MovieCast', :conditions => { "cast_type" => "distributor" }
 # has_many :editors,  :class_name => 'MovieCast', :conditions => { "cast_type" => "editor" }
  has_many :taggings, :conditions => {:taggable_type => "Discussion",:tagger_type => "Movie"},:foreign_key => "tagger_id"
  has_many :discussions ,:through => :taggings

  has_many :votes,:dependent => :destroy, :class_name => 'Review',:foreign_key => "movie_id"  
  has_many :like_votes, :conditions => [ "rating > 3"], :dependent => :destroy, :class_name => 'Review',:foreign_key => "movie_id"
  has_many :dislike_votes, :conditions => [ "rating < 3"], :dependent => :destroy, :class_name => 'Review',:foreign_key => "movie_id"

  #accepts_nested_attributes_for :meta_detail,:video, :movie_casts, :critics_reviews,:poster,  :allow_destroy => true
  accepts_nested_attributes_for :meta_detail, :movie_casts, :critics_reviews,  :allow_destroy => true
  accepts_nested_attributes_for :movie_casts, :reject_if => proc { |attributes| attributes['celebrity_id'].blank? }, :allow_destroy => true
  accepts_nested_attributes_for :actors, :reject_if => proc { |attributes| attributes['celebrity_id'].blank? }, :allow_destroy => true
  accepts_nested_attributes_for :crew_members, :reject_if => proc { |attributes| attributes['celebrity_id'].blank? }, :allow_destroy => true
  accepts_nested_attributes_for :tweets, :allow_destroy => true

  scope :find_using_id, lambda {|perm| where("permalink = ?", perm) }
  scope :latest, order('release_date desc nulls last')
  scope :sort_by_release_date_asc, order('release_date asc nulls last')
  scope :sort_by_user_interest_desc, order('user_percent desc nulls last')
  scope :sort_by_media_updated_date, order('media_updated_date desc nulls last')
  scope :limit, lambda{|l| limit(limit) }
  scope :name_is_not_blank, where("name IS NOT NULL")
  scope :released, where("release_date <= ?", (Date.today))
  scope :comming_soon_movies, where("release_date > ?  or release_date IS NULL", (Date.today))
  scope :name_without_dictionary_word, where("dictionary_word = ?", false)
  scope :name_with_dictionary_word, where("dictionary_word = ?", true)
  scope :this_year, where("release_date >= ?  and release_date IS NOT  NULL", Date.today.beginning_of_year.to_s)
  scope :todays_new_movies, where(:created_at => (Date.today.beginning_of_day)..Date.today.end_of_day)
  scope :todays_updated_movies, where(:updated_at => (Date.today.beginning_of_day)..Date.today.end_of_day)
  scope :todays_poster, where(:poster_updated_at => (Date.today.beginning_of_day)..Date.today.end_of_day)
  scope :this_month, where("release_date >= ?  and release_date IS NOT  NULL", Date.today.beginning_of_month.to_s)
  scope :past1month_upcoming_movies, where("release_date >= ?  or release_date IS NULL", (Date.today - 30).to_s)
  scope :non_dictionary, where(:dictionary_word => false)
  scope :theatres_this_week, where(:release_date => (Date.today - 4)..(Date.today + 5)).order('release_date desc')
  scope :dictionary_film, where(:dictionary_word => true)
  scope :released_tweet_fetch, where(:release_date => (Date.today - 14)..(Date.today))
  scope :coming_soon_six_months, where(:release_date => (Date.today)..(Date.today + 180))
  scope :last_six_months, where(:release_date => (Date.today - 180)..(Date.today))
  scope :sort_by_tweet_percent_desc, order('tweet_percent desc nulls last')

  scope :this_week, where(:created_at => (Date.today - 4)..(Date.today + 5)).order('created_at desc')
  scope :diff_score_nonzero, where("diff_score > 0")
  scope :five_days_released_movies, where(:release_date => (Date.today - 4)..(Date.today + 1))
  scope :four_days_upcomming_movies, where(:release_date => (Date.today + 1)..(Date.today + 5))
  scope :this_week_released_movies, where(:release_date => (Date.today.end_of_week - 6)..(Date.today.end_of_week + 1))
  scope :next_week_upcoming_movies, where(:release_date => (Date.today.end_of_week + 1)..(Date.today.end_of_week + 6))
  scope :last_week_released_movies, where(:release_date => (Date.today.beginning_of_week - 7)..(Date.today.beginning_of_week))   
 
  scope :hindi_movies, where(:language => "Hindi")
  scope :telugu_movies, where(:language => "Telugu")
  scope :tamil_movies, where(:language => "Tamil")
  scope :hollywood_movies, where(:language => "English")
  def self.find_for_sitemap
    find(:all, :order => "id")
  end

  def movie_stream
    @cp = [52]
    @movie_stream = MovieStream.where("movie_id = #{self.id}").order("id desc").find(:first)
    if @movie_stream and @cp.include?(@movie_stream.studio_user_id)
      if !@movie_stream.youtube.blank?
        @movie_stream.full_movie = ""
        return @movie_stream
      else
        return nil
      end
    else
      return @movie_stream
    end
  end
  def self.get_default_trailer(movie)
    @video_id = ""
    @videoids = ""
    @video = []
    @videos = ""
    tagging = Tagging.find(:all, :conditions => ["tagger_id = ?  and taggable_type = 'Video'",movie.id], :select => "taggable_id")
    unless tagging.blank?
      tagging.each do |t|
        unless t.taggable_id.blank?
          if @video_id.blank?
            @video_id = t.taggable_id
          else
            @video_id = @video_id.to_s + "," + t.taggable_id.to_s
          end
        end
      end
    end
    @video = Tagging.where("taggable_id IN (#{@video_id})").find(:all, :conditions => ["lower(tagger_type) = 'trailer'"], :select => "taggable_id", :order => ["id desc"]) unless @video_id.blank?
    unless @video.blank?
      @video.each do |v|
        if @videoids.blank?
          @videoids = v.taggable_id
        else
          @videoids = @videoids.to_s + "," + v.taggable_id.to_s
        end
      end
      @videos = Video.where("id IN (#{@videoids})").find(:all,:conditions => ["rank = 1"]).first
    end
    unless @videos.blank?
      @trailer = @videos
    else
      @trailer = false
    end
    return @trailer
  end

  def self.filter_toprated(years,genres,lang,avail_watch,top_rated,casts,first_time)
    lang = lang.blank? ? "'Hindi'" : lang
    cond = ""
    #if (years == "" && avail_watch != "true")
      #cond += "release_date BETWEEN '#{Date.today - 180}' AND '#{Date.today}'"
    #else
    if !years.blank?
      all_year = years.split(",")
      all_year.each do |year|
        if(year == "new_6")
          if cond == ""
            cond += " (release_date BETWEEN '#{Date.today - 180}' AND '#{Date.today}')"
          else
            cond += " OR (release_date BETWEEN '#{Date.today - 180}' AND '#{Date.today}')"
          end
        end
        if(year == "2010_now")
          if cond == ""
            cond += "(EXTRACT(YEAR FROM release_date) >= 2010 and release_date <= '#{Date.today}')"
          else
            cond += " OR (EXTRACT(YEAR FROM release_date) >= 2010 and release_date <= '#{Date.today}')"
          end
        end
        if(year == "1980-2009")
          if cond == ""
            cond += "(EXTRACT(YEAR FROM release_date) >= 1980 and EXTRACT(YEAR FROM release_date) <= 2009)"
          else
            cond += " OR (EXTRACT(YEAR FROM release_date) >= 1980 and EXTRACT(YEAR FROM release_date) <= 2009)"
          end
        end
        if(year == "1960-1979")
          if cond == ""
            cond += " (EXTRACT(YEAR FROM release_date) >= 1960 and EXTRACT(YEAR FROM release_date) <= 1979)"
          else
            cond += " OR (EXTRACT(YEAR FROM release_date) >= 1960 and EXTRACT(YEAR FROM release_date) <= 1979)"
          end
        end
        if(year == "classic")
          if cond == ""
            cond += "(EXTRACT(YEAR FROM release_date) < 1960)"
          else
            cond += " OR (EXTRACT(YEAR FROM release_date) < 1960)"
          end
        end
      end
      cond = "(#{cond})" if !cond.blank?
    end
    if(genres != "" and !genres.nil?)
      if cond == ""
        genre_cond = "("
      else
        genre_cond = " and ("
      end
      all_genre = genres.split(",")
      all_genre.each do |genre|
        if cond == "" && genre_cond == "("
          genre_cond += " genre like LOWER('%#{genre}%')"
        else
          if all_genre.count < 1
            genre_cond += " and genre like LOWER('%#{genre}%')"
          else
            if genre_cond == "(" || genre_cond == " and ("
              genre_cond += " genre like LOWER('%#{genre}%')"
            else
              genre_cond += " or genre like LOWER('%#{genre}%')"
            end
          end
        end
      end
      genre_cond += ")"
      cond += genre_cond
    end
    if(top_rated == "true")
      if cond == ""
        cond += " muvimeter > 60"
      else
        cond += " and muvimeter > 60"
      end
    end
    if !lang.blank?
      if cond == ""
        cond += " language IN (#{lang})"
      else
        cond += " and language IN (#{lang})"
      end
    end
    if first_time == "true"
      lmt = 2
    else
      lmt = 5
    end
    if(avail_watch == "true")
      #@fil_movies = Movie.where(cond).joins(:movie_stream).on("movie_stream.movie_id = films.id").order("muvimeter desc").limit(5)
      if(cond == "")
        if casts == ""
          @fil_movies = Movie.select("films.*").joins("JOIN movie_streams ON movie_streams.movie_id = films.id WHERE movie_streams.youtube != '' or movie_streams.full_movie != '' and studio_user_id NOT IN ('52')").order("release_date desc").limit(10)
        else
          @fil_movies = Movie.select("films.*").where("films.id is not null and studio_user_id NOT IN ('52')").joins("JOIN movie_streams ON movie_streams.movie_id = films.id WHERE movie_streams.youtube != '' or movie_streams.full_movie != ''").joins(:movie_casts).where("movie_casts.celebrity_id IN (#{casts})").order("release_date desc").limit(10)
        end
      else
        cond += " and (movie_streams.youtube != '' OR movie_streams.full_movie != '') and films.id is not null and studio_user_id NOT IN ('52') "
        if casts == ""
          @fil_movies = Movie.select("films.*").where(cond).joins("JOIN movie_streams ON movie_streams.movie_id = films.id").order("release_date desc").limit(10)
        else
          @fil_movies = Movie.select("films.*").where(cond).joins("JOIN movie_streams ON movie_streams.movie_id = films.id").joins(:movie_casts).where("movie_casts.celebrity_id IN (#{casts})").order("release_date desc").limit(10)
        end
      end

    else
      if casts == ""
        @fil_movies = Movie.where(cond).order("release_date desc").limit(10)
      else
        @fil_movies = Movie.select("DISTINCT(films.id),films.*").where(cond).joins(:movie_casts).where("movie_casts.celebrity_id IN (#{casts})").order("release_date desc").limit(10)
      end
    end
    return @fil_movies
  end

  def self.filter_toprated_old(year,genre,cast_id,lang)
    lang = lang[0..lang.length-2]
    if(year == "new_6")
      cond = "release_date BETWEEN '#{Date.today - 180}' AND '#{Date.today}'"
    elsif(year == "2000_now")
      cond = "EXTRACT(YEAR FROM release_date) >= 2000 and release_date <= '#{Date.today}'"
    elsif(year == "1990")
      cond = "EXTRACT(YEAR FROM release_date) >= 1990 and EXTRACT(YEAR FROM release_date) <= 1999"
    elsif(year == "1980")
      cond = "EXTRACT(YEAR FROM release_date) >= 1980 and EXTRACT(YEAR FROM release_date) <= 1989"
    elsif(year == "1970")
      cond = "EXTRACT(YEAR FROM release_date) >= 1970 and EXTRACT(YEAR FROM release_date) <= 1979"
    elsif(year == "1960")
      cond = "EXTRACT(YEAR FROM release_date) >= 1960 and EXTRACT(YEAR FROM release_date) <= 1969"
    elsif(year == "classic")
      cond = "EXTRACT(YEAR FROM release_date) < 1960"
    end
    if(genre != "all")
      cond += "and genre like '%#{genre}%'"
    end
    
    if(lang == "")
      cond += " and language = 'English'"
    else
      cond += " and language IN (#{lang})"
    end

    if(cast_id != "")
      @fil_movies = Movie.select("DISTINCT(films.id),films.*").where(cond).joins(:movie_casts).where("movie_casts.celebrity_id = #{cast_id}").order("muvimeter desc").limit(5)
    else
      @fil_movies = Movie.where(cond).order("muvimeter desc").limit(5)
    end

    return @fil_movies
  end

  def review_users(type)
    reviews = []
    all_reviews = self.reviews.order("id desc")
    if type == "like"
      all_reviews.each do |review|
        if review.rating
          if review.rating >= 3.0
            reviews << review
          end
        end
      end
    else
      all_reviews.each do |review|
        if review.rating
          if review.rating < 3.0
            reviews << review
          end
        end
      end
    end
    return reviews
  end

  def check_name_is_blank
    self.update_attribute('name', 'unnamed') if self.name.blank?
  end

  def create_sitemap
    if Sitemap.delay.create!
      system("s3cmd sync --acl-public public/sitemap.xml s3://#{BUCKET}/public/sitemap.xml")
    end
  end
  
  def get_first_two_actors
    actor_name = ""
    self.movie_casts.where("cast_type = 'actor'").limit(2).each do |cast|
      if cast.celebrity
        if actor_name.blank?
          actor_name = cast.celebrity.name
        else
          actor_name = actor_name + ","+ cast.celebrity.name
        end
      end
    end
    return actor_name
  end
  
  def get_first_two_actors_link
    actor_name = ""
    self.movie_casts.where("cast_type = 'actor'").limit(2).each do |cast|
      if cast.celebrity
        if actor_name.blank?
          actor_name = "<a href='/stars/#{cast.celebrity.permalink}' style='font-weight:normal;'>#{cast.celebrity.name.truncate(15)}</a>"
        else
          actor_name = actor_name + ", <a href='/stars/#{cast.celebrity.permalink}' style='font-weight:normal;'>"+ cast.celebrity.name.truncate(15)+"</a>"
        end
      end
    end
    return actor_name.html_safe
  end

  def get_first_two_actors_link_gray
    actor_name = ""
    self.movie_casts.where("cast_type = 'actor'").limit(2).each do |cast|
      if cast.celebrity
        if actor_name.blank?
          actor_name = '<a href="/stars/'"#{cast.celebrity.permalink}"'" style="color:#333333;font-weight:bold;">'"#{cast.celebrity.name.truncate(15)}"'</a>'
        else
          actor_name = actor_name + ', <a href="/stars/'"#{cast.celebrity.permalink}"'" style="color:#333333; font-weight:bold;">'+ cast.celebrity.name.truncate(15)+'</a>'
        end
      end
    end
    return actor_name.html_safe
  end

  def if_name_is_dictionary_word
    if self.dictionary_word
      self.tweets.each do |tweet|
        TweetIgnNeu.create(tweet.attributes.except("id", "updated_at", "created_at"))
        tweet.destroy
      end
      self.facebook_feeds.posts.destroy_all

    end
  end


  def banner_image
    #self.poster_file_name.blank?? '/images/no-image.png' : "/system/posters/#{self.id}/medium/#{self.poster_file_name}"
      poster = Poster.check_for_default_poster(self.id, "Movie", "Poster", "poster")
      if poster == false
        #self.poster_file_name.blank?? '/images/no-image.png' : "/system/posters/#{self.id}/standard/#{self.poster_file_name.gsub(" ", "%20")}"
        return '/images/no-image.png'

      else
        poster_image = Poster.where("id IN (#{poster})").find(:all, :conditions => ["rank = 1"], :order => ["id desc"]).first
        unless poster_image.blank?
          unless poster_image.poster_file_name.blank?
            return "/system/posters/#{poster_image.id}/standard/#{poster_image.poster_file_name.gsub(" ", "%20")}"
          else
            return '/images/no-image.png'
          end
        else
          self.poster_file_name.blank?? '/images/no-image.png' : "/system/posters/#{self.id}/standard/#{self.poster_file_name.gsub(" ", "%20")}"
        end
      end
  end

  def banner_image_thumb
    poster = Poster.check_for_default_poster(self.id, "Movie", "Poster", "poster")
      if poster == false
        return '/images/no-image.png'
      else
        poster_image = Poster.where("id IN (#{poster})").find(:all, :conditions => ["rank = 1"], :order => ["id desc"]).first
        unless poster_image.blank?
          unless poster_image.poster_file_name.blank?
            return "/system/posters/#{poster_image.id}/thumb/#{poster_image.poster_file_name.gsub(" ", "%20")}"
          else
            return '/images/no-image.png'
          end
        else
          self.poster_file_name.blank?? '/images/no-image.png' : "/system/posters/#{self.id}/thumb/#{self.poster_file_name.gsub(" ", "%20")}"
        end
      end
  end

  def banner_image_medium
    poster = Poster.check_for_default_poster(self.id, "Movie", "Poster", "poster")
      if poster == false
        return '/images/no-image.png'
      else
        poster_image = Poster.where("id IN (#{poster})").find(:all, :conditions => ["rank = 1"], :order => ["id desc"]).first
        unless poster_image.blank?
          unless poster_image.poster_file_name.blank?
            return "/system/posters/#{poster_image.id}/medium/#{poster_image.poster_file_name.gsub(" ", "%20")}"
          else
            return '/images/no-image.png'
          end
        else
          self.poster_file_name.blank?? '/images/no-image.png' : "/system/posters/#{self.id}/medium/#{self.poster_file_name.gsub(" ", "%20")}"
        end
      end
  end

  def full_image
    poster = Poster.check_for_default_poster(self.id, "Movie", "Poster", "poster")
    if poster == false
      return '/images/no-image.png'

    else
      poster_image = Poster.where("id IN (#{poster})").find(:all, :conditions => ["rank = 1"], :order => ["id desc"]).first
      unless poster_image.blank?
        unless poster_image.poster_file_name.blank?
          return "/system/posters/#{poster_image.id}/original/#{poster_image.poster_file_name.gsub(" ", "%20")}"
        else
            return '/images/no-image.png'
        end
      else
      self.poster_file_name.blank?? '/images/no-image.png' : "/system/posters/#{self.id}/original/#{self.poster_file_name.gsub(" ", "%20")}"
      end
    end
  end


  def crop_full_image
    poster = Poster.check_for_default_poster(self.id, "Movie", "Poster", "poster")
    if poster == false
      return '/images/no-image.png'

    else
      poster_image = Poster.where("id IN (#{poster})").find(:all, :conditions => ["rank = 1"], :order => ["id desc"]).first
      unless poster_image.blank?
        unless poster_image.poster_file_name.blank?
          return "/system/posters/#{poster_image.id}/crop_original/#{poster_image.poster_file_name.gsub(" ", "%20")}"
        else
            return '/images/no-image.png'
        end
      else
      self.poster_file_name.blank?? '/images/no-image.png' : "/system/posters/#{self.id}/crop_original/#{self.poster_file_name.gsub(" ", "%20")}"
      end
    end
  end

  def standard_image
    poster = Poster.check_for_default_poster(self.id, "Movie", "Poster", "poster")
    if poster == false
      return '/images/no-image.png'

    else
      poster_image = Poster.where("id IN (#{poster})").find(:all, :conditions => ["rank = 1"], :order => ["id desc"]).first
      unless poster_image.blank?
        unless poster_image.poster_file_name.blank?
          return "/system/posters/#{poster_image.id}/standard/#{poster_image.poster_file_name.gsub(" ", "%20")}"
        else
            return '/images/no-image.png'
        end
      else
      self.poster_file_name.blank?? '/images/no-image.png' : "/system/posters/#{self.id}/standard/#{self.poster_file_name.gsub(" ", "%20")}"
      end
    end
  end



  def average_rating
    reviews.blank? ? 'No ratings yet' : reviews.select("SUM(rating) as total").first.total.to_i / reviews.count
  end

  def average_rating_percent
    #reviews.blank? ? 0 : (100 * reviews.select("SUM(rating) as total").first.total.to_i) / (reviews.count * 5) rescue 0
    tweets.blank? ? 0 : (100 * tweets.select("SUM(rating) as total").first.total.to_i) / tweets.count(:all,:conditions=>["interest = ?","f"]) rescue 0
  end

  def average_rating_count
    #reviews.blank? ? 0 : reviews.count
    tweets.blank? ? 0 : tweets.count rescue 0
  end

  def average_critics_reviews_rating_percent
    critics_reviews.blank? ? 0 : (100 * critics_reviews.select("SUM(rating) as total").first.total.to_i) / (critics_reviews.count * 5)
  end

  def fb_friends_liked(user)
    #user.facebook_friend_likes(user.facebook_omniauth.uid).by_fb_item_id(self.fbpage_id) unless user.facebook_omniauth.blank?
    return 0 if user.blank? || user.facebook_friends.blank?
    return self.facebook_feeds.friend_likes.friends_ids(user.facebook_friends_ids).count rescue 0
  end


  def self.fetch_tweets_and_facebook_feeds
    delay = 0
    Movie.name_is_not_blank.name_without_dictionary_word.latest.each do |movie|
      Tweet.delay({:run_at => delay.minutes.from_now}).fetch_tweet_for_movie(movie)
      FacebookFeed.delay({:run_at => delay.minutes.from_now}).fetch_all_post_for_movie(movie)
      delay += 15
    end
  end

  def friend_likes(user) # this method is used in movie show
    return [] if user.blank? || user.facebook_friends.blank?
    self.facebook_feeds.friend_likes.friends_ids(user.facebook_friends_ids).limit(4)
  end

  def like_or_interest
    if self.release_date.blank? || self.release_date > Date.today
      return 'interested'
    else
      return 'liked'
    end
  end

  def self.top_box_office(limit_to)
    self.order(:release_date).order(:gross_revenue).limit(limit_to)
  end

  def self.top_trending(limit_to)
    #self.select('films.*, SUM(tweets.id) as no_of_tweets').joins(:tweets).order("no_of_tweets").order(4)
    []
  end

  def self.update_reviews_precentage
    Movie.latest.includes(:tweets, :reviews, :critics_reviews).each do |movie|
      #review_count = movie.reviews.blank? ? 0 : (100 * movie.reviews.select("SUM(rating) as total").first.total.to_i) / (movie.reviews.count * 5) rescue 0
      #critics_percent = movie.critics_reviews.blank? ? 0 : (100 * movie.critics_reviews.select("SUM(rating) as total").first.total.to_i) / (movie.critics_reviews.count * 5)
     # if review_count == 0 || tweet_count == 0
     #   user_percent =  (review_count + tweet_count)
     # else
     #   user_percent =  (review_count + tweet_count)/ 2 rescue 0
     # end
      #if movie.release_date.blank?
      #    tweet_percent = movie.tweets.reviews.pos_or_neg.blank? ? 0 : ((100 * movie.tweets.reviews.pos_or_neg.select("SUM(rating) as total").first.total.to_i) / movie.tweets.reviews.pos_or_neg.count)  rescue 0
      #elsif  movie.release_date <= Date.today
      #    tweet_percent = movie.tweets.reviews.pos_or_neg.blank? ? 0 : ((100 * movie.tweets.reviews.pos_or_neg.select("SUM(rating) as total").first.total.to_i) / movie.tweets.reviews.pos_or_neg.count)  rescue 0
      #else
      #    tweet_percent = movie.tweets.interests.pos_or_neg.blank? ? 0 : ((100 * movie.tweets.interests.pos_or_neg.select("SUM(rating) as total").first.total.to_i) / movie.tweets.interests.pos_or_neg.count)  rescue 0
      #end
      #user_percent = tweet_percent
      #movie.update_attribute('critics_percent', critics_percent) unless movie.critics_percent == critics_percent
      #movie.update_attribute('user_percent',  user_percent) unless movie.user_percent == user_percent
      Movie.update_one_movie_percentage(movie)
      
    end
  end

  def self.update_one_movie_percentage(movie)
      if movie.critics_reviews.blank?
        critics_percent = 0
      else
        #critics_percent = movie.critics_reviews.count.to_f < 10 ? (100 * (movie.critics_reviews.select("SUM(rating) as total").first.total.to_f / (movie.critics_reviews.count.to_f * 5)))>50 ? (100 * (movie.critics_reviews.select("SUM(rating) as total").first.total.to_f / (movie.critics_reviews.count.to_f * 5)))+10 : (100 * (movie.critics_reviews.select("SUM(rating) as total").first.total.to_f / (movie.critics_reviews.count.to_f * 5)))-10 : 100 * (movie.critics_reviews.where("rating > 2.5").count.to_f/movie.critics_reviews.count.to_f)
        if movie.critics_reviews.count.to_f < 10
          critics_percent = 100 * (movie.critics_reviews.select("SUM(rating) as total").first.total.to_f / (movie.critics_reviews.count.to_f * 5))
          if critics_percent >= 50
            critics_percent += 10
          else
            critics_percent -= 10
          end
        else
          critics_percent =  100 * (movie.critics_reviews.where("rating > 2.5").count.to_f/movie.critics_reviews.count.to_f)
        end
        critics_percent = critics_percent < 0 ? 0 : critics_percent > 100 ? 100 : critics_percent
      end

      if movie.reviews.blank?
        user_percent = 0
      else
        #user_percent = movie.reviews.count.to_f < 10 ? (100 * (movie.reviews.select("SUM(rating) as total").first.total.to_f / (movie.reviews.count.to_f * 5)))>50 ? (100 * (movie.reviews.select("SUM(rating) as total").first.total.to_f / (movie.reviews.count.to_f * 5)))+10 : (100 * (movie.reviews.select("SUM(rating) as total").first.total.to_f / (movie.reviews.count.to_f * 5)))-10 : (100 * (movie.reviews.where("rating > 2.5").count.to_f/movie.reviews.count.to_f))
         if movie.reviews.count.to_f < 10
          user_percent = 100 * (movie.reviews.select("SUM(rating) as total").first.total.to_f / (movie.reviews.count.to_f * 5))
          if user_percent >= 50
            user_percent += 10
          else
            user_percent -= 10
          end
        else
          user_percent = 100 * (movie.reviews.where("rating > 2.5").count.to_f/movie.reviews.count.to_f)
        end
        user_percent = user_percent < 0 ? 0 : user_percent > 100 ? 100 : user_percent
      end
      
      if movie.release_date.blank? or movie.release_date > Date.today
          #tweet_percent = movie.tweets.tweets_prev_week.interests.pos_or_neg.blank? ? 0 : movie.tweets.tweets_prev_week.interests.pos_or_neg.count < 10 ? movie.tweets.tweets_prev_week.interests.pos_or_neg.select("SUM(rating) as total").first.total.to_f  : ((100 * movie.tweets.tweets_prev_week.interests.pos_or_neg.select("SUM(rating) as total").first.total.to_f) / movie.tweets.tweets_prev_week.interests.pos_or_neg.count)  rescue 0
          #tweet_count = movie.tweets.tweets_prev_week.reviews.pos_or_neg.count

      elsif  movie.release_date <= Date.today
          tweet_percent =  movie.tweets.reviews.pos_or_neg.blank? ? 0 : movie.tweets.reviews.pos_or_neg.count < 100 ? 0 : ((100 * movie.tweets.reviews.pos_or_neg.select("SUM(rating) as total").first.total.to_f) / movie.tweets.reviews.pos_or_neg.count)  rescue 0
          tweet_count =  movie.tweets.reviews.pos_or_neg.count
      else
          tweet_percent = movie.tweets.tweets_prev_week.interests.pos_or_neg.blank? ? 0 : movie.tweets.tweets_prev_week.interests.pos_or_neg.count < 20 ? movie.tweets.tweets_prev_week.interests.pos_or_neg.select("SUM(rating) as total").first.total.to_f : ((100 * movie.tweets.tweets_prev_week.interests.pos_or_neg.select("SUM(rating) as total").first.total.to_f) / movie.tweets.tweets_prev_week.interests.pos_or_neg.count)  rescue 0
          tweet_count = movie.tweets.tweets_prev_week.interests.pos_or_neg.count
      end

      critics_denom =  critics_percent != 0 ? 2 : 0
      user_denom = user_percent != 0 ? 1 : 0
      tweet_denom = tweet_percent != 0 ? 1 : 0
      muvi_meter_denom = critics_denom + user_denom + tweet_denom

      muvi_meter = 0
      if  muvi_meter_denom != 0
        muvi_meter = ((2 * critics_percent) + user_percent + tweet_percent)/ muvi_meter_denom
      else
          muvi_meter = 0
      end
      round_muvimeter =  muvi_meter.round
puts "______"
puts round_muvimeter
      muvi_meter = round_muvimeter < 15 ? 15 : round_muvimeter > 98 ? 98 : round_muvimeter

     
       
      unless tweet_percent.nil?
        if tweet_percent > 0 || movie.release_date == Date.today || critics_percent > 0
          movie.update_attribute('tweets_count', tweet_count) unless movie.tweets_count == tweet_count
          movie.update_attribute('tweet_percent', tweet_percent) unless movie.tweet_percent == tweet_percent
        end
      end
puts "#####"
puts muvi_meter

      if !movie.release_date.blank? or movie.release_date > Date.today
        movie.update_attribute('critics_percent', critics_percent) unless movie.critics_percent == critics_percent
        movie.update_attribute('user_percent',  user_percent) unless movie.user_percent == user_percent
        movie.update_attribute('muvimeter',muvi_meter) unless movie.muvimeter == muvi_meter
      end
  end

def self.update_muvimeter_all
 Movie.find(:all).each do |movie|
  if movie.release_date.blank? or movie.release_date > Date.today
    max_views = Movie.maximum("wiki_views")
    delta = max_views < 100 ? 1 : max_views < 1000 ? 10 : max_views < 10000 ? 100 : max_views < 100000 ? 1000 : max_views < 1000000 ? 10000 : 100000
      muvi_buzz = movie.wiki_views == 0 ? 0 : 100 - ((max_views - movie.wiki_views)/delta) unless movie.wiki_views.nil?
    movie.update_attribute('muvimeter',muvi_buzz)  unless movie.muvimeter == muvi_buzz 
  else 
   update_one_movie_percentage(movie)
   puts movie.name
  end
 end
end

  def self.update_muvimeter_a
    Movie.find(:all, :conditions => ["name = 'Playing for Keeps (2012)'"]).each do |mov|
    
    update_one_movie_percentage(mov)
    puts mov.name
   end
 
  end

  def self.update_reviews_percentage_movie(movie_name)
    puts movie_name
    Movie.where(:name => movie_name).each do |movie| 
    puts movie.tweets.reviews.pos_or_neg
    tweet_count = movie.tweets.reviews.pos_or_neg.blank? ? 0 : ((100 * movie.tweets.reviews.pos_or_neg.select("SUM(rating) as total").first.total.to_i) / movie.tweets.reviews.pos_or_neg.count)  rescue 0
    puts tweet_count
    end
  end

  def self.update_top_box_office
    TopBoxOffice.destroy_all
    Movie.top_box_office(4).each_with_index do |movie, idx|
      TopBoxOffice.create({:movie_id => movie.id, :position => idx})
    end
  end

  def self.update_top_trending
    TopTrending.destroy_all
    date = (Date.today - 7).to_date.to_s
    # tweets_count+facebook_feeds_count+reviews_count
    Movie.find_by_sql("select id, (tweets_count) as count from films where release_date >='#{date}' order by count DESC limit 4;").each_with_index do |movie, idx|
      TopTrending.create({:movie_id => movie.id, :position => idx})
    end
  end

  def self.update_tweets_count
    Movie.latest.each do |movie|
     if movie.release_date.blank?
      movie.update_attributes(:tweets_count => movie.tweets.interests.pos_or_neg.count)
     elsif movie.release_date > Date.today
      movie.update_attributes(:tweets_count => movie.tweets.interests.pos_or_neg.count)
     else
      movie.update_attributes(:tweets_count => movie.tweets.reviews.pos_or_neg.count)
     end 
    end
  end

  def self.update_all_counters
    Movie.latest.all.each do |movie|
      hash = {:tweets_count => -movie.tweets_count, :facebook_feeds_count => -movie.facebook_feeds_count, :movie_casts_count => -movie.movie_casts_count, :critics_reviews_count => -movie.critics_reviews_count, :reviews_count =>  -movie.reviews_count }
      Movie.update_counters movie.id, hash

      hash = {:tweets_count => movie.tweets.reviews.pos_or_neg.count, :facebook_feeds_count => movie.facebook_feeds.count, :movie_casts_count => movie.movie_casts.count, :critics_reviews_count => movie.critics_reviews.count, :reviews_count => movie.reviews.count}
      Movie.update_counters movie.id, hash
    end
  end

  def update_tweets_count_after_tweet_delete
    self.update_attribute('tweets_count', self.tweets.reviews.pos_or_neg.count)
  end

  def self.delete_tweets_and_facebook_posts_for_dictionary_word_movies
    Movie.name_with_dictionary_word.each do |movie|
      
      movie.tweets.destroy_all
      #movie.tweets.each do |tweet|
      #  TweetIgnNeu.create(tweet.attributes.except("id", "updated_at", "created_at"))
      #  tweet.destroy
      #end
      movie.facebook_feeds.posts.destroy_all
    end
    Movie.delay.update_all_counters
    Movie.delay.update_reviews_precentage
  end


  def self.fetch_movie_info
   Movie.where(" wiki_link like  '%imdb.com/title/%' and poster_release_date is null ").each do |movie|
     begin
     #imdb_link = "http://www.imdb.com/find?s=tt&q=" + movie.name
     #doc = Nokogiri::HTML(open(URI.parse(URI.encode(imdb_link))))
     #puts movie.name,URI.encode(imdb_link)
     #mov_rel_date = doc.xpath("//div[@id='wrapper']/div[@id='root']/div[@id='pagecontent']/div[@id='content-2-wide']/div[@id='main']/div[@class='article title-overview']/div/table[@id = 'title-overview-widget-layout']/tr/td[@id = 'overview-top']/div[@class = 'infobar']/span[@class = 'nobr']/a").text
     #if mov_rel_date.length == 0
     #  mov_rel_date = doc.xpath("//div[@id='wrapper']/div[@id='root']/div[@id='pagecontent']/div[@id='content-2-wide']/div[@id='main']/div[@class='article title-overview']/div/table[@id = 'title-overview-widget-layout']/tr/td[@id = 'overview-top']/h1/span/a").text
     #end
     api_link = "http://www.imdbapi.com/?i=" + movie.wiki_link[26..34]
     doc2 = Net::HTTP.get_response(URI.parse(api_link))
    data = doc2.body
    result = JSON.parse(data)
    mov_poster_path = result["Poster"]
    puts movie.name
    puts mov_poster_path.to_s
     if mov_poster_path.to_s != 'N/A'
      image = File.new("/home/ubuntu/muvi.in/public/thumbnails/imdb/"+movie.name.gsub(' ','_')+".png","wb")
      image << open(mov_poster_path.to_s).read
      movie.poster = File.new('/home/ubuntu/muvi.in/public/thumbnails/imdb/' + movie.name.gsub(' ','_')+'.png')
      movie.save
     end
     #mov_dir_name = doc.xpath("//div[@id='wrapper']/div[@id='root']/div[@id='pagecontent']/div[@id='content-2-wide']/div[@id='main']/div[@class='article title-overview']/div/table[@id = 'title-overview-widget-layout']/tr/td[@id = 'overview-top']/div[@class='txt-block']/a[1]").text
    #mov_cast_name =doc.xpath("//div[@id='wrapper']/div[@id='root']/div[@id='pagecontent']/div[@id='content-2-wide']/div[@id='main']/div[@class='article title-overview']/div/table[@id = 'title-overview-widget-layout']/tr/td[@id = 'overview-top']/div[@class='txt-block'][2..5]").text
     #mov_poster_path = doc.xpath("//div[@id='wrapper']/div[@id='root']/div[@id='pagecontent']/div[@id='content-2-wide']/div[@id='main']/div[@class='article title-overview']/div/table[@id = 'title-overview-widget-layout']/tr/td[@id='img_primary']/a/img/@src")
     #puts mov_poster_path.to_s
     #if mov_poster_path.to_s != ''
     # image = File.new("/home/ubuntu/muvi.in/public/thumbnails/imdb/"+movie.name.gsub(' ','_')+".png","wb")
     # image << open(mov_poster_path.to_s).read
     # movie.poster = File.new('/home/ubuntu/muvi.in/public/thumbnails/imdb/' + movie.name.gsub(' ','_')+'.png')
     # movie.save
    #end
    rescue
     puts movie.name
     next
  #  begin
     #api_link = "http://www.imdbapi.com/?i=" + movie.wiki_link[26..34]
     #puts api_link
     #doc2 = Net::HTTP.get_response(URI.parse(api_link))
     #data = doc2.body
     #result = JSON.parse(data)
     #puts result
     #puts mov_rel_date
     #puts mov_dir_name
     #puts mov_cast_name
    #movie.update_attributes(:initial_release_date => mov_rel_date, :wiki_link => movie.wiki_link + " , " + URI.encode(imdb_link))
  #  rescue
  #   puts movie.name + "INFO"
  #   next
    end
    end
  end

  def self.google_fetch_poster
    goog_link = "http://www.google.com/search?tbm=isch&hl=en&source=hp&q="
    goog_options = "&btnG=Search+Images&gbv=2&aq=f&aqi=&oq=&sout=1&biw=1&bih=1"
    Movie.where(" release_date is not null and poster_file_name is null ").each do |movie|
      begin
      fetch_url1 = goog_link + movie.name + " " + movie.release_date.to_s[0..3] + goog_options
      doc = Nokogiri::HTML(open(URI.parse(URI.encode(fetch_url1))))
      poster_link = /http(.*?)\&/.match(doc.xpath("//table/tr[1]/td[1]/a[1]/@href").to_s)
      movie_poster_path =  poster_link.to_s.chop
      puts movie.name , movie_poster_path
      image = File.new("/home/ubuntu/muvi.in/public/thumbnails/imdb/"+movie.name.gsub(' ','_')+movie_poster_path[-4,4],"wb")
      image << open(movie_poster_path).read
      movie.poster = File.new('/home/ubuntu/muvi.in/public/thumbnails/imdb/' + movie.name.gsub(' ','_')+movie_poster_path[-4,4])
      movie.save

      rescue
        begin
        puts "rescued"+movie.name
        poster_link_1 = /http(.*?)http/.match(doc.xpath("//table/tr[1]/td[1]/a[1]/img/@src").to_s)
        poster_link = poster_link_1.to_s.chop.chop.chop.chop.chop
        puts poster_link
        image = File.new("/home/ubuntu/muvi.in/public/thumbnails/imdb/"+movie.name.gsub(' ','_')+".jpg","wb")
        image << open(poster_link).read
        movie.poster = File.new('/home/ubuntu/muvi.in/public/thumbnails/imdb/' + movie.name.gsub(' ','_')+".jpg")
        movie.save
        rescue
           puts "super rescued"+movie.name
        end
        next
      end
    end
  end


def self.import_posters
  folder = "/home/ubuntu/muvi.in/public/thumbnails/imdb/"
  #Dir.entries(folder).each do |file_name|
  # unless ['.', '..'].include?(file_name)
   file_name = "Amar_Raj.jpg"
   movie_name = file_name.split('.')[0]
   movie = Movie.where(:name => 'Amar Raj').first
   unless movie.blank?
    movie.poster = File.new(folder+file_name)
    movie.save
   else
    puts "movie_name:#{movie_name}"
   end
  #end
#end
end
 def self.missing_release_date_update
   searchlink = "http://movies.bollysite.com/search.html?filter=movies&q="
   Movie.where("initial_release_date is null  and release_date is null").each do |movie|
     begin
     fetch_url1 = searchlink + movie.name
     puts URI.encode(fetch_url1)
     doc = Nokogiri::HTML(open(URI.parse(URI.encode(fetch_url1))))
     match_item = doc.xpath("//body/div/div/ul/li")
     i = 0
     match_item.each do |item|
       i = i + 1
       if item.xpath("//body/div/div/ul/li/a/font")[i].text.strip == movie.name.strip
        puts item.xpath("//body/div/div/ul/li/a/font")[i].text.strip
        release_dt = item.xpath("//body/div/div/ul/li/font")[i].text.gsub(/-/,"").gsub(/\(/,"").gsub(/\)/,"").strip
        movie.update_attributes(:initial_release_date => release_dt)
       else
        next
       end
     end
     rescue
      next
     end
   end
 end

  def self.latest_trailers_old
    @latest_trailers = []
    @trailers = Video.order('created_at desc nulls last').find(:all, :conditions => ["trailer_file_name IS NOT NULL"])
    #@trailers = Video.order('created_at desc nulls last').find(:all)
    #@latest_trailers = Video.find(:all)

    if !@trailers.blank?
      @trailers.each do |lt|
          @movie = lt.movie
          unless @movie.blank?
          if (@movie.release_date.blank? or @movie.release_date > Date.today)
            @latest_trailers << @movie
          end
        end
      end
    end
    return @latest_trailers
  end

  def self.latest_trailers
    @latest_trailers = []
    @trailers = Tagging.where("t2.taggable_type = 'Video'").find(:all, :select => ["t2.tagger_id"], :joins => ["inner join taggings t2 on taggings.taggable_id = t2.taggable_id"], :conditions => ["lower(taggings.tagger_type)='trailer' and t2.tagger_id IS NOT NULL and t2.tagger_type='Movie'"], :group => ["t2.tagger_id, t2.created_at"], :order => ["t2.created_at desc"],:limit => 12)
    unless @trailers.blank?
      @trailers.each do |tr|
        @movie = Movie.find_by_id(tr.tagger_id)
        unless @movie.blank?
          if (@movie.release_date.blank? or @movie.release_date > Date.today or @movie.release_date > (Date.today - 10))
            #if @latest_trailers.size == 12
            #  break
            #else
              if @latest_trailers.include?(@movie) == false
                @latest_trailers << @movie
              end
            #end
          end
        end        
      end
    end
    return @latest_trailers
  end

  def self.latest_pictures
    @latest_pictures = []
    @pictures = Tagging.where("t2.taggable_type = 'Poster'").find(:all, :select => ["t2.tagger_id, t2.tagger_type"], :joins => ["inner join taggings t2 on taggings.taggable_id = t2.taggable_id"], :conditions => ["lower(taggings.tagger_type)='poster' and t2.tagger_id IS NOT NULL and t2.tagger_type='Movie'"], :group => ["t2.tagger_id, t2.tagger_type, t2.created_at"], :order => ["t2.created_at desc"],:limit => 30)
    unless @pictures.blank?
      @pictures.each do |pic|
        @name = ""
        @name = Movie.find_by_id(pic.tagger_id)

        unless @name.blank?
          if @latest_pictures.size == 12
            break
          else
            if (@name.release_date.blank? or @name.release_date > Date.today)
              if @latest_pictures.include?(@name) == false
                @latest_pictures << @name
              end
            end
          end
        end
      end
    end
    return @latest_pictures
  end

  def self.get_fb_id
    pub_url = "http://www.facebook.com/profile.php?id=100000281507658&sk=friends&list=1"
    doc = Nokogiri::HTML(open(pub_url))
    return doc
  end

  def self.get_muvimeter(movie)
    muvimeter = movie.muvimeter || 0
    html = ""
    html += "<div style='margin-top:12px;padding-bottom: 5px;width: 320px;float:left'>
  <div style='height: 62px; margin-bottom: 8px; padding: 0; width: 300px;'>
    <span style='font-weight: bold;'>
      <a href='http://www.muvi.com/movies/#{movie.permalink}#critics' onclick='go_to_tab(0);' style='color: #4F4F4F;font-size: 12px; text-decoration: none;'>MUVIMETER</a>
    </span>
    <div style='clear: both;'></div>
    <div style='background-color: #D8D8D8; border: 1px solid #BECBD4; border-radius: 6px 6px 6px 6px; height: 25px; margin-bottom: 0; margin-top: 2px; padding: 3px 3px 2px; width: 180px; float:left'>"

      if (muvimeter >= 60)
        html += "<img src='http://www.muvi.com/images/long-G-RatingBar.jpg' width='#{muvimeter}%' height='23px'>"
      else
        html += "<img src='http://www.muvi.com/images/long-R-RatingBar.jpg' width='#{muvimeter}%' height='23px'>"
      end


    html += "</div>
    <div style='color: #53555F; font-size: 20px; letter-spacing: -1px; margin-left: 5px;  padding: 0; text-align: left; width: 35px; margin-top:5px; float:left'>
      <a href='http://www.muvi.com/movies/#{movie.permalink}#critics' style='font-size:20px; color:#4F4F4F;text-decoration: none;font-weight:bold'>#{muvimeter}%</a>
    </div>
    <div style='float:right'>"
      if(muvimeter >= 60)
         html += "<img src='http://www.muvi.com/images/thumbUp.png' title='Jhakaas' alt='Jhakaas'>"
      else
         html += "<img src='http://www.muvi.com/images/thumbDown.png' title='Bakwaas' alt='Bakwaas'>"
      end

    html += "</div>
  </div>
</div>"
    return html.html_safe
  end

  def self.send_notification(notification_type,options = {})
    if notification_type == "want_to_see"
      #movie released yesterday, tomorrow and have one review
      @movie = Movie.find(:all,:conditions => ["release_date = ? or release_date = ?", (Date.today - 1), (Date.today + 1)])
      #@movie = Movie.find(:all, :conditions => ["id = 10650"])
      unless @movie.blank?
        @movie.each do |movie|
          @subject = "Movie Tweets for #{movie.name}!"
          @content = Movie.get_muvimeter(movie)
          @want_to_see = WantToSee.where("movie_id = ?", movie.id).find(:all)
          unless @want_to_see.blank?
            @want_to_see.each do |watch|
              @user = User.find_by_id(watch.user_id)
              @email = @user.email
              #@email = "sanjibjan18@exelanz.com"
              unless @email.blank?
                UserMailer.deliver_notify(@email, @subject, @content)
              end
            end
          end
        end
      end

    elsif notification_type == "user"
      User.where("facebook_id IS NOT NULL").find(:all).each do |user|
        unless user.user_tokens.blank?
          unless user.user_connection.blank?
            @review = ""
            @subject = "Movie Reviews"
        
            ActiveSupport::JSON.decode(user.user_connection.connections).each do |conn|
              begin
                @rev = User.find_by_id(conn).reviews(:all, :conditions => ["date(created_at) = ?", Date.today]).first
                unless @rev.blank?
                  @movie = Movie.find_by_id(@rev.movie_id)
                  @review = @review + "<br><br><span style='font-weight:bold;font-style:italic;'>" + @movie.name + "</span><br>" + @rev.description.to_s + "<br><span style='color:#666666; font-style:italic;font-size:10px'>" + user.display_name + "</span>"
                end
              rescue
              end
            end
          end
          if !@review.blank? and !user.email.blank?
            #puts "##############################"
            #puts @review
            #puts user.email
            UserMailer.deliver_notify(user.email, @subject, @review)
          end
        end
      end      
      
    elsif notification_type == "top_ten"
      @email = options[:email]
      @subject = options[:subject]
      @content = options[:content]
      begin
        UserMailer.deliver_notify(@email, @subject, @content)
      rescue
        puts "err msg"
      end
    end
  end

  def self.update_comingsoon_movie(taggable_type, tagger_type, taggable_id)
    trailer = Tagging.where("t2.taggable_type = '#{taggable_type}'").find(:all, :select => ["t2.tagger_id"], :joins => ["inner join taggings t2 on taggings.taggable_id = t2.taggable_id"], :conditions => ["lower(taggings.tagger_type)='#{tagger_type}' and taggings.taggable_id = #{taggable_id} and t2.tagger_id is not null"], :group => ["t2.tagger_id"]).first
    unless trailer.blank?
      unless trailer.tagger_id.blank?
        comingsoon_movie = Movie.find_by_id(trailer.tagger_id)
        unless comingsoon_movie.blank?
          if comingsoon_movie.release_date.blank?
            comingsoon_movie.update_attribute("media_updated_date", Time.now)
          elsif comingsoon_movie.release_date > Date.today
            comingsoon_movie.update_attribute("media_updated_date", Time.now)
          end
        end
      end
    end
  end



  def self.send_movie_celeb_email
    blocked_email = ['willis@penn-olson.com']
    @user = User.where("notify_movie_celeb = 1 and email IS NOT NULL and email NOT IN(?)", blocked_email).find(:all)
    unless @user.blank?
      @user.each do |user|
        movie_email = []
        celeb_email = []
        @subject = ""
        @content = ""

        movie_email = create_movie_email_content(user)
        celeb_email = create_celeb_email_content(user)


        if !movie_email[0].blank? or !celeb_email[0].blank?
          #@email = "anusuyanayak@gmail.com"          
          #@email = "tutestuser360@rediff.com"
          @email = user.email

          if !movie_email[1].blank?
            if @subject.blank?
              @subject = movie_email[1]
            end
          elsif !celeb_email[1].blank?
            if @subject.blank?
              @subject = celeb_email[1]
            end
          else
            @subject = "Hi"
          end


          @content = "Hi #{user.display_name},"
          @content += "<div style='font-family:arial;'><br/><span style='color:#F7600D'>Following are some latest updates in Bollywood last week that you may care about -</span><div style='clear:both'></div>"
          @content += movie_email[0]
          unless celeb_email[0].blank?
            @content += "<div class='clear' style='height:20px'></div>" + celeb_email[0]
          end
          @content += "<div class='clear' style='height:20px'></div>Click on the links above to see more details and leave a comment.<div style='clear:both;height:10px'></div><div style='color:#F7600D'>Regards, <br/>Your friends at Muvi</div></div>"

          unless @email.blank? and (!movie_email[1].blank? or !celeb_email[1].blank?)
             puts "___________________"
             puts @email
             puts @content
            begin
              UserMailer.deliver_notify(@email, @subject, @content)
            rescue
            end
          end
        end
      end
    end
  end

  def self.send_activity_email
    blocked_email = ['willis@penn-olson.com']
    @user = User.where("notify_activity = 1 and email IS NOT NULL and last_sign_in_at IS NOT NULL and email NOT IN(?)", blocked_email).find(:all, :select => ["*, date(last_sign_in_at) as last_sign_in_at"])
    

    unless @user.blank?
      @user.each do |user|        
        @connection_id = ""
        @connection = user.user_connection
        unless @connection.blank?
          @conn = ActiveSupport::JSON.decode(@connection.connections)
          unless @conn.blank?
            @conn.each do |conn|
              if @connection_id.blank?
                @connection_id = conn
              else
                @connection_id = @connection_id.to_s + "," + conn.to_s
              end
            end
          end
        end
  
        unless @connection_id.blank?
          movie_email = []
          celeb_email = []
          topten_email = []
          @subject = ""
          @content = ""
          @email = ""

          movie_email = create_conn_movie_email_content(user, :connection_id => @connection_id)
          celeb_email = create_conn_celeb_email_content(user, :connection_id => @connection_id)
          topten_email = create_conn_topten_email(user, :connection_id => @connection_id)

          if !movie_email[0].blank? or !celeb_email[0].blank? or !topten_email[0].blank?
            @email = user.email

            if !movie_email[1].blank?
              @subject = movie_email[1]
            elsif !celeb_email[1].blank?
              if @subject.blank?
                @subject = celeb_email[1]
              end
            elsif !topten_email[1].blank?
              if @subject.blank?  
                @subject = topten_email[1]
              end
            else
              @subject = "Hi"
            end


            @content = "Hi #{user.display_name},"
            @content += "<div style='font-family:arial;'><p><span style='color:#F7600D'>Following are the latest activities of your connections</span><div style='clear:both'></div>"

            unless movie_email[0].blank?
              @content += movie_email[0]
            end

            unless celeb_email[0].blank?
              @content += "<div class='clear' style='height:20px'></div>" + celeb_email[0]
            end
            unless topten_email[0].blank?
              @content += "<div class='clear' style='height:20px'></div>" + topten_email[0]
            end

            @content += "<div class='clear' style='height:20px'></div>Click on the links above to see more details and leave a comment.<div style='clear:both;height:10px'></div><div style='color:#F7600D'>Regards, <br/>Your friends at Muvi</div></div>"

            if !@email.blank? and (!movie_email[1].blank? or !celeb_email[1].blank? or !topten_email[1].blank?)
               #puts "___________________"
               #puts @email
               #puts @content
              begin
                puts @email
                UserMailer.deliver_notify(@email, @subject, @content)
                @email = nil
              rescue
              end
            end
          end
        end
      end
    end
  end


  def self.create_celeb_email_content(user, options = {})
        @total_email_content = "" 
        @email_celeb_tweet_content = []
        @email_news_content = []
        @email_video_content = []
        @email_poster_content = []
        @count_celeb_in_email = 0 #Max is 2
        @email_subject = ""
        @total_email_content_arr = []

        @celeb_array = Fan.where("user_id = #{user.id}").find(:all, :select => ["celebrity_id, created_at"], :order => ["created_at desc"])
        unless @celeb_array.blank?
          @celeb_array.each do |celeb_array|
            if @count_celeb_in_email == 2
              break
            end
            @celebrity = Celebrity.find_by_id(celeb_array.celebrity_id)
            unless @celebrity.blank?

              #Celebrity Tweets
              @email_celeb_tweet_content = get_celeb_tweet(user, celeb_array.celebrity_id, :connection_id => options[:connection_id])
              #Tweet ends

              #Add latest news for the movie
              @email_news_content = get_news(user, celeb_array.celebrity_id, 'Celebrity',"http://www.muvi.com/celebrities/#{@celebrity.permalink}#news")
              #News ends

              #Video
              @email_video_content = get_video(user, celeb_array.celebrity_id, 'Celebrity',:connection_id => options[:connection_id])
              #Video ends

              #Poster
              @email_poster_content = get_poster(user, celeb_array.celebrity_id, 'Celebrity',:connection_id => options[:connection_id])
              #Poster ends

            
              #compose the email subject
              if !@email_video_content[1].blank?
                if @email_subject.blank?
                  @email_subject = @email_video_content[1]
                end
              elsif !@email_poster_content[1].blank?
                if @email_subject.blank?
                  @email_subject = @email_poster_content[1]
                end
              elsif !@email_news_content[1].blank?
                if @email_subject.blank?
                  @email_subject = @email_news_content[1]
                end
              elsif !@email_celeb_tweet_content[1].blank?
                if @email_subject.blank?
                  @email_subject = @email_celeb_tweet_content[1]
                end
              end

              #compose the total email content
              if !@email_celeb_tweet_content[0].blank? or !@email_news_content[0].blank? or !@email_video_content[0].blank? or !@email_poster_content[0].blank?

                @count_celeb_in_email = @count_celeb_in_email + 1
                @total_email_content += "<div style='clear:both; height:10px;'></div><a style='text-decoration:none;color:#3A3A3A' href='http://www.muvi.com/celebrities/#{@celebrity.permalink}'><b>#{@celebrity.name}</b></a>"

                @total_email_content += @email_celeb_tweet_content[0] + @email_news_content[0] + @email_video_content[0] + @email_poster_content[0]

                @total_email_content += "<div style='clear:both'></div>"
              end
            end
          end # Fan loop ends
        end  # Blank check of fan ends
        @total_email_content_arr[0] = @total_email_content
        @total_email_content_arr[1] = @email_subject
        return @total_email_content_arr     
  end

  def self.create_movie_email_content(user, options = {})
    @total_email_content = ""
    @total_email_content_arr = []
    @email_news_content = []
    @email_video_content = []
    @email_poster_content = []
    @count_movie_in_email = 0 #Max is 2
    @email_subject = ""
    @total_email_content_arr = []

      @movie_array = WantToSee.where("user_id = #{user.id}").find(:all, :select => ["movie_id, created_at"], :order => ["created_at desc"])
      unless @movie_array.blank?
        @movie_array.each do |movie_array|
          if @count_movie_in_email == 2
            break
          end

          @movie = Movie.find_by_id(movie_array.movie_id)
          unless @movie.blank?

            #Add latest news for the movie
            @email_news_content = get_news(user, movie_array.movie_id, 'Movie',"http://www.muvi.com/movies/#{@movie.permalink}#news", :connection_id => options[:connection_id])
            #News ends
 
            #Video
            @email_video_content = get_video(user, movie_array.movie_id, 'Movie', :connection_id => options[:connection_id])
            #Video ends

            #Poster
            @email_poster_content = get_poster(user, movie_array.movie_id, 'Movie', :connection_id => options[:connection_id])
            #Poster ends
          

            #compose the email subject
            if !@email_video_content[1].blank?
              if @email_subject.blank?
                @email_subject = @email_video_content[1]
              end
            elsif !@email_poster_content[1].blank?
              if @email_subject.blank?
                @email_subject = @email_poster_content[1]
              end
            elsif !@email_news_content[1].blank?
              if @email_subject.blank?
                @email_subject = @email_news_content[1]
              end
            end

            #compose the total email content
            if !@email_news_content[0].blank? or !@email_video_content[0].blank? or !@email_poster_content[0].blank?

              @count_movie_in_email = @count_movie_in_email + 1
              @total_email_content += "<div style='clear:both; height:10px;'></div><a href='http://www.muvi.com/movies/#{@movie.permalink}' style='text-decoration:none;color:#3A3A3A'><b>#{@movie.name}</b></a>"

              if @movie.release_date <= Date.today
                @total_email_content += "<div style='clear:both;'></div>Muvimeter of <a href='http://www.muvi.com/movies/#{@movie.permalink}' style='text-decoration:none'>#{@movie.name}</a> is #{@movie.muvimeter}%. Click to check all critics and twitter reviews."
              end
              @total_email_content += @email_news_content[0] + @email_video_content[0] + @email_poster_content[0]        
  
              @total_email_content += "<div style='clear:both'></div>"
            end
          end
      end #want to see loop ends
    end # Blank check of want to see ends

    @total_email_content_arr[0] = @total_email_content
    @total_email_content_arr[1] = @email_subject 
    return @total_email_content_arr
  end


  def self.get_celeb_tweet(user, celebrity_id, options = {}) 
    @celeb_tweet_content = ""
    @celeb_tweet_content_arr = []
    @subject = ""

    @celebrity = Celebrity.find_by_id(celebrity_id)

    unless options[:connection_id].blank?
      @celeb_tweet = CelebTweet.where("date(created_at) > '#{(Date.today - 7)}' and celebrity_id = #{celebrity_id} and fan_tweet = 'f' and user_id NOT IN (#{user.id}) and user_id IN (#{options[:connection_id]})").find(:all)
    else
      @celeb_tweet = CelebTweet.where("date(created_at) > '#{(Date.today - 7)}' and celebrity_id = #{celebrity_id} and fan_tweet = 'f' and user_id NOT IN (#{user.id})").find(:all)
    end

    unless @celeb_tweet.blank?
      if @subject.blank?
        @subject = "New tweet from #{@celebrity.name} and more..."
      end
      @celeb_tweet_content = "<div class='clear'></div>#{@celeb_tweet.size} new <a style='text-decoration:none;color:#3F48CC' href='http://www.muvi.com/celebrities/#{@celebrity.permalink}#ui-tabs-1'>tweets</a>"
    end

    @celeb_tweet_content_arr[0] = @celeb_tweet_content
    @celeb_tweet_content_arr[1] = @subject
    return @celeb_tweet_content_arr
  end

  def self.get_fan(user, celebrity_id, options = {})
    @fan_content = ""
    @fan_content_arr = []
    @subject= ""

    @celebrity = Celebrity.find_by_id(celebrity_id)
    unless options[:connection_id].blank?
      @fan_next_two = Fan.where("date(created_at) >= '#{user.last_sign_in_at}' and user_id NOT IN (#{user.id}) and user_id IN (#{options[:connection_id]}) and celebrity_id = #{celebrity_id}").find(:all, :select => ["user_id"], :limit => 2, :order => ["created_at desc"])
      unless @fan_next_two
        @fan_next_two = Fan.where("date(created_at) >= '#{Date.today - 1}' and user_id NOT IN (#{user.id}) and user_id IN (#{options[:connection_id]}) and celebrity_id = #{celebrity_id}").find(:all, :select => ["user_id"], :limit => 2, :order => ["created_at desc"])
      end
    else
      @fan_next_two = Fan.where("date(created_at) > '#{(Date.today - 7)}' and user_id NOT IN (#{user.id}) and celebrity_id = #{celebrity_id}").find(:all, :select => ["user_id"], :limit => 2, :order => ["created_at desc"])
    end

    unless @fan_next_two.blank?
      user_1 = ""
      user_2 = ""
      u_1 = User.find_by_id(@fan_next_two[0].user_id)
      user_1 = "<a style='text-decoration:none;color:#3F48CC' href='http://www.muvi.com/profile/#{u_1.id}/#{u_1.display_name}'>#{u_1.display_name}</a>"

      if @fan_next_two.size > 1
        u_2 = User.find_by_id(@fan_next_two[1].user_id)
        user_2 = "<a style='text-decoration:none;color:#3F48CC' href='http://www.muvi.com/profile/#{u_2.id}/#{u_2.display_name}'>#{u_2.display_name}</a>"
      end

      unless user_1.blank?
        if @subject.blank?
          @subject = u_1.display_name + " became a fan of #{@celebrity.name} and more..."
        end
        @fan_content += "<div class='clear'></div>#{user_1}"
      end
      unless user_2.blank?
        @fan_content += " and " + user_2
      end

      if user_1 != "" or user_2 != ""
        @fan_content += " became fans."
      end
    end
    @fan_content_arr[0] = @fan_content
    @fan_content_arr[1] = @subject
    return @fan_content_arr
  end

  def self.get_user_review(user, movie_id, options = {})
    @review_content = ""
    @review_content_arr = []
    @subject = ""
    unless options[:connection_id].blank?
      @review = Review.where("date(created_at) >= '#{user.last_sign_in_at}' and user_id NOT IN (#{user.id}) and user_id IN (#{options[:connection_id]}) and movie_id=#{movie_id}").find(:all, :select => ["user_id"], :limit => 2, :group => ["user_id"])
      unless @review
        @review = Review.where("date(created_at) >= '#{Date.today - 1}' and user_id NOT IN (#{user.id}) and user_id IN (#{options[:connection_id]}) and movie_id=#{movie_id}").find(:all, :select => ["user_id"], :limit => 2, :group => ["user_id"])
      end
    else
      @review = Review.where("date(created_at) > '#{(Date.today - 7)}' and user_id NOT IN (#{user.id}) and movie_id=#{movie_id}").find(:all, :select => ["user_id"], :limit => 2, :group => ["user_id"])
    end

    unless @review.blank?
      user_1 = ""
      user_2 = ""

      u_1 = UserProfile.find_by_user_id(@review[0].user_id)
      user_1 = "<a style='text-decoration:none;color:#3F48CC' href='http://www.muvi.com/profile/#{u_1.user_id}/#{u_1.display_name}'>#{u_1.display_name}</a>"

      if @review.size > 1
        u_2 = UserProfile.find_by_user_id(@review[1].user_id)
        user_2 = "<a style='text-decoration:none;color:#3F48CC' href='http://www.muvi.com/profile/#{u_2.user_id}/#{u_2.display_name}'>#{u_2.display_name}</a>"
      end
      unless u_1.blank?
        if @subject.blank?
          @subject = u_1.display_name + " added rating and more..."
        end
        @review_content += "<div class='clear'></div>#{user_1}"
      end

      unless u_2.blank?
        @review_content += " and " + user_2
      end

      if user_1 != "" or user_2 != ""
        @review_content += " added rating."
      end
    end
    @review_content_arr[0] = @review_content
    @review_content_arr[1] = @subject
    return @review_content_arr
  end

  def self.get_next_want_to_see(user, movie_id, options = {})
    @next_want_to_see_content = ""
    @next_want_to_see_content_arr = []
    @subject = ""
    @want_to_see_next = ""
    
    @want_to_see_next = WantToSee.where("date(created_at) >= '#{user.last_sign_in_at}' and user_id NOT IN (#{user.id}) and user_id IN (#{options[:connection_id]}) and movie_id = #{movie_id}").find(:all, :select => ["user_id"], :order => ["created_at desc"]).first
    unless @want_to_see_next
      @want_to_see_next = WantToSee.where("date(created_at) >= '#{Date.today - 1}' and user_id NOT IN (#{user.id}) and user_id IN (#{options[:connection_id]}) and movie_id = #{movie_id}").find(:all, :select => ["user_id"], :order => ["created_at desc"]).first
    end

    unless @want_to_see_next.blank?
      next_user_want_to_see = User.find_by_id(@want_to_see_next.user_id)
      unless next_user_want_to_see.blank?
        if @subject.blank?
          @subject = next_user_want_to_see.display_name + " wants to see and more."
        end
        @next_want_to_see_content = "<div style='clear:both'></div><a style='text-decoration:none;color:#3F48CC' href='http://www.muvi.com/profile/#{next_user_want_to_see.id}/#{next_user_want_to_see.display_name}'>#{next_user_want_to_see.display_name} </a> wants to see."
      end
    end
    @next_want_to_see_content_arr[0] = @next_want_to_see_content
    @next_want_to_see_content_arr[1] = @subject
    return @next_want_to_see_content_arr
  end

  def self.get_news(user, tagger_id, tagger_type, link, options = {})
    @news_content = ""
    @news_content_arr = []
    @subject = ""
    news = "" 
    unless options[:connection_id].blank?
      news = Tagging.where("date(created_at) >= '#{Date.today - 1}' and taggable_type = 'Feed' and tagger_type = '#{tagger_type}' and tagger_id = #{tagger_id} and taggable_id IS NOT NULL").find(:first, :select => ["id, taggable_id"], :order => ["created_at desc"])
    else
      news = Tagging.where("date(created_at) > '#{(Date.today - 7)}' and taggable_type = 'Feed' and tagger_type = '#{tagger_type}' and tagger_id = #{tagger_id} and taggable_id IS NOT NULL").find(:all, :select => ["id, taggable_id"], :order => ["created_at desc"])
    end

    unless news.blank?
      begin
        feed = Feed.find_by_id(news[0].taggable_id, :select => ["entry_title, entry_url"])
        unless feed.blank?
          @news_content += "<div class='clear'></div><a style='text-decoration:none;color:#3F48CC' href='#{link}'>#{feed.entry_title}</a>"
          if news.size.to_i > 1
            @news_content += " and #{news.size.to_i - 1} other latest news."
          end
          if @subject.blank?
            @subject = "New news and more..."
          end
        end
      rescue
      end
    end
    @news_content_arr[0] = @news_content
    @news_content_arr[1] = @subject
    return @news_content_arr
  end

  def self.get_poster(user, tagger_id, tagger_type, options = {})
    @poster_content = ""
    @poster_content_arr  = []
    @subject = ""

    if tagger_type == "Movie"
      @name = Movie.find_by_id(tagger_id)
      @link_path = "movies"
      poster_condition = "lower(taggings.tagger_type)='poster' and t2.tagger_id = #{tagger_id} and t2.tagger_type = 'Movie'"

   elsif tagger_type == "Celebrity"
      @name = Celebrity.find_by_id(tagger_id)
      @link_path = "celebrities"
      poster_condition = "t2.tagger_id = #{tagger_id} and t2.tagger_type = 'Celebrity'"
   end
   @posterlink = "http://www.muvi.com/#{@link_path}/#{@name.permalink}#poster"
   
   poster = Tagging.where("date(t2.created_at) > '#{(Date.today - 7)}' and t2.taggable_type = 'Poster'").find(:all, :select => ["t2.tagger_id"], :joins => ["inner join taggings t2 on taggings.taggable_id = t2.taggable_id"], :conditions => ["#{poster_condition}"], :group => ["t2.tagger_id, t2.created_at"], :order => ["t2.created_at desc"])

   @total_poster = 0

    unless poster.blank?
      @total_poster = poster.size.to_i
    end

    if @total_poster.to_i > 0
      if @subject.blank?
        @subject = "New poster added for #{@name.name} and more..."
      end
      @poster_content = "<div class='clear'></div>#{@total_poster} new <a style='text-decoration:none;color:#3F48CC' href='#{@posterlink}'>posters</a>"
    end
    @poster_content_arr[0] = @poster_content
    @poster_content_arr[1] = @subject
    return @poster_content_arr
  end

  def self.get_video(user, tagger_id, tagger_type, options = {})
    @video_content = ""
    @video_content_arr  = []
    @subject = ""

    if tagger_type == "Movie"
      @name = Movie.find_by_id(tagger_id)
      @link_path = "movies"
      video_condition = "lower(taggings.tagger_type)='trailer' and t2.tagger_id = #{tagger_id} and t2.tagger_type = 'Movie'"

   elsif tagger_type == "Celebrity"
      @name = Celebrity.find_by_id(tagger_id)
      @link_path = "celebrities"
      video_condition = "t2.tagger_id = #{tagger_id} and t2.tagger_type = 'Celebrity'"
   end

   @videolink = "http://www.muvi.com/#{@link_path}/#{@name.permalink}#video"

   trailer = Tagging.where("date(t2.created_at) > '#{(Date.today - 7)}' and t2.taggable_type = 'Video'").find(:all, :select => ["t2.tagger_id"], :joins => ["inner join taggings t2 on taggings.taggable_id = t2.taggable_id"], :conditions => ["#{video_condition}"], :group => ["t2.tagger_id, t2.created_at"], :order => ["t2.created_at desc"])


    @total_video = 0
    unless trailer.blank?
      @total_video = trailer.size.to_i
    end


    if @total_video_poster.to_i > 0
      if @subject.blank?
        @subject = "New trailer added for #{@name.name} and more..."
      end
      @video_content = "<div class='clear'></div>#{@total_video} new <a style='text-decoration:none;color:#3F48CC' href='#{@videolink}'>trailers</a>"
    end
    @video_content_arr[0] = @video_content
    @video_content_arr[1] = @subject
    return @video_content_arr
  end

  def self.create_conn_movie_email_content(user, options = {})
    @total_email_content = ""
    @total_email_content_arr = []
    @email_review_content = []
    @email_next_want_to_see_content = []
    @email_video_poster_like_content = []
    @count_conn_movie_in_email = 0 #Max is 2
    @email_subject = ""
    @total_email_content_arr = []

    unless options[:connection_id].blank?
      @movie_array = Activity.where("secondary_subject_type = 'Movie' and user_id NOT IN (#{user.id}) and user_id in (#{options[:connection_id]})").find(:all, :select => ["secondary_subject_id as movie_id, count(*) as activity_count"], :group => ["secondary_subject_id"], :order => ["activity_count desc"])
    end
    
      unless @movie_array.blank?
          @movie_array.each do |movie_array|
          if @count_conn_movie_in_email == 2
            break
          end
	
          @movie = Movie.find_by_id(movie_array.movie_id)
          unless @movie.blank?
            #Add Rating/Review
            @email_review_content = get_user_review(user, movie_array.movie_id, :connection_id => options[:connection_id])
            #Rating/Review ends

            #Add another one want to see
            @email_next_want_to_see_content = get_next_want_to_see(user, movie_array.movie_id, :connection_id => options[:connection_id])
            #want to see ends


            #Video and poster
            @email_video_poster_like_content = get_video_poster_like(user, movie_array.movie_id, 'Movie', :connection_id => options[:connection_id])

            #Video and poster ends

            #compose the email subject
            if @email_next_want_to_see_content[1].blank?
              @email_subject = @email_next_want_to_see_content[1]

            elsif !@email_review_content[1].blank?
              @email_subject = @email_review_content[1]

            elsif !@email_video_poster_like_content[1].blank?
              @email_subject = @email_video_poster_like_content[1]      

            end

            #compose the total email content
            if !@email_review_content[0].blank? or !@email_next_want_to_see_content[0].blank? or !@video_poster_like_content[0].blank?
              @total_email_content += "<div style='clear:both; height:10px;'></div><a style='text-decoration:none;color:#3A3A3A' href='http://www.muvi.com/movies/#{@movie.permalink}'><b>#{@movie.name}</b></a>"
              @count_conn_movie_in_email = @count_conn_movie_in_email + 1
              @total_email_content += @email_review_content[0] + @email_next_want_to_see_content[0] + @email_video_poster_like_content[0]
        
              @total_email_content += "<div style='clear:both'></div>"
            end

          end
      end #want to see loop ends
    end # Blank check of want to see ends


    @total_email_content_arr[0] = @total_email_content
    @total_email_content_arr[1] = @email_subject
    return @total_email_content_arr
  end

  def self.create_conn_celeb_email_content(user, options = {})
    @total_email_content = ""
    @email_fan_content = ""
    @count_conn_celeb_in_email = 0 #Max is 2
    @email_subject = ""
    @total_email_content_arr = []

    @celeb_array = Activity.where("secondary_subject_type = 'Celebrity' and user_id NOT IN (#{user.id}) and user_id in (#{options[:connection_id]})").find(:all, :select => ["secondary_subject_id as celebrity_id, count(*) as activity_count"], :group => ["secondary_subject_id, created_at"], :order => ["activity_count desc, created_at desc"])

    unless @celeb_array.blank?
      @celeb_array.each do |celeb_array|
        if @count_conn_celeb_in_email == 2
            break
        end
        @celebrity = Celebrity.find_by_id(celeb_array.celebrity_id)
        unless @celebrity.blank?
          #Add fan content
          @email_fan_content = get_fan(user, celeb_array.celebrity_id, :connection_id => options[:connection_id])
          #Fan ends
        end

        #compose the email subject
        if !@email_fan_content[1].blank?
          if @email_subject.blank?
            @email_subject = @email_fan_content[1]
          end
        end

        #compose the total email content
        if !@email_fan_content[0].blank?
          @total_email_content += "<div style='clear:both; height:10px;'></div><a style='text-decoration:none;color:#3A3A3A' href='http://www.muvi.com/celebrities/#{@celebrity.permalink}'><b>#{@celebrity.name}</b></a>"
          @count_conn_celeb_in_email = @count_conn_celeb_in_email + 1

          @total_email_content += @email_fan_content[0]
          @total_email_content +=  "<div style='clear:both'></div>"
        end

      end
    end

    @total_email_content_arr[0] = @total_email_content
    @total_email_content_arr[1] = @email_subject
    return @total_email_content_arr
  end

  def self.get_video_poster_like(user, tagger_id, tagger_type, options = {})
    @video_poster_like_content = ""
    @video_poster_like_content_arr  = []
    @subject = ""
    @video_id = ""

    if tagger_type == "Movie"
      @name = Movie.find_by_id(tagger_id)
      @link_path = "movies"
    elsif tagger_type == "Celebrity"
      @name = Celebrity.find_by_id(tagger_id)
      @link_path = "celebrities"
    end

    @video = Tagging.where("tagger_id = #{tagger_id} and taggable_type = 'Video'").find(:all, :select => ["taggable_id"], :order => ["created_at desc"])
    unless @video.blank?
      @video.each do |video|
        if @video_id.blank?
          @video_id = video.taggable_id.to_s
        else
          @video_id += @video_id.to_s + "," + video.taggable_id.to_s
        end        
      end

      @get_like = Vote.where("date(created_at) >= '#{user.last_sign_in_at}' and voter_id IN (#{options[:connection_id]}) and votable_type = 'Video' and votable_id IN(#{@video_id})").find(:first, :select => ["votable_id, voter_id"], :order => ["created_at desc"])
      unless @get_like
        @get_like = Vote.where("date(created_at) >= '#{Date.today - 1}' and voter_id IN (#{options[:connection_id]}) and votable_type = 'Video' and votable_id IN(#{@video_id})").find(:first, :select => ["votable_id, voter_id"], :order => ["created_at desc"])
      end

      unless @get_like.blank?
        user = User.find_by_id(@get_like.voter_id)
        video_name = Video.find(@get_like.votable_id, :select => ["name"])
        unless user.blank?
          if @subject.blank?
            @subject = user.display_name + " likes #{video_name.name}"
          end
          user_1 = "<a href='http://www.muvi.com/profile/#{user.id}/#{user.display_name}' style='text-decoration:none;color:#3F48CC'>#{user.display_name}</a>"
          @video_poster_like_content = "<div class='clear'></div>#{user_1} likes <a style ='text-decoration:none;color:#3F48CC;' href='http://www.muvi.com/#{@link_path}/#{@name.permalink}#video'>#{video_name.name}</a>"
        end
      end
    end    
    @video_poster_like_content_arr[0] = @video_poster_like_content
    @video_poster_like_content_arr[1] = @subject
    return @video_poster_like_content_arr
  end

  def self.create_conn_topten_email(user, options = {})
    @total_email_content = ""
    @email_topten_content = ""
    @count_topten_in_email = 0 #Max is 2
    @email_subject = ""
    @total_email_content_arr = []

    @top_ten = TopTen.where("user_id IN (#{options[:connection_id]}) and user_id != 0 and date(updated_at) >= '#{user.last_sign_in_at}'").find(:all, :limit => ["2"])
    unless @top_ten
      @top_ten = TopTen.where("user_id IN (#{options[:connection_id]}) and user_id != 0 and date(updated_at) >= '#{Date.today - 1}'").find(:first, :limit => ["2"])
    end

    unless @top_ten.blank?
      @top_ten.each do |top_ten|
        user = User.find_by_id(top_ten.user_id)
        unless user.blank?
          if @email_subject.blank?
            @email_subject = user.display_name + " added a top 10 #{top_ten.name}"
          end
          user_1 = "<a href='http://www.muvi.com/profile/#{user.id}/#{user.display_name}' style='text-decoration:none;color:#3F48CC'>#{user.display_name}</a>"
          @email_topten_content += "<div class='clear'></div>#{user_1} added a top 10 <a style ='text-decoration:none;color:#3F48CC' href='http://www.muvi.com/top_ten/#{top_ten.id}/#{top_ten.name}'>#{top_ten.name}</a>"
        end
      end
      #compose the total email content
      if !@email_topten_content[0].blank?
        @total_email_content += "<div style='clear:both; height:10px;'></div><a href='http://www.muvi.com/top_ten' style='text-decoration:none;color:#3A3A3A'><b>Top 10</b></a>"

        @total_email_content += @email_topten_content

        @total_email_content += "<div style='clear:both'></div>"
      end
    end
    @total_email_content_arr[0] = @total_email_content
    @total_email_content_arr[1] = @email_subject
    return @total_email_content_arr
  end

  def self.get_language(params, cookies)
    lang = ""
    unless params[:lang].blank?
      if params[:lang].scan(",")
        l = params[:lang].split(",")
        for i in 0..(l.size)
          unless l[i].blank?
            lang += "'#{l[i]},'"
          end
        end
      end
    else
      if cookies[:hindi] == "yes"
        lang = "'hindi',"
      end
      if cookies[:english] == "yes"
        lang += "'english',"
      end
      if cookies[:tamil] == "yes"
        lang += "'tamil',"
      end
      if cookies[:telugu] == "yes"
        lang += "'telugu',"
      end
      if lang.scan(",")
        lang = lang.chop
      end
    end
    return lang
  end

  def self.get_in_theaters(params, cookies)
    movie_language = Movie.get_language(params, cookies)
    if movie_language.blank?
      movie_language = "'hindi'"
    end
    @movies = Movie.latest.released.where("lower(language) IN (#{movie_language})").order("release_date desc").limit("5").search
    return @movies
  end

  def self.get_upcoming(params, cookies)
    movie_language = Movie.get_language(params, cookies)
    if movie_language.blank?
      movie_language = "'hindi'"
    end

    @movies = Movie.comming_soon_movies.where("lower(language) IN (#{movie_language}) and release_date > ?", (Date.today)).order("release_date asc nulls last").limit("5").search
    return @movies
  end

  def self.get_related_movies(movie_id)
    @movies = []
    @movie = Movie.select("related_movies").find_using_id(movie_id).first
    unless @movie.blank?
      if !@movie.related_movies.blank?
        @related_movies =  ActiveSupport::JSON.decode(@movie.related_movies)
        @related_movies.each do |related_movie|
          if related_movie['id'].to_i != 0
            @movies << Movie.find_by_id(related_movie['id'].to_i)
          end
        end
      return @movies
      end
    end
  end
  def self.set_related_movie(main_movie)
    @related_movies =  ActiveSupport::JSON.decode(main_movie.related_movies)
    @related_movies.each do |movie|
      items = []
      ctr = 0
      new_item = true
      m = Movie.find_by_id(movie['id'])
      if !m.related_movies.blank?
        related_movies =  ActiveSupport::JSON.decode(m.related_movies)
        related_movies.each do |r|
          item = {}
          if r['id'].to_i == main_movie.id.to_i
            new_item = false
          end
          item['id'] = r['id']
          item['type'] =  r['type']
          items << item
          ctr += 1
        end
      end
      if new_item == true
          item = {}
          item['id'] = main_movie.id
          item['type'] = "Sequel"
          items << item
      end
      m.related_movies = items.to_json
      m.save
    end
  end

  def self.fm_like_dislike(label,user_id, flag)
    movie_like_dislike = ""
    if flag == "true"
      movie_user_reviews = Review.where("user_id = #{user_id} and description != '' and rating >= 3").find(:all, :order => ["created_at desc"], :limit => [2])
    else
      movie_user_reviews = Review.where("user_id = #{user_id} and description != '' and rating < 3").find(:all, :order => ["created_at desc"], :limit => [2])
    end

    movie_user_reviews.each do |like|
      movie = Movie.find_by_id(like.movie_id)
      if movie_like_dislike.blank?
        movie_like_dislike = label + " <a href='/movies/#{movie.permalink}'>#{movie.name}</a>"
      else
        movie_like_dislike += ", <a href='/movies/#{movie.permalink}'>#{movie.name}</a>".html_safe
      end
    end
    return movie_like_dislike.html_safe
  end

  def self.fetch_wiki(wiki_url, year, month, day)
    wiki_url = wiki_url.split('/')[-1]
    wiki = ActiveSupport::JSON.decode(open("http://stats.grok.se/json/en/#{year}#{month}/#{URI.escape(wiki_url).to_s}"))
    return wiki["daily_views"].as_json["#{year}-#{month}-#{day}"]
  end
  def self.wikiviews_extract()
    time = Date.today - 1.day
    Movie.where("wiki_link like '%wikipedia%' and wiki_link not like '%redlink=1%'").each do |movie|
      if movie.release_date.blank? or movie.release_date > Date.today
        wk_count=fetch_wiki(URI.escape(movie.wiki_link),time.strftime("%Y").to_s, time.strftime("%m").to_s, time.strftime("%d").to_s)
        movie.update_attribute(:wiki_views, wk_count)
        puts movie.name
      end
    end
  end

  def self.add_movie_overview
    all_movie = HollywoodMovie.where("id > 61590").find(:all, :order => ["id desc"])

    all_movie.each do |m|

      unless m.overview.blank? and m.overview != 'No overview found'
       chk_movie = Movie.find_by_name("#{m.name}")
       unless chk_movie.blank?
         #if chk_movie.story.blank?
           chk_movie.story = m.overview
           chk_movie.save
		 puts m.id
                 puts chk_movie.name
                 puts m.overview
		 #return
         #end
       end
      end
    end
  end
   
end

