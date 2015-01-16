class ReviewsController < ApplicationController
  layout 'website'
  skip_before_filter :authenticate_user!, :only => [:show, :show_popup]
  
 def new
    @movie = Movie.find_using_id(params[:movie_id]).first
    respond_with @movie
    @review = @movie.reviews.find(params[:id])
 end  
 def create
   @user_badge =  UserBadge.new
   @user_badge.add_badge_points(current_user.id)
   @movie = Movie.find_using_id(params[:movie_id]).first
   @review = Review.where(:user_id => current_user.id, :movie_id => @movie.id)
   if @review.size > 0
     @review = Review.where(:user_id => current_user.id, :movie_id => @movie.id).first
     unless params[:review][:description].blank?
       if @review.description != params[:review][:description] or  @review.rating != params[:review][:rating].to_f
         @review.update_attributes(:description =>  params[:review][:description])
       end
     else
       if @review.rating != params[:review][:rating].to_f
         @review.update_attributes(:rating =>  params[:review][:rating])
         if params['review']['rating'].to_i > 3
           @new_badge = @user_badge.add_badge_points(current_user.id, 'like', @movie.id)
         else
           @new_badge = @user_badge.add_badge_points(current_user.id, 'dislike', @movie.id)
         end
       end
     end
   else
     @movie.reviews.create(params[:review].merge(:user_id => current_user.id))
     if params['review']['rating'].to_i > 3
       @new_badge = @user_badge.add_badge_points(current_user.id, 'like', @movie.id)
     else
       @new_badge = @user_badge.add_badge_points(current_user.id, 'dislike', @movie.id)
     end
   end
   Movie.delay.update_one_movie_percentage(@movie)
      if params[:profile_review] == "true" || params[:page_name] == "profile"
        if params[:block] == "like"
          review_movies = current_user.user_profile.liked_movies
          @prev_item = review_movies.last.movie
          @next_item = review_movies.count > 1 ? review_movies[1].movie : ""
        elsif params[:block] == "dislike"
          review_movies = current_user.user_profile.disliked_movies
          @prev_item = review_movies.last.movie
          @next_item = review_movies.count > 1 ? review_movies[1].movie : ""
        end
      end
      #######################
      # After review, clear want to see record
      @count = WantToSee.find(:all, :select => ["id"],
                         :conditions =>["user_id = ? AND movie_id = ?", current_user.id, @movie.id])
      if @count.size > 0
        WantToSee.delete_all(:user_id => current_user.id, :movie_id => @movie.id)
      end
      # Ends
      #######################

      respond_to do |format|
        format.html  {redirect_to root_path}
        format.js
      end
  end

  def edit
    @movie =  Movie.find_using_id(params[:movie_id]).first
    @review = @movie.reviews.find(params[:id])
  end

  def update 
    @movie = Movie.find_using_id(params[:movie_id]).first
    @movie.reviews.update(params[:review].merge(:user_id => current_user.id))
    respond_to do |format|
      format.html  {redirect_to root_path}
      format.js
     end
  end 

  def show
    @movie = Movie.find_using_id(params[:movie_id]).first
    @review = @movie.reviews.find(params[:id])
  end
  def vote_review
    @review = Review.find_by_id(params[:id])
    @review.vote :voter =>current_user, :vote => params[:vote]
    render :text=>"true"
  end

  def show_popup
    if params[:cls] != "UserProfile"
      @item = params[:cls].constantize.find_by_id(params[:id])
      if params[:type] == 'like'
        render :partial => '/shared/like_dislike', :locals =>{:review => @item, :type => 'like'}
      elsif params[:type] == 'dislike'
        render :partial => '/shared/like_dislike', :locals =>{:review => @item, :type => 'dislike'}
      elsif params[:type] == 'like_dislike'
        render :partial => '/shared/like_dislike', :locals =>{:review => @item, :type => 'all'}
      elsif  params[:type] == 'want_to_see'
        render :partial => '/shared/want_notwant_see', :locals =>{:movie => @item}
      elsif  params[:type] == 'comment'
        render :partial => '/shared/comment_popup', :locals =>{:item => @item}
      else
        render :partial => '/shared/fan_unfan', :locals =>{:celeb => @item}
      end
    else
      user = User.find_by_id(params[:id])
      @follow_users = []
      if params[:type] == 'following'
        @following = UserConnection.find_by_user_id(params[:id])
        conn =  ActiveSupport::JSON.decode(@following.connections)
        conn.each do |con|
          user_token = UserToken.find(:first,:conditions => ["user_id = ?",con])
          unless user_token.blank?
            @follow_users << user = User.find_by_id(con)
          end
        end
      else
        @follower = UserFollower.find_by_user_id(params[:id])
        conn =  ActiveSupport::JSON.decode(@follower.followers)
        conn.each do |con|
          #user_token = UserToken.find(:first,:conditions => ["user_id = ?",con])
          #unless user_token.blank?
          @follow_users << user = User.find_by_id(con)
          #end
        end
      end
      render :partial => '/user_profiles/follow_popup'
    end
  end
  
  def save_review
    @p_item = params[:refer_cls].constantize.find_by_id(params[:refer_id])
    @movie = Movie.find_by_id(params[:movie_id])
    @review = Review.where(:user_id => current_user.id, :movie_id => @movie.id)
    if params[:rating] == "like"
      rating = 4
    else
      rating = 2
    end
    @user_badge =  UserBadge.new
    @user_badge.add_badge_points(current_user.id)
    if @review.size > 0
      @review.first.update_attribute("rating",rating)
      if rating > 3
        @user_badge.add_badge_points(current_user.id, 'like', @movie.id)
      else
        @user_badge.add_badge_points(current_user.id, 'dislike', @movie.id)
      end
    else
      @movie.reviews.create({:user_id => current_user.id,:rating=>rating})
      if rating > 3
        @user_badge.add_badge_points(current_user.id, 'like', @movie.id)
      else
        @user_badge.add_badge_points(current_user.id, 'dislike', @movie.id)
      end
    end
    respond_to do |format|
      format.html  {}
      format.js
    end
  end

end
