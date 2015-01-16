  require 'arel'
  require 'open-uri'
  require 'nokogiri'
module ApplicationHelper
 # WillPaginate::ViewHelpers.pagination_options[:renderer] = 'MuviPagination'
  WillPaginate::ViewHelpers.pagination_options[:previous_label] = 'previous'
  WillPaginate::ViewHelpers.pagination_options[:next_label] = 'next'

  def self.change_lang_format
    users = User.where("language like '%-%'")
    users.each do |user|
      u_lang = []
      langs = user.language.to_s.split("\n-")
      langs.each_with_index do |lang,i|
        if i > 0
          u_lang << lang.gsub("\n","").gsub(" ","")
        end
      end
      user.update_attribute('language',u_lang.to_s);
      p(u_lang)
    end
  end

  def self.user_not_connected
    user_not_connected = []
    has_linked_user = false
    @users = User.where("email IS NOT NULL and last_sign_in_at IS NOT NULL and sign_in_count > 0")
    @users.each do |user|
      all_list = UserMovieList.where("user_id = #{user.id} and tag != ''")
      all_list.each do |list|
        linked_user = Follow.where("followable_id = #{list.id} and followable_type = 'UserMovieList' and follower_idfollower_type = 'User'")
        has_linked_user = true
        break
      end
      if !has_linked_user
        user_not_connected << {:user_id => user.id,:created_at => user.created_at}
      end
    end
    p(user_not_connected)
  end

  def generate_tooltip_block(type,page_type)
    tool_detail = TooltipHint.where("block_type = '#{type}' and page_type = '#{page_type}'").last
    tooltip_block = "<div style='font-size:14px;'>#{tool_detail.content}</div>"
    return tooltip_block
  end
  
  def self.create_movielists
    @intheater_lists = Movie.last_week_released_movies
    @upcoming_lists = Movie.next_week_upcoming_movies
    @top_lists = Movie.last_six_months.where("muvimeter >= 60").order("muvimeter desc")
    HomeMovielist.delete_all
    @intheater_lists.each do |muvi|
      movie_list = HomeMovielist.new
      movie_list.list_type = 'in_theater'
      movie_list.movie_id = muvi.id
      movie_list.lang = muvi.language
      movie_list.save
    end

    @upcoming_lists.each do |muvi|
      movie_list = HomeMovielist.new
      movie_list.list_type = 'upcoming'
      movie_list.movie_id = muvi.id
      movie_list.lang = muvi.language
      movie_list.save
    end
    eng_cnt = 0
    hn_cnt = 0
    tel_cnt = 0
    tam_cnt = 0
    @top_lists.each do |muvi|
      movie_list = HomeMovielist.new
      movie_list.list_type = 'top_rated'
      movie_list.movie_id = muvi.id
      movie_list.lang = muvi.language
      if muvi.language == 'English'
        eng_cnt += 1
        if eng_cnt < 10
          movie_list.save
        end
      elsif muvi.language == 'Hindi'
        hn_cnt += 1
        if hn_cnt < 10
          movie_list.save
        end
      elsif muvi.language == 'Telugu'
        tel_cnt += 1
        if tel_cnt < 10
          movie_list.save
        end
      elsif muvi.language == 'Tamil'
        tam_cnt += 1
        if tam_cnt < 10
          movie_list.save
        end
      end
    end
  end

  def self.cache_clear
    Rails.cache.clear('star_page_cache')
    Rails.cache.clear('movie_page_cache')
    Rails.cache.clear('home_page_cache')
    Rails.cache.clear('trailer_page_cache')
    Rails.cache.clear('poster_page_cache')
  end
 
  def self.reset_all_history_score
    @history_score_time = Movie.order('id').first.history_score_updated_at
    Poster.all.each do |poster|
      ApplicationHelper.reset_score(poster,@history_score_time)
    end
    Video.all.each do |video|
      ApplicationHelper.reset_score(video,@history_score_time)
    end

    News.all.each do |news|
      ApplicationHelper.reset_score(news,@history_score_time)
    end 
    Movie.all.each do |movie|
      ApplicationHelper.reset_score(movie,@history_score_time)
    end
    Celebrity.all.each do |celeb|
      ApplicationHelper.reset_score(celeb,@history_score_time)
    end
  end 
  
  def self.reset_score(data,last_history_score_time)
    if data.history_score_updated_at.blank?
      data.update_attribute('history_score_updated_at', Time.now)
    end
    if Time.now > "#{Date.today} 05:00".to_time && data.history_score_updated_at <= 24.hour.ago
      data.history_score = data.score
      data.history_score_updated_at = Time.now
      data.save false
    end
  end

  def self.reset_flag
    flag_movies = Movie.where("flag != '' ")
    flag_celebs = Celebrity.where("flag != '' ")
    flag_posters = Poster.where("flag != '' ")
    flag_videos = Video.where("flag != '' ")
    flag_news = News.where("flag != '' ")
    flag_movies.each do |movie|
      if !movie.flag_set_at.blank? && movie.flag_set_at <= 24.hours.ago
        movie.update_attributes(:flag => "",:flag_set_at=>"")
      end
    end
    flag_celebs.each do |celeb|
      if !celeb.flag_set_at.blank? && celeb.flag_set_at <= 24.hours.ago
        celeb.update_attributes(:flag => "",:flag_set_at=>"")
      end
    end
    flag_posters.each do |poster|
      if !poster.flag_set_at.blank? && poster.flag_set_at <= 24.hours.ago
        poster.update_attributes(:flag => "",:flag_set_at=>"")
      end
    end
    flag_videos.each do |video|
      if !video.flag_set_at.blank? && video.flag_set_at <= 24.hours.ago
        video.update_attributes(:flag => "",:flag_set_at=>"")
      end
    end
    flag_news.each do |news|
      if !news.flag_set_at.blank? && news.flag_set_at <= 24.hours.ago
        news.update_attributes(:flag => "",:flag_set_at=>"")
      end
    end

  end
  
  def self.insert_home_page(item,page_no,flag,flag_no)
    @exist_item = HomePageSetting.where("subject_id = #{item.id} and subject_type = '#{item.class.to_s}' and page_no = #{page_no}").first
    if @exist_item and @exist_item.flag_detail == ""
      @exist_item.delete
    end
    if @exist_item.blank? or (@exist_item && @exist_item.flag_detail == "")
      if item.diff_score.to_i > 0 or ![10,11,20,21,30,31,40,41].include?(page_no)
        puts page_no
        @home_page_setting = HomePageSetting.new
        @home_page_setting.page_no = page_no
        @home_page_setting.subject_type = item.class.to_s
        @home_page_setting.subject_id = item.id
        @home_page_setting.flag = flag_no
        @home_page_setting.flag_detail = flag
        @home_page_setting.score = item.diff_score
        @home_page_setting.release_date = item.release_date if item.class.to_s == "Movie"
        @home_page_setting.item_created_at = item.created_at
        @home_page_setting.save
      end
    end
  end

  def self.activity_score_calc(data,recent_activity,flag = "",flag_no = "",type = "")
    unless data.updated_at.strftime("%Y-%m-%d").to_s == Date.today.to_s
      data.history_score = data.score
      data.diff_score = 0
      data.save false
    end
    activity_score = 1
    no_latest_activities = recent_activity.where(["secondary_subject_id = #{data.id} and created_at >= ?",data.score_updated_at]).count
    old_score = data.score
    if no_latest_activities > 0
      new_score = (data.score.to_i + (no_latest_activities * activity_score))
      data.score = new_score
      data.score_updated_at = Time.now
      data.save false
    end

    diff_score = (data.score.to_i - data.history_score.to_i)
    data.update_attribute('diff_score', diff_score)if data.diff_score != diff_score
    
    ApplicationHelper.reset_home_page(data,flag,flag_no,type)
  end
  
  def self.reset_home_page(item,flag,flag_no,type = "")
    page_nos = []
    if item.class.to_s == "Movie"
      if item.language == "Hindi"
        if type == "released" 
          page_nos = [12] 
        elsif type == "upcoming"
          page_nos = [13]
        else
          page_nos = [10]
        end
      elsif  item.language == "English"
        if type == "released"
          page_nos = [22]
        elsif type == "upcoming"
          page_nos = [23]
        else
          page_nos = [20]
        end
      elsif  item.language == "Tamil"
        if type == "released"
          page_nos = [32]
        elsif type == "upcoming"
          page_nos = [33]
        else
          page_nos = [30]
        end
      elsif  item.language == "Telugu"
        if type == "released"
          page_nos = [42]
        elsif type == "upcoming"
          page_nos = [43]
        else
          page_nos = [40]
        end
      end
    elsif item.class.to_s == "Celebrity"
      if item.language && item.language.include?("Hindi")
        page_nos << 10
        page_nos << 11
      end
      if  item.language && item.language.include?("English")
        page_nos << 20
        page_nos << 21
      end
      if  item.language && item.language.include?("Tamil")
        page_nos << 30
        page_nos << 31
      end
      if  item.language && item.language.include?("Telugu")
        page_nos << 40
        page_nos << 41
      end
    elsif item.class.to_s == "Poster"  
      movie_tag = item.taggings.where("tagger_type = 'Movie'").first
      celeb_tag = item.taggings.where("tagger_type = 'Celebrity'").first
      movie = Movie.find_by_id(movie_tag.tagger_id,:select=>"language") if movie_tag
      celeb = Celebrity.find_by_id(celeb_tag.tagger_id,:select=>"language") if celeb_tag
      if movie && !movie.language.blank? 
        if movie.language == "Hindi"
          if type == "picture"
            page_nos = [16]
          else
            page_nos = [10]
          end
        elsif movie.language == "English"
          if type == "picture"
            page_nos = [26]
          else
            page_nos = [20]
          end
        elsif movie.language == "Tamil"
          if type == "picture"
            page_nos = [36]
          else
            page_nos = [30]
          end
        elsif movie.language == "Telugu"
          if type == "picture"
            page_nos = [46]
          else
            page_nos = [40]
          end
        end
      end
      if celeb && !celeb.language.blank?
        if celeb.language && celeb.language.include?("Hindi")
          page_nos = [10,11]
        elsif celeb.language && celeb.language.include?("English")
          page_nos = [20,21]
        elsif celeb.language && celeb.language.include?("Tamil")
          page_nos = [30,31]
        elsif celeb.language && celeb.language.include?("Telugu")
          page_nos  = [40,41]
        end
      end
    elsif item.class.to_s == "Video"
      movie_tag = item.taggings.where("tagger_type = 'Movie'").first
      celeb_tag = item.taggings.where("tagger_type = 'Celebrity'").first
      movie = Movie.find_by_id(movie_tag.tagger_id,:select=>"language") if movie_tag
      celeb = Celebrity.find_by_id(celeb_tag.tagger_id,:select=>"language") if celeb_tag
      if movie && !movie.language.blank?
        if movie.language == "Hindi"
          if type == "trailer"
            page_nos = [14]
          else
            page_nos = [10]
          end
        elsif movie.language == "English"
          if type == "trailer"
            page_nos = [24]
          else
            page_nos = [20]
          end
        elsif movie.language == "Tamil"
          if type == "trailer"
            page_nos = [34]
          else
            page_nos = [30]
          end
        elsif movie.language == "Telugu"
          if type == "trailer"
            page_nos = [44]
          else
            page_nos = [40]
          end
        end
      end
      if celeb && !celeb.language.blank?
        if celeb.language && celeb.language.include?("Hindi")
          if type == "trailer"
            page_nos = [14]
          else
            page_nos = [10,11]
          end
        elsif celeb.language && celeb.language.include?("English")
          if type == "trailer"
            page_nos = [24]
          else
            page_nos = [20,21]
          end
        elsif celeb.language && celeb.language.include?("Tamil")
          if type == "trailer"
            page_nos = [34]
          else
            page_nos = [30,31]
          end
        elsif celeb.language && celeb.language.include?("Telugu")
          if type == "trailer"
            page_nos = [44]
          else
            page_nos  = [40,41]
          end
        end
      end
      
    elsif item.class.to_s == "News"
      movie_tag = item.taggings.where("tagger_type = 'Movie'").first
      celeb_tag = item.taggings.where("tagger_type = 'Celebrity'").first
      movie = Movie.find_by_id(movie_tag.tagger_id,:select=>"language") if movie_tag
      celeb = Celebrity.find_by_id(celeb_tag.tagger_id,:select=>"language") if celeb_tag
      if movie && !movie.language.blank?
        if movie.language == "Hindi"
          page_nos = [10]
        elsif movie.language == "English"
          page_nos = [20]
        elsif movie.language == "Tamil"
          page_nos = [30]
        elsif movie.language == "Telugu"
          page_nos = [40]
        end
      end
      if celeb && !celeb.language.blank?
        if celeb.language && celeb.language.include?("Hindi")
          page_nos = [10,11]
        elsif celeb.language && celeb.language.include?("English")
          page_nos = [20,21]
        elsif celeb.language && celeb.language.include?("Tamil")
          page_nos = [30,31]
        elsif celeb.language && celeb.language.include?("Telugu")
          page_nos  = [40,41]
        end
      end
    end
    page_nos.each do |page_no|
      ApplicationHelper.insert_home_page(item,page_no,flag,flag_no)
    end
  end 
  
  def self.arrange_home_page
    page_nos = [10,11,12,13,14,16,20,21,22,23,24,26,30,31,32,33,34,36,40,41,42,43,44,46]
    page_nos.each do |page|
      @page_data = HomePageSetting.where("page_no = '#{page}'").order("score desc")
      p(@page_data)
      HomePageSetting.where("page_no = #{page}").delete_all
      @page_data.each do |data|
        @home_page = HomePageSetting.new
        @home_page.subject_id = data.subject_id
        @home_page.subject_type = data.subject_type
        @home_page.score = data.score
        @home_page.flag = data.flag
        @home_page.flag_detail = data.flag_detail
        @home_page.page_no = data.page_no
        @home_page.release_date = data.release_date
        @home_page.item_created_at = data.item_created_at
        @home_page.save
      end
    end
  end

  def self.reset_old_score
    item_cls = ["Movie","Celebrity","Poster","Video","News"]
    item_cls.each do |cls|
      cls.constantize.where("diff_score > 0").each do |item|
        activities = item.activities.where("date(created_at) = '#{Date.today}'")
        if activities.blank?
          item.history_score = item.score
          item.diff_score = 0
          item.save false
        end
      end
    end
  end

  def self.calculate_diff_score
    ApplicationHelper.reset_old_score()
    HomePageSetting.delete_all("page_no in (10,11,12,13,14,16,20,21,22,23,24,26,30,31,32,33,34,36,40,41,42,43,44,46)")
    languages = ["Hindi","English","Tamil","Telugu"]
    Movie.five_days_released_movies.each do |movie|
      ApplicationHelper.score_addition(movie,'release_movie')
      if movie.release_date >= Date.today - 2 and movie.release_date <= Date.today 
        ApplicationHelper.activity_score_calc(movie,Activity.movie_1week_activitis,"Just Released",2)
      else
        ApplicationHelper.activity_score_calc(movie,Activity.movie_1week_activitis)
      end
    end
    Movie.four_days_upcomming_movies.each do |movie|
      ApplicationHelper.score_addition(movie,'upcoming_movie')
      ApplicationHelper.activity_score_calc(movie,Activity.movie_1week_activitis,"Upcoming",1)
    end

    Movie.this_week_released_movies.each do |movie|
      movie.actors.limit(4).each do |actor|
        celebrity = Celebrity.find_by_id(actor.celebrity_id)
        if celebrity && celebrity.image != "/images/no-image.png"
          ApplicationHelper.score_addition(celebrity,'in_theater_celebrity')
          ApplicationHelper.activity_score_calc(celebrity,Activity.celeb_1week_activitis,"In Theaters",3,"in_theaters")
        end
      end
    end
    
    Celebrity.bday_celebrity.each do |celeb|
      if celeb.image != "/images/no-image.png"
        ApplicationHelper.score_addition(celeb,"bday_celebrity")
        ApplicationHelper.activity_score_calc(celeb,Activity.celeb_1week_activitis,"Happy Birthday",4,"happy_bday")
      end
    end
    Poster.three_days_poster.each do |poster|
      movie_tag = poster.taggings.where("tagger_type = 'Movie'").first
      if movie_tag
        movie = Movie.find_by_id(movie_tag.tagger_id)
        if movie && (movie.release_date.blank? || movie.release_date >= Date.today || movie.release_date >= Date.today - 30)
          ApplicationHelper.score_addition(poster,'Poster')
          poster_tag = poster.taggings.where("tagger_type = 'poster'").first
          if poster_tag
            ApplicationHelper.activity_score_calc(poster,Activity.poster_1week_activitis,"Latest Poster",6,"latest_poster")
          else
            ApplicationHelper.activity_score_calc(poster,Activity.poster_1week_activitis)
          end
        end
      end
    end
    Video.five_days_video.each do |video|
      movie_tag = video.taggings.where("tagger_type = 'Movie'").first
      if movie_tag
        movie = Movie.find_by_id(movie_tag.tagger_id)
        if movie && (movie.release_date.blank? || movie.release_date >= Date.today || movie.release_date >= Date.today - 30)
          ApplicationHelper.score_addition(video,'Video')
          trailer_tag = video.taggings.where("tagger_type = 'trailer'").first
          if trailer_tag &&  video.created_at >= Date.today - 3
            ApplicationHelper.activity_score_calc(video,Activity.video_1week_activitis,"Latest Trailer",5,"latest_trailer")
          else
            ApplicationHelper.activity_score_calc(video,Activity.video_1week_activitis)
          end
        end
      end
    end
    Activity.select('secondary_subject_id').group('secondary_subject_id').movie_1week_activitis.each do |movie_activity|
      movie = Movie.find_by_id(movie_activity.secondary_subject_id)
      ApplicationHelper.activity_score_calc(movie,Activity.movie_1week_activitis)
    end

    Activity.select('secondary_subject_id').group('secondary_subject_id').celeb_1week_activitis.each do |celeb_activity|
      celeb = Celebrity.find_by_id(celeb_activity.secondary_subject_id)
      ApplicationHelper.activity_score_calc(celeb,Activity.celeb_1week_activitis)
    end    
    Activity.select('secondary_subject_id').group('secondary_subject_id').poster_1week_activitis.each do |poster_activity|
      poster = Poster.find_by_id(poster_activity.secondary_subject_id)
      ApplicationHelper.activity_score_calc(poster,Activity.poster_1week_activitis)
    end
    Activity.select('secondary_subject_id').group('secondary_subject_id').video_1week_activitis.each do |video_activity|
      video = Video.find_by_id(video_activity.secondary_subject_id)
      ApplicationHelper.activity_score_calc(video,Activity.video_1week_activitis)
    end
    Activity.select('secondary_subject_id').group('secondary_subject_id').news_1week_activitis.each do |news_activity|
      news = News.find_by_id(news_activity.secondary_subject_id)
      ApplicationHelper.activity_score_calc(news,Activity.news_1week_activitis)
    end
    Movie.hindi_movies.where("release_date <= ?",Date.today).order("release_date desc").limit(20).each do |release_movie|
      if release_movie.release_date >= Date.today - 2 and release_movie.release_date <= Date.today
        ApplicationHelper.activity_score_calc(release_movie,Activity.movie_1week_activitis,"Just Released","2","released")
      else
        ApplicationHelper.activity_score_calc(release_movie,Activity.movie_1week_activitis,"","","released")
      end
    end
    Movie.hollywood_movies.where("release_date <= ?",Date.today).order("release_date desc").limit(20).each do |release_movie|
      if release_movie.release_date >= Date.today - 2 and release_movie.release_date <= Date.today
        ApplicationHelper.activity_score_calc(release_movie,Activity.movie_1week_activitis,"Just Released","2","released")
      else
        ApplicationHelper.activity_score_calc(release_movie,Activity.movie_1week_activitis,"","","released")
      end
    end
    Movie.tamil_movies.where("release_date <= ?",Date.today).order("release_date desc").limit(20).each do |release_movie|
      if release_movie.release_date >= Date.today - 2 and release_movie.release_date <= Date.today
        ApplicationHelper.activity_score_calc(release_movie,Activity.movie_1week_activitis,"Just Released","2","released")
      else
        ApplicationHelper.activity_score_calc(release_movie,Activity.movie_1week_activitis,"","","released")
      end
    end
    Movie.telugu_movies.where("release_date <= ?",Date.today).order("release_date desc").limit(20).each do |release_movie|
      if release_movie.release_date >= Date.today - 2 and release_movie.release_date <= Date.today
        ApplicationHelper.activity_score_calc(release_movie,Activity.movie_1week_activitis,"Just Released","2","released")
      else
        ApplicationHelper.activity_score_calc(release_movie,Activity.movie_1week_activitis,"","","released")
      end
    end
    Movie.hindi_movies.where("release_date > ?",Date.today).order("release_date asc").limit(20).each do |upc_movie|
      if upc_movie.release_date < Date.today +  5
        ApplicationHelper.activity_score_calc(upc_movie,Activity.movie_1week_activitis,"Upcoming","1","upcoming")
      else
        ApplicationHelper.activity_score_calc(upc_movie,Activity.movie_1week_activitis,"","","upcoming")
      end
    end 
    Movie.hollywood_movies.where("release_date > ?",Date.today).order("release_date asc").limit(20).each do |upc_movie|
      if upc_movie.release_date < Date.today +  5
        ApplicationHelper.activity_score_calc(upc_movie,Activity.movie_1week_activitis,"Upcoming","1","upcoming")
      else
        ApplicationHelper.activity_score_calc(upc_movie,Activity.movie_1week_activitis,"","","upcoming")
      end
    end
    Movie.tamil_movies.where("release_date > ?",Date.today).order("release_date asc").limit(20).each do |upc_movie|
      if upc_movie.release_date < Date.today +  5
        ApplicationHelper.activity_score_calc(upc_movie,Activity.movie_1week_activitis,"Upcoming","1","upcoming")
      else
        ApplicationHelper.activity_score_calc(upc_movie,Activity.movie_1week_activitis,"","","upcoming")
      end
    end
    Movie.telugu_movies.where("release_date > ?",Date.today).order("release_date asc").limit(20).each do |upc_movie|
      if upc_movie.release_date < Date.today +  5
        ApplicationHelper.activity_score_calc(upc_movie,Activity.movie_1week_activitis,"Upcoming","1","upcoming")
      else
        ApplicationHelper.activity_score_calc(upc_movie,Activity.movie_1week_activitis,"","","upcoming")
      end
    end
    languages.each do |lang|
      ApplicationHelper.get_trailers_only(lang).each do |trailer|
        movie_tag = trailer.taggings.where("tagger_type = 'Movie'").first
        movie = Movie.find_by_id(movie_tag.tagger_id) if movie_tag
        if trailer.created_at >= Date.today - 3
          if movie and (movie.release_date.blank? || movie.release_date > Date.today || movie.release_date >= Date.today - 30)
            ApplicationHelper.activity_score_calc(trailer,Activity.video_1week_activitis,"Latest Trailer","5","trailer")
          end
        else
          ApplicationHelper.activity_score_calc(trailer,Activity.video_1week_activitis,"","","trailer")
        end
      end
      ApplicationHelper.get_pictures(lang).each do |picture|
        movie_tag = picture.taggings.where("tagger_type = 'Movie'").first
        movie = Movie.find_by_id(movie_tag.tagger_id) if movie_tag
        ApplicationHelper.activity_score_calc(picture,Activity.poster_1week_activitis,"","","picture")
      end
    end
    ApplicationHelper.arrange_home_page
    #ApplicationHelper.cache_clear
  end
  
  def self.score_addition(item,item_type)
    if item_type == "Poster"
      poster_tag = item.taggings.where("tagger_type = 'poster'").first
      if poster_tag
        if item.diff_score < 3
          new_score = item.score.to_i + 3
          item.update_attribute('score',new_score)
        end
      else
        if item.diff_score < 1
          new_score = item.score.to_i + 1
          item.update_attribute('score',new_score)
        end
      end
    elsif item_type == "Video"
      trailer_tag = item.taggings.where("tagger_type = 'trailer'").first
      if trailer_tag && item.created_at >= Date.today - 3
        if item.diff_score < 3
          new_score = item.score.to_i + 3
          item.update_attribute('score',new_score)
        end
      else
        if item.diff_score < 1
          new_score = item.score.to_i + 1
          item.update_attribute('score',new_score)
        end
      end
    elsif item_type == "release_movie"
      if item.release_date and item.release_date >= Date.today - 2
        if item.diff_score < 3
          new_score = item.score.to_i + 3
          item.update_attribute('score',new_score)
        end
      elsif item.release_date and item.release_date >= Date.today - 4 and item.release_date < Date.today - 2
        if item.diff_score < 1
          new_score = item.score.to_i + 1
          item.update_attribute('score',new_score)
        end
      end
    elsif item_type == "upcoming_movie"
      if item.release_date and item.release_date > Date.today and item.release_date <= Date.today + 2
        if item.diff_score < 3
          new_score = item.score.to_i + 3
          item.update_attribute('score',new_score)
        end
      elsif item.release_date and item.release_date > Date.today+2 and item.release_date <= Date.today + 4
        if item.diff_score < 1
          new_score = item.score.to_i + 1
          item.update_attribute('score',new_score)
        end
      end
    elsif item_type == "in_theater_celebrity"
      if item.diff_score < 1
        new_score = item.score.to_i + 1
        item.update_attribute('score',new_score)
      end
    elsif item_type == "bday_celebrity"
      if item.diff_score < 3
        new_score = item.score.to_i + 3
        item.update_attribute('score',new_score)
      end
    end
  end

  def self.get_pictures(lang)
    all_posters = []
    Poster.all(:order => "diff_score desc, created_at desc",:limit=>"200").each do |poster|
      tag_picture = Tagging.where("taggable_id = ? AND taggable_type = ? ",poster.id,"Poster")
      if !tag_picture.nil? && !tag_picture.blank?
        movie_tagger = poster.taggings.where("tagger_type = 'Movie'").first
        movie = Movie.find_by_id(movie_tagger.tagger_id,:select=>"language") if movie_tagger
        if movie && !movie.language.blank? && movie.language == lang
          all_posters << poster
        end
      end
    end
    return ((((all_posters.sort_by &:diff_score).reverse).uniq)[0..19]) 
  end

  def self.get_trailers_only(lang)
    all_trailers = []
    Video.all(:order => "diff_score desc, created_at desc",:limit=>"200").each do |video|
      tag_trailer = Tagging.where("taggable_id = ? AND taggable_type = ? AND tagger_type = ?",video.id,"Video","trailer")
      if !tag_trailer.nil? && !tag_trailer.blank?
        movie_tagger = video.taggings.where("tagger_type = 'Movie'").first
        movie = Movie.find_by_id(movie_tagger.tagger_id,:select=>"language") if movie_tagger
        if movie && !movie.language.blank? && movie.language == lang
          all_trailers << video
        end
      end
    end
    return ((((all_trailers.sort_by &:diff_score).reverse).uniq)[0..19])
  end

  def self.check_flag_items(admin_flag_items,arranged_items)
     
    arranged_ids = []
    flag_ids = []
    home_data = []
    arranged_items.each do |item|
      arranged_ids << item.id
    end
    admin_flag_items.each do |item|
      flag_ids << item.id
    end
    
    left_ids = flag_ids - arranged_ids
    p(left_ids)
    admin_flag_items.each do |flag_item|
      if left_ids.include?(flag_item.id)
        home_data << flag_item
      end
    end
    return home_data
  end

  def self.calculate_score(obj)
    score = 0 
    if obj.class.to_s == "Celebrity"
      score += obj.fans.count
    elsif obj.class.to_s == "Movie"
      score += obj.reviews.count
      score += obj.critics_reviews.count
      score += obj.want_to_sees.count
    else
      score += obj.votes.count
      score += obj.comments.count
    end
    if obj.score != score || obj.score != 0 || obj.history_score != 0
      obj.update_attributes(:score => score,:history_score => 0,:diff_score=>0,:history_score_updated_at=> Time.now)
    end
  end
  
  def self.calculate_all_score
    videos = Video.find(:all)
    videos.each do |video|
      ApplicationHelper.calculate_score(video)
    end
    posters = Poster.find(:all)
    posters.each do |poster|
      ApplicationHelper.calculate_score(poster)
    end
    #discussions = Discussion.find(:all)
    #discussions.each do |discussion|
      #ApplicationHelper.calculate_score(discussion)
    #end
    all_news = News.find(:all)
    all_news.each do |news|
      ApplicationHelper.calculate_score(news)
    end
    #critics_reviews = CriticsReview.find(:all)
    #critics_reviews.each do |critics_review|
      #ApplicationHelper.calculate_score(critics_review)
    #end
    #reviews = Review.find(:all)
    #reviews.each do |review|
      #ApplicationHelper.calculate_score(review)
    #end
    celebrities = Celebrity.find(:all)
    celebrities.each do |celebrity|
      ApplicationHelper.calculate_score(celebrity)
    end
    movies = Movie.find(:all)
    movies.each do |movie|
      ApplicationHelper.calculate_score(movie)
    end
    #celeb_tweets = CelebTweet.find(:all)
    #celeb_tweets.each do |tweet|
      #ApplicationHelper.calculate_score(tweet)
    #end
  end

  def link_to_remove_fields(name, f)
    f.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)")
  end

  def display_egg(item)
    return thumb_class((item.rating > 3)? 100 : 0) if item.rating
  end
  def rating_mood(rating)
    if rating.to_i == 2
      return image_tag('bad.png', :class => 'thumb',:style=>"height:20px;")
    elsif rating.to_i == 4
      return image_tag('avg.png', :class => 'thumb',:style=>"height:20px;")
    elsif rating.to_i == 5
      return image_tag('good.png', :class => 'thumb',:style=>"height:20px;")
    end
  end

  def thumb_class_for_union_result(result) # this method is used in shared/movie_tweets
    if result[0].to_s == 'movie_tweet'
      return thumb_class((result[5].to_s == 'pos')? 100 : 0)

    elsif result[0].to_s == 'celebrity_tweet'
      return thumb_class((result[4].to_s == 'pos')? 100 : 0)
    elsif result[0].to_s == 'movie_review'
      return thumb_class(0) if result[4].blank?
      return thumb_class((result[4].to_f >= 3)? 100 : 0)
    else
      return thumb_class(0) if result[3].blank?
      return thumb_class((result[3].to_f >= 3)? 100 : 0)
    end
  end

  def display_name(result) # this method is used in shared/movie_tweets and shared/celebrity_tweets
    if result[0].to_s == 'movie_tweet'
      return result[5] rescue  ''

    elsif result[0].to_s == 'celebrity_tweet'
      return result[5] rescue  ''
    elsif result[0].to_s == 'movie_review'
      return User.find(result[2]).display_name
    else
      return User.find(result[1]).display_name
    end
  end

  def display_image(result)
    if result[0].to_s == 'movie_tweet'
      return image_tag(Twitter.profile_image("#{result[5]}", :size => 'normal')) rescue image_tag('no-profile.png')
    elsif result[0].to_s == 'celebrity_tweet'
      return image_tag(Twitter.profile_image("#{result[4]}", :size => 'normal')) rescue image_tag('no-profile.png')
    elsif result[0].to_s == 'movie_review'
      return image_tag(User.find(result[2]).user_image)
    else
      #return image_tag(User.find(result[1]).image)
      return image_tag(User.find(result[1]).user_image)
    end
  end


  def activity_message(activity)
    message = ''
    message += link_to activity.actor_name.to_s, new_facebook_post_path(:id => activity.subject_id), :remote => true
    if (activity.action.to_s == 'liked' || activity.action.to_s == 'interested')
       message += ' '+ ((activity.action.to_s == 'liked')? 'likes' : 'interested in' ) + ' ' + link_to(activity.secondary_subject.name, path_for_movie(activity.secondary_subject))
    else
      begin
        if activity.subject.value.insert(0, ' ').concat(' ').downcase.gsub(/[^0-9A-Za-z]/, ' ').squeeze(" ")[" #{activity.secondary_subject.name.downcase} ".gsub(/[^0-9A-Za-z]/, ' ').squeeze(" ").to_s]
          message += ' said '+ activity.subject.value.downcase.gsub(activity.secondary_subject.name.downcase, link_to(activity.secondary_subject.name, path_for_movie(activity.secondary_subject)))
        else
           message += ' about ' +  link_to(activity.secondary_subject.name, path_for_movie(activity.secondary_subject)) + ' ' +  activity.subject.value.to_s
        end
      rescue
        ''
      end
    end
    message.html_safe
  end
  def activity_block(activity, show_review = false)
   message = ""
   review_message = ""
   user_profile = UserProfile.find_by_user_id(activity.user_id)
   user = link_to(user_profile.display_name, "/profile/#{activity.user_id}/#{user_profile.display_name}", :style => 'font-weight:normal').to_s
   time_ago = "<br/><span style='font-size:10px;font-weight:normal'>".html_safe +  distance_of_time_in_words(Time.now, activity.created_at.to_time) + " ago</span>".html_safe
   if activity.subject_type == 'TopTen'
     begin
       message = link_to(TopTen.find(activity.subject_id).name, "/top_ten/#{activity.subject_id}/#{TopTen.find(activity.subject_id).name}", :style => 'font-weight:normal').to_s
       message = message + ' created by ' + user + time_ago
     rescue
       message = activity.subject_type.to_s + activity.id.to_s
     end
   elsif activity.subject_type == 'Review'
     begin
       movie = Movie.find(activity.secondary_subject_id)
       message = link_to(movie.name, movie_path(movie), :style => 'font-weight:normal').to_s
       message = message +  ' reviewed by ' + user + time_ago
       if show_review == true
         review = Review.where(:user_id => activity.user_id, :movie_id => activity.secondary_subject_id).first
         ['0.5', '1.0', '1.5', '2.0', '2.5', '3.0', '3.5', '4.0', '4.5', '5.0'].each do |rate|
           if review.rating.to_s == rate
             review_message = review_message + "<input checked class='star {split:2}' disabled='disabled' name='review_#{review.id}_#{activity.id}' type='radio' value='#{rate}'>".html_safe
           else
             review_message = review_message + "<input class='star {split:2}' disabled='disabled' name='review_#{review.id}_#{activity.id}' type='radio' value='#{rate}'>".html_safe
           end
         end
         review_message = review_message.to_s + "<br>".html_safe + review.description.to_s + " " + link_to("Add your review", movie_path(movie)).to_s
       end
     rescue
       message = activity.subject_type.to_s + activity.id.to_s
     end
   elsif activity.subject_type == 'Watch'
     begin
       movie = Movie.find(activity.secondary_subject_id)
       message = link_to(movie.name, movie_path(movie), :style => 'font-weight:normal').to_s
       message = message + ' will be seen by ' + user + time_ago
     rescue
       message = activity.subject_type.to_s + activity.id.to_s
     end
   elsif activity.subject_type == 'Not watch'
     begin
       movie = Movie.find(activity.secondary_subject_id)
       message = link_to(movie.name, movie_path(movie), :style => 'font-weight:normal').to_s
       message = user + ' don\'t want to watch '+ message + time_ago
     rescue
       message = activity.subject_type.to_s + activity.id.to_s
     end
   elsif activity.subject_type == 'Fan'
     begin
       celeb = Celebrity.find(activity.secondary_subject_id)
       message = link_to(celeb.name, star_path(celeb), :style => 'font-weight:normal').to_s
       message = message + ' has a new fan, ' + user + time_ago
     rescue
       message = activity.subject_type.to_s + activity.id.to_s
     end
   elsif activity.subject_type == 'Unfan'
     begin
       celeb = Celebrity.find(activity.secondary_subject_id)
       message = link_to(celeb.name, star_path(celeb), :style => 'font-weight:normal').to_s
       message = user + ' left fandom of ' + message + time_ago
     rescue
       message = activity.subject_type.to_s + activity.id.to_s
     end
   elsif activity.subject_type == 'Follow'
     #begin
       user_fb = ""
       user_profile = UserProfile.find_by_user_id(activity.secondary_subject_id)
       user_fb_id = User.find_by_id(activity.secondary_subject_id)
       unless user_profile.blank?
         unless user_profile.profile_image_file_name.blank?
          user_fb = link_to(user_profile.display_name, "/profile/#{user_profile.user_id}/#{user_profile.display_name}", :style => 'font-weight:normal').to_s
         else
           unless user_fb_id.facebook_id.blank?
             user_fb = link_to(user_profile.display_name,"/profile/#{user_profile.user_id}/#{user_profile.display_name}", :style => 'font-weight:normal').to_s
           else
              user_fb = link_to(user_profile.display_name, "/profile/#{user_profile.user_id}/#{user_profile.display_name}", :style => 'font-weight:normal').to_s
           end
         end
       end
       message = user_fb + ' is followed by, ' + user + time_ago
     #rescue
     #  message = activity.subject_type.to_s + activity.id.to_s 
     #end
   elsif (activity.subject_type == 'Likes' and activity.secondary_subject_type == 'Video')
     link = activity.action.split("<a href='")
     new_link = link[1].split("'>")
     begin
       message = link_to(Video.find(activity.secondary_subject_id).name, new_link[0].gsub("videos", "video"), :style => 'font-weight:normal').to_s
     rescue  
     end
     message = message + ' is liked by ' + user + time_ago
      
   elsif (activity.subject_type == 'Dislikes' and activity.secondary_subject_type == 'Video')
     link = activity.action.split("<a href='")
     new_link = link[1].split("'>")

     begin
       message = link_to(Video.find(activity.secondary_subject_id).name, new_link[0].gsub("videos", "video"), :style => 'font-weight:normal').to_s
     rescue
     end
     message = message + ' is disliked by ' + user + time_ago
   elsif (activity.subject_type == 'Likes' and activity.secondary_subject_type == 'Poster')
     link = activity.action.split("<a href='")
     new_link = link[1].split("'>")
     begin
       message = link_to(Poster.find(activity.secondary_subject_id).name, new_link[0].gsub("posters", "poster"), :style => 'font-weight:normal').to_s
     rescue
     end
     message = message + ' is liked by ' + user + time_ago
   elsif (activity.subject_type == 'Dislikes' and activity.secondary_subject_type == 'Poster')
     link = activity.action.split("<a href='")
     new_link = link[1].split("'>")
     begin
       message = link_to(Poster.find(activity.secondary_subject_id).name, new_link[0].gsub("posters", "poster"), :style => 'font-weight:normal').to_s
     rescue
     end
     message = message + ' is disliked by ' + user + time_ago
   elsif (activity.subject_type == 'Post')
     if activity.secondary_subject_type == 'Discussion'
       @discussion = Discussion.find_by_id(activity.secondary_subject_id)
       item = Discussion.activity_item(@discussion)
     else
       item = activity.secondary_subject_type.constantize.find_by_id(activity.secondary_subject_id)
     end
     if item.class.to_s == "Movie"
       link = "/movies/#{item.permalink}"
     else
       link = "/stars/#{item.permalink}"
     end
     message = activity.action+ " about <a href='#{link}' style='font-weight:normal;'>#{item.name}</a>" + time_ago 
   else
     message = activity.subject_type.to_s + activity.id.to_s
   end
   begin
   message = "<div class='row'><div class='image left'>#{activity_image(activity)}</div><h4 style='font-weight:normal'>#{message}</h4>#{review_message}<div class='clear'></div></div>"
   rescue
   end
   return message.html_safe
  end


  def activity_image(activity)
    image = ""
    if activity.subject_type == 'TopTen'
      begin
        if activity.secondary_subject_type == 'Movie'
          image = TopTen.last_item(activity.subject_id).banner_image_thumb
        elsif activity.secondary_subject_type == 'Celebrity'
          image = TopTen.last_item(activity.subject_id).thumb_image
        end
      rescue
      end
    elsif activity.subject_type == 'Follow'
      user = UserProfile.find_by_user_id(activity.secondary_subject_id)
      user_fb_id = User.find_by_id(activity.secondary_subject_id)
      unless user.blank?
        unless user.profile_image_file_name.blank?
          image = "/system/profile_images/#{user.id}/small/#{user.profile_image_file_name.gsub(' ', '%20')}"    #user.profile_image.url(:thumb)
        else
          unless user_fb_id.facebook_id.blank?
            image = "http://graph.facebook.com/#{user_fb_id.facebook_id}/picture?type=large"
          else
            image = "no-profile.png"
          end  
        end
      end
      #image = User.find(activity.secondary_subject_id).image

    elsif ((activity.subject_type == 'Likes' or activity.subject_type == 'Dislikes') and activity.secondary_subject_type == 'Video')
      video = Video.find_by_id(activity.secondary_subject_id)
      unless video.blank?
        unless video.video_remote_url.blank?
          video_id_arr = video.video_remote_url.split("/")
          video_id = video_id_arr[video_id_arr.size.to_i - 1]
          image = "http://img.youtube.com/vi/#{video_id}/1.jpg"
        else
          image = "/system/trailer_thumbnails/#{activity.secondary_subject_id}/1.jpg"
        end
      end
    elsif ((activity.subject_type == 'Likes' or activity.subject_type == 'Dislikes') and activity.secondary_subject_type == 'Poster')
      poster = Poster.find_by_id(activity.secondary_subject_id)
      unless poster.blank?
        #image = poster.poster.url(:thumb)
        image = "#{URL}/system/posters/#{poster.id}/thumb/#{poster.poster_file_name.gsub(' ', '%20')}"
      end
    elsif activity.secondary_subject_type == 'Discussion'
      @discussion = Discussion.find_by_id(activity.secondary_subject_id)
      image = Discussion.activity_thumb(@discussion)
    else
      if activity.secondary_subject_type == 'Movie'
        image = Movie.find(activity.secondary_subject_id).banner_image_thumb
      elsif activity.secondary_subject_type == 'Celebrity'
        image = Celebrity.find(activity.secondary_subject_id).thumb_image
      end
    end
    if image != ""
      return image_tag(image).html_safe
    else
      return image_tag("/mages/no-image.png").html_safe
    end
  end

  def path_for_movie(movie)
    if movie.release_date.blank? || movie.release_date > Date.today
      return coming_soon_movie_path(movie)
    else
      return movie_path(movie)
    end
  end

  def review_options
    option ||= [['Select a opinion', ''], ['Positive','pos'], ['Negative','neg'],['Neutral','neu'],['Ignore','ign']]
  end

  def tweet_review_options
    option ||= [['Select a opinion', ''], ['Positive','pos'], ['Negative','neg'] ,['Neutral','neu'],['Ignore','ign']]
  end

  def link_to_add_fields(name, f, association, render_partial)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(render_partial, :ff => builder)
    end
    link_to_function(name, raw("add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")"))
  end


  def find_page(key)
    page =  Page.find_reference(key).first rescue nil
    page.blank? ? "#" : "/#{page.permalink}"
  end

  def find_page_msn(key)
    page =  Page.find_reference(key).first rescue nil
    page.blank? ? "#" : "/msn_embed/#{page.permalink}"
  end


  def ratingbar(rating,meter='')
    rating ||= 0
    text = ""
    if meter == "criticsmeter"
      if rating.to_i >= 60
        text += "<div class='small_positive' style='width:#{rating}%;'>&nbsp;</div>"
      else
        text += "<div class='small_negative' style='width:#{rating}%;'>&nbsp;</div>"
      end
    elsif meter != "muvimeter"
      if rating.to_i >= 60
        text += "<div class='positive' style='width:#{rating}%;'>&nbsp;</div>"
      else
        text += "<div class='negative' style='width:#{rating}%;'>&nbsp;</div>"
      end
    else
      if rating.to_i >= 60
        text += "<div class='inner_positive' style='width:#{rating}%;'>&nbsp;</div>"
      else
        text += "<div class='inner_negative' style='width:#{rating}%;'>&nbsp;</div>"
      end
    end
    text.html_safe
  end

  def thumb_class(rating)
    rating ||= 0
    if rating.to_i >= 60
      #return image_tag('thumbUp.png', :class => 'thumb', :title => 'Jhakaas', :alt => 'Jhakaas',:style=>"height:20px;")
      return image_tag('good.png', :class => 'thumb', :title => 'Jhakaas', :alt => 'Jhakaas',:style=>"height:20px;")
    else
      #return image_tag('thumbDown.png', :class => 'thumb', :title => 'Bakwaas', :alt => 'Bakwaas',:style=>"height:20px;")
      return image_tag('bad.png', :class => 'thumb', :title => 'Bakwaas', :alt => 'Bakwaas',:style=>"height:20px;")
    end
  end

  def rating_thumb(rating)
    rating ||= 0
    if rating.to_f >= 3
      return image_tag('thumbUp.png', :class => 'thumb')
    else
      return image_tag('thumbDown.png', :class => 'thumb')
    end
  end

  def title
    return Setting.find_by_key("home_page_meta_title").value rescue nil
  end

  def meta_keyword
    return Setting.find_by_key("home_page_meta_keywords").value rescue nil
  end

  def meta_description
    return Setting.find_by_key("home_page_meta_description").value rescue nil
  end

  def meta_keywords_and_title(key, object, type)
    if key and !object
      title =  Setting.find_by_key("#{key}_page_meta_title").value rescue nil
      keywords =  Setting.find_by_key("#{key}_page_meta_keywords").value rescue nil
      description =  Setting.find_by_key("#{key}_page_meta_description").value rescue nil
    elsif key == "celebrity_together"
      title = "#{object.name} and #{@costar.name}"
      keywords = "#{object.name} and #{@costar.name}, #{object.name} and #{@costar.name} movies, movies of #{object.name} and #{@costar.name}"
      description = "List of movies in which both #{object.name} and #{@costar.name} were there"
    elsif key and object
      if type.blank?
        title =  !object.meta_title.blank? ? object.meta_title : "#{object.name} Pictures | Videos | Upcoming | Latest Updates - #{Date.today.strftime('%b %d')}"

        #title = "#{object.name} Pictures | Videos | Upcoming | Latest Updates - #{Date.today.strftime('%b %d')}" if title.blank?

        keywords =  !object.meta_keywords.blank? ? object.meta_keywords : "#{object.name} bio, #{object.name} movies, #{object.name} pictures, #{object.name} videos, #{object.name} tweets"

        #keywords = "#{object.name} bio, #{object.name} movies, #{object.name} pictures, #{object.name} videos, #{object.name} tweets" if keywords.blank?

        description = !object.meta_description.blank? ? object.meta_description : "#{object.name} upcoming and top movies, information, videos and pictures"

        #description =  "#{object.name} upcoming and top movies, information, videos and pictures" if description.blank?
      else
        title =  "#{object.display_name}'s Filmy Profile" rescue "Filmy Profile"

        keywords =  "#{object.display_name}, #{object.display_name} Muvi, #{object.display_name} Movie, #{object.display_name} Bollywood, #{object.display_name} Filmy Profile" rescue "Muvi,Bollywood,Filmy Profile"

        description = "View #{object.display_name}'s filmy profile. Muvi is world's largest movie based interest network that helps movie lovers such as #{object.display_name} discover new movies they may like and celebrities they may want to follow" rescue "Filmy profile. Muvi is world's largest movie based interest network that helps movie lovers to discover new movies they may like and celebrities they may want to follow"

      end
   else
      unless object.blank?
        begin
          title =  !object.meta_title.blank? ? object.meta_title : "#{object.name} Pictures | Trailers | Reviews | Latest Updates - #{Date.today.strftime('%b %d')}"
          #title = "#{object.name} Pictures | Trailers | Reviews | Latest Updates - #{Date.today.strftime('%b %d')}" if title.blank?

          keywords = !object.meta_keywords.blank? ? object.meta_keywords : "#{object.name} review, #{object.name} trailer, #{object.name} clips, #{object.name} info, #{object.name} pictures, #{object.name} videos"
          #keywords =  "#{object.name} review, #{object.name} trailer, #{object.name} clips, #{object.name} info, #{object.name} pictures, #{object.name} videos" if keywords.blank?

          description = !object.meta_description.blank? ? object.meta_description : "#{object.name} cast and crew information, review, buzz, videos and pictures"
          #description = "#{object.name} cast and crew information, review, buzz, videos and pictures" if description.blank?

        rescue
        end
      end
    end
    title = 'Indian movies database, reviews and trailers with social networking: Muvi.com' if title.blank?
    keywords = "indian movies, hindi movies, bollywood movies, bollywood movie review, hindi movie review, telugu movies, telugu movies, telugu movie review, tamil movies, tamil movie review, hindi movie trailer, telugu movie trailer, tamil movie trailer" if keywords.blank?
    description = "indian movies, hindi movies, bollywood movies, bollywood movie review, hindi movie review, telugu movies, telugu movies, telugu movie review, tamil movies, tamil movie review, hindi movie trailer, telugu movie trailer, tamil movie trailer" if description.blank?

    content = "<title> #{title} </title> \n <meta name='keywords' content='#{keywords.chomp}' /> \n <meta name='description' content='#{description.chomp}' /> "
    content.html_safe
  end

  def create_image_middle(source, width, height)
    return image_tag(source, :style => "width:#{width}; height: #{height}")
  end

  def muvilayout_detail(source,options = {})
    options.symbolize_keys!
    tree = '<div class="moviCasts left" style="width:203px;height:70px;"><div class="actress left"><a href="'"#{options[:link_on_name]}"'">'

    #tree += '<img width='"#{options[:width]}"' height='"#{options[:height]}"' src="'"#{source}"'">'
    tree += create_image_middle(source, options[:width], options[:height])
    tree += '</a>
</div><div class="actressNames left">
<h4 class="large"><a href="'"#{options[:link_on_name]}"'">'+options[:name]+'</a></h4>'

    unless options[:subtexts].blank?
      tree += '<h4 style="color:#8891A0">'
      sublink = options[:sublink].split(",")
      count = 0
      options[:subtexts].split(",").each do |subname|
        tree += '<a href="'+sublink[count]+'" style="color:#8891A0;font-weight:normal">'+subname+'</a>, '
        count = count + 1
      end
      tree = tree.chop.chop
      tree += '</h4>'
    end
tree += '</div>
</div>'

    return "<div style='cursor:pointer' onclick=\"window.location.href='#{options[:link_on_name]}'\" >#{tree}</div>".html_safe
  end

  def get_actor_name_old(movie)
    @celeb_id = ""
    @casts = movie.movie_casts.find(:all,
                                    :select => ["celebrity_id"],
                                    :conditions => ["cast_type = 'actor'"])
    unless @casts.blank?
      @casts.each do |actor|
        unless actor.celebrity_id.blank?
          if @celeb_id.blank?
            @celeb_id = actor.celebrity_id.to_s
          else
            @celeb_id = @celeb_id.to_s + "," + actor.celebrity_id.to_s
          end
        end
      end
    end
    unless @celeb_id.blank?
      #@celeb_id = @celeb_id.chop
      @actors = Celebrity.find(:all,
                               :select => ["id, name, permalink,cell_rank"],
                               :conditions => ["id IN (#{@celeb_id})"])
    end
    return @actors
  end

  def get_movie_name(movieid)
    begin
    @movie_name = Movie.find(movieid)
      return @movie_name.name
    rescue
      if current_user && current_user.is_admin?
        return "Movie deleted"
      end
    end
  end
 
  def get_celebrity_name(celebid)
    @celebrity_name = Celebrity.find_by_id(celebid)
    return @celebrity_name ? @celebrity_name.name : ""
  end

  def create_image(source)
    return image_tag(source)
  end

  def sidebar_detail(source,options = {})
    options.symbolize_keys!
    if !options[:buzz].blank?
       #tree = '<div class="row" onmouseover=\'$(this).css("background-color", "#F0F1F3");\' onmouseout=\'$(this).css("background-color", "#FFFFFF");\'><div class="image left"><a href="'"#{options[:link_on_name]}"'"><img width='"#{options[:width]}"' height='"#{options[:height]}"' src="'"#{source}"'"></a></div><div class="reviewText" style="font-size:11px; height:auto;width:auto">'"#{options[:name]}"'</div>'

       tree = '<div class="row" onmouseover=\'$(this).css("background-color", "#F0F1F3");\'><div class="image left"><a href="'"#{options[:link_on_name]}"'">'
       tree += create_image(source)
       tree += '</a>'
       tree += '</div><div class="reviewText" style="font-size:11px; height:auto;width:auto">'"#{options[:name]}"'</div>'
       tree += '</div>'
    else
       #tree = '<div class="row ext" onmouseover=\'$(this).css("background-color", "#F0F1F3");\' onmouseout=\'$(this).css("background-color", "#FFFFFF");\'><div class="image left"><a href="'"#{options[:link_on_name]}"'"><img width='"#{options[:width]}"' height='"#{options[:height]}"' src="'"#{source}"'"></a></div>'
      tree = '<div class="row ext" onmouseover=\'$(this).css("background-color", "#F0F1F3");\'><div class="image left"><a href="'"#{options[:link_on_name]}"'">'

      #<img width='"#{options[:width]}"' height='"#{options[:height]}"' src="'"#{source}"'"></a>'

      tree += create_image(source)
      tree += '</a>'

      tree += '</div>'

       if options[:right_side_text].blank? or options[:right_side_text].to_i == 0
        tree += '<div class="names">'
       else
         tree += '<div class="names left ext_name" style="margin-right:5px">'
       end
       tree += '<h4 class="large"><a href="'"#{options[:link_on_name]}"'">'+options[:name]+'</a></h4>'    



      unless options[:subtexts].blank?
        tree += '<h4 style="color:#8891A0">'
        sublink = options[:sublink].split(",")
        count = 0
        options[:subtexts].split(",").each do |subname|
          unless sublink[count].blank?
            tree += '<a href="'+sublink[count]+'" style="color:#8891A0;font-weight:normal;">'+subname+'</a>, '
          end
          count = count + 1
        end
        tree = tree.chop.chop
        tree += '</h4>'
      end

      unless options[:second_subtext].blank?
        tree += '<label style="color:#8891A0">'"#{Time.parse(options[:second_subtext].to_s).strftime('%B %d, %Y').to_s unless options[:second_subtext].blank?}"' </label>'
      end

      tree += '</div>'

      #To show the golder/rotton egg for in theaters in sidebar
      if !options[:right_side_text].blank? and options[:right_side_text].to_i != 0
        if options[:right_side_text].to_i < 60
          color = "#C13737"
        else
          color = "#87B84B"
        end
        tree += '<div class="left" style="color:#FFFFFF; padding: 3px 4px; background-color: '"#{color}"'"><b>'"#{options[:right_side_text]}"'%</b> </div>'
      end
      #ends

      tree +=' </div>'

    end

    if !options[:end].blank? && !options[:end].nil?
      tree += '</div>'
    end

    if options[:right_side_text].blank? and options[:second_subtext].blank?
      return "<div style='cursor:pointer' onclick=\"window.location.href='#{options[:sublink]}'\" >#{tree}</div>".html_safe
    else
      return "<div style='cursor:pointer' onclick=\"window.location.href='#{options[:link_on_name]}'\" >#{tree}</div>".html_safe
    end

    return tree.html_safe
  end

  def sidebar_content(options = {})
    options.symbolize_keys!
    tree = '<div class='"#{options[:class]}"'>
    <div class="sidebar_header"><h3>'"#{options[:heading]}"'</h3>'
    unless options[:second_heading].blank?
      tree += options[:second_heading]
    end
    tree +='</div>'
    return tree.html_safe
  end

  def display_buzz_image(result)
    if result[0].to_s == 'celebrity_tweet'
      return (Twitter.profile_image("#{result[4]}", :size => 'normal')) rescue ('images/no-profile.png')
    end
  end

  def get_movie_name_of_celeb(celeb, selected_celeb)
    @movie_id = ""
    @casts = ""
    @movies = []
    if selected_celeb.blank?
      @casts = celeb.movie_casts.find(:all,
                                    :select => ["movie_id"],
                                    :conditions => ["cast_type = 'actor' and celebrity_id = #{celeb.id}"],
                                    :group => ["movie_id"])

    else
      unless celeb.blank?
        @casts = MovieCast.find_by_sql("select movie_id from movie_casts where celebrity_id = #{celeb.id}  group by movie_id intersect select movie_id from movie_casts where celebrity_id = #{selected_celeb.id} group by movie_id")
      end
    end

    unless @casts.blank?
      @casts.each do |movie|
        unless movie.movie_id.blank?
          if @movie_id.blank?
            @movie_id = movie.movie_id.to_s
          else
            @movie_id = @movie_id.to_s + ","+ movie.movie_id.to_s
          end
        end
      end
    end
  
    unless @movie_id.blank?
      @movies = Movie.find(:all,:conditions => ["id IN (#{@movie_id}) and release_date IS NOT NULL and release_date <= '#{Date.today}'"],:order => ["critics_percent desc"])
    end
    return @movies
  end

  def get_default_video(movie_id)
    video = Video.find_by_movie_id(movie_id,:conditions => ["default_video = 't'"])
    unless video.blank?
      return video
    else
      return false
    end
  end

  def get_default_trailer_old(movie_id)
    arr1 = []
    arr2 = []
    new_arr = []
    video = ""
    video_id = ""
    tagging = Tagging.find(:all, :conditions => ["tagger_id = ?",movie_id], :select => "taggable_id")
    unless tagging.blank?
      tagging.each do |t|
        arr1 << t.taggable_id
      end
    end
    trailer = Tagging.find(:all, :conditions => ["lower(tagger_type) = 'trailer'"], :select => "taggable_id")
    unless trailer.blank?
      trailer.each do |tr|
        arr2 << tr.taggable_id
      end
    end
    new_arr = (arr1 & arr2).uniq
    new_arr.each do |id|
      video_id = id
    end
    unless video_id.blank?
      return video_id
    else
      return false
    end
  end
  
  def get_default_trailer(movie_id)
     video_id = ""
     video = ""
     tagging = Tagging.find(:all, :conditions => ["tagger_id = ?  and taggable_type = 'Video'",movie_id], :select => "taggable_id")
     unless tagging.blank?
       tagging.each do |t|
         unless t.taggable_id.blank?
           if video_id.blank?
             video_id = t.taggable_id
           else
             video_id = video_id.to_s + "," + t.taggable_id.to_s
           end
         end
       end
     end
     video = Tagging.where("taggable_id IN (#{video_id})").find(:all, :conditions => ["lower(tagger_type) = 'trailer'"], :select => "taggable_id", :order => ["id desc"]) unless video_id.blank?
     unless video.blank?
       videoids = ""
       video.each do |v|
         if videoids.blank?
           videoids = v.taggable_id
         else
            #break
           videoids = videoids.to_s + "," + v.taggable_id.to_s
         end
       end
       return videoids
     else
       return false
     end
  end

  def self.celeb_upcoming_movies(celebrity)
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

  
  def upcoming_movies(celebrity)
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

  def self.celeb_top_rated_movies(celebrity)
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

  def top_rated_movies(celebrity)
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

  def full_filmography(celebrity)
    @all_movie = []
    celebrity.movie_casts.find(:all,:select => ["movie_id"], :conditions => ["movie_id IS NOT NULL"], :group => ["movie_id"]).each do |mov_cast|
         @movie_release = mov_cast.movie
         unless @movie_release.blank?
          if !@movie_release.release_date.blank? and !@movie_release.release_date.nil? and @movie_release.release_date <= Date.today
            @all_movie << @movie_release
          end
        end
    end

    unless @all_movie.blank?
      @all_movie.uniq
      begin
        @all_movie.sort!{|b,a| a.release_date <=> b.release_date }
      rescue
      end
    end
    return @all_movie
  end

  def get_actor_name(movie)
    @actors = []
    if movie && movie.movie_casts
      movie.movie_casts.each do |cast|
        case cast.cast_type
          when 'actor' then @actors << cast
        end
      end
    end
    return @actors
  end

  def user_profile_image(user)    
    unless user.profile_image_file_name.blank?
      return user.profile_image.url(:small)
    else
      return 'no-profile.png'
    end
  end

  def fetch
    puts current_user
    if !session[:invite_id].blank?
       current_user.accept_fb_invite(session[:invite_id])
    end
    #current_user.fetch_fb_feeds
    redirect_to root_path
  end

  def self.broadcast(channel, block)
    message = {:channel => channel, :data => block, :ext => {:auth_token => "FAYE_TOKEN"}}

    uri = URI.parse("#{FAYE_URL}/faye")
    Net::HTTP.post_form(uri, :message => message.to_json)
  end

  def celeb_all_movies(celeb)
    @all_movies = celeb.movie_casts.find(:all, :select => ["movie_id"], :conditions => ["movie_id IS NOT NULL and films.id IS NOT NULL and films.release_date <= NOW()"],:joins => ["LEFT JOIN films on films.id = movie_casts.movie_id"], :group => ["movie_id"])
    return @all_movies
  end


  def self.celeb_play_movies(celebrity)
    @play_movie = []
    celebrity.movie_casts.find(:all,:select => ["movie_id"], :conditions => ["movie_id IS NOT NULL"], :group => ["movie_id"]).each do |mov_cast|
         @movie_release = mov_cast.movie
         unless @movie_release.blank?
          if !@movie_release.release_date.blank? and !@movie_release.release_date.nil? and @movie_release.release_date <= Date.today
	    check_stream = MovieStream.find_by_movie_id(@movie_release.id)
	    unless check_stream.blank?
		if !check_stream.youtube.blank? || !check_stream.full_movie.blank?
	            @play_movie << @movie_release
		end
	    end
          end
        end
    end

    unless @play_movie.blank?
      @play_movie.uniq
      begin
        @play_movie.sort!{|b,a| a.muvimeter <=> b.muvimeter }
      rescue
      end
    end
    return @play_movie
  end


end

