class Feed < ActiveRecord::Base
  require 'feedzirra'
  acts_as_commentable
  acts_as_taggable
  acts_as_taggable_on :feeds
  validates_presence_of :entry_title
  acts_as_votable
  has_many :like_votes, :conditions => [ "vote_flag = ?", 'true' ], :dependent => :destroy, :class_name => 'Vote',:foreign_key => "votable_id"
  has_many :dislike_votes, :conditions => [ "vote_flag = ?", 'false' ], :dependent => :destroy, :class_name => 'Vote',:foreign_key => "votable_id"

  def self.get_feeds
    @feed_url_arr = [
                     "http://www.bollywood-stars.net/feed/",
                     "http://www.indiaglitz.com/channels/hindi/rss/news-rss.xml",
                     "http://timesofindia.indiatimes.com/rssfeeds/4724967.cms",
                     "http://in.news.yahoo.com/rss/bollywood",
                     "http://www.aaj.tv/entertainment/film/feed/",
                     "http://www.indiatvnews.com/rssfeed/masala_bollywood_news.php",
                     "http://feeds.feedburner.com/oneindia-entertainment-bollywood",
                     "http://www.bollywoodlife.com/feed/",
                     "http://www.indiafm.com/rss/news.xml",
                     "http://www.glamsham.com/rss/glamRss.xml",
                     "http://www.tmz.com/rss.xml",
                     "http://www.hollywoodlife.com/feed/",
                     "http://feeds.feedburner.com/comingsoonnet30",
                     "http://www.manatelugumovies.net/feeds/posts/default",
                     "http://teluguone.com/tmdb/rss_news.xml",
                     "http://teluguone.com/tmdb/rss_gossip.xml",
                     "http://www.galatta.com/entertainment/rss/telugu.xml",
                     "http://www.galatta.com/entertainment/rss/tamil.xml",
                     "http://feedproxy.google.com/oneindia-entertainment-tamilmovies",
                     "http://feedproxy.google.com/oneindia-entertainment-telugumovies",
                     "http://www.nextmovie.com/feed/",
                     "http://www.thewrap.com/rss/latest",
                     "http://feeds.feedburner.com/thr/news",
                     "http://feeds.eonline.com/eonline/movienews" 
                    ]

    @feed_source = [
                    "Bollywood Stars",
                    "IndiaGlitz",
                    "TimesOfIndia",
                    "Yahoo India",
                    "Aajtak",
                    "India TV",
                    "OneIndia",
                    "Bollywood Life",
                    "Bollywood Hungama",
                    "Glamsham",
                    "TMZ",
                    "Hollywood Life",
                    "ComingSoon.Net",
                    "ManaTeluguMovies",
                    "TeluguOne",
                    "TeluguOne Gossip",
                    "Galatta Telugu",
                    "Galatta Tamil",
                    "OneIndia Tamil",
                    "OneIndia Telugu",
                    "NextMovie",
                    "The Wrap",
                    "Hollywood Reporter",
                    "E Online"
                   ]
    @feed_count = 0
    @feed_url_arr.each do |feed_fetch_url|
      feed =  Feedzirra::Feed.fetch_and_parse(feed_fetch_url)
      #entry = feed.entries.first
      unless feed.blank?
       begin
        feed.entries.each do |entry|
          @feed_data = Feed.new
          @feed_data.feed_title=feed.title
          @feed_data.url = feed.url
          @feed_data.feed_url = feed.feed_url
          @feed_data.etag = feed.etag
          @feed_data.last_modified = feed.last_modified
  
          @feed_data.entry_title = entry.title      
          @feed_data.entry_url = entry.url        
          @feed_data.author = entry.author     
          @feed_data.summary = entry.summary   
          @feed_data.content = entry.content   
          @feed_data.published = entry.published
          @feed_data.categories = entry.categories 

          @tag_list = ""
        
          @movie = Movie.where("release_date >= ? or release_date > ?  or release_date IS NULL", (Date.today - 30).to_s, (Date.today + 2)).find(:all,:select => ["id, name"], :order => ["id desc"])
          @movie.each do |movie|
            a = entry.title
            b = movie.name
    
            begin
              if a =~ /\b#{b}\b/
              #if (entry.categories.include?movie.name) or (a =~ /#{b} /) or (a =~ / #{b}/) or (a =~ / #{b} /)
                if @tag_list == ""
                  @tag_list << movie.name
                else
                  @tag_list = @tag_list + ","+movie.name
                end  
              end
            rescue Exception => exc
             #puts "MMMMMMMM"
             #puts exc.message
           end
          end
  
          @celebrity = Celebrity.find(:all, :select => ["id, name"], :conditions => ["name != '' and is_dictionary_word = 'f'"], :order => ["id desc"])
          @celebrity.each do |celeb|
            a = entry.title
            b = celeb.name
         
            begin
              if a =~ /\b#{b}\b/
              #if (entry.categories.include?celeb.name) or (a =~ /#{b} /) or (a =~ / #{b}/) or (a =~ / #{b} /)
                if @tag_list == ""
                  @tag_list = celeb.name
                else
                  @tag_list = @tag_list + ","+celeb.name
                end
              end
            rescue Exception => exc
             #puts "#####################"
             #puts exc.message
           end
          end


          @feed_data.tag_list = @tag_list
          @feed_data.source = @feed_source[@feed_count]
  
          # Duplicate check
          begin
            @duplicate = Feed.find(:all, :select => ["id"],:conditions => [" feed_title = '#{feed.title}' and url = '#{feed.url}' and feed_url = '#{feed.feed_url}' and entry_url = '#{entry.url}'"])
          rescue
          end
        
          if @duplicate.nil? or (@duplicate.size == 0)
            begin
              if @feed_data.save        
                @count = 0       
                @feed_data.taggings.order("id asc").each do |t|
                  if @count == 0
                    t.update_attribute("default_tag","true")
                  end
                  #t.update_attributes(:tagger_id => @taggable_id[@count], :tagger_type => @taggable_type[@count])
                  tagname = Tag.find_by_id(t.tag_id)
                  @movie = Movie.find_by_name(tagname.name)
                  unless @movie.blank?
                   t.update_attributes(:tagger_id => @movie.id, :tagger_type => "Movie")
                  end
                  @celebrity = Celebrity.find_by_name(tagname.name)
                  unless @celebrity.blank?
                    t.update_attributes(:tagger_id => @celebrity.id, :tagger_type => "Celebrity")
                  end

                  @count = @count + 1
                end         
              end
            rescue
            end
          end
        end
       rescue Exception => exc
         #puts "______________________"
         #puts exc.message
       end
      end
      @feed_count = @feed_count + 1
    end
  end
 
  def self.get_news_feed(feed_id)
    @feed = Feed.find_by_id(feed_id)
    return @feed
  end

end
