class PostersController < ApplicationController
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token
  layout:check
 def index
    @posters = Poster.find :all
  end
  def pictures
    render :template => "/home_display/index" , :locals => {:type => "picture"}
  end

  def load_picture_page
    page_no = DisplayHelper.get_page_number("pictures", params, cookies)
    if page_no.blank?
      page_no = 24
    end

    @arr = DisplayHelper.get_result('pictures_page_cache', page_no, "picture")
    #@arr.sort!{|a,b| (b.item_created_at).strftime("%Y-%m-%d") <=> (a.item_created_at).strftime("%Y-%m-%d")}
    @arr.sort!{|a,b| b.score <=> a.score}
    @result = @arr.paginate(:page => params[:page], :per_page => PER_PAGE)

    #render :template => "/home_display/index"
    unless params[:page].blank?
      respond_to do |format|
        format.js {}
      end
    else
      render :partial => "/home_display/load_language"
    end
  end

  def new
    @poster = Poster.new
  end

  def create
  end

  def show
    @poster = Poster.find(params[:id])
  end
  
  def delete
  end

  def like
    @poster = Poster.find_by_id(params[:like_poster_id])
    if Vote.where("votable_id = #{@poster.id} and votable_type = 'Poster' and voter_id = #{current_user.id} and voter_type = 'User' and vote_flag = 't'").size == 0
      @poster.vote :voter =>current_user, :vote => 'like'
      @user_badge =  UserBadge.new
      @user_badge.add_badge_points(current_user.id,'like_poster')
      unless params[:movie_id].blank?
        @movie = Movie.find_by_id(params[:movie_id])
        Poster.log_poster_activity(current_user,@poster, 'Likes', @movie, 'movies')
        Poster.post_to_wall(current_user,@poster, 'Likes', @movie, 'movies')
      end

      unless params[:celebrity_id].blank?
        @celebrity = Celebrity.find_by_id(params[:celebrity_id])
        Poster.log_poster_activity(current_user,@poster, 'Likes', @celebrity, 'stars')
        Poster.post_to_wall(current_user,@poster, 'Likes', @celebrity, 'stars')
      end
    end
    respond_to do |format|
      format.js { }
    end
  end

  def dislike
    @poster = Poster.find_by_id(params[:dislike_poster_id])
    if Vote.where("votable_id = #{@poster.id} and votable_type = 'Poster' and voter_id = #{current_user.id} and voter_type = 'User' and vote_flag = 'f'").size == 0
      @poster.vote :voter =>current_user, :vote => 'bad'
      @user_badge =  UserBadge.new
      @user_badge.add_badge_points(current_user.id,'dislike_poster')
      unless params[:movie_id].blank?
        @movie = Movie.find_by_id(params[:movie_id])
        @action = "Dislikes"
        @path = "movies"
        Poster.log_poster_activity(current_user,@poster, 'Dislikes', @movie, 'movies')
        Poster.post_to_wall(current_user,@poster, 'Dislikes', @movie, 'movies')
      end

      unless params[:celebrity_id].blank?
        @celebrity = Celebrity.find_by_id(params[:celebrity_id])
        Poster.log_poster_activity(current_user,@poster, 'Dislikes', @celebrity, 'stars')
        Poster.post_to_wall(current_user,@poster, 'Dislikes', @celebrity, 'stars')
      end
    end
    respond_to do |format|
      format.js { }
    end
  end
 
  def check_vote
    vote = Poster.check_vote(params[:poster_id], current_user.id)
    render :text => vote
  end
  
  def show_item_detail
    @item = "";
    @p_item = params[:refer_type].constantize.find_by_id(params[:refer_id])
    if params[:item_type] == "Poster"
      @poster_list = Poster.get_poster(@p_item.id, "#{@p_item.class.to_s}", "Poster")
      @poster_list.each_with_index do |poster,i|
        if poster.id.to_s == params[:item_id].to_s
          if params[:type] == "next"
            @item = @poster_list[i+1]
            break
          else
            @item = @poster_list[i-1]
            break
          end
        end
      end
    elsif params[:item_type] == "Video"
      @video_list =  Video.get_video(@p_item.id, "#{@p_item.class.to_s}", "Video")
      @video_list.each_with_index do |video,i|
        if video.id.to_s == params[:item_id].to_s
          if params[:type] == "next"
            @item = @video_list[i+1]
            break
          else
            @item = @video_list[i-1]
            break
          end
        end
      end
    elsif params[:item_type] == "Feed"
      @news = Tagging.where("tagger_type = '#{@p_item.class.to_s}' and taggable_type='Feed'").find(:all, :conditions => ["tagger_id = ?", @p_item.id], :order => ["created_at desc"], :limit => ["3"])
      @news.each_with_index do |n,i|
        feed = Feed.get_news_feed(n.taggable_id)
        if feed.id.to_s == params[:item_id].to_s
          if params[:type] == "next"
            n_tag = @news[i+1]
            @item = Feed.get_news_feed(n_tag.taggable_id)
            break
          else
            n_tag = @news[i-1]
            @item = Feed.get_news_feed(n_tag.taggable_id)
            break
          end
        end
      end
    elsif params[:item_type] == "CelebTweet"
      if @p_item.class.to_s == "Celebrity"
        @tweets =  @p_item.celebrity_tweets.order("created_at desc")
      end
      @tweets.each_with_index do |tweet,i|
        if tweet.id.to_s == params[:item_id].to_s
          if params[:type] == "next"
            @item = @tweets[i+1]
            break
          else
            @item = @tweets[i-1]
            break
          end
        end
      end
    elsif params[:item_type] == "Celebrity"
      if params[:refer_type] == "Movie"
        @actors = @p_item.movie_casts.where("cast_type = 'actor'").limit(12).includes(:celebrity)
      else
        @actors = Celebrity.get_top_costars(@p_item)
      end
      @actors.each_with_index do |actor,i|
        if actor.celebrity.id.to_s == params[:item_id].to_s
          if params[:type] == "next"
            @item = @actors[i+1].celebrity
            break
          else
            @item = @actors[i-1].celebrity
            break
          end
        end
      end
    elsif params[:item_type] == "Movie"
      if params[:block_type] == "related_movies"
        @movies = Movie.get_related_movies(@p_item.permalink)
      elsif params[:block_type] == "upcomming"
        @movies = Celebrity.upcoming_movies(@p_item)
      else
        @movies = Celebrity.top_rated_movies(@p_item)
      end
      @movies.each_with_index do |movie,i|
        if movie.id.to_s == params[:item_id].to_s
          if params[:type] == "next"
            @item = @movies[i+1]
            break
          else
            @item = @movies[i-1]
            break
          end
        end
      end
    end
    if @item
      if params[:item_type] == "Celebrity"
        if params[:refer_type] == "Movie"
          block_type = "cast_crew"
        else
          block_type = "costar"
        end
        render :partial => "shared/show_celeb_block", :locals=>{:item=>@item,:type=>block_type}
      elsif params[:item_type] == "Movie" #and  params[:refer_type] == "Celebrity"
        render :partial => "shared/show_muvi_detail", :locals=>{:item=>@item,:type => params[:block_type]}
      else
        render :partial => "shared/show_block_detail", :locals=>{:item=>@item}
      end
    else
      render :text => ""
    end
  end

end    

