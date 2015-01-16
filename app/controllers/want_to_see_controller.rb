class WantToSeeController < ApplicationController
  skip_before_filter :authenticate_user!
  #layout 'website'
  def create
    movie_id = params[:movie_id] ? params[:movie_id] : params[:want_to_see][:movie_id]
    @movie = Movie.find_by_id(movie_id)
    params[:movie_id] = movie_id
    if params[:block_type] == "notwant_see" || params[:block_type] == "wantsee"
      if params[:block_type] == "wantsee"
        wsee_movies = current_user.user_profile.want_to_sees
        @prev_item = wsee_movies.last.movie
        @next_item = wsee_movies.count > 1 ? wsee_movies[1].movie : ""
      elsif params[:block_type] == "notwant_see"
        nsee_movies = current_user.user_profile.not_want_to_sees
        @prev_item = nsee_movies.last.movie
        @next_item = nsee_movies.count > 1 ? nsee_movies[1].movie : ""
      end
    end

    @count = WantToSee.check_user(current_user.id,movie_id) 
    if @count.blank?
      @wanttosee = false
      @notwanttosee = false
      @want_to_see = WantToSee.new
      @want_to_see.user_id = current_user.id
      @want_to_see.movie_id = movie_id
      if params[:action_type] == "see"
        @wanttosee = true
        @want_to_see.is_want_to_see = true
      else
        @notwanttosee = true
      end
      if @want_to_see.save
        @user_badge =  UserBadge.new
        @user_badge.add_badge_points(current_user.id)
      end
      respond_to do |format|
        format.html  #{redirect_to root_path}
        format.js
      end
    else
      if params[:action_type] == "see"
        if @count.is_want_to_see == true
          #WantToSee.delete_all(:user_id => current_user.id, :movie_id => movie_id, :is_want_to_see => true)
          @wanttosee = true
        else
          @count.update_attribute('is_want_to_see', true)
          @notwanttosee = false
          @wanttosee = true
        end
        #WantToSee.delete_all(:user_id => current_user.id, :movie_id => movie_id, :is_want_to_see => true)
      else
        if @count.is_want_to_see == false
          #WantToSee.delete_all(:user_id => current_user.id, :movie_id => movie_id, :is_want_to_see => false)
          @notwanttosee = true
        else
          @count.update_attribute('is_want_to_see' ,false)
          @wanttosee = false
          @notwanttosee = true
        end
        #@count.is_want_to_see
        #WantToSee.delete_all(:user_id => current_user.id, :movie_id => movie_id, :is_want_to_see => false)
      end
      respond_to do |format|
        format.html  #{redirect_to root_path}
        format.js{ render 'not_anymore.js.erb'}
      end

    end
  end

 def not_anymore
   @movie = Movie.find_by_id(params[:want_to_see][:movie_id])
   @count = WantToSee.find(:all, 
              :select => ["id"],
              :conditions =>["user_id = ? AND movie_id = ?", current_user.id, params[:want_to_see][:movie_id]])
   if @count.size > 0
     WantToSee.delete_all(:user_id => current_user.id, :movie_id => params[:want_to_see][:movie_id])
     @user_badge =  UserBadge.new
     @user_badge.add_badge_points(current_user.id)
 
     @movie = Movie.find_by_id(params[:want_to_see][:movie_id])
     @activity = Activity.new
     @activity.user_id = current_user.id
     @activity.secondary_subject_type = "Movie"
     @activity.secondary_subject_id = params[:want_to_see][:movie_id]
     @activity.subject_type = "Not watch"
     @activity.action = "#{current_user.display_name} does not want to watch <a href='#{movie_path(@movie)}'>#{@movie.name}.</a>"
     @activity.save
   end
   if params[:block_type] == "notwant_see" || params[:block_type] == "wantsee"
     if params[:block_type] == "wantsee"
       wsee_movies = current_user.user_profile.want_to_sees
       @prev_item = wsee_movies.last.movie
       @next_item = wsee_movies.count > 1 ? wsee_movies[1].movie : ""
     elsif params[:block_type] == "notwant_see"
       nsee_movies = current_user.user_profile.not_want_to_sees
       @prev_item = nsee_movies.last.movie
       @next_item = nsee_movies.count > 1 ? nsee_movies[1].movie : ""
     end
   end
   respond_to do |format|
     format.html  #{redirect_to root_path}
     format.js
   end
 end
  def add
    ListOfMovie.add_update_list(params[:user_id], params["movie_id"], 'wanna see')
    render :text => "true"
    #render "add.js", :layout => nil
  end
  def seen
    ListOfMovie.wanna_see_to_seen(params[:user_id], params["movie_id"])
    render :json => params.to_json
  end

end
