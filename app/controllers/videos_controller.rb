class VideosController < ApplicationController
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token
  before_filter :msn_redirect, :only => [:index, :trailers]

  layout:check

  def index
    @videos = Video.find :all
  end

  def trailers
    render :template => "/home_display/index" , :locals => {:type => "trailer"}
  end

  def load_trailer_page
    page_no = DisplayHelper.get_page_number("trailers", params, cookies)
    if page_no.blank?
      page_no = 24
    end
    
    @arr = DisplayHelper.get_result('trailer_page_cache', page_no, "trailer")
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
    @video = Video.new
  end

  def create
    @video = Video.new(params[:video])
    if @video.save
      @video.convert
      flash[:notice] = 'Video has been uploaded'
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end

  def show
    @video = Video.find(params[:id])
  end
  
  def delete
    @video = Video.find(params[:id])
    @video.destroy
    redirect_to :action => 'index'
  end

  def like
    @video = Video.find_by_id(params[:like_video_id])
    if Vote.where("votable_id = #{@video.id} and votable_type = 'Video' and voter_id = #{current_user.id} and voter_type = 'User' and vote_flag = 't'").size == 0
      @video.vote :voter =>current_user, :vote => 'like'
      @user_badge =  UserBadge.new
      @user_badge.add_badge_points(current_user.id,'like_video')

      unless params[:movie_id].blank?
        @movie = Movie.find_by_id(params[:movie_id])
        Video.log_video_activity(current_user,@video, 'Likes', @movie, 'movies')
        Video.post_to_wall(current_user,@video, 'Likes', @movie, 'movies')
      end

      unless params[:celebrity_id].blank?
        @celebrity = Celebrity.find_by_id(params[:celebrity_id])
        Video.log_video_activity(current_user,@video, 'Likes', @celebrity, 'stars')
        Video.post_to_wall(current_user,@video, 'Likes', @celebrity, 'stars')

      end
    end
    respond_to do |format|
      format.js { }
    end
  end

  def dislike
    @video = Video.find_by_id(params[:dislike_video_id])
    if Vote.where("votable_id = #{@video.id} and votable_type = 'Video' and voter_id = #{current_user.id} and voter_type = 'User' and vote_flag = 'f'").size == 0
      @video.vote :voter =>current_user, :vote => 'bad'
      @user_badge =  UserBadge.new
      @user_badge.add_badge_points(current_user.id,'dislike_video')

      unless params[:movie_id].blank?
        @movie = Movie.find_by_id(params[:movie_id])
        Video.log_video_activity(current_user,@video, 'Dislikes', @movie, 'movies')
        Video.post_to_wall(current_user,@video, 'Dislikes', @movie, 'movies')
      end

      unless params[:celebrity_id].blank?
        @celebrity = Celebrity.find_by_id(params[:celebrity_id])
        Video.log_video_activity(current_user,@video, 'Dislikes', @celebrity, 'stars')
        Video.post_to_wall(current_user,@video, 'Disikes', @celebrity, 'stars')

      end
    end
    respond_to do |format|
      format.js { }
    end
  end
 
  def check_vote
    vote = Video.check_vote(params[:video_id], current_user.id)
    render :text => vote
  end

end
