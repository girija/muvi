class CommentsController < ApplicationController
  before_filter :find_movie,:find_celebrity,:find_review,:find_activity,:find_discussion, :find_video, :find_poster, :find_celeb_tweet, :only => [:create, :index]
  skip_before_filter :authenticate_user! , :only => [:index]
  layout 'website'
  def index
  end


  def create
    if !params[:celeb_comment].blank?
      @comment = @celebrity.comments.new(params[:comment].merge({:user_id => current_user.id}))
      @comment.delay(:priority => 0).save
      respond_to do |format|
        format.html { redirect_to star_path(celebrity) }
        format.js { }
      end

    elsif !params[:activity_comment].blank?
      com = "comment_#{params[:id]}"
      params[:comment][:comment] = params[com]
      @comment = @activity.comments.new(params[:comment].merge({:user_id => current_user.id}))
      if @comment.save
        @activity = Activity.new
        @activity.user_id = current_user.id
        @activity.secondary_subject_type = "Comment"
        @activity.subject_type = "Comment"
        @user = User.find_by_id(params[:comment][:user_id])
        unless @user.blank?
          @activity.action = "#{current_user.display_name} commented on <a href='/profile/#{params[:comment][:user_id]}/#{@user.user_profile.display_name}'>#{@user.user_profile.display_name}.</a>"
          @activity.delay(:priority => 0).save
        end
      end
 
      respond_to do |format|
        format.html {}
        format.js { }
      end

    elsif !params[:review_comment].blank?
      com = "review_comment_#{params[:id]}"
      params[:comment][:comment] = params[com]
      @comment = @review.comments.new(params[:comment].merge({:user_id => current_user.id}))
      if @comment.save
        @activity = Activity.new
        @activity.user_id = current_user.id
        @activity.secondary_subject_type = "Comment"
        @activity.subject_type = "Comment"
        @user = User.find_by_id(params[:comment][:user_id])
        unless @user.blank?
          @activity.action = "#{current_user.display_name} commented on <a href='/profile/#{params[:comment][:user_id]}/#{@user.user_profile.display_name}'>#{@user.user_profile.display_name}.</a>"
          @activity.save
        end
      end
      respond_to do |format|
        format.html {}
        format.js { }
      end
    elsif !params[:discussion_comment].blank?
      com = "discussion_comment_#{@refer.id}"
      params[:comment][:comment] = params[com]
      @comment = @refer.comments.new(params[:comment].merge({:user_id => current_user.id}))
      @comment.save
      if params[:inner_page] == "true"
        @p_item = params[:refer_type].constantize.find_by_id(params[:refer_id])
      end
      respond_to do |format|
        format.html {}
        format.js { }
      end
    elsif !params[:celeb_tweet_comment].blank?
      com = "tweet_comment_#{params[:celeb_tweet_comment]}"
      params[:comment][:comment] = params[com]
      @comment = @celeb_tweet.comments.new(params[:comment].merge({:user_id => current_user.id}))
      if @comment.save
        respond_to do |format|
          format.html {}
          format.js { }
        end
      end
    elsif !params[:movie_review_comment].blank?
      com = "movie_review_comment_#{params[:movie_review_comment]}"
      params[:comment][:comment] = params[com]
      @comment = @review.comments.new(params[:comment].merge({:user_id => current_user.id}))
      if @comment.save
        @activity = Activity.new
        @activity.user_id = current_user.id
        @activity.secondary_subject_type = "Comment"
        @activity.subject_type = "Comment"
        @user = User.find_by_id(params[:comment][:user_id])
        unless @user.blank?
          @activity.action = "#{current_user.display_name} commented on <a href='/profile/#{params[:comment][:user_id]}/#{@user.user_profile.display_name}'>#{@user.user_profile.display_name}.</a>"
          @activity.save
        end
      end
      respond_to do |format|
        format.html {}
        format.js { }
      end
    elsif !params[:video_comment].blank?
      com = "video_comment_#{@video.id}"
      @comment = Video.save_comment(current_user.id, @video, params[com])
      #com = "video_comment_#{@video.id}"
      #params[:comment][:comment] = params[com]
      #@comment = @video.comments.new(params[:comment].merge({:user_id => current_user.id}))
      #@comment.save
      respond_to do |format|
        format.html {}
        format.js { }
      end
    elsif !params[:poster_comment].blank?
      com = "poster_comment_#{@poster.id}"
      @comment = Poster.save_comment(current_user.id, @poster, params[com])
      #com = "video_comment_#{@video.id}"
      #params[:comment][:comment] = params[com]
      #@comment = @video.comments.new(params[:comment].merge({:user_id => current_user.id}))
      #@comment.save
      respond_to do |format|
        format.html {}
        format.js { }
      end
    else
      @comment = @movie.comments.new(params[:comment].merge({:user_id => current_user.id}))
      @comment.save
      respond_to do |format|
        format.html { redirect_to movie_path(movie) }
        format.js { }
      end
    end
  end

  private
  def find_movie
    @movie = Movie.find_using_id(params[:movie_id]).first
  end
  def find_celebrity
    @celebrity = Celebrity.find_using_id(params[:celebrity_id]).first
  end
  def find_activity
    unless params[:activity_comment].nil?
      @activity = Activity.find(params[:activity_comment])
    end
  end
  def find_review
    unless params[:review_comment].nil?
      @review = Review.find(params[:review_comment])
    end
    unless params[:movie_review_comment].nil?
      @review = Review.find_by_id(params[:movie_review_comment])
      @review = @review ? @review : CriticsReview.find_by_id(params[:movie_review_comment])
    end
  end
  
  def find_discussion
    unless params[:discussion_comment].nil?
      @refer = params[:item_class].constantize.find_by_id(params[:discussion_comment])
    end
  end
  def find_video
    unless params[:video_comment].nil?
      @video = Video.find(params[:video_comment])
    end
  end
  def find_poster
    unless params[:poster_comment].nil?
      @poster = Poster.find(params[:poster_comment])
    end
  end
  def find_celeb_tweet
    unless params[:celeb_tweet_comment].nil?
      @celeb_tweet = CelebTweet.find_by_id(params[:celeb_tweet_comment])
    end
  end
end
