class TopTen < ActiveRecord::Base
  belongs_to :user
  validates :name, :presence => true
  after_create :log_activity
  after_create :post_to_wall

  def self.find_for_sitemap
    TopTen.find(:all, :conditions => ["rank != 0"], :order => "id")
  end

  def log_activity
    @activity = Activity.new
    @activity.user_id = self.user_id
    @activity.subject_id = self.id
    @activity.subject_type = "TopTen"
    if self.item_type == 0
      @activity.secondary_subject_id = TopTen.last_item(self.id).id
      @activity.secondary_subject_type = "Movie"
    elsif self.item_type == 1
      @activity.secondary_subject_id = TopTen.last_item(self.id).id
      @activity.secondary_subject_type = "Celebrity"
    end
    @activity.action = "<a href='/profile/#{self.user_id}/#{self.user.display_name}'>#{self.user.display_name}</a> added Top 10 <a href='/top_ten/#{self.id}/#{self.name}'>#{self.name}</a>."
    @activity.save
  end
  def self.get_top_ten_items(id)
    items = []
    topten = find(id)
    unless topten.blank?
      tenitems =  ActiveSupport::JSON.decode(topten.items)
      tenitems['items'].each do |item|
       if item['id'] != 0
         if !items.include?(item['id'])
          items << item['id']
         end
       end
      end
    end
    return items
  end

  def self.get_top_ten_item_notes(id)
    notes = []
    topten = find(id)
    unless topten.blank?
      tenitems =  ActiveSupport::JSON.decode(topten.items)
      tenitems['items'].each do |item|
       if item['id'] != 0
         if !notes.include?(item['id'])
          notes << item['notes']
         end
       end
      end
    end
    return notes
  end
  
  def self.get_top_ten_by_muvimeter(need_last = false, release_year='',genre='all', celebrity='all', limit = 10,cookies)
   items = []
   release_year = release_year.to_s
   if release_year == ''
    #release_year = '2011'
    release_year = Time.now.year
   end
   
   if release_year == 'Any' 
     start_date = get_lowest_release_date.to_s
     end_date = "#{Time.new.year}-12-31"
   #elsif release_year == '2011'
   #  start_date = "#{release_year}-01-01"
   #  end_date = "#{release_year}-12-31"
   #elsif release_year == '2010'
   #  start_date = "#{release_year}-01-01"
   #  end_date = "#{release_year}-12-31"
   #elsif release_year == '2009'
   #  start_date = "#{release_year}-01-01"
   #  end_date = "#{release_year}-12-31"
   elsif release_year == '2000s'
     start_date = "2000-01-01"
     end_date = "2009-12-31"
   elsif release_year == '1990s'
     start_date = "1990-01-01"
     end_date = "1999-12-31"
   elsif release_year == '1980s'
     start_date = "1980-01-01"
     end_date = "1989-12-31"
   elsif release_year == '1970s'
     start_date = "1970-01-01"
     end_date = "1979-12-31"
   elsif release_year == 'Before 1970s'
     start_date = get_lowest_release_date.to_s
     end_date = "1969-12-31"
   else
     start_date = "#{release_year}-01-01"
     end_date = "#{release_year}-12-31"
   end
   lang_filter = ""
   if cookies[:hindi] == "yes" 
      lang_filter += " language = 'Hindi' OR " 
   end  
   if cookies[:english] == "yes"
      lang_filter += " language = 'English' OR "
   end
   if cookies[:tamil] == "yes"
      lang_filter += " language = 'Tamil' OR "
   end
   if cookies[:telugu] == "yes"
      lang_filter += " language = 'Telugu' OR "
   end
   if lang_filter != ""
      lang_filter = lang_filter[0..lang_filter.length - 4]     
   end

   if celebrity != 'all'
    topten = MovieCast.find_by_sql("SELECT movie_id as id  FROM movie_casts JOIN films ON movie_casts.movie_id = films.id  WHERE celebrity_id = #{celebrity}  AND films.release_date between  '#{start_date.to_date}' and  '#{end_date.to_date}' AND release_date <= '#{Date.today}' order by muvimeter DESC LIMIT 10")
   elsif genre == 'all'
     topten = Movie.select("id, muvimeter").where(:release_date =>(start_date.to_date)...(end_date.to_date)).where("release_date <= ? AND muvimeter IS NOT NULL AND (#{lang_filter})", Date.today).order('muvimeter DESC').limit(limit)
   else
     topten = Movie.select("id, muvimeter").where(:release_date =>(start_date.to_date)...(end_date.to_date), :genre => genre).where("release_date <= ? AND muvimeter IS NOT NULL AND (#{lang_filter})", Date.today).order('muvimeter DESC').limit(limit)
   end
   
   unless topten.blank?  
     topten.each do |item|
      items << item[:id]
     end
     if need_last == true
       return  Movie.find(items.last)
     end
   end
   return items
  end
  
  def self.get_top_ten_upcoming_by_tweets(need_last = false,cookies)
   items = []
   lang_filter = ""
   if cookies[:hindi] == "yes"
      lang_filter += " language = 'Hindi' OR "
   end
   if cookies[:english] == "yes"
      lang_filter += " language = 'English' OR "
   end
   if cookies[:tamil] == "yes"
      lang_filter += " language = 'Tamil' OR "
   end
   if cookies[:telugu] == "yes"
      lang_filter += " language = 'Telugu' OR "
   end
   if lang_filter != ""
      lang_filter = lang_filter[0..lang_filter.length - 4]
   end

   #topten = Movie.select("id, tweet_percent").where("release_date > ? AND (#{lang_filter})", Date.today).order('tweet_percent desc nulls last').limit(10)
   topten = Movie.select("id, muvimeter").where("release_date > ? AND (#{lang_filter})", Date.today).order('muvimeter desc nulls last').limit(10)

   topten.each do |item|
    items << item[:id]
   end
   if need_last == true
     return  Movie.find_by_id(items.last)
   end
   return items
  end
  
  def self.display_name(user_id)
    user = UserProfile.find_by_user_id(user_id)
    return user.blank? ? '' : user.display_name
  end
  def self.get_lowest_release_date
     first_date = Movie.where("release_date IS NOT NULL").order("release_date ASC").limit(1)
     first_date.each do |date|
      return date.release_date
     end
  end
  def self.last_item(id)
    topten = find(id)
    unless topten.blank?
      items =  ActiveSupport::JSON.decode(topten.items)
    end
    if topten.item_type == 0
      return  Movie.find(items['items'].last['id'])
    elsif topten.item_type == 1 
     return Celebrity.find(items['items'].last['id'])
    end
  end
  
  def self.image(id, type)
    if type == 0
     movie = Movie.find(id)
     return movie.full_image
    elsif type == 1
     celeb = Celebrity.find(id)
     return celeb.large_image
    end
  end
  
  def post_to_wall
    if self.user.user_profile &&  self.user.user_profile.post_to_social_media && self.user.facebook_omniauth
        client = Koala::Facebook::GraphAPI.new(self.user.facebook_token)
        client.delay.put_wall_post("",{:name => "#{self.user.display_name} added Top 10 #{self.name} ",:link => "#{SITE_URL}/top_ten/#{self.id}/#{self.name}",:description => "#{self.name} - #{self.user.display_name}", :picture => "http://muvi.com/images/logo_in.png"}) 
    end
  end

end
