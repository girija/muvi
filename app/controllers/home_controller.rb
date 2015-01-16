class HomeController < ApplicationController
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token
  before_filter :msn_redirect, :only => [:contact_us]

  #layout 'home'
  layout:check

  require 'arel'
  require 'open-uri'
  require 'nokogiri'
  require 'jcode' if RUBY_VERSION < '1.9'
  require "net/http"
  require "uri"

  def contacts_callback
    @contacts = request.env['omnicontacts.contacts']
  end

  def import_failed
    # you can redirect to wherever you want. Just sample sake I defined
  end

  def fetch_contact
    @contacts = Contacts.new(params[:type], params[:email], params[:password]).contacts
    respond_to do |format|
      format.js
    end
  end

   def index
    if !cookies[:muviuser_id].blank? && cookies[:redirected].to_i == 1
      user = User.find_by_id(cookies[:muviuser_id])
      unless user.blank?
        auth_token = user.authentication_token
        cookies[:redirected] = 0
        redirect_to "/users/sign_in?authentication_key=#{auth_token}"
        return
      end

    else

     @all_wanna_see_activity = []
     @all_seen_activity = []	
     unless current_user.blank?
       if current_user.sign_in_count == 0 or current_user.sign_in_count == 1
 	 begin
	        #ListOfMovie.update_discovery(current_user.id)
	 rescue Exception => exc
		puts "+++++++++++++"
       		puts exc.message
  	  end
        end
        @current_user_id = current_user.id

        @recent_movies = Movie.released.order("release_date DESC").limit(3)
        @top_rated_movies = Movie.last_six_months.where("language = 'English'").order("muvimeter desc").limit(5)
        #@all_activity = AllActivityHelper.display_notification(0, current_user.id)
        if current_user.is_studio_admin == true
          redirect_to "/add_movie"
        end
      else
        render :layout => "default_home"
      end
    end
  end


  def pass
   list_of_movies = ListOfMovie.find_by_user_id(current_user.id)
   if list_of_movies.discovery_lists.blank? #or  ActiveSupport::JSON.decode(list_of_movies.discovery_lists).size <=3
     #ListOfMovie.update_discovery(current_user.id)
     curated_movies = CuratedMovie.first
     if curated_movies
       if Geocoder.search(request.remote_ip)[0].country_code == "IN"
         loc_list = curated_movies.bol_movies
       else
         loc_list = curated_movies.hol_movies
       end
       movie_list =  list_of_movies.pass_lists.blank? ? ActiveSupport::JSON.decode(loc_list) : ActiveSupport::JSON.decode(loc_list) - ActiveSupport::JSON.decode(list_of_movies.pass_lists)
       p(movie_list)
       if movie_list.blank? || movie_list.count < 2
         ListOfMovie.update_discovery(current_user.id)
         list_of_movies = ListOfMovie.find_by_user_id(current_user.id)
         discovery_list = (list_of_movies.discovery_lists.gsub("[","").gsub("]","").split(",").map(&:to_i).select{|v| v.to_i != params[:movie_id].to_i}).sort_by{rand}[0,1]
       else
         discovery_list = (movie_list.to_json.gsub("[","").gsub("]","").split(",").map(&:to_i).select{|v| v.to_i != params[:movie_id].to_i}).sort_by{rand}[0,1]
       end
     end
   else
     #list_of_movies = ListOfMovie.find_by_user_id(current_user.id)
     discovery_list = (list_of_movies.discovery_lists.gsub("[","").gsub("]","").split(",").map(&:to_i).select{|v| v.to_i != params[:movie_id].to_i}).sort_by{rand}[0,1]
     if ActiveSupport::JSON.decode(list_of_movies.discovery_lists).size <=3
       ListOfMovie.update_discovery(current_user.id)
     end
   end
   @current_movie = Movie.find(discovery_list[0].to_i)
   if !@current_movie.banner_image.index('no-image.png').nil?
     render :partial => "skip_pass"
   else
     @pass_list = []
     @pass_list = ActiveSupport::JSON.decode(list_of_movies.pass_lists) if list_of_movies.pass_lists
     if !list_of_movies.pass_lists.blank?
       @pass_list << params[:movie_id].to_i unless params[:movie_id].blank?
     else
       @pass_list = [params[:movie_id].to_i] unless params[:movie_id].blank?
     end
     unless @pass_list.blank?
       puts params[:movie_id]
       list_of_movies.pass_lists = @pass_list.to_json
       list_of_movies.save
       if list_of_movies.discovery_lists
         @list_discovery = list_of_movies.discovery_lists.gsub("[","").gsub("]","").split(",").map { |s| s.to_i}
         @tmp_array = []
         @list_discovery.each do |ld|
           if ld.to_i != params[:movie_id].to_i
            @tmp_array << ld.to_i
           end
         end
         list_of_movies.update_attribute('discovery_lists',@tmp_array.uniq.to_json)
       end
     end
     movie_id = discovery_list[0].to_i

     @video_id = ""
     @video = ""

     tagging = Tagging.find(:all, :conditions => ["tagger_id = ?  and taggable_type = 'Video'",movie_id], :select => "taggable_id")
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
       @videos = Video.where("id IN (#{@videoids})").find(:all,:conditions => ["rank = 1"]).first
       #video = Video.find_by_id(videoids,:conditions => ["rank = 1"])
     end
     unless @videos.blank?
       @trailer = @videos
     else
       @trailer = false
     end
     #render "pass.js", :layout => nil
     #respond_to do |format|
     #     format.js
     #end
     render :partial => "pass"
   end
  end

  def pass_old
   list_of_movies = ListOfMovie.find_by_user_id(current_user.id)
      list_of_movies = ListOfMovie.find_by_user_id(current_user.id)
       discovery_list = []
       movies_seen_array = JSON.parse(list_of_movies.seen_lists) + JSON.parse(list_of_movies.wanna_see_lists)
       movies_seen_array.each do |i|
         discovery_list << i["object"]["id"].to_i
       end
     logger.info("Session discovery size")
     logger.info(session[:discovery_size])
     logger.info(discovery_list.length)
     logger.info("Discovery List")
     logger.info(discovery_list)
     logger.info("Stored current movie")
     logger.info(current_user.current_movie_id)
     discovery_size_length = discovery_list.length
     if current_user.current_movie_id.blank? or session[:discovery_size] == discovery_size_length
        if discovery_list.length > 0
           current_movie = discovery_list[rand(discovery_size_length)]
        else
           current_movie = 53736
        end
     else
        current_movie = current_user.current_movie_id
     end
     logger.info("Current MOvie")
     logger.info(current_movie)
     reccomended_movie = nil
     while reccomended_movie.blank? or !Movie.exists?(reccomended_movie) or discovery_list.include?(reccomended_movie) do
        begin
         list_fetch = open("http://ec2-122-248-213-135.ap-southeast-1.compute.amazonaws.com:3000/application/#{current_movie}/0").read
        rescue OpenURI::HTTPError => ex
           list_fetch = 0
        end
        logger.info("List from reccomender")
        logger.info(list_fetch)
        if list_fetch == 0
           current_movie = discovery_list[rand(discovery_size_length)]
        else
           reccomended_movie = list_fetch
        end
     end
  # if params[:first_time] == "truex"
     logger.info("Reccomending Movie")
     logger.info(reccomended_movie)
     @next_movie = Movie.find(reccomended_movie)
     @movie_id = reccomended_movie
     current_user.update_attribute(:current_movie_id,reccomended_movie)
  # end
     session[:discovery_size] = discovery_size_length
   @next_movie_pass = Movie.find(reccomended_movie)
   movie_id = reccomended_movie

   #if params[:first_time] == "truex"
   #  @next_movie = Movie.find(discovery_list[0].to_i)
   #  @movie_id = @next_movie.id
   #end
   #@next_movie_pass = Movie.find(discovery_list[0].to_i)

   @current_movie = Movie.find(discovery_list[0].to_i)

   movie_id = discovery_list[0].to_i 
   #################

   @video_id = ""
   @video = ""

   tagging = Tagging.find(:all, :conditions => ["tagger_id = ?  and taggable_type = 'Video'",movie_id], :select => "taggable_id")
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
     @videos = Video.where("id IN (#{@videoids})").find(:all,:conditions => ["rank = 1"]).first
     #video = Video.find_by_id(videoids,:conditions => ["rank = 1"])
   end
   unless @videos.blank?
     @trailer = @videos
   else
     @trailer = false
   end
   render "pass.js", :layout => nil
  end

  def page
    begin
      @page = Page.where('permalink = ?', params[:id]).first
    rescue
      logger.debug "*** RecordNotFound with id = #{params[:id]} ***"
      render_404
    end
   end

  def contact_us
    #@content = Page.find_reference('contact-us').first rescue nil
  end

  def user_agreement
    @page = Page.find_by_permalink('terms-and-conditions') rescue nil
  end


  def muvi_agreement
    @page = Page.find_by_permalink('terms-and-conditions') rescue nil
  end

  def add
    ListOfMovie.add_update_list(params[:user_id], params["movie_id"], 'seen it')
    render :text=>"true"
    #render "add.js.erb", :layout => nil
  end
  def reload
    @movie = Movie.find_by_id(params["movie_id"])
    render "reload.js", :layout => nil
  end

  def forgot_password

  end

  def send_forgot_password
    #@email = params[:u_email]
    #@subject = "Reset your MUVI password"
    #@content = "http://#{request.env["HTTP_HOST"]}/"

    @user = User.find_by_email(params[:u_email])
    @user.reset_password_token = User.reset_password_token
    @user.save
    #@user.send_reset_password_instructions#.invoke_job
    change_pwd_link = "http://www.muvi.com/users/password/edit?reset_password_token=#{@user.reset_password_token}"
    #change_pwd_link = edit_password_url(@user, :reset_password_token => @user.reset_password_token)
    UserMailer.forgot_password(@user,change_pwd_link)
  
    respond_to do |format|
      format.js
    end
  end

  def wanna_see_and_seen_movie
    AllNotification.find(:first, :conditions => ["id = #{params[:notification_id]}"]).destroy
    ListOfMovie.add_update_list(params[:user_id], params["movie_id"], params[:type])
    respond_to do |format|
      format.js
    end
  end

  def delete_activity
    list = ListOfMovie.find_by_user_id(params[:user_id])
    unless list.blank?
      @activity_deleted = []
      if list.activity_deleted
        @activity_deleted = ActiveSupport::JSON.decode(list.activity_deleted)
        if !@activity_deleted.include?(params[:activity_id].to_i)
          @activity_deleted << params[:activity_id].to_i
        end
        list.activity_deleted = @activity_deleted
      else
        @activity_deleted << params[:activity_id].to_i
        list.activity_deleted = @activity_deleted.to_json
      end
      list.update_attribute("activity_deleted", @activity_deleted.to_json)
      render :text => 1
    end
  end

  def show_invite
    if current_user.blank?
      redirect_to "/"
    end
  end

  def show_choose_language
    if current_user.blank?
      redirect_to "/"
    end
  end

  def show_admin_list
    @lists = []
    @lists = AdminList.find(:all)
    render :partial => "show_admin_list"
  end

  def show_movie
    #  unless cookies[:language].blank?
    #    @user_movies = Movie.find(:all, :conditions => ["language = '#{cookies[:language].camelize}'"], :limit => 6)
    #  else
    #    @user_movies = Movie.find(:all, :order => ["id desc"], :limit => 6)
    #  end

    lang = ""
    lang_arr = []
    if cookies[:hindi] == "yes"
      #lang = "'Hindi'"
      unless lang.blank?
        lang += "," + "'Hindi'"
      else
        lang = "'Hindi'"
      end
      lang_arr.push("Hindi")
    end

    if cookies[:english] == "yes"
      unless lang.blank?
        lang += "," + "'English'"
      else
        lang = "'English'"
      end
      lang_arr.push("English")
    end
    if cookies[:tamil] == "yes"
      unless lang.blank?
        lang += "," + "'Tamil'"
      else
        lang = "'Tamil'"
      end
      lang_arr.push("Tamil")
    end

    if cookies[:telugu] == "yes"
      unless lang.blank?
        lang += "," + "'Telugu'"
      else
        lang = "'Telugu'"
      end
      lang_arr.push("Telugu")
    end

    if cookies[:kannada] == "yes"
      unless lang.blank?
        lang += "," + "'Kannada'"
      else
        lang = "'Kannada'"
      end
      lang_arr.push("Kannada")
    end


    if cookies[:marathi] == "yes"
      unless lang.blank?
        lang += "," + "'Marathi'"
      else
        lang = "'Marathi'"
      end
      lang_arr.push("Marathi")
    end


    if cookies[:gujarati] == "yes"
      unless lang.blank?
        lang += "," + "'Gujarati'"
      else
        lang = "'Gujarati'"
      end
      lang_arr.push("Gujarati")
    end


    if cookies[:malayalam] == "yes"
        unless lang.blank?
        lang += "," + "'Malayalam'"
      else
        lang = "'Malayalam'"
      end
      lang_arr.push("Malayalam")
    end


    if cookies[:bhojpuri] == "yes"
        unless lang.blank?
        lang += "," + "'Bhojpuri'"
      else
        lang = "'Bhojpuri'"
      end
      lang_arr.push("Bhojpuri")
    end


    if cookies[:punjabi] == "yes"
      unless lang.blank?
          lang += "," + "'Punjabi'"
      else
        lang = "'Punjabi'"
      end
      lang_arr.push("Punjabi")
    end


    if cookies[:bengali] == "yes"
      unless lang.blank?
            lang += "," + "'Bengali'"
      else
        lang = "'Bengali'"
      end
      lang_arr.push("Bengali")
    end

    if lang.blank?
      lang = "'English'"
    end
    @u = User.find_by_id(current_user.id)
    @u.update_attribute("language", lang_arr.to_s)

    @user_movies = []
    @user_movies = HomeMovielist.where("list_type = 'top_rated' and lang IN (#{lang})").limit(6)
    render :partial => "show_movie"
  end

  def show_feed
    if !current_user.blank?
      @recent_movies = Movie.released.order("release_date DESC").limit(3)
      @top_rated_movies = Movie.last_six_months.where("language = 'English'").order("muvimeter desc").limit(5)
      @all_activity = AllActivityHelper.display_notification(0, current_user.id)
      #@movie_lists = ListOfMovie.find_by_user_id(current_user.id)

      @current_user_id = current_user.id
    else
      redirect_to "/"
    end
    
  end

  def load_seen_wanna_see
    render :partial => "load_seen_wanna_see"
  end

  def load_movies_from_lists
    @user_followed_list = Follow.user_followed_list(current_user.id)
    @list = Follow.load_movies_from_lists(current_user.id)
    render :partial => "load_movies_from_lists", :locals => {:movie_lists => @list}
  end

  def load_movies_for_this_list
    if params[:list_id] == "all"
      @list = Follow.load_movies_from_lists(current_user.id)
    else
      @list = Follow.load_movies(current_user.id, params[:list_id])
    end
    render :partial => "load_movies", :locals => {:movie_lists => @list}
  end

  def show_all_feed
    @all_activity = AllActivityHelper.display_notification(0, current_user.id)
    render :partial => "/home/show_feed_sidebar", :locals => {:all_activity => @all_activity}
  end

  def get_movie_cast
    m = Movie.find_by_id(params[:movie_id])
    render :text => m.get_first_two_actors_link_gray.html_safe
  end
  def fetch_movie_lists
    render  :partial => "/shared/movie_lists"
  end

  def update_user_language
    lang = ""
    lang_arr = []
    if cookies[:hindi] == "yes"
      lang = "'Hindi'"
      lang_arr.push("Hindi")

    elsif cookies[:english] == "yes"
      lang = "'English'"
      lang_arr.push("English")
    end
    unless current_user.blank?
      @u = User.find_by_id(current_user.id)
      @u.update_attribute("language", lang_arr.to_s)

      DisplayHelper.admin_feed_for_new_user(current_user)
    end

    render :text => 1
  end

  def test1
    render :layout=>false
  end

  def admin_feed_for_new_user
     DisplayHelper.admin_feed_for_new_user(current_user)
     #render :partial => admin_feed_for_new_user
     #render :text => 1
  end

  def add_movie
  end

  def test_page
    render :partial => "test_page"
  end
end

