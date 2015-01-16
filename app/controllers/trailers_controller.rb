class TrailersController < ApplicationController
  skip_before_filter :authenticate_user!, :except => [:play_fullmovie]
  skip_before_filter :verify_authenticity_token
  layout false

  def index
    #if current_user.id == 101
      #recomended = RecomendedMovie.where("user_id = 101").select("movie_ids").first
    #else
    #recomended = RecomendedMovie.where("language = 'Hindi' and user_id IS NULL").select("movie_ids").first
    #end
    #first_recomend = ActiveSupport::JSON.decode(recomended.movie_ids)[0]
    #movie =  Movie.find_by_id(first_recomend)
    #trailer = Movie.get_default_trailer(movie)
    #@first_movie_id = first_recomend
    #@default_poster = movie.full_image
    #if trailer != false
    #  @default_trailer = "#{VIDEO_URL}/system/trailers/#{trailer.id}/original/#{trailer.trailer_file_name.to_s}"
    #else
    #  @default_trailer = "http://dfquahprf1i3f.cloudfront.net/public/system/trailers/3029/original/_tArLLmV1IU.mp4"
    #end
    @wannasee_cnt = 0
    AllActivity.get_current_user_wanna_list(current_user.id).each do |w_see|
      movie_stream = MovieStream.find_by_movie_id(w_see)
      if movie_stream && (!movie_stream.full_movie.blank? || !movie_stream.youtube.blank?)
        @wannasee_cnt += 1
      end
    end
  end

  def wannasee_movies
    @wanna_see_movies = []
    AllActivity.get_current_user_wanna_list(current_user.id).each do |w_see|
      movie_stream = MovieStream.find_by_movie_id(w_see)
      if movie_stream && (!movie_stream.full_movie.blank? || !movie_stream.youtube.blank?)
        movie =  Movie.find_by_id(w_see)
        @wanna_see_movies << {:id => movie.id, :poster=> movie.full_image, :name => movie.name, :casts => movie.get_first_two_actors} if movie
      end
    end
    render :json => @wanna_see_movies.to_json
  end

  def recomended_movies
    @recomended_movies = []
    #if current_user.id == 101
    #  rec_movies = RecomendedMovie.where("user_id = 101").select("movie_ids").first
    #else
    #rec_movies = RecomendedMovie.where("language = 'Hindi' and user_id IS NULL").select("movie_ids").first
    #end
    #ActiveSupport::JSON.decode(rec_movies.movie_ids).each do |rec|
    #  movie =  Movie.find_by_id(rec.to_i)
    #  @recomended_movies << {:id => movie.id, :poster=> movie.full_image, :name => movie.name, :casts => movie.get_first_two_actors}
    #end

    user_lang = ""
    language = ActiveSupport::JSON.decode(current_user.language)
    language.each do |lang|
      user_lang += "'#{lang}',"
    end
    user_lang = user_lang.chop!
    rec_movies = Movie.select("films.*").where("language in (#{user_lang}) and muvimeter > 60 and (movie_streams.youtube != '' or movie_streams.full_movie != '')").joins("JOIN movie_streams ON movie_streams.movie_id = films.id").order("random()").limit(5)
    rec_movies.each do |movie|
      @recomended_movies << {:id => movie.id, :poster=> movie.full_image, :name => movie.name, :casts => movie.get_first_two_actors}
    end

    render :json => @recomended_movies.to_json
  end  

  def info
    cast1_name = ""
    cast1_permalink = ""
    cast2_name = ""
    cast2_permalink = ""
    video_path = ""
    youtube_path = ""
    uploaded_path = ""
    uploaded_webm_path = ""
    uploaded_movie = false
    pay_per_view = ""
    @movie = Movie.find_by_id(params[:movie_id])
    @movie.movie_casts.where("cast_type = 'actor'").limit(2).each_with_index do |cast,i|
      if cast.celebrity
        celeb = cast.celebrity
        if !celeb.name.blank?
          if i == 0
            cast1_name = celeb.name
            cast1_permalink = celeb.permalink
          else
            cast2_name = celeb.name
            cast2_permalink = celeb.permalink
          end
        end
      end
    end
    @full_movie = MovieStream.find_by_movie_id(params[:movie_id])
    full_movie_path = ""
    if !@full_movie.blank?
      if !@full_movie.youtube.blank?
        video_path = @full_movie.youtube
      end

      if !@full_movie.full_movie.blank?
	video_path = "http://muviassetsdev.s3.amazonaws.com/uploads/movie_stream/full_movie/#{@full_movie.id}/#{@full_movie.full_movie}"
        uploaded_path = "http://muviassetsdev.s3.amazonaws.com/uploads/movie_stream/full_movie/#{@full_movie.id}/#{@full_movie.full_movie}"
        uploaded_webm_path = "http://muviassetsdev.s3.amazonaws.com/uploads/movie_stream/full_movie/#{@full_movie.id}/#{@full_movie.full_movie_webm}"
        uploaded_movie = true
        pay_per_view = @full_movie.pay_per_view
      end
      if !@full_movie.youtube.blank?
        youtube_path = @full_movie.youtube
      end
    end
    trailer = Movie.get_default_trailer(@movie)
    trailer_poster = ""
    if trailer != false
      video_url = "#{VIDEO_URL}/system/trailers/#{trailer.id}/original/#{trailer.trailer_file_name.to_s}"
      trailer_poster = "#{VIDEO_URL}/system/trailer_thumbnails/#{trailer.id}/1.jpg"
    else
      video_url = ""
    end
    movie_info = {:poster_path => "#{POSTER_URL}#{@movie.full_image}",
                  :name => @movie.name,
                  :story => @movie.story,
                  :why_watch => @movie.additional_info,
                  :movie_permalink => @movie.permalink,
		  :video_path => video_path,
                  :youtube_path => youtube_path,
                  :uploaded_path => uploaded_path,
                  :uploaded_webm_path => uploaded_webm_path,
                  :trailer_path => video_url,
                  :trailer_poster => trailer_poster,
                  :cast1_name => cast1_name,
                  :cast1_permalink => cast1_permalink,
                  :cast2_permalink => cast2_permalink,
                  :cast2_name => cast2_name,
                  :uploaded_movie => uploaded_movie,
                  :pay_per_view => pay_per_view
                }
    
    render :json => movie_info.to_json
  end

  def wanaasee_add
    seen_list = AllActivity.get_current_user_seen_list(current_user.id)
    if !seen_list.include?(params[:movie_id].to_i)
      ListOfMovie.add_update_list(current_user.id, params["movie_id"], 'wanna see')
    end
    render :text => "ok"
  end

  def seenit_add
    ListOfMovie.add_update_list(current_user.id, params["movie_id"], 'seen it')
    render :text => "ok"
  end

  def add_to_vl
    vl = VideoLog.where("movie_id = #{params['mid']} and user_id = #{current_user.id} and watch_status = 'start'").first
    if vl.blank?
      vl = VideoLog.new
      vl.movie_id = params["mid"]
      vl.user_id = current_user.id
      vl.video_type = params["vt"]
      vl.watch_status = params["status"]
      vl.save
    else
      vl.watch_status = params["status"]
      vl.save
    end
    render :text => 1
  end

  def play_fullmovie
    @first_movie_id = params[:fullmovie_id]
    if !params[:ads].blank?
      movie_stream = MovieStream.find_by_movie_id(params[:fullmovie_id])
      #if params[:ads] == "true"
      #  @video_link = movie_stream.youtube
      #else
      #  @video_link = "http://muviassetsdev.s3.amazonaws.com/uploads/movie_stream/full_movie/#{movie_stream.id}/#{movie_stream.full_movie}"
      #  @video_webm_link = "http://muviassetsdev.s3.amazonaws.com/uploads/movie_stream/full_movie/#{movie_stream.id}/#{movie_stream.full_movie_webm}"
      #end
      unless movie_stream.full_movie.blank?
        @video_link = "http://muviassetsdev.s3.amazonaws.com/uploads/movie_stream/full_movie/#{movie_stream.id}/#{movie_stream.full_movie}"
        @video_webm_link = "http://muviassetsdev.s3.amazonaws.com/uploads/movie_stream/full_movie/#{movie_stream.id}/#{movie_stream.full_movie_webm}"
      else
        @video_link = movie_stream.youtube
      end
    end
    @wannasee_cnt = 0
    AllActivity.get_current_user_wanna_list(current_user.id).each do |w_see|
      if MovieStream.find_by_movie_id(w_see)
        @wannasee_cnt += 1
      end
    end
    render template: "trailers/index"
  end

  def pay_for_movie
    @sub = UserSubscriptions.find(:first, :conditions => ["user_id = #{current_user.id} AND end_date > '#{Date.today}'"])
    unless @sub.blank?
      render :text => "ok"
    else
      render :text => "not subscribed"
    end
  end
  
  def pay_for_movie_old
    paid_movies = []
    already_paid = false
    @paid_movie = PaidMovie.find_by_user_id(current_user.id)
    user_profile = current_user.user_profile
    if (@paid_movie.nil? || @paid_movie.blank?) 
      if user_profile.movie_coins.to_i > params[:coins].to_i
        @paid_movie = PaidMovie.new
        @paid_movie.user_id = current_user.id
        @paid_movie.movie_id = "[#{params[:movie_id].to_i}]"
        @paid_movie.save
      end
    else
      paid_movies = ActiveSupport::JSON.decode(@paid_movie.movie_id)
      if !paid_movies.include?(params[:movie_id].to_i)
        paid_movies << params[:movie_id].to_i
        @paid_movie.movie_id = paid_movies.to_s
        @paid_movie.save
      else
        already_paid = true
      end
    end
    if already_paid == false
      user_profile = current_user.user_profile
      if user_profile.movie_coins.to_i >= params[:coins].to_i
        movie_coins = user_profile.movie_coins.to_i - params[:coins].to_i    
        user_profile.update_attribute("movie_coins",movie_coins)
        render :text => "ok"
      else
        render :text => "insufficient coins"
      end
    else
      render :text => "ok"
    end
  end
end

