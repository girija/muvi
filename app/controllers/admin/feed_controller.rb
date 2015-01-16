class Admin::FeedController < ApplicationController
  before_filter :authenticate_user!
  before_filter :admin?
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token
 
  layout 'admin'

  def index

  end

  def save_admin_feed
    params[:activity] = params[:activity].gsub(/\r\n/," ")
    activity_string = params[:activity]


    #### as the list url is changed, the following code is to get the list id in the object id field ####
    if params[:activity_type] == "follow this list"
      @final_arr = []
      @final_arr << params[:activity]
      @final_arr = @final_arr.to_json
      act = ActiveSupport::JSON.decode(@final_arr)
      act.each do|a|
	a1 = ActiveSupport::JSON.decode(a)
        if a1["object"]["id"].blank?
          object_url_arr = a1["object"]["url"].split("list/")
          list = UserMovieList.find_by_permalink(object_url_arr[1])
          unless list.blank?
            a1["object"]["id"] = list.id.to_s      
          end
        end
        a = a1.to_json
        act = a
      end
      activity_string = act.to_s
    end
    ############################ ends #####################

    activity = AllActivity.new
    #activity.activity = params[:activity].gsub(/\r\n/," ")
    activity.activity = activity_string
    activity.activity_type = params[:activity_type]
    activity.save

    redirect_to "/admin/feed"
  end

  def generate_json
    movie = Movie.find_by_id(params[:movie_id])

      @final_arr = []
      actor = ""
      verb = ""
      object = ""
      target = ""

    user_profile_url = params[:user_profile_url].split("profile")
    user_id = (user_profile_url[1].split("/"))[1]

    current_user = User.find_by_id(user_id)
    unless current_user.user_profile.profile_image_file_name.blank?
      image_url = "/system/profile_images/#{current_user.user_profile.id}/small/#{current_user.user_profile.profile_image_file_name.gsub(' ', '%20')}"
    else
      unless current_user.facebook_id.blank?
        image_url = "http://graph.facebook.com/#{current_user.facebook_id}/picture?type=normal"
      else
        image_url = "/images/no-profile.png"
      end
    end

    actor = { :url => "http://#{params[:user_profile_url]}",
              :objectType => "user",
              :id => "#{user_id}",
              :image => {:url => "#{image_url}", :width => 250, :height => 250},
              :displayName => "#{current_user.display_name}"
           }


     verb = params[:verb]

     ################### CREATE OBJECT      
     url = ""
     image = ""
     object_id = ""
     object_name = ""

     target_id = ""
     target_name = ""
     target_url = ""
     target_image = ""

     if params[:object_type] == "movie"
        movie_url = params[:movie_url].split("/")
        m = Movie.find(:first, :conditions => ["permalink = '#{movie_url[movie_url.size - 1]}'"])
        unless m.blank?
          object_id = m.id
          object_name = m.name
          url = "/movies/#{m.permalink}"
          image = POSTER_URL + m.banner_image
        end

      elsif params[:object_type] == "list"
        list_url = params[:list_url].split("/")
	if params[:activity_type] == "follow filmography"
          l = Celebrity.find(:first, :conditions => ["permalink = '#{list_url[list_url.size - 1]}'"])
	else
	  l = UserMovieList.find(:first, :conditions => ["id =  '#{list_url[list_url.size - 1]}'"])

    	  @list_first_movie = UserMovieList.find_by_id(object_id)
	  unless @list_first_movie.blank?
	    @list_movie = Movie.find_by_id(ActiveSupport::JSON.decode(@list_first_movie.movie_id)[0])
	    target_name = @list_movie.name
	    target_id = @list_movie.id
	    target_url = "/movies/#{@list_movie.permalink}"
	    target_image = POSTER_URL + @list_movie.banner_image
	  end
	end
        unless l.blank?
          object_id = l.id
	  if params[:activity_type] == "follow filmography"
            object_name = l.name
          else
            object_name = l.tag
          end
        end
      end


      object = {:url => "#{url}", :objectType => "#{params[:object_type]}", :id => "#{object_id}",
               :image => {:url => "#{image}", :width => 250, :height => 250},
               :displayName => "#{object_name}"
              }
puts "###########"
puts object
      ############### CREATE TARGET

      
      unless params[:target_user_profile_url].blank?
        target_user_profile_url = params[:target_user_profile_url].split("profile")
        target_user_id = (target_user_profile_url[1].split("/"))[1]
        target_user = User.find_by_id(target_user_id)

        target_url = params[:target_user_profile_url]
        target_name = target_user.display_name
        target_id = (target_user_profile_url[1].split("/"))[1]
      end

        target = { :url => target_url,
                :objectType => "user",
                :id => target_id,
                :image => {:url => "", :width => 250, :height => 250},
                :displayName => target_name
              }
      

      @final_arr << {:published => Date.today, :actor => actor, :verb => verb, :object => object, :target => target}

      activity = AllActivity.new
      activity.user_id = user_id
      activity.activity = @final_arr.to_json
      if params[:object_type] == "movie"
        activity.movie_id = object_id
      end
      activity.activity_type = params[:activity_type]
      activity.target_user_id = target_user_id
      activity.origin = "admin"
      activity.save

    end

  def enable_disable_live_chat

  end

  def chat_available
	unless params[:c].blank?
		#::Rails.application.config.LIVE_CHAT = params[:c]
		chat = Chat.find(:first)
		if params[:c].to_i == 0
			chat.update_attribute("is_enabled", "false")
		else
			chat.update_attribute("is_enabled", "true")
		end
	end
	render :text => "success"
  end

  def add_admin_lists
    @all_list = AdminList.find(:all)
  end

  def save_admin_lists
    AdminList.destroy_all
    cnt = 0
    params[:listName].each do |list_name|
      unless list_name.blank?
        admin_list = AdminList.new
        admin_list.list_id = params[:list_id][cnt]
        admin_list.list_name = list_name
        admin_list.save
        cnt = cnt + 1
      end
    end
    redirect_to "/admin/add_admin_lists"
  end

  def autocomplete
    list_names = UserMovieList.where("tag ILIKE '#{params[:term].strip}%'").search.all.collect do |list|
      { "label" => list.tag, "value" => list.id }
    end
    render :json => list_names.to_json
  end

end
