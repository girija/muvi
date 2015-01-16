class MobileController < ApplicationController
  require 'json'
  include ActionView::Helpers::DateHelper
  skip_before_filter :authenticate_user!, :verify_authenticity_token
  
  def test_console
    puts "dddddddddddddddddddddddd"
    render :text => "ffffffffffffff"
  end
  def authenticate
    @u = []
    username = params[:username]
    password = params[:password]
    user = User.find_for_authentication(:email => username)
    unless user.nil?
      logged_in = user.valid_password?(password) ? user : nil
    end
    unless logged_in.nil?
      current_user = user
      @u << {:logged_in => 1, :id => user.id, :name => user.display_name}

      render :json => JSON.pretty_generate(@u)
    else
      @u << {:logged_in => 0}
      render :json => JSON.pretty_generate(@u)
    end
  end

  def register_user
    @r = []
    u = User.find_by_email(params[:email])
    unless u.blank?
      @r << {:logged_in => 1, :id => u.id, :name => u.display_name}
      render :json => JSON.pretty_generate(@r)
    else
      @u = User.new
      @u.email = params[:email]
      @u.password = params[:password]
      @u.save

      #Save user profile
      @up = UserProfile.new
      @up.display_name = params[:name]
      @up.user_id = @u.id
      @up.save

      #Save User token for FB register
      unless params[:uid].blank?
        @ut = UserToken.new
        @ut.user_id = @u.id
        @ut.uid = params[:uid]
        @ut.token = params[:token]
        @ut.provider = "facebook"
        @ut.save
      end

      @r << {:logged_in => 1, :id => @u.id, :name => @up.display_name}
      render :json => JSON.pretty_generate(@r)
    end
  end
  
  def list_for_mobile
    offset = params[:offset]
    current_date = Date.today
      if params[:move] == 'up'
        @muvies = Movie.select("id, name, poster_file_name, muvimeter, release_date").order("release_date asc nulls last, id").where("release_date > ?", current_date).limit(4).offset(offset).reverse!
      elsif params[:move] == 'down'
        @muvies = Movie.select("id, name, poster_file_name, muvimeter, release_date").order("release_date desc nulls last, id").where("release_date <= ?" , current_date).limit(4).offset(offset)
      else      
        @muvies = Movie.select("id, name, poster_file_name, muvimeter, release_date").order("release_date desc nulls last, id").where("release_date <= ?" , current_date).limit(7)
    end
    @muvies.each do |muvi|
      @actors = []
      muvi.movie_casts.each do |cast|
        case cast.cast_type
          when 'actor' then @actors << cast
        end
        if @actors.size == 2
          break
        end 
      end
      actor_name = ''
      @actors.each do |act|
        unless act.celebrity.blank?
         if actor_name.blank?
          actor_name = act.celebrity.name
         else
           actor_name = actor_name + ", "+ act.celebrity.name
         end
        end
      end
      muvi["release_on"] = muvi.release_date.strftime('%b %g, %Y')
      if FileTest.exists?("public#{muvi.banner_image.gsub("%20", " ")}")
        #muvi["picture"] =    Base64.encode64(File.read("public#{muvi.banner_image}"))
        muvi["img_url"] = muvi.banner_image
      else
        #muvi["picture"] =    Base64.encode64(File.read("public/images/no-image.png"))
        muvi["img_url"] = "/images/no-image.png"
      end
      muvi["cast"] = actor_name
    end
    ActiveRecord::Base.include_root_in_json = false
    render :json => @muvies.to_json
  end

  def save_review
    @movie = Movie.find_using_id(params[:movie_id]).first
    @review = Review.where(:user_id => params[:user_id],:movie_id => @movie.id)
    if @review.size > 0
      @review = Review.where(:user_id => params[:user_id], :movie_id => @movie.id).first
      unless params[:description].blank?
        if @review.description != params[:description] or  @review.rating != params[:rating].to_f
          @review.update_attributes(:description =>  params[:description])
        end
      else
        if @review.rating != params[:rating].to_f
          @review.update_attributes(:rating =>  params[:rating])
        end
      end
    else
      @movie.reviews.create(:user_id => params[:user_id],:rating => params[:rating])
    end
    #######################
    # After review, clear want to see record
    @count = WantToSee.find(:all, :select => ["id"],
                       :conditions =>["user_id = ? AND movie_id = ?", params[:user_id], @movie.id])
    if @count.size > 0
      WantToSee.delete_all(:user_id => params[:user_id], :movie_id => @movie.id)
    end
    # Ends
    #######################
    render :text => "true"
  end
  
  def upcomings_old
     up_date = !params[up_date].blank? ? Date.today : params[up_date]
     if !params[:up_date].blank?
       up_date = params[:up_date].to_date
     else
       up_date = Date.today 
     end
#     movies =  Movie.select("id, name, poster_file_name,release_date").where("release_date > ?", (Date.today-200)).order("release_date asc nulls last")
     items = {} 
     future_date = Movie.select("DISTINCT(release_date) as rd").where("release_date > ?", up_date).order("release_date asc nulls last").limit(3)
     future_date.each do |d|
        current_date = d[:rd]
        @movies = Movie.select("id, name, poster_file_name,release_date").where("release_date = ? ", current_date.to_date)
        muvi_items = [] 
        @movies.each do |muvi|
         @actors = []
         muvi.movie_casts.each do |cast|
          case cast.cast_type
            when 'actor' then @actors << cast
          end
         end
         actor_name = ''
         @actors.each do |act|
          unless act.celebrity.blank?
           if actor_name.blank?
            actor_name = act.celebrity.name
           else
             actor_name = actor_name + ", "+ act.celebrity.name
            end
          end
         end
         muvi["release_on"] = muvi.release_date.strftime('%b %g, %Y')
         if FileTest.exists?("public#{muvi.banner_image}")
           muvi["img_url"] = muvi.banner_image
           #muvi["picture"] =    Base64.encode64(File.read("public#{muvi.banner_image}"))
         else
           muvi["img_url"] = "/images/no-image.png"
           #muvi["picture"] =    Base64.encode64(File.read("public/images/no-image.png"))
         end
         muvi["cast"] = actor_name
         muvi_items << muvi
        end
        items[current_date]  = []
        items[current_date] << muvi_items
     end 
    
     #@muvies = Movie.select("id, name, poster_file_name,release_date").comming_soon_movies.where("release_date > ?", (Date.today + 2)).order("release_date asc nulls last")
     ActiveRecord::Base.include_root_in_json = false
     render :json => items
  end


  def in_theater
    unless params[:language].blank?
      lang = params[:language].split(",")
      new_lang = ""
      unless lang.blank?
        lang.each do |l|
          unless l.blank?
            new_lang += "'"+ l + "',"
          end
        end
        new_lang = new_lang.chop
      end
    end
   
    unless new_lang.blank?
      condition = "language IN (#{new_lang})"
    else
      condition = ""
    end 
    #mov = Movie.where("release_date <= ?", Date.today).order("release_date desc").find(:all, :limit => "5")
    offset = params[:offset]
    current_date = Date.today

    if params[:term].nil? and params[:term].blank?
      if params[:move] == 'up'
        mov = Movie.select("id, name, poster_file_name, muvimeter, release_date, permalink, language").order("release_date asc nulls last").where("release_date > ?", current_date).limit(4).offset(offset).find(:all, :conditions => ["#{condition}"]).reverse!

      elsif params[:move] == 'down'
        mov = Movie.select("id, name, poster_file_name, muvimeter, release_date, permalink, language").order("release_date desc nulls last").where("release_date <= ?" , current_date).limit(4).offset(offset).find(:all, :conditions => ["#{condition}"])

      else
        up_mov = Movie.select("id, name, poster_file_name, muvimeter, release_date, permalink,language").order("release_date asc nulls last").where("release_date > ?", current_date).limit(15).find(:all, :conditions => ["#{condition}"]).reverse!
        rel_mov = Movie.select("id, name, poster_file_name, muvimeter, release_date, permalink, language").order("release_date desc nulls last").where("release_date <= ?" , current_date).limit(15).find(:all, :conditions => ["#{condition}"])
        mov = up_mov+rel_mov
      end
    else
      name = {:name_contains => params[:term].strip}
      term = params[:term].strip.gsub(/[']/, '\\\\\'')
      condition = "name ILIKE ?", "#{term}%"
      mov = Movie.select("id, name, poster_file_name, muvimeter, release_date, permalink, language").where(condition).order("name").limit(15).search(name)

    end

    #mov.map! {|m| {:name => m.name, :permalink => m.permalink}}
    #render :text => "Ext.util.JSONP.callback(#{mov.to_json})"
    @final = []
    mov.each do |m|
      @actors = []
      like_reviews = []      
      want_to_see = []
      m.movie_casts.each do |cast|
        case cast.cast_type
          when 'actor' then @actors << cast
          if @actors.size == 3
            break
          end
        end
      end
      actor_name = ''
      @actors.each do |act|
        unless act.celebrity.blank?
          if actor_name.blank?
            actor_name = act.celebrity.name
          else
            actor_name = actor_name + ", "+ act.celebrity.name
          end
        end
      end 
      thumb_image = "#{POSTER_URL}#{m.banner_image_medium}"
      banner_image = "#{POSTER_URL}#{m.banner_image}"
      muvimeter = ""
      unless m.muvimeter.blank?
        if m.muvimeter.to_i >= 60
          muvimeter = "<div style='background-color: #D8D8D8; border: 1px solid #BECBD4;border-radius: 6px;-moz-border-radius:6px; -webkit-border-radius:6px; height: 19px; padding:0px 3px 5px 2px; width: 77px;float:left;margin-right:2px'>  <div style='width:#{m.muvimeter}%; background:url(\"http://www.muvi.com/images/G-RatingBar.jpg\") repeat-x scroll 0 1px transparent; border-radius:6px;-moz-border-radius:6px; -webkit-border-radius:6px; height:17px;'>&nbsp;</div></div><div style='float:left;'>#{m.muvimeter}%</div>"

        elsif m.muvimeter.to_i < 60
          muvimeter = "<div style='background-color: #D8D8D8; border: 1px solid #BECBD4;border-radius: 6px;-moz-border-radius:6px; -webkit-border-radius:6px; height: 19px; padding: 0px 3px 5px 2px; width: 77px;float:left;margin-right:3px'><div style='width:#{m.muvimeter}%; background:url(\"http://www.muvi.com/images/R-RatingBar.jpg\") repeat-x scroll 0 1px transparent; border-radius:6px;-moz-border-radius:6px; -webkit-border-radius:6px; height:17px;'>&nbsp;</div></div><div style='float:left;'>#{m.muvimeter}%</div>"

        end
      end
      unless m.release_date.blank?
        release_date = m.release_date.strftime('%B %d, %Y')
        if m.release_date > current_date
          is_upcomming = true
        else
          is_upcomming = false
        end
      else
        release_date = "" 
      end

      if params[:user_id]
        logged_in = 1
      else
        logged_in = 0
      end
      user_like_status = ""
      user_dislike_status = ""
      user_wantsee_status = ""
      if is_upcomming
        m.want_to_sees.each do |w_see|
          if w_see.user_id.to_s == params[:user_id]
            user_wantsee_status = true
          end
          want_see = {}
          want_see[:user_id] = w_see.user_id
          want_see[:user_name] = w_see.user.display_name
          if  w_see.user.user_image =~ /http:/
              want_see[:user_image] = "#{w_see.user.user_image}"
            else
              want_see[:user_image] = "#{POSTER_URL}#{w_see.user.user_image}"
            end
            want_to_see << want_see
        end
      else
        m.reviews.each do |review|
          if review.rating > 3
            if review.user_id.to_s == params[:user_id]
              user_like_status = true
            end
            rev = {}
            rev[:user_id] = review.user_id
            rev[:user_name] = review.user.display_name
            if  review.user.user_image =~ /http:/
              rev[:user_image] = "#{review.user.user_image}"
            else
              rev[:user_image] = "#{POSTER_URL}#{review.user.user_image}"
            end
            like_reviews << rev
          else
            if review.user_id.to_s == params[:user_id]
              user_dislike_status = true
            end
          end
        end
      end
      @final << {:id => m.id, :name => m.name, :permalink => m.permalink, :thumb_image => "#{thumb_image}", :banner_image => "#{banner_image}", :actor => actor_name, :muvimeter => muvimeter.html_safe, :release_date => release_date, :is_logged_in => logged_in,:muvimeter_percent => m.muvimeter.to_i,:like_reviews => like_reviews,:user_like_status=>user_like_status,:user_dislike_status=>user_dislike_status,:is_upcomming => is_upcomming, :language => m.language,:user_wantsee_status => user_wantsee_status,:want_to_see => want_to_see}
    end
    render :json => JSON.pretty_generate(@final) 
  end
  def has_review
    m = Movie.find(params[:movie_id])
    if current_user && current_user.reviwed_movie?(m)
        render :text => "Ext.util.JSONP.callback(#{current_user.my_rating(m).to_i})"
      else
        render :text => "Ext.util.JSONP.callback(0)"
    end
  end

  def get_user_token
    user = User.select("token").find_by_id(params[:user_id])
    unless user.blank?
      @final = [:user_info => user]
      render :json => @final.to_json
    else
      render :json => [:error => "user does not exist"].to_json
    end
  end

  def get_user_details
    #unless current_user.blank?
      user = User.select("id, email, facebook_id, encrypted_password").find_by_id_and_token(params[:user_id], params[:token])
      if user
        up = UserProfile.select("display_name").find_by_user_id(user.id)
        ua = UserAddress.find_by_user_id(user.id)

        user_image = ""
        unless user.user_profile.blank?
          unless user.user_profile.profile_image_file_name.blank?
            user_image = "/system/profile_images/#{user.user_profile.id}/small/#{user.user_profile.profile_image_file_name.gsub(' ', '%20')}"
          else
            unless user.facebook_id.blank?
              user_image = "http://graph.facebook.com/#{user.facebook_id}/picture?type=normal"
            else
              user_image = "/images/no-profile.png"
            end
          end
        else
          user_image = "/images/no-profile.png"
        end

        @final = [:user_info => user, :user_profile => up, :user_address => ua, :user_image => user_image]
        render :json => @final.to_json
      end
    #else
    #  render :json => [:error => "Please login to view user details"].to_json
    #end
  end

  def get_movie_details
    puts "get_movie_details func"
    @movie_final = []
    m = Movie.find_by_id(params[:movie_id])
    current_date = Date.today
    @final = []
    @actors = []
    @cast_detail = []
    @episode_detail = []

    movie_stream = MovieStream.find(:all, :conditions => ["movie_id = #{m.id} and episode_number IS NOT NULL and is_episode = 1"])
    unless movie_stream.blank?
      movie_stream.each do |ms|
	episode = {}
        episode["episode_number"] = ms.episode_number
        episode["episode_title"] = ms.episode_title
        episode["episode_story"] = ms.episode_story
        episode["episode_date"] = ms.episode_date
	episode["series_number"] = ms.series_number

	unless ms.full_movie.blank?
	  episode["episode_path"] = ms.full_movie
	else
	  episode["episode_path"] = ms.youtube
	end

	episode_poster = ""
	tagging = Tagging.find(:first, :conditions => ["tagger_id = ?  and taggable_type = 'Episode' and tagger_type='Movie'",ms.id], :select => "taggable_id")
        unless tagging.blank?
	  @poster_id = Tagging.where("taggable_id = #{tagging.taggable_id}").find(:first, :conditions => ["lower(tagger_type) = 'episode'"], :select => "taggable_id")
	  poster = Poster.find_by_id(@poster_id.taggable_id)
	  unless poster.poster_file_name.blank?
  	    episode_poster = "#{POSTER_URL}/system/posters/#{poster.id}/medium/#{poster.poster_file_name.gsub(" ", "%20")}"		         else
            episode_poster =  "#{POSTER_URL}/images/no-image.png"
	  end
	end
	episode["episode_poster"] = episode_poster

	@episode_detail << episode
      end
    end


    m.movie_casts.includes(:celebrity).each do |cast|
      if cast.cast_type == 'actor'
        celeb = {}
        celeb["celeb_id"] = cast.celebrity_id

        unless cast.celebrity.blank?
          celeb["celeb_name"] = cast.celebrity.name
          celeb["celeb_image"] = "#{POSTER_URL}#{cast.celebrity.thumb_image}"
          celeb["permalink"] = cast.celebrity.permalink
        end

        celeb["role_name"] = cast.role_name
        @cast_detail << celeb
      end
    end
    m.movie_casts.each do |cast|
      case cast.cast_type
        when 'actor' then @actors << cast
        if @actors.size == 2
          break
        end
      end
    end
    actor_name = ''
    @actors.each do |act|
      unless act.celebrity.blank?
        if actor_name.blank?
          actor_name = act.celebrity.name
        else
          actor_name = actor_name + ", "+ act.celebrity.name
        end
      end
    end
    thumb_image = "#{POSTER_URL}#{m.banner_image_medium}"
    banner_image = "#{POSTER_URL}#{m.banner_image}"
    discussions = []
    m.discussions.reverse.first(3).each do |discussion|
      comment = {}
      comment["id"] = discussion.id
      comment["question"] = discussion.question
      #comment["description"] = discussion.description
      comment["user"] = {}
      comment["user_id"] = discussion.user_id
      user = User.find_by_id(discussion.user_id)
      if user
        user_profile = UserProfile.find_by_user_id(discussion.user_id)
        comment["time_diff"] = distance_of_time_in_words(Time.now,discussion.created_at) + " ago"
        unless user_profile.blank?
          comment["user_name"] = user_profile.display_name
        end
        comment["user_image"] = "#{POSTER_URL}#{user.user_image}"
        discussions <<  comment
      end
    end
      
    unless m.genre.blank?
      genre = m.genre
    else
      genre = ""
    end
  
    unless m.release_date.blank?
      if m.release_date > current_date
        is_upcomming = true
      else
        is_upcomming = false
      end
    end

    unless m.release_date.blank?
      release_date = m.release_date.strftime('%B %d, %Y')
    else
      release_date = ""
    end
      
    if params[:user_id]
      logged_in = 1
    else
      logged_in = 0
    end
    user_like_status = ""
    user_dislike_status = ""
    user_wsee_status = ""
    like_reviews = []
    p(m.want_to_sees)
    puts "special log message"
    m.want_to_sees.each do |w_see|
      if w_see.user_id.to_s == params[:user_id]
        user_wsee_status = true
      end
    end
    m.reviews.each do |review|
      if review.rating > 3
        if review.user_id.to_s == params[:user_id]
          user_like_status = true
        end
        rev = {}
        rev[:user_id] = review.user_id
        rev[:user_name] = review.user.display_name
        if  review.user.user_image =~ /http:/
          rev[:user_image] = "#{review.user.user_image}"
        else
          rev[:user_image] = "#{POSTER_URL}#{review.user.user_image}"
        end
        like_reviews << rev
      else
        if review.user_id.to_s == params[:user_id]
          user_dislike_status = true
        end
      end
    end

    @movie_final << {:id => m.id, :name => m.name, :content_type => m.content_type, :story => m.story, :permalink => m.permalink, :thumb_image => "#{thumb_image}", :banner_image => "#{banner_image}", :actor => actor_name, :muvimeter =>  m.muvimeter.to_i, :tweet_percent => m.tweet_percent.to_i, :release_date => release_date, :is_logged_in => logged_in,:discussions => discussions,:genre => genre,:cast_detail => @cast_detail,:like_reviews => like_reviews,:user_dislike_status=>user_dislike_status,:user_like_status=>user_like_status,:is_upcomming=>is_upcomming,:user_wsee_status => user_wsee_status, :episode_detail => @episode_detail}
    render :json => @movie_final.to_json
  end
  
  def fetch_details
    @item_final = []
    posters = []
    videos = []
    user_reviews = []
    if params[:fetch_type] == "picture"
      movie = params[:item_type].constantize.find_using_id(params[:item_id]).first
      poster_list = Poster.get_poster(movie.id, params[:item_type], "Poster")
      posters = []
      poster_list.each do |poster|
        pic = {}
        pic[:id] = poster.id
        pic[:name] = poster.name
        pic[:path] = "#{POSTER_URL}/system/posters/#{poster.id}/medium/#{poster.poster_file_name.gsub(" ", "%20")}"
        posters << pic
      end
    elsif params[:fetch_type] == "video"
      movie = params[:item_type].constantize.find_using_id(params[:item_id]).first
      video_list =  Video.get_video(movie.id, params[:item_type], "Video")
      videos = []
      video_list.each do |video|
        vid = {}
        vid[:id] = video.id
        vid[:name] = video.name
        unless video.video_remote_url.blank?
          video_id_arr = video.video_remote_url.split("/")
          video_id = video_id_arr[video_id_arr.size.to_i - 1]

          vid[:path] = "http://img.youtube.com/vi/#{video_id}/1.jpg"         
          vid[:link] = video.video_remote_url
        else
          vid[:path] = "#{POSTER_URL}/system/trailer_thumbnails/#{video.id}/1.jpg"
          vid[:link] = "#{POSTER_URL}/system/trailers/#{video.id}/original/#{video.trailer_file_name}"
        end
        videos << vid
      end
    elsif params[:fetch_type] == "review"
    end
    @item_final << {:id => movie.id, :name => movie.name, :permalink => movie.permalink, :poster_list=>posters, :video_list => videos,:user_reviews => user_reviews}
    #render :json => @item_final.to_json
    render :json => JSON.pretty_generate(@item_final)
  end

 def upcomings
    offset = params[:offset]
      if params[:move] == 'up'
        mov = Movie.where("release_date > ? or release_date IS NULL", Date.today).order("release_date asc nulls last").select("id, name, poster_file_name, tweet_percent, release_date, permalink").order("release_date asc nulls last, id").limit(4).offset(offset).reverse!

      elsif params[:move] == 'down'
        mov = Movie.where("release_date > ? or release_date IS NULL", Date.today).order("release_date asc nulls last").select("id, name, poster_file_name, tweet_percent, release_date, permalink").order("release_date desc nulls last, id").limit(4).offset(offset)

      else
        mov = Movie.where("release_date > ? or release_date IS NULL", Date.today).order("release_date asc nulls last").select("id, name, poster_file_name, tweet_percent, release_date, permalink").order("release_date desc nulls last, id").limit(7)
    end

    @final = []
    mov.each do |m|
      @actors = []
      m.movie_casts.each do |cast|
        case cast.cast_type
          when 'actor' then @actors << cast
          if @actors.size == 2
            break
          end
        end
      end
      actor_name = ''
      @actors.each do |act|
        unless act.celebrity.blank?
          if actor_name.blank?
            actor_name = act.celebrity.name
          else
            actor_name = actor_name + ", "+ act.celebrity.name
          end
        end
      end
      if FileTest.exists?("public#{m.banner_image_thumb}")
        thumb_image = "http://#{request.env["HTTP_HOST"]}#{m.banner_image_thumb}"
      else
        thumb_image = "http://#{request.env["HTTP_HOST"]}/images/no-image.png"
      end
      if FileTest.exists?("public#{m.banner_image}")
        banner_image = "http://#{request.env["HTTP_HOST"]}#{m.banner_image}"
      else
        banner_image = "http://#{request.env["HTTP_HOST"]}/images/no-image.png"
      end
      tweet_percent = ""
      unless m.tweet_percent.blank?
        if m.tweet_percent.to_i >= 60
          tweet_percent = "<div style='background-color: #D8D8D8; border: 1px solid #BECBD4;border-radius: 6px;-moz-border-radius:6px; -webkit-border-radius:6px; height: 19px; padding:0px 3px 5px 2px; width: 77px;float:left;margin-right:2px'>  <div style='width:#{m.tweet_percent}%; background:url(\"http://www.muvi.com/images/G-RatingBar.jpg\") repeat-x scroll 0 1px transparent; border-radius:6px;-moz-border-radius:6px; -webkit-border-radius:6px; height:17px;'>&nbsp;</div></div><div style='float:left;'>#{m.tweet_percent}%</div>"

        elsif m.tweet_percent.to_i < 60
          tweet_percent = "<div style='background-color: #D8D8D8; border: 1px solid #BECBD4;border-radius: 6px;-moz-border-radius:6px; -webkit-border-radius:6px; height: 19px; padding: 0px 3px 5px 2px; width: 77px;float:left;margin-right:3px'><div style='width:#{m.tweet_percent}%; background:url(\"http://www.muvi.com/images/R-RatingBar.jpg\") repeat-x scroll 0 1px transparent; border-radius:6px;-moz-border-radius:6px; -webkit-border-radius:6px; height:17px;'>&nbsp;</div></div><div style='float:left;'>#{m.tweet_percent}%</div>"

        end
      end
      unless m.release_date.blank?
        release_date = m.release_date.strftime('%B %d, %Y')
      else
        release_date = ""
      end

      if user_signed_in?
        logged_in = 1
      else
        logged_in = 0
      end

      @final << {:id => m.id, :name => m.name, :permalink => m.permalink, :thumb_image => "#{thumb_image}", :banner_image => "#{banner_image}", :actor => actor_name, :tweet_percent => tweet_percent.html_safe, :release_date => release_date, :is_logged_in => logged_in}
    end
    render :text => "Ext.util.JSONP.callback(#{@final.to_json})"
  end

  def get_movie_video
    muvi_id = params[:movie_id]
    @final_trailer = []
    video_id = ""
    video = ""
    tagging = Tagging.find(:all, :conditions => ["tagger_id = ?",muvi_id], :select => "taggable_id")
    unless tagging.blank?
      tagging.each do |t|
        if video_id.blank?
          video_id = t.taggable_id
        else
          video_id = video_id.to_s + "," + t.taggable_id.to_s
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
            videoids = videoids.to_s + "," + v.taggable_id.to_s
        end
      end
      video = Video.where("id IN (#{videoids})").find(:all,:conditions => ["rank = 1"]).first
      @final_trailer << {:trailer => video.trailer.url.gsub("%20", " ").gsub("flv", "mp4"), :video_remote_url => video.video_remote_url}
    else
      
    end
    render :text => "Ext.util.JSONP.callback(#{@final_trailer.to_json})"
  end

  def get_details
    movie = Movie.find_by_id(params[:movie_id])
    #movie = Movie.find_by_id(5495)
    unless movie.blank?
      cr = movie.critics_reviews.order("created_at desc").limit(10)
      @critics = []
      unless cr.blank?
        cr.each do |c|
          unless c.summary.blank?
            summary = c.summary.slice!(0, 120)
          else
            summary = ""
          end
          
          begin
            img = "http://#{request.env["HTTP_HOST"]}#{c.film_critic.profile_image}"
          rescue
            img = "http://#{request.env["HTTP_HOST"]}/images/no-profile.png"
          end

          begin
            c_img = "http://#{request.env["HTTP_HOST"]}#{c.critic_image}"
          rescue
            c_img = ""
          end

          begin
            name = c.film_critic.name
          rescue
            name = ""
          end
          @critics << {:id => c.id, :summary => summary, :user_image => img, :critic_image => c_img, :name => name}
        end
      end
    end
    render :text => "Ext.util.JSONP.callback(#{@critics.to_json})"
  end

  def get_critics_review
    #reviews_query = "((select 'movie_review' as model,user_id,description,rating,'' as review,'' as twitter_name,created_at from reviews where reviews.movie_id=#{params[:movie_id]} order by reviews.created_at desc) ) as temp"
    #result_review = ActiveRecord::Base.connection.select_rows("select * from #{reviews_query}")
    #user_review = []
    #profile_img = ""
    #profile_image = ""
    #profile_name = ""
    #review_description = ""
    #result_review.each do |result|
    #  profile_img = User.find(result[1]).user_image_for_mobile
    #  profile_name = User.find(result[1]).display_name
    #  review_description = result[2].slice!(0, 120) unless result[2].blank?   
    #   user_review << {:profile_image => profile_img, :profile_name => profile_name, :review_description => review_description}
    #end
   
    movie_critics_review = []
    profile_img = ""
    profile_image = ""
    critics_name = ""
    critics_org = ""
    critics_rating = ""
    review_description = ""

    @critics_review = CriticsReview.where("movie_id = ?", params[:movie_id]).published.latest.search({:movie_id_eq => params[:movie_id]})
  
    unless @critics_review.blank?
      @critics_review.each do |critics_review|
        fc = critics_review.film_critic
        unless fc.blank?
          unless fc.profile_image.blank?
            unless fc.thumbnail_image_file_name.blank?
              profile_img = "#{POSTER_URL}/system/thumbnail_images/#{fc.id}/thumb/#{fc.thumbnail_image_file_name.gsub(" ", "%20")}"
            else
              profile_img = "#{POSTER_URL}/images/no-profile.png" 
            end 
          else
            profile_image = "#{POSTER_URL}/images/no-profile.png"
          end
        end        
        review_description = critics_review.summary.slice!(0, 60) unless critics_review.summary.blank?
        critics_name = critics_review.film_critic.name
        critics_org = critics_review.film_critic.organization
        critics_rating = critics_review.rating
        movie_critics_review << {:profile_image => profile_img, :critics_name => critics_name, :review_description => review_description, :critics_org => critics_org, :critics_rating => critics_rating}
      end
    end
    #render :text => "Ext.util.JSONP.callback(#{user_review.to_json})"
    render :json => JSON.pretty_generate(movie_critics_review)
  end

  def get_movie_tweet
    twitter_query = "((select 'movie_tweet' as model,user_id,content,rating,review,twitter_screen_name as twitter_name,tweeted_on from tweets WHERE ( tweets.interest = true ) AND (tweets.review = 'pos' or tweets.review = 'neg'
 ) AND (tweets.movie_id = #{params[:movie_id]}) ) order by tweets.tweeted_on desc limit 10) as temp"
    result_twitter = ActiveRecord::Base.connection.select_rows("select * from #{twitter_query}")
    tweets = []
    tweet_image = ""
    profile_name = ""
    tweet_description = ""
    result_twitter.each do |result|
      tweet_image = "http://api.twitter.com/1/users/profile_image?screen_name=#{result[5]}"
      profile_name = result[5]
      tweet_description = result[2].slice!(0, 120)
      tweets << {:profile_image => tweet_image, :profile_name => profile_name, :tweet_description => tweet_description}
    end
    render :text => "Ext.util.JSONP.callback(#{tweets.to_json})"
  end

  def get_celeb_tweet
    twitter_query = "((select 'celebrity_tweet' as model, content,rating,review,twitter_screen_name as twitter_name,tweeted_on from celeb_tweets tweets WHERE  (tweets.fan_tweet = 't')  AND (tweets.review = 'pos' or tweets.review = 'neg' ) AND (tweets.celebrity_id = #{params[:celebrity_id]}) ) order by tweets.tweeted_on desc limit 10) as temp"
    result_twitter = ActiveRecord::Base.connection.select_rows("select * from #{twitter_query}")
    tweets = []
    tweet_image = ""
    profile_name = ""
    tweet_description = ""
  
    result_twitter.each do |result|
      tweet_image = "http://api.twitter.com/1/users/profile_image?screen_name=#{result[4]}"
      profile_name = result[4]
      tweet_description = result[1].slice!(0, 120)
      tweets << {:profile_image => tweet_image, :profile_name => profile_name, :tweet_description => tweet_description}
    end
    render :text => "Ext.util.JSONP.callback(#{tweets.to_json})"
  end

  def get_celeb_detail
    @celeb_detail = []
    @celeb = Celebrity.find_by_id(params[:celebrity_id])
    movie = []
    movie_blank_release = []
    @celeb.movie_casts.find(:all,:select => ["movie_id"], :conditions => ["movie_id IS NOT NULL"], :group => ["movie_id"], :order => ["movie_id asc"]).each do |mov_cast|
      @movie_release = mov_cast.movie
      unless @movie_release.blank?
        if !@movie_release.release_date.blank? and @movie_release.release_date > Date.today
          movie << @movie_release
        elsif @movie_release.release_date.blank?
          movie_blank_release << @movie_release
        end
      end
    end

    movie.uniq
    unless movie.blank?
     movie.sort!{|a,b| (a.release_date).strftime("%Y-%m-%d") <=> (b.release_date).strftime("%Y-%m-%d")}
    end
    movie = movie | movie_blank_release

    if FileTest.exists?("public#{@celeb.image.gsub("%20", " ")}")
      banner_image = "http://#{request.env["HTTP_HOST"]}#{@celeb.image}"
    else
      banner_image = "http://#{request.env["HTTP_HOST"]}/images/no-image.png"
    end

    popularity = ""
      unless @celeb.popularity.blank?
        if @celeb.popularity.to_i >= 60
          popularity = "<div style='background-color: #D8D8D8; border: 1px solid #BECBD4;border-radius: 6px;-moz-border-radius:6px; -webkit-border-radius:6px; height: 19px; padding:0px 3px 5px 2px; width: 77px;float:left;margin-right:2px'>  <div style='width:#{@celeb.popularity.to_i}%; background:url(\"http://www.muvi.com/images/G-RatingBar.jpg\") repeat-x scroll 0 1px transparent; border-radius:6px;-moz-border-radius:6px; -webkit-border-radius:6px; height:17px;'>&nbsp;</div></div><div style='float:left;'>#{@celeb.popularity.to_i}%</div>"

        elsif @celeb.popularity.to_i < 60
          popularity = "<div style='background-color: #D8D8D8; border: 1px solid #BECBD4;border-radius: 6px;-moz-border-radius:6px; -webkit-border-radius:6px; height: 19px; padding: 0px 3px 5px 2px; width: 77px;float:left;margin-right:3px'><div style='width:#{@celeb.popularity.to_i}%; background:url(\"http://www.muvi.com/images/R-RatingBar.jpg\") repeat-x scroll 0 1px transparent; border-radius:6px;-moz-border-radius:6px; -webkit-border-radius:6px; height:17px;'>&nbsp;</div></div><div style='float:left;'>#{@celeb.popularity.to_i}%</div>"

        end
      end

      if user_signed_in?
        logged_in = 1
      else
        logged_in = 0
      end

    upcoming = ""
    upcoming_id = ""
    unless movie.blank?
      upcoming = movie[0].name
      upcoming_id = movie[0].id
    end
    @celeb_detail << {:id => @celeb.id, :name => @celeb.name, :permalink => @celeb.permalink, :popularity => popularity, :upcoming => upcoming, :upcoming_id => upcoming_id, :banner_image => "#{banner_image}", :is_logged_in => logged_in}

    render :text => "Ext.util.JSONP.callback(#{@celeb_detail.to_json})"
  end

  def get_details_old
      
      if params[:type] == 'celeb'
        celeb = {} 

        @celeb = Celebrity.find_by_id(params[:id])    
        celeb['name'] = @celeb.name
        celeb['id'] = @celeb.id
        celeb['popularity'] = @celeb.popularity.to_i
        celeb_img = @celeb.image
        if FileTest.exists?("public#{celeb_img.gsub("%20", " ")}")
         celeb['picture'] = celeb_img
         #celeb['picture'] = Base64.encode64(File.read("public#{celeb_img}"))
        else
          celeb['picture'] =  "/images/no-profile.png"
          #celeb['picture'] =  Base64.encode64(File.read("public/images/no-profile.png"))
        end

        movie = []
        movie_blank_release = []
        @celeb.movie_casts.find(:all,:select => ["movie_id"], :conditions => ["movie_id IS NOT NULL"], :group => ["movie_id"], :order => ["movie_id asc"]).each do |mov_cast|
          @movie_release = mov_cast.movie
          unless @movie_release.blank?
            if !@movie_release.release_date.blank? and @movie_release.release_date > Date.today
              movie << @movie_release
            elsif @movie_release.release_date.blank?
              movie_blank_release << @movie_release
            end
          end
        end
        movie.uniq
        unless @movie.blank?
         movie.sort!{|a,b| (a.release_date).strftime("%Y-%m-%d") <=> (b.release_date).strftime("%Y-%m-%d")}
        end
        movie = movie | movie_blank_release
        celeb['upcoming'] =  movie
        ActiveRecord::Base.include_root_in_json = false
        render :json => celeb

      else
       @muvies = Movie.select("id,name,poster_file_name, muvimeter, release_date, permalink, tweet_percent").where("id = ?", params[:id])
       @muvies.each do |muvi|

        # videos = Video.get_video(muvi.id, "Movie", "Video")
        # muvi['videos'] = videos

         @actors = []
         muvi.movie_casts.each do |cast|
          case cast.cast_type
            when 'actor' then @actors << cast
          end
          if @actors.size == 4 
            break
          end
        end
        actor_name = ''
        @actors.each do |act|
          unless act.celebrity.blank?
            if actor_name.blank?
              actor_name = "<a href='celebdetails.html?id=#{act.celebrity.id}'>#{act.celebrity.name}</a>"
            else
              actor_name = actor_name + ", <a href='celebdetails.html?id=#{act.celebrity.id}'>#{act.celebrity.name}</a>"
            end
          end
        end
        muvi["release_on"] = muvi.release_date.strftime('%b %g, %Y')
        if FileTest.exists?("public#{muvi.banner_image}")
          #muvi["picture"] =    Base64.encode64(File.read("public#{muvi.banner_image}"))
          muvi["img_url"] = muvi.banner_image
        else
          #muvi["picture"] =  Base64.encode64(File.read("public/images/no-image.png"))
          muvi["img_url"] = "/images/no-image.png"
        end
        muvi["cast"] = actor_name
        video_id = ""
        video = ""
        tagging = Tagging.find(:all, :conditions => ["tagger_id = ?",muvi.id], :select => "taggable_id")
        unless tagging.blank?
          tagging.each do |t|
            if video_id.blank?
              video_id = t.taggable_id
            else
              video_id = video_id.to_s + "," + t.taggable_id.to_s
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
            videoids = videoids.to_s + "," + v.taggable_id.to_s
          end
        end
        video = Video.where("id IN (#{videoids})").find(:all,:conditions => ["rank = 1"]).first
        muvi['trailer'] = video.trailer.url.gsub("%20", " ").gsub("flv", "mp4")
       # muvi['trailer'] = videoids.trailer
     end
      
        critics_review = [] 
        muvi.critics_reviews.each do |critic|   
          review = {}
          profile_img = critic.film_critic.profile_image
          review['tr'] = profile_img
          if FileTest.exists?("public#{profile_img}")
            review['image'] = profile_img
            #review['image'] =    Base64.encode64(File.read("public#{profile_img}"))
          else
             review['image'] = "/public/images/no-profile.png"
             #review['image']  =    Base64.encode64(File.read("public/images/no-profile.png"))
          end

          review['name'] = critic.film_critic.name
          review['description'] = critic[:summary] 
          critics_review << review
        end
        
        muvi['critic_reviews'] =  critics_review
   
        reviews_query = "((select 'movie_review' as model,user_id,description,rating,'' as review,'' as twitter_name,created_at from reviews where reviews.movie_id=#{muvi.id} order by reviews.created_at desc) ) as temp"
        result_review = ActiveRecord::Base.connection.select_rows("select * from #{reviews_query}")
        user_review = []
        result_review.each do |result|
          review = {} 
          if result[0].to_s == 'movie_tweet'
            profile_img = Twitter.profile_image("#{result[5]}", :size => 'normal') rescue 'no-profile.png'
            profile_name = result[5]
          elsif result[0].to_s == 'celebrity_tweet'
            profile_img = Twitter.profile_image("#{result[4]}", :size => 'normal') rescue 'no-profile.png'
            profile_name = result[4]
          else
            profile_img = User.find(result[1]).image
            profile_name = User.find(result[1]).display_name
          end
          review['tr'] = profile_img
          if FileTest.exists?("public#{profile_img}")
            review['image'] = profile_img
            #review['image'] =    Base64.encode64(File.read("public#{profile_img}"))
          else
            review['image'] = "/public/images/no-profile.png"
            #review['image']  =    Base64.encode64(File.read("public/images/no-profile.png"))
          end
          review['name'] = profile_name
          review['description'] = result[2]
          user_review << review
        end
      
        muvi['user_reviews'] =  user_review 
      end
      ActiveRecord::Base.include_root_in_json = false
      render :json => @muvies.to_json
    end
  end
  
  def celebs_old
    celebrities = [] 
    if params[:type] == 'birthday'
      celebrities = Celebrity.where("(extract(day from birthdate) = extract(day from now())) and (extract(month from birthdate) = extract(month from now()))").find(:all) 
    elsif params[:type] == 'intheater'
      @celeb_theater = HomePageSetting.where("page_no = 2 and item_id = 1 and subject_type_id = 1").find(:all)
      @celeb_theater.each do |celeb_theater|
        celebrities <<  Celebrity.find_by_id(celeb_theater.subject_id)
      end

    end
    celebs = []    
    celebrities.each do |celeb| 
       celebrity = {} 
       celeb_img = celeb.image 
       if FileTest.exists?("public#{celeb_img.gsub("%20", " ")}")
         #celebrity['image'] = Base64.encode64(File.read("public#{celeb_img}"))
         celebrity['image_url'] = celeb_img
       else
         #celebrity['image'] =  Base64.encode64(File.read("public/images/no-profile.png"))
         celebrity['image_url'] = "public/images/no-profile.png"
       end
        celebrity[:name] = celeb.name
        celebrity[:id] = celeb.id
        celebs << celebrity
    end
      
    ActiveRecord::Base.include_root_in_json = false
    render :json => celebs.to_json
  end

  def celebs
    celebrities = []
    bday_count = 0
    celebrities = Celebrity.where("(extract(day from birthdate) = extract(day from now())) and (extract(month from birthdate) = extract(month from now()))").find(:all)
    #celebrities = Celebrity.find(:all, :limit => 5, :order => ["id asc"])
    bday_count = celebrities.size

    @celeb_theater = HomePageSetting.where("page_no = 2 and item_id = 1 and subject_type_id = 1").find(:all)
    @celeb_theater.each do |celeb_theater|
      celebrities <<  Celebrity.find_by_id(celeb_theater.subject_id)
    end

    @celebs = []
    celebrities.each do |celeb|
      if FileTest.exists?("public#{celeb.thumb_image.gsub("%20", " ")}")
        thumb_image = "http://#{request.env["HTTP_HOST"]}#{celeb.thumb_image}"
      else
        thumb_image = "http://#{request.env["HTTP_HOST"]}/images/no-image.png"
      end
      if FileTest.exists?("public#{celeb.image.gsub("%20", " ")}")
        banner_image = "http://#{request.env["HTTP_HOST"]}#{celeb.image}"
      else
        banner_image = "http://#{request.env["HTTP_HOST"]}/images/no-image.png"
      end


      @celebs << {:id => celeb.id, :name => celeb.name, :permalink => celeb.permalink, :thumb_image => "#{thumb_image}", :banner_image => "#{banner_image}", :bday_count => bday_count}
    end

      render :text => "Ext.util.JSONP.callback(#{@celebs.to_json})"
  end


  def searchx
    total = 15
    total_name_list = []
    term = params[:term].strip.gsub(/[']/, '\\\\\'')
    condition = "name ILIKE ?", "#{term}%"
    items = {}

    @movies =  Movie.select("id, name, poster_file_name, muvimeter, release_date").where(condition).order("release_date desc nulls last, name ASC")
    items['movies'] = []
    @movies.each do |item|
      actors = []
      item.movie_casts.each do |cast|
        case cast.cast_type
          when 'actor' then actors << cast
        end
      end
      actor_name = ''
      actors.each do |act|
        unless act.celebrity.blank?
         if actor_name.blank?
          actor_name = act.celebrity.name
         else
           actor_name = actor_name + ", "+ act.celebrity.name
         end
        end
      end
      item["cast"] = actor_name
      if FileTest.exists?("public#{item.banner_image}")
        item["picture"] =    Base64.encode64(File.read("public#{item.banner_image}"))
      else
        item["picture"] =    Base64.encode64(File.read("public/images/no-image.png"))
      end
      items['movies'] << item
    end

    @celebrities = Celebrity.where(condition).order("cell_rank ASC nulls last, name ASC")
    items['celebs'] = []
    @celebrities.each do |item|
      celeb = {} 
      celeb_img = celeb.image 
       if FileTest.exists?("public#{celeb_img.gsub("%20", " ")}")
         celeb['picture'] = Base64.encode64(File.read("public#{celeb_img}"))
       else
         celeb['picture'] =  Base64.encode64(File.read("public/images/no-profile.png"))
       end
       celeb['name'] = item['name']
       celeb['id'] = item.id
      items['celebs'] << celeb
    end
    result = {}
    result['items'] = []
    result['items'] << items
    ActiveRecord::Base.include_root_in_json = false
    render :json => result.to_json
    return

    unless first_name_list.blank?
      first_name_list .each do |c|
        total_name_list << c
      end
    end

    if total_name_list.size < total
      name_needed = total - total_name_list.size
      if request.env["HTTP_REFERER"] =~ /celebrities/
        second_name_list = Movie.select("id, name, poster_file_name, muvimeter, release_date").where(condition).order("release_date desc nulls last, name ASC").search.paginate(:page => 1, :per_page => name_needed)
      else
        second_name_list = Celebrity.where(condition).order("cell_rank ASC nulls last, name ASC").search.paginate(:page => 1, :per_page => name_needed).collect(&:name)
      end
      unless second_name_list.blank?
        second_name_list.each do |m|
          if total_name_list.size == total
            break
          else
            total_name_list << m
          end
        end
      end
    end

    if total_name_list.size < total
      user_needed = total - total_name_list.size
      user_name_list = UserProfile.where("user_profiles.user_id IS NOT NULL and display_name ILIKE ?", "#{term}%").joins("inner join user_tokens on user_profiles.user_id = user_tokens.user_id").search.paginate(:page => 1, :per_page => user_needed).collect(&:display_name)

      unless user_name_list.blank?
        user_name_list.each do |u|
          if total_name_list.size == total
            break
          else
            total_name_list << u
          end
        end
      end
    end
    ActiveRecord::Base.include_root_in_json = false

    render :json => total_name_list.to_json

  end
  def search
    total_name_list = []
    name = {:name_contains => params[:term].strip}
    term = params[:term].strip.gsub(/[']/, '\\\\\'')
    condition = "name ILIKE ?", "#{term}%"
    @movies = Movie.select("id, name, poster_file_name, muvimeter, release_date, permalink").where(condition).order("name").search(name)
    @movies.meta_sort ||= 'name.asc'
    @movies = @movies.all.paginate :page => 1, :per_page => 30

    #@celebrities = Celebrity.search :name_starts_with =>  "#{term}"
    #@celebrities.meta_sort ||= 'name.asc'
    #@celebrities = @celebrities.all.paginate :page => 1, :per_page => 5

    #@users = UserProfile.search :display_name_starts_with => "#{term}"
    #@users.meta_sort ||= 'display_name.asc'
    #@users = @users.all.paginate :page => 1, :per_page => 5

    unless @movies.blank?
      @movies.each do |movie|
        @actors = []
        movie.movie_casts.each do |cast|
          case cast.cast_type
            when 'actor' then @actors << cast
            if @actors.size == 2
              break
            end
          end
        end
        actor_name = ''
        @actors.each do |act|
          unless act.celebrity.blank?
            if actor_name.blank?
              actor_name = act.celebrity.name
            else
              actor_name = actor_name + ", "+ act.celebrity.name
            end
          end
        end
        #if FileTest.exists?("public#{movie.banner_image}")
        #   img_url = movie.banner_image
        #else    
        #   img_url = "/images/no-image.png"
        #end

        url = URI.parse(POSTER_URL + "#{movie.banner_image_medium}")
        req = Net::HTTP::Get.new(url.path)
        result = Net::HTTP.start(url.host, url.port) { |http| http.get(url.path) }
        if result.code == "200"
          thumb_image = "#{POSTER_URL}#{movie.banner_image_medium}"
        else
          thumb_image = "#{POSTER_URL}/images/no-image.png"
        end

        url_1 = URI.parse(POSTER_URL + "#{movie.banner_image}")
        req_1 = Net::HTTP::Get.new(url_1.path)
        result_1 = Net::HTTP.start(url_1.host, url_1.port) { |http| http.get(url_1.path) }
        if result_1.code == "200"
          banner_image = "#{POSTER_URL}#{movie.banner_image}"
        else
          banner_image = "#{POSTER_URL}/images/no-image.png"
        end



        muvimeter = ""
        unless movie.muvimeter.blank?
          if movie.muvimeter.to_i >= 60
            muvimeter = "<div style='background-color: #D8D8D8; border: 1px solid #BECBD4;border-radius: 6px;-moz-border-radius:6px; -webkit-border-radius:6px; height: 19px; padding:0px 3px 5px 2px; width: 77px;float:left;margin-right:2px'>  <div style='width:#{movie.muvimeter}%; background:url(\"http://www.muvi.com/images/G-RatingBar.jpg\") repeat-x scroll 0 1px transparent; border-radius:6px;-moz-border-radius:6px; -webkit-border-radius:6px; height:17px;'>&nbsp;</div></div><div style='float:left;'>#{movie.muvimeter}%</div>"

          elsif movie.muvimeter.to_i < 60
            muvimeter = "<div style='background-color: #D8D8D8; border: 1px solid #BECBD4;border-radius: 6px;-moz-border-radius:6px; -webkit-border-radius:6px; height: 19px; padding: 0px 3px 5px 2px; width: 77px;float:left;margin-right:3px'><div style='width:#{movie.muvimeter}%; background:url(\"http://www.muvi.com/images/R-RatingBar.jpg\") repeat-x scroll 0 1px transparent; border-radius:6px;-moz-border-radius:6px; -webkit-border-radius:6px; height:17px;'>&nbsp;</div></div><div style='float:left;'>#{movie.muvimeter}%</div>"

          end
        end

        unless movie.release_date.blank?
          release_date = movie.release_date.strftime('%b %g, %Y')
        else
          release_date = ""
        end

        if user_signed_in?
          logged_in = 1
        else	
          logged_in = 0
        end

        total_name_list << {:id => movie.id, :name => movie.name, :permalink => movie.permalink, :thumb_image => "#{thumb_image}", :banner_image => "#{banner_image}", :actor => actor_name, :muvimeter_percent => movie.muvimeter, :release_date => release_date, :is_logged_in => logged_in}
        #total_name_list << {:label => movie.name,:img=>img_url,:cat => "movie",:id => movie.id}
      end
    end
   # unless @celebrities.blank?
   #  @celebrities .each do |celeb|
   #     total_name_list << {:label => celeb.name,:img=>celeb.thumb_image,:cat=>"celebrity", :id => celeb.id}
   #   end
   # end
   # unless @users.blank?
   #   @users .each do |user|
   #     total_name_list << {:label => user.display_name,:img=>user.user.user_image,:cat=>"user", :id => user.id}
   #   end
   # end
    muvi = {} 
    muvi['items'] = total_name_list
    #render :text => "Ext.util.JSONP.callback(#{total_name_list.to_json})"
    render :json => JSON.pretty_generate(total_name_list)
  end
  def is_logged_in
    if user_signed_in?
      render :json => JSON.pretty_generate('yes')
      #render :text => "Ext.util.JSONP.callback('yes')"
    else
      render :json => JSON.pretty_generate('result' => 'no')
      #render :text => "Ext.util.JSONP.callback('no')"
    end 
  end

  def check_fan
    celeb_id = params[:celebrity_id]
    @count = Fan.find(:all,
            :select => ["id"],
            :conditions =>["user_id = ? AND celebrity_id = ?", current_user.id, params[:celebrity_id]])
    if @count.size == 0
      render :text => "Ext.util.JSONP.callback('no')"
    else
      render :text => "Ext.util.JSONP.callback('yes')"
    end
  end

  def check_watch
    movie_id = params[:movie_id]
    @count = WantToSee.find(:all,
            :select => ["id"],
            :conditions =>["user_id = ? AND movie_id = ?", current_user.id, movie_id])
    if @count.size == 0
      render :text => "Ext.util.JSONP.callback('no')"
    else
      render :text => "Ext.util.JSONP.callback('yes')"
    end
  end

  def get_item_detail
    @item_detail = []
    user_id = params[:user_id]
    @item = params[:item_type].capitalize.constantize.find_by_id(params[:item_id])
    @item_likes = @item.like_votes
    @item_dislikes = @item.dislike_votes
    @item_comments = @item.comments
    user_like_status = ""
    user_dislike_status = ""
    like_votes = []
    @item_dislikes.each do |d_vote|
      if d_vote.voter_id.to_s == params[:user_id]
        user_dislike_status = true
      end
    end
    @item_likes.each do |l_vote|
      if l_vote.voter_id.to_s == params[:user_id]
        user_like_status = true
      end
      rev = {}
      l_user = User.find_by_id(l_vote.voter_id)
      rev[:user_id] = l_vote.voter_id
      rev[:user_name] = l_user.display_name
      if  l_user.user_image =~ /http:/
        rev[:user_image] = "#{l_user.user_image}"
      else
        rev[:user_image] = "#{POSTER_URL}#{l_user.user_image}"
      end
      like_votes << rev
    end
    
    item_comments = []
    @item_comments.each do |comment|
      com = {}
      com["id"] = comment.id
      com["comment"] = comment.comment
      com["user_id"] = comment.user_id
      user = comment.user#User.find_by_id(discussion.user_id)
      if user
        #user_profile = UserProfile.find_by_user_id(discussion.user_id)
        com["time_diff"] = distance_of_time_in_words(Time.now,comment.created_at) + " ago"
        com["user_name"] = user.user_profile.display_name
        com["user_image"] = "#{POSTER_URL}#{user.user_image}"
        item_comments <<  com
      end
    end
    @item_detail << {:id => @item.id, :name => @item.name, :comments => item_comments,:like_votes => like_votes,:user_dislike_status=>user_dislike_status,:user_like_status=>user_like_status}
    render :json => @item_detail.to_json
  end
  
  def vote_item
    @item = params[:item_type].capitalize.constantize.find_by_id(params[:item_id])
    user = User.find_by_id(params[:user_id])
    @item.vote :voter =>user, :vote => params[:rating]
    render :text => "true"
  end

  def want_see
    @movie = Movie.find_by_permalink(params[:movie_id])
    @count = WantToSee.check_user(params[:user_id],@movie.id)
    if @count.blank?
      @want_to_see = WantToSee.new
      @want_to_see.user_id = params[:user_id]
      @want_to_see.movie_id = @movie.id
      @want_to_see.is_want_to_see = true
      @want_to_see.save
    end
    render :text => "true"
  end  

  def fetch_items
    @item_detail = []
    remote_url = "http://dfquahprf1i3f.cloudfront.net/public"
    lang = params[:language].split(",")
    lang_no = {"Hindi" => 10,"English" => 20, "Tamil" => 30, "Telugu" => 40}
    new_lang = ""
    unless lang.blank?
      lang.each do |l|
        unless l.blank?
          new_lang += lang_no[l].to_s + ","
        end
      end
      new_lang = new_lang.chop
    end
    unless new_lang.blank?
      condition = "language IN (#{new_lang})"
    else
      condition = ""
    end
    if params[:type] == "trailers"
      @items = HomePageSetting.where("page_no IN (#{new_lang}) and subject_type = 'Video'")
      @items.each do |item|
        user_like_status = ""
        user_dislike_status = ""
        like_votes = []

        video = Video.find_by_id(item.subject_id)
        unless video.video_remote_url.blank?
          video_path = video.video_remote_url
          video_id_arr = video.video_remote_url.split("/")
          video_id = video_id_arr[video_id_arr.size.to_i - 1]
          pic_path = "http://img.youtube.com/vi/#{video_id}/1.jpg"
        else
          pic_path = "#{remote_url}/system/trailer_thumbnails/#{video.id}/1.jpg"
          video_path = "#{remote_url}/system/trailers/#{video.id}/original/#{video.trailer_file_name}"
        end
        
        movie_tag = video.taggings.where("tagger_type='Movie'").first
        movie = Movie.find_by_id(movie_tag.tagger_id)
        movie_poster = "#{remote_url}#{movie.banner_image}"
        video_likes = video.like_votes
        video_dislikes = video.dislike_votes
        video_dislikes.each do |d_vote|
          if d_vote.voter_id.to_s == params[:user_id]
            user_dislike_status = true
          end
        end
        video_likes.each do |l_vote|
          if l_vote.voter_id.to_s == params[:user_id]
            user_like_status = true
          end
          rev = {}
          l_user = User.find_by_id(l_vote.voter_id)
          rev[:user_id] = l_vote.voter_id
          rev[:user_name] = l_user.display_name
          if  l_user.user_image =~ /http:/
            rev[:user_image] = "#{l_user.user_image}"
          else
            rev[:user_image] = "#{POSTER_URL}#{l_user.user_image}"
          end
          like_votes << rev
        end 
        @item_detail << {:id => video.id, :name => video.name, :path => video_path, :pic_path => pic_path, :movie_poster => movie_poster, :like_votes => like_votes, :user_like_status => user_like_status, :user_dislike_status => user_dislike_status}
      end
    elsif params[:type] == "pictures"
      @items = HomePageSetting.where("page_no IN (#{new_lang}) and subject_type = 'Poster'")
      @items.each do |item|
        user_like_status = ""
        user_dislike_status = ""
        like_votes = []

        poster = Poster.find_by_id(item.subject_id)
        pic_path = "#{remote_url}/system/posters/#{poster.id}/crop_standard/#{poster.poster_file_name}"

        pic_likes = poster.like_votes
        pic_dislikes = poster.dislike_votes
        pic_dislikes.each do |d_vote|
          if d_vote.voter_id.to_s == params[:user_id]
            user_dislike_status = true
          end
        end
        pic_likes.each do |l_vote|
          if l_vote.voter_id.to_s == params[:user_id]
            user_like_status = true
          end
          rev = {}
          l_user = User.find_by_id(l_vote.voter_id)
          rev[:user_id] = l_vote.voter_id
          rev[:user_name] = l_user.display_name
          if  l_user.user_image =~ /http:/
            rev[:user_image] = "#{l_user.user_image}"
          else
            rev[:user_image] = "#{POSTER_URL}#{l_user.user_image}"
          end
          like_votes << rev
        end
        @item_detail << {:id => poster.id, :name => poster.name, :pic_path => pic_path, :like_votes => like_votes, :user_like_status => user_like_status, :user_dislike_status => user_dislike_status}
      end
    end
    render :text => @item_detail.to_json
  end
end
