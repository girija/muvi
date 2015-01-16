class AllActivitiesController < ApplicationController

  def index
    @all_activity = AllActivity.find(:all)
  end

  def close_activity
    AllNotification.find(:first, :conditions => ["id = #{params[:notification_id]}"]).destroy
    render :text => 1
  end

  def add_activity
    notif = AllNotification.find_by_id(params[:notification_id])
    if !notif.blank?
      notif.destroy
    end
    act_chk = ""
    unless params[:target_user_id].blank?
      c_user_id = params[:current_user_id].blank? ? current_user.id : params[:current_user_id]
      act_chk = AllActivity.find(:first, :conditions => ["user_id = #{c_user_id} and movie_id = #{params[:movie_id]} and activity_type = '#{params[:activity_type]}' and target_user_id = #{params[:target_user_id]}"])
    end

    if act_chk.blank?
      target_user = User.find_by_id(params[:target_user_id])
      activity = AllActivity.new
      activity.user_id = c_user_id
 
      movie = Movie.find_by_id(params[:movie_id])
      c_user = User.find_by_id(c_user_id)   
      @final_arr = []
      actor = ""
      verb = ""
      object = ""
      target = ""

      unless c_user.user_profile.profile_image_file_name.blank?
        image_url = "/system/profile_images/#{c_user.user_profile.id}/small/#{c_user.user_profile.profile_image_file_name.gsub(' ', '%20')}"
      else
        unless c_user.facebook_id.blank?
          image_url = "http://graph.facebook.com/#{c_user.facebook_id}/picture?type=normal"
        else
          image_url = "/images/no-profile.png"
        end
      end

      up = c_user.user_profile
      #actor = { :url => "http://#{request.env["HTTP_HOST"]}/profile/#{current_user.id}/#{User.convert_to_seo_url(current_user.display_name)}",
      actor = { :url => "http://#{request.env["HTTP_HOST"]}/#{up.permalink}",
              :objectType => "user",
              :id => "#{c_user.id}",
              :image => {:url => "#{image_url}", :width => 250, :height => 250},
              :displayName => "#{up.display_name}"
           }

      verb = params[:activity_type]

      m = Movie.find_by_id(params[:movie_id])
      url = ""
      image = ""
      unless m.blank?
        url = "http://#{request.env["HTTP_HOST"]}/movies/#{m.permalink}"
        image = POSTER_URL + m.banner_image
      end

      if params[:activity_type] == "kudos"
        if !params[:list_id].blank?
          list = UserMovieList.find_by_id(params[:list_id])
          destination_url = "http://#{request.env["HTTP_HOST"]}/movie_list/#{list.id}/#{list.tag}?movie_id=#{params[:movie_id]}##{params[:movie_id]}"
        else
          destination_url = "http://#{request.env["HTTP_HOST"]}/movies/#{m.permalink}"
        end

        object = {:url => "#{url}", :objectType => "movie", :id => "#{params[:movie_id]}",
               :image => {:url => "#{image}", :width => 250, :height => 250},
               :displayName => "#{movie.name}",
               :destination_url => destination_url
              }
      else
        object = {:url => "#{url}", :objectType => "movie", :id => "#{params[:movie_id]}",
               :image => {:url => "#{image}", :width => 250, :height => 250},
               :displayName => "#{movie.name}",
               :destination_url => ""
              }
      end
    
      tu = target_user.user_profile
      #target = { :url => "http://www.muvi.com/profile/#{params[:target_user_id]}/#{User.convert_to_seo_url(target_user.display_name)}",
      target = { :url => "http://www.muvi.com/#{tu.permalink}",
                :objectType => "user",
                :id => "#{params[:target_user_id]}",
                :image => {:url => "", :width => 250, :height => 250},
                :displayName => "#{tu.display_name}"
              }

      @final_arr << {:published => Date.today, :actor => actor, :verb => verb, :object => object, :target => target}
      activity.activity = @final_arr.to_json
      activity.movie_id = params[:movie_id]
      activity.activity_type = params[:activity_type]
      activity.target_user_id = params[:target_user_id]
   
      activity.save
    end
    render :text => 1
  end

  def get_movie_list
    #movie_id = AllActivityHelper.get_wanna_list(0,params[:cur_user_id])
    #movie_id = movie_id + AllActivityHelper.get_wanna_list(0,params[:cur_user_id])    
    conn_id = UserConnection.find_by_user_id(params[:cur_user_id]).connections
    render :text => conn_id
  end

  def update_feed_history
    FeedHistory.update_history(params[:user_id], params[:activity_type], params[:object_id])
    render :text => 1
  end

end
