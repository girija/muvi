class MoviesController < ApplicationController
 skip_before_filter :authenticate_user!
 skip_before_filter :verify_authenticity_token 
 before_filter :msn_redirect, :only => [:show]
 #layout 'website'
 layout:check

  def index
    @search = Movie.released.latest.search(params[:search])
    @movies = @search.paginate(:page => params[:page], :per_page => 12)
    if @movies.size == 1
      redirect_to movie_path(@movies.first) and return
    end
  end

  def fetch_cast_crew
    celebs = []
    term = params[:term].strip.gsub(/[']/, '\\\\\'')
    @celebrities = Celebrity.search :name_starts_with =>  "#{term}"
    @celebrities.meta_sort ||= 'name.asc'
    @celebrities = @celebrities.all(:select=>"id,name",:limit=>"5")
    unless @celebrities.blank?
      @celebrities .each do |celeb|
        celebs << {:label => celeb.name.truncate(40), :id => celeb.id}
      end
    end
    render :json => celebs.to_json
  end

  def filter_top_movies
    @top_rated_movies = Movie.filter_toprated(params[:year],params[:genre],params[:language],params[:avail_watch],params[:top_rated],params[:cast],params[:first_time])
    render :partial => "shared/toprated_movies"
  end

  def show
    @movie = Movie.find_using_id(params[:id]).includes([:comments,:taggings]).first

    unless @movie.blank?
      @poster_list = Poster.get_poster(@movie.id, "Movie", "Poster")
      @video_list =  Video.get_video(@movie.id, "Movie", "Video")
      @critics_reviews = []
      if params[:engage] == "1"
        @top_videos = Video.get_top_score_record(@video_list)
        @top_posters = Video.get_top_score_record(@poster_list)
        #@discussions = (@movie.discussions.sort_by &:created_at).reverse
        @engage_items = ((@top_videos+@top_posters+@movie.discussions).sort_by &:created_at).reverse
        render :partial => "shared/engage"
      end
      @critics_reviews = @movie.critics_reviews.order("created_at desc")#.paginate(:page => params[:page], :per_page => 15)
      tagging = Tagging.find(:all, :conditions => ["tagger_id = ?  and taggable_type = 'Video' and tagger_type='Movie'",@movie.id], :select => "taggable_id")
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
        @videoids = ""
        @video.each do |v|
          if @videoids.blank?
            @videoids = v.taggable_id
          else
            @videoids = @videoids.to_s + "," + v.taggable_id.to_s
          end
        end
        @videos = Video.where("id IN (#{@videoids})").find(:all,:conditions => ["rank = 1"]).last
      end
      unless @videos.blank?
        @trailer = @videos
      else
        @trailer = false
      end
      @liked_reviews = @movie.review_users('like')
      @disliked_reviews = @movie.review_users('dislike')
      if !current_user.blank?
        #@want_to_see_movies_1 = User.get_movie_want_to_see(current_user,@movie.id,true)
        #@want_to_see_movies = @want_to_see_movies_1.collect {|x| x.user_id}.uniq

        #@not_want_to_see_movies_1 = User.get_movie_want_to_see(current_user,@movie.id, false)
        #@not_want_to_see_movies = @not_want_to_see_movies_1.collect {|x| x.user_id}.uniq
        
        @all_activity = AllActivityHelper.get_movie_notification(current_user.id, @movie.id)
        @all_notifications = @critics_reviews + @liked_reviews + @disliked_reviews + @all_activity
        @all_notifications = @all_notifications.sort!{|a,b| (b.created_at) <=> (a.created_at)}

      else
        #@want_to_see_movies_1 = @movie.want_to_sees
        #@want_to_see_movies = @want_to_see_movies_1.collect {|x| x.user_id}.uniq

        #@not_want_to_see_movies_1 = @movie.not_want_to_sees
        #@not_want_to_see_movies = @not_want_to_see_movies_1.collect {|x| x.user_id}.uniq

        @all_activity = AllActivityHelper.get_movie_notification("", @movie.id)
        @all_notifications = @critics_reviews + @liked_reviews + @disliked_reviews + @all_activity
        @all_notifications = @all_notifications.sort!{|a,b| (b.created_at) <=> (a.created_at)}

      end

      @actors = []
      @director = []
      @producer = []
      @writer = []
      @music = []

      @cast_crew = []
      @movie.movie_casts.includes(:celebrity).each do |cast|
        @cast_crew << cast
        case cast.cast_type
        when 'actor' then @actors << cast
        when 'director' then @director << cast
        when 'producer' then @producer << cast
        when 'writer' then @writer << cast
        when 'musics' then @music << cast
        end
      end
      @latest_trailers = Movie.latest_trailers
      @is_wanna_see = false
      unless current_user.blank?
        #@count_want_to_see = WantToSee.find(:all,:conditions =>["user_id = ? AND movie_id = ?", current_user.id,@movie.id])
         @subscription = UserSubscriptions.find(:first, :conditions => ["user_id = #{current_user.id} AND agent = 'muvi' AND end_date > '#{Date.today}'"])
         unless @subscription.blank?
           @subs = 1
         else
           @subs = 0
         end

        list = ListOfMovie.find_by_user_id(current_user.id)
        if list && !list.wanna_see_lists.blank?
          wannasee_list = ActiveSupport::JSON.decode(list.wanna_see_lists)
          if wannasee_list
            wannasee_list.each do |wanna_see|
              if wanna_see["object"]["id"] == @movie.id.to_s
                @is_wanna_see = true
                return
              end
            end
          end
        end
      end
      if !params[:news].nil? && params[:news] == "news"
        @news = Tagging.where("tagger_type = 'Movie' and taggable_type='Feed'").find(:all, :conditions => ["tagger_id = ?", @movie.id], :order => ["created_at desc"])
        if !params[:ajax].nil? && params[:ajax] == "1"
          render :partial => "/shared/all_news"
          return
        end
      else
        @news = Tagging.where("tagger_type = 'Movie' and taggable_type='Feed'").find(:all, :conditions => ["tagger_id = ?", @movie.id], :order => ["created_at desc"], :limit => 3)
      end

      unless params[:video_id].blank?
        video = Video.find_by_id(params[:video_id])
        unless video.blank?
          unless video.video_remote_url.blank?
            @video_type = "external"
            video_id_arr = video.video_remote_url.split("/")
            @video_id = video_id_arr[video_id_arr.size.to_i - 1]
          else
            @video_type = "internal"
          end
        end
      end
      @related_movies = Movie.get_related_movies(params[:id])
      @movie_tweets = Tweet.where("movie_id  = #{@movie.id}").order(" tweeted_on desc")

    else
      puts "permalink not found"
      redirect_to "/404.html"
      return
    end
  end

  def autocomplete
    first_block = []
    second_block = []
    third_block = []
    fourth_block = []
    total_name_list = []
    term = params[:q].strip.gsub(/[']/, '\\\\\'')
    search_type = params[:s_type].nil? ? "All" : params[:s_type]
    Sunspot.config.pagination.default_per_page = 5
    if search_type == "All" || search_type == "Movies"
      @mov_search = Movie.solr_search do
                      fulltext("'#{params[:q]}'")
                      #paginate page: 1, per_page: 5
                  end
      @movies = @mov_search.results
    end

    if search_type == "All" || search_type == "Celebrities"
      @celeb_search = Celebrity.solr_search  do
                      fulltext params[:q]
                    end

      @celebrities = @celeb_search.results
    end
    
    if search_type == "All" || search_type == "Users"
      @user_search = User.solr_search  do
                    fulltext params[:q]
                   end
      @users = @user_search.results
    end

    if search_type == "All" || search_type == "Lists"
      @list_search = UserMovieList.solr_search  do
                      fulltext params[:q]
                    end
      @lists = @list_search.results
    end
    unless @movies.blank?
      @movies.each do |movie|
        first_block << {:name => movie.name.truncate(40), :cat => "Movies", :id => movie.id, :permalink => movie.permalink}
      end
    end
    unless @celebrities.blank?
      @celebrities .each do |celeb|
        second_block << {:name => celeb.name.truncate(40),:cat=>"Stars", :id => celeb.id, :permalink => celeb.permalink}
      end
    end
    unless @users.blank?
      @users .each do |user|
	user_permalink = user.user_profile.permalink
        third_block << {:name => user.display_name.truncate(40),:cat=>"Users", :id => user.id, :permalink => user_permalink}
      end
    end

    unless @lists.blank?
      @lists .each do |list|
        fourth_block << {:name => list.tag.truncate(40),:cat=>"Lists", :id => list.id, :permalink => list.permalink}
      end
    end
    
    if request.env["HTTP_REFERER"] =~ /stars/
      total_name_list = second_block + first_block + fourth_block + third_block
    elsif request.env["HTTP_REFERER"] =~ /connections/
      total_name_list = third_block + first_block + fourth_block + second_block
    else
      total_name_list = first_block + fourth_block + second_block + third_block
    end
    render :json => total_name_list.to_json
  end

  def get_fb_id
    content = Movie.get_fb_id
    #render :text => content    
    #puts "#############"
    render :text => content
  end
  def popup
    @movie = Movie.find_by_id(params[:id])
    render :partial => 'shared/movie_badge'
  end
  def videopopup
     if params[:object_type] == 'movie'
       @movie = Movie.find_using_id(params[:object_id]).first
       @video = Video.find_by_id(params[:id])
       @video_list =  Video.get_video(@movie.id, "Movie", "Video")
       render :partial => 'shared/movie_video'
     elsif params[:object_type] == 'celebrity'
       @celeb = Celebrity.find_using_id(params[:object_id]).first
       @video = Video.find_by_id(params[:id])
       @video_list =  Video.get_video(@celeb.id, "Celebrity", "Video")
       render :partial => 'shared/celebrity_video'
     end
  end
  def posterpopup
     if params[:object_type] == 'movie'
       @movie = Movie.find_using_id(params[:object_id]).first
       @poster = Poster.find_by_id(params[:id])
       @poster_list = Poster.get_poster(@movie.id, "Movie", "Poster")
       render :partial => 'shared/movie_poster'
     elsif params[:object_type] == 'celebrity'
       @celeb = Celebrity.find_using_id(params[:object_id]).first
       @poster = Poster.find_by_id(params[:id])
       @poster_list = Poster.get_poster(@celeb.id, "Celebrity", "Poster")
       render :partial => 'shared/celebrity_poster'
     end
  end


  def get_in_theater
    @in_theaters = Movie.get_in_theaters(params, cookies)
    if !@in_theaters.blank? and @in_theaters.size != 0
      render :partial => "/shared/in_theaters"
    end
  end


  def get_upcoming
    @upcoming = Movie.get_upcoming(params, cookies)
    if !@upcoming.blank? and @upcoming.size != 0
      render :partial => "/shared/upcoming"
    end
  end
  
  def movie_rating_popup
    @movie = Movie.find_by_id(params[:id])
    render :partial => 'shared/movie_rating_popup'
  end

  def fetch_more
    @movie = Movie.find_by_id(params[:movie_id]);
    @actors = []
    @movie.movie_casts.includes(:celebrity).each do |cast|
      case cast.cast_type
       when 'actor' then @actors << cast
      end
    end
    @critics_reviews = @movie.critics_reviews.latest.limit(5)
    render :partial => 'shared/movie_detail'
  end

  def fetch_only_review
    @movie = Movie.find_by_id(params[:movie_id])
    @critics_reviews = @movie.critics_reviews.order("created_at desc")
    @user_reviews = @movie.reviews
    @all_notifications = @critics_reviews + @user_reviews
    @all_notifications = @all_notifications.sort!{|a,b| (b.created_at) <=> (a.created_at)}
    render :partial => "shared/movie_notifications"
  end
  def play_trailer
    @movie = Movie.find_using_id(params[:id]).first
    unless @movie.blank?
      tagging = Tagging.find(:all, :conditions => ["tagger_id = ?  and taggable_type = 'Video' and tagger_type='Movie'",@movie.id], :select => "taggable_id")
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
        @videoids = ""
        @video.each do |v|
          if @videoids.blank?
            @videoids = v.taggable_id
          else
            @videoids = @videoids.to_s + "," + v.taggable_id.to_s
          end
        end
        @videos = Video.where("id IN (#{@videoids})").find(:all,:conditions => ["rank = 1"]).last
      end
      unless @videos.blank?
        @trailer = @videos
      else
        @trailer = false
      end
    end
    @video_url = "#{VIDEO_URL}/system/trailers/#{@trailer.id}/original/#{@trailer.trailer_file_name.to_s}"
    #render :partial => "play_trailer"
  end
end
