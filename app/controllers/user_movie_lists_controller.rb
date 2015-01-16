class UserMovieListsController < ApplicationController
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token
  layout :check

  def old_show_list
    @list = UserMovieList.find_by_id(params[:id])
    redirect_to "/list/#{@list.permalink}", status: 302
  end

  def show_list
    #@list = UserMovieList.find_by_id(params[:id])
    @list = UserMovieList.find_by_permalink(params[:permalink])
  end
  
  def remove_movie
    list = UserMovieList.find_by_id(params[:list_id])
    @movie_id_arr = []
    @new_tag_list = []
    @movie_id_arr = ActiveSupport::JSON.decode(list.movie_id)
    @movie_id_arr = @movie_id_arr - [params[:movie_id]]
    @tag_list = ActiveSupport::JSON.decode(list.tag_list)
    unless @tag_list.blank?
      @tag_list.each do |t_list|
        if t_list["object"]["objectType"] == "movie" and t_list["object"]["id"] != params[:movie_id].to_s
          @new_tag_list << t_list
        end
      end
    end
    list.movie_id = @movie_id_arr.to_json
    list.tag_list = @new_tag_list.to_json
    list.save
    render :text => "ok"
  end
  
  def save_movie
    list = UserMovieList.find_by_id(params[:list_id])
    @final_arr  = ActiveSupport::JSON.decode(list.tag_list)
    @tag_list = create_tag_list(current_user.id, current_user.display_name, params[:movie_id], "#{t}")
    @final_arr << @tag_list
    @movie_id_arr = []
    @movie_id_arr = ActiveSupport::JSON.decode(list.movie_id)
    if !@movie_id_arr.include?(params[:movie_id])
      @movie_id_arr << params[:movie_id]
    end
    list.tag_list = @final_arr.to_json
    list.movie_id = @movie_id_arr.to_json
    list.save

    #
    UserMovieList.added_movie_to_list(current_user, params[:movie_id], list.tag, list.id)
    #
    @movie = Movie.find_by_id(params[:movie_id])
    render :partial => "movie_list"
  end


  def remove_list_from_movie_page
    unless params[:list_id].blank?
	list = UserMovieList.find_by_id(params[:list_id])
        @movie_id_arr = []
        @movie_id_arr = ActiveSupport::JSON.decode(list.movie_id)
	@movie_id_arr.delete_if{|i| i.to_i == params[:movie_id].to_i}
    end
    render :text => 1
  end

  def save_list_from_movie_page
    unless params[:list_id].blank?
      list = UserMovieList.find_by_id(params[:list_id])
      @movie_id_arr = []
      @movie_id_arr = ActiveSupport::JSON.decode(list.movie_id)
      if !@movie_id_arr.include?(params[:movie_id])
        @movie_id_arr << params[:movie_id]
      end
      list.tag_list = @final_arr.to_json
      list.movie_id = @movie_id_arr.to_json
      list.save
      @movie = Movie.find_by_id(params[:movie_id])
    end

    unless params[:new_list].blank?
      exist_tags = UserMovieList.where(" tag != '' and user_id = #{current_user.id} and lower(tag) = lower('#{params[:tag].to_s}')")
      unless exist_tags.blank?
        exist_tags.each do |et|
          list = UserMovieList.find_by_id(et.id)
          @movie_id_arr = ActiveSupport::JSON.decode(et.movie_id)
          if !@movie_id_arr.include?(params[:movie_id])
            @movie_id_arr << params[:movie_id]
          end
          list.movie_id = @movie_id_arr.to_json
          list.save
        end
      else
        @final_arr = []
        @list = create_tag_list(current_user.id, current_user.display_name, params[:movie_id], "#{params[:tag].capitalize}")
        @final_arr << @list
        @movie_id_arr = []
        @movie_id_arr << params[:movie_id]
        list = UserMovieList.new
        list.user_id = current_user.id
        list.movie_id = @movie_id_arr.to_json
        list.tag = params[:tag].capitalize
        list.tag_list = @final_arr.to_json
        list.save
      end
    end
    render :text => 1
  end

  def save_movie_rating
    tag = ""
    act_id = ""
    list_id = ""
    saved = 0
    in_list = UserMovieList.find_by_user_id(current_user.id)
    unless params["hidden-tags"].blank?
      tag = params["hidden-tags"].split(",")
      unless tag.blank?
        exist_tags = UserMovieList.where(" tag != '' and user_id = #{current_user.id} and movie_id like '%#{params[:movie_id].to_s}%'")
        exist_tags.each do |et|
          new_movie_id = ActiveSupport::JSON.decode(et.movie_id) - ["#{params[:movie_id]}"]
          movie_ids_final = new_movie_id.to_json
          et.movie_id = movie_ids_final
          et.save
        end
        tag.each do |t|
         unless t.blank?
	  t = t.capitalize	  
          chk = UserMovieList.find_by_user_id_and_tag(current_user.id, "#{t}")
          if in_list.nil?
	    @final_arr = []
	    @list = create_tag_list(current_user.id, current_user.display_name, params[:movie_id], "#{t}")
	    @final_arr << @list
	    @movie_id_arr = []
	    @movie_id_arr << params[:movie_id]
	    list = UserMovieList.new
	    list.user_id = current_user.id
	    list.movie_id = @movie_id_arr.to_json
	    list.tag = t.capitalize
	    list.tag_list = @final_arr.to_json
	    list.save
	    saved = 1
            list_id = list.id


            if !params[:notification_id].blank? and params[:notification_id] != "undefined"
              AllNotification.find(:first, :conditions => ["id = #{params[:notification_id]}"]).destroy unless params[:notification_id].blank?
            end
            #################Save in activity table
            @final_arr_ac = []
            @list_ac = create_tag_list(current_user.id, current_user.display_name, params[:movie_id], "#{t}")                         
            @final_arr_ac << @list_ac
            list_ac = AllActivity.new
            list_ac.user_id = current_user.id
            list_ac.movie_id = params[:movie_id]
            list_ac.activity = @final_arr_ac.to_json
            list_ac.activity_type = "rated"
            list_ac.save
            act_id = list_ac.id

            UserMovieList.show_invite(current_user, params[:movie_id], t, list_id)
	  else
	    if chk.nil?
	      @final_arr = []
	      @list = create_tag_list(current_user.id, current_user.display_name, params[:movie_id], "#{t}")					
	      @final_arr << @list				
	      @movie_id_arr = []
	      @movie_id_arr << params[:movie_id]
	      list = UserMovieList.new
	      list.user_id = current_user.id
	      list.movie_id = @movie_id_arr.to_json
	      list.tag = t.capitalize
	      list.tag_list = @final_arr.to_json
	      list.save
	      saved = 1
              list_id = list.id

              if !params[:notification_id].blank? and params[:notification_id] != "undefined"
                begin
                  AllNotification.find(:first, :conditions => ["id = #{params[:notification_id]}"]).destroy
                rescue
                end
              end

            #################Save in activity table
            @final_arr_ac = []
            @list_ac = create_tag_list(current_user.id, current_user.display_name, params[:movie_id], "#{t}")                         
            @final_arr_ac << @list_ac
            list_ac = AllActivity.new
            list_ac.user_id = current_user.id
            list_ac.movie_id = params[:movie_id]
            list_ac.activity = @final_arr_ac.to_json
            list_ac.activity_type = "rated"
            list_ac.save
            act_id = list_ac.id

              UserMovieList.show_invite(current_user, params[:movie_id], t, list_id)

            else				
	      @final_arr  = ActiveSupport::JSON.decode(chk.tag_list)
	      @list = create_tag_list(current_user.id, current_user.display_name, params[:movie_id], "#{t}")
	      begin
	        @final_arr << @list
              rescue
              end

	      @movie_id_arr = []
	      @movie_id_arr = ActiveSupport::JSON.decode(chk.movie_id)					
              if !@movie_id_arr.include?(params[:movie_id])
                @movie_id_arr << params[:movie_id]
              end
	      chk.tag_list = @final_arr.to_json
	      chk.movie_id = @movie_id_arr.to_json
	      chk.save
	      saved = 1
              list_id = chk.id
              followers = chk.followers
              followers.each do |fol|
                rated_list = ListOfMovie.find_by_user_id(fol.id)
                rated_movie =  ActiveSupport::JSON.decode(rated_list.rated_movie)
                if !rated_movie.include?(params[:movie_id].to_i)
                  UserMovieList.save_rating(current_user, params[:movie_id],'list_rated_movie',fol.id,chk.id)
                end
              end
	    end
	  end
         end
        end
      end
    end

    if params[:hid_rate]
      movie_list = UserMovieList.where(" tag IS NULL and user_id = #{current_user.id}").limit("1")
      user_movie_list = movie_list.first
      if user_movie_list.blank?
        @movie_id_arr = []
	@movie_id_arr << params[:movie_id]
	u_list = UserMovieList.new
	u_list.user_id = current_user.id
	u_list.movie_id = @movie_id_arr.to_json
	u_list.save
      else
	if user_movie_list.movie_id
	  @movie_id_arr = ActiveSupport::JSON.decode(user_movie_list.movie_id)
	else
	  @movie_id_arr = []
	end
        if !@movie_id_arr.include?(params[:movie_id])
          @movie_id_arr << params[:movie_id]
        end
	user_movie_list.movie_id = @movie_id_arr.to_json
	user_movie_list.save
      end 
      rating = params[:hid_rate]
      @reviews = Review.where(:user_id => current_user.id, :movie_id => params[:movie_id])
      if @reviews.size > 0
        @review = @reviews.first
	#@review.update_attributes(:rating =>  rating,:description =>  params[:review_text])
	@review.update_attribute('rating', rating)
        @review.update_attribute('description', params[:review_text])
      else
        r = Review.new
	r.user_id = current_user.id
	r.movie_id = params[:movie_id]
	r.rating = rating
	r.description = params[:review_text]
	r.review = 't'
	r.save
      end
      @rated_movie = []
      list = ListOfMovie.find_by_user_id(current_user.id)
      if list 
	if list.rated_movie
	  @rated_movie =  ActiveSupport::JSON.decode(list.rated_movie)
	  if !@rated_movie.include?(params[:movie_id].to_i)
	    @rated_movie << params[:movie_id].to_i
	  end
	  list.rated_movie = @rated_movie.to_json
	else
	  @rated_movie << params[:movie_id].to_i
	  list.rated_movie = @rated_movie.to_json
	end
	list.save
      end
      ##########################################################
      ############## Send notification #########################
      #all_activity = []
      #rate_arr = UserMovieList.create_rate_json(current_user.id, params[:movie_id], act_id)
      #all_activity << rate_arr
      #DisplayHelper.notify(all_activity, current_user.id)
      #AllActivityHelper.get_notification_list(1, current_user.id, '', '')
      UserMovieList.save_rating(current_user, params[:movie_id],'rated','','')
      #UserMovieList.save_rating(current_user, params[:movie_id])
      #############################################
      #############################################      
    end
    respond_to do |format|
      format.js
    end
  end
  
  def create_tag_list(user_id, user_name, movie_id, tag)
	actor = ""
	verb = ""
	object = ""
	target = ""
 
        image_url = ""

      unless current_user.user_profile.profile_image_file_name.blank?
        image_url = "/system/profile_images/#{current_user.user_profile.id}/small/#{current_user.user_profile.profile_image_file_name.gsub(' ', '%20')}"
      else
        unless current_user.facebook_id.blank?
          image_url = "http://graph.facebook.com/#{current_user.facebook_id}/picture?type=normal"
        else
          image_url = "/images/no-profile.png"
        end
      end

        up = current_user.user_profile

	actor = {:url => "/#{up.permalink}",
	:objectType => "user",
	:id => "#{user_id}",
	:image => {:url => "#{image_url}", :width => 250, :height => 250},
	:displayName => "#{user_name}"
	}

	verb = "add to tag"

	m = Movie.find_by_id(movie_id)
	url = ""
	image = ""
	unless m.blank?
	url = "http://www.muvi.com/movies/#{m.permalink}"
	image = POSTER_URL + m.banner_image
	end
	object = {:url => "#{url}", :objectType => "movie", :id => "#{m.id}",
	 :image => {:url => "#{image}", :width => 250, :height => 250},
	 :displayName => "#{m.name}"
	}

	@tag_list = ""
	@tag_list = {:published => Date.today, :actor => actor, :verb => verb, :object => object, :target => target}
	return @tag_list
  end

  def autocomplete
    tags = []
    final_tags = []
    @all_tags = UserMovieList.all(:select=>"id,tag",:conditions=>"user_id = #{current_user.id}")
    unless @all_tags.blank?
      @all_tags.each do |tag|
        tags << {:tag => tag.tag}
      end
    end
    final_tags = {:tags => tags}
    render :json => final_tags.to_json
  end

  def send_list_invite
    if !params[:notification_id].blank?
      begin
        AllNotification.find(:first, :conditions => ["id = #{params[:notification_id]}"]).destroy
      rescue
      end
    end

    activity = []
    arr = []
      @final_arr = []
      actor = ""
      verb = ""
      object = ""
      target = ""

      image_url = ""
      unless current_user.user_profile.profile_image_file_name.blank?
        image_url = "/system/profile_images/#{current_user.user_profile.id}/small/#{current_user.user_profile.profile_image_file_name.gsub(' ', '%20')}"
      else
        unless current_user.facebook_id.blank?
          image_url = "http://graph.facebook.com/#{current_user.facebook_id}/picture?type=normal"
        else
          image_url = "/images/no-profile.png"
        end
      end

      #actor = { :url => "/profile/#{current_user.id}/#{User.convert_to_seo_url(current_user.display_name)}",

      up = current_user.user_profile

      actor = {:url => "/#{up.permalink}",
              :objectType => "user",
              :id => "#{current_user.id}",
              :image => {:url => "#{image_url}", :width => 250, :height => 250},
              :displayName => "#{current_user.display_name}"
           }

      verb = "invited"

      object = {:url => "", :objectType => "list", :id => "#{params[:list_id]}",
               :image => {:url => "", :width => 250, :height => 250},
               :displayName => "#{UserMovieList.find_by_id(params[:list_id]).tag}"
              }

      @final_arr << {:published => Date.today, :actor => actor, :verb => verb, :object => object, :target => target}
      act_new = AllActivity.new
      act_new.user_id = current_user.id
      act_new.activity = @final_arr.to_json
      act_new.activity_type = "invited"
      act_new.save
      render :text => "Invitation sent"
  end

  def get_fb_share
    render :partial => "/user_movie_lists/fb_share", :locals => {:list_id => params[:list_id]}
  end

  def add_to_list
    @list = UserMovieList.order("id desc").find(:all, :conditions => ["user_id = ? and tag != ?", params[:user_id], ''])
    render :partial => "add_to_list"
  end

  def add_to_list_ratepopup
    @list = UserMovieList.order("id desc").find(:all, :conditions => ["user_id = ? and tag != ?", params[:user_id], ''])
    render :partial => "add_to_list_ratepopup"
  end

  def rename_list
    list = UserMovieList.find(params[:list_id])
    unless list.blank?
      list.tag = params[:new_name]
      list.save
    end
    render :text => 1
  end

  def remove_list
    UserMovieList.find(params[:list_id]).destroy
    render :text => 1
  end

  def fetch_review
    @reviews = Review.where(:user_id => params[:user_id], :movie_id => params[:movie_id])
    @review = @reviews.first
    render :text => @review.rating.to_s + "|" + @review.description
    #respond_to do |format|
    #  format.html  {}
    #  format.js
    #end
  end

end
