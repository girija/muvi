class UserProfilesController < ApplicationController
  require 'paperclip_processors/cropper'
  require 'paperclip_processors/time_stamper'
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token, :only => [:update_image,:update_crop]
  before_filter :msn_redirect, :only => [:view]

  #layout 'website'
  layout:check

  def edit
    @user_profile = current_user.user_profile || UserProfile.new
  end


  def create
    @user_profile = current_user.build_user_profile(params[:user_profile])
    respond_to do |format|
      if @user_profile.save
        format.html { redirect_to(edit_user_profile_path(@user_profile) , :notice => 'user_profile was successfully created.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user_profile.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @user_profile = current_user.user_profile rescue current_user.build_user_profile

    respond_to do |format|
      if @user_profile.update_attributes(params[:user_profile])
        #format.html { redirect_to(edit_user_profile_path(@user_profile) , :notice => 'user_profile was successfully updated.') }

        up = current_user.user_profile
        format.html { redirect_to("/#{up.permalink}" , :notice => 'user_profile was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user_profile.errors, :status => :unprocessable_entity }
      end
    end
  end

  def old_view
    @user = User.find_by_id(params[:user_id])
    @user_profile = @user.user_profile
    redirect_to "/#{@user_profile.permalink}", status: 302
  end

  def view 
    ####### Redirect based on msn embed page #####
    #if request.fullpath !~ /\/msn_embed/
    #  if request.env["HTTP_REFERER"] =~ /\/msn_embed/
    #    request.env["HTTP_HOST"] = request.env["HTTP_HOST"]+"/msn_embed"
    #    url = "http://"+request.env["HTTP_HOST"]+request.fullpath
    #    redirect_to url
    #  end
    #end
    ######## End msn redirect #####################
    @user_profile = UserProfile.find_by_permalink(params[:user_perma])
    unless @user_profile.blank?
      @user = @user_profile.user
    end
    #@user = User.find_by_id(params[:user_id])
    unless @user.blank?
      #@user_profile = @user.user_profile
      unless current_user.blank?
        @count_follow = UserConnection.find_by_user_id(current_user.id)
      end

      @activities = Activity.find(:all,:conditions => ["user_id = ? and secondary_subject_type != ? and subject_type != ?",@user.id,"Comment", "Activity"], :order => ["created_at desc"], :limit => 2)

      @movie_activities = Activity.find(:all,:conditions => ["user_id = ? and (subject_type in ('Fan', 'Unfan', 'Watch', 'Not watch'))", @user.id], :order => ["created_at desc"], :limit => 6)

      @fan = Fan.find(:all,:conditions =>["user_id = ? and is_fan = true", @user.id])
      @unfan = Fan.find(:all,:conditions =>["user_id = ? and is_fan = false", @user.id])
      @want_to_see = WantToSee.find(:all,:conditions =>["user_id = ? and is_want_to_see = true", @user.id])
      @not_want_to_see = WantToSee.find(:all,:conditions =>["user_id = ? and is_want_to_see = false", @user.id])

      @follow = UserConnection.find_by_user_id(@user.id)

    
      @movie_user_reviews = Review.where("user_id = #{@user.id}").find(:all, :order => ["created_at desc"])

      unless current_user.blank?      
        #@suggested_user = Fan.get_suggested_user(current_user)

        #@suggested_friend = User.get_suggested_user(current_user)
        #@your_network = User.get_user_connections(current_user)
      end
      #@tagged_list = UserMovieList.where(:user_id => params[:user_id])
      #@all_seen = ListOfMovie.find_by_user_id(params[:user_id])

    end

  end

  def get_all_lists
    @page = params[:page]
    @user_profile = UserProfile.find_by_permalink(params[:user_id])
    unless @user_profile.blank?
      @user = @user_profile.user
      @tagged_list = UserMovieList.where("user_id = #{@user.id} and tag != ''").paginate(:page => @page, :per_page => 1)
    end
    #@user = User.find_by_id(params[:user_id])
    #unless @user.blank?
    #  @user_profile = @user.user_profile
    #end
    render :partial => "load_list", :locals=>{:tagged_list => @tagged_list, :user_profile => @user_profile}
  end

  def get_all_seen_lists
    @user_profile = UserProfile.find_by_permalink(params[:user_id])
    unless @user_profile.blank?
      @user = @user_profile.user
      @all_seen = ListOfMovie.find_by_user_id(@user.id)
    end
    #@user = User.find_by_id(params[:user_id])
    #unless @user.blank?
    #  @user_profile = @user.user_profile
    #end
    render :partial => "load_all_seen_list", :locals=>{:all_seen => @all_seen, :user_profile => @user_profile }
  end

  def get_all_wanna_see_lists
    @user_profile = UserProfile.find_by_permalink(params[:user_id])
    unless @user_profile.blank?
      @user = @user_profile.user
      @all_wanna_see = ListOfMovie.find_by_user_id(@user.id)
    end
    #@user = User.find_by_id(params[:user_id])
    #unless @user.blank?
    #  @user_profile = @user.user_profile
    #end
    render :partial => "load_all_wanna_see_list", :locals=>{:all_wanna_see => @all_wanna_see, :user_profile => @user_profile }
  end


  def save_data
    unless params[:content].blank?
      @user_profile = UserProfile.find_by_id(params[:id])
      @user_profile.update_attribute("#{params[:field]}",params[:content])
    end
    render :text => "ok"
  end

  def add_bio
    unless params[:user_profiles][:bio].blank?
      @user_profile = UserProfile.find_by_user_id(params[:user_profiles][:user_id])
      unless @user_profile.blank?
        @bio = params[:user_profiles][:bio].gsub(/(\r)?\n/, '<br/>')
        @user_profile.update_attribute("bio",@bio)
      end
    end
    respond_to do |format|
     format.html  {redirect_to root_path}
     format.js
    end
  end
  def show
    @your_network = User.get_user_connections(current_user)
    @followers = UserFollower.get_follower(current_user.id)

    render :partial => "/shared/your_network"
  end
  
  def update_image
    unless params[:user].blank?
      unless current_user.blank?
        profile = UserProfile.find_by_user_id(current_user.id)
        unless profile.blank?
          begin
            profile.update_attributes(params[:user])
          rescue
          end
        end
        respond_to do |format|
          #format.html{redirect_to "/crop_image"}
          unless params[:from].blank?
            format.html{redirect_to "/crop_image?from=1"}
          else
            format.html{redirect_to "/crop_image"}
          end
        end
      else
        respond_to do |format|
          format.html {redirect_to root_path }
        end
      end
    end
  end

  def new_crop
    unless params[:from].blank?
      render :layout => false
    end
  end

  def show_upload_form
    result_array = {}
    muvi = []
    ca = ClientApplication.find_by_name(params[:oauthApp])
    unless ca.blank?
      user = User.find_by_id_and_token(params[:user_id], "#{params[:token]}")
      unless user.blank?
        render :layout => false
      else
        muvi << {:result => "Token doesnot match"}
        result_array['items'] = muvi
        render :text => "jsonpcallback_reset_pass('#{result_array.to_json}')"
      end
    else
      muvi << {:result => "app not authorized"}
      result_array['items'] = muvi
      render :text => "jsonpcallback_reset_pass('#{result_array.to_json}')"
    end
  end

  def crop
    @user_profile = UserProfile.find_by_user_id(current_user.id)
    render :layout => false
  end

  def update_crop
    @user_profile = UserProfile.find_by_user_id(current_user.id)
    @user_profile.update_attributes(params[:user_profile])
    render :text => "ok"
    #respond_to do |format|
    #  format.html {redirect_to "/profile/#{current_user.id}/#{User.convert_to_seo_url(current_user.display_name)}" }
    #end
  end

  def block_detail
    @user_profile = UserProfile.find_by_user_id(params[:profile_id])
    @item = params[:item_type].constantize.find_by_id(params[:item_id])
    if params[:item_type] == "Movie"
      @movies = []
      if params[:block_type] == "like"
        like_rewiews = @user_profile.liked_movies
        like_rewiews.each_with_index do |review,i|
          if review.movie_id.to_s == params[:item_id]
            @next_item = like_rewiews[i+1].nil? ? "" : like_rewiews[i+1].movie
            @prev_item = like_rewiews[i-1].movie
            break
          end
        end
      elsif params[:block_type] == "dislike"
        dislike_rewiews = @user_profile.disliked_movies
        dislike_rewiews.each_with_index do |review,i|
          if review.movie_id.to_s == params[:item_id]
            @next_item = dislike_rewiews[i+1].nil? ? "" : dislike_rewiews[i+1].movie
            @prev_item = dislike_rewiews[i-1].movie
            break
          end
        end
      elsif params[:block_type] == "wantsee"
        wantsee_movies = @user_profile.want_to_sees
        wantsee_movies.each_with_index do |w_see,i|
          if w_see.movie_id.to_s == params[:item_id]
            @next_item = wantsee_movies[i+1].nil? ? "" : wantsee_movies[i+1].movie
            @prev_item = wantsee_movies[i-1].movie
            break
          end
        end
      elsif params[:block_type] == "notwant_see"
        n_see_movies = @user_profile.not_want_to_sees
        n_see_movies.each_with_index do |n_see,i|
          if n_see.movie_id.to_s == params[:item_id]
            @next_item = n_see_movies[i+1].nil? ? "" : n_see_movies[i+1].movie
            @prev_item = n_see_movies[i-1].movie
            break
          end
        end
      end
    elsif params[:item_type] == "Celebrity"
      if  params[:block_type] == "fan"
        fans = @user_profile.fan_celebs
        fans.each_with_index do |fan,i|
          if fan.celebrity_id.to_s == params[:item_id]
            @next_item = fans[i+1].nil? ? "" : fans[i+1].celebrity
            @prev_item = fans[i-1].celebrity
            break
          end
        end
      elsif params[:block_type] == "unfan"
        unfans = @user_profile.unfan_celebs
        unfans.each_with_index do |unfan,i|
          if unfan.celebrity_id.to_s == params[:item_id]
            @next_item = unfans[i+1].nil? ? "" : unfans[i+1].celebrity
            @prev_item = unfans[i-1].celebrity
            break
          end
        end
      end
    elsif params[:item_type] == "Poster"
      like_posters = @user_profile.like_posters
      like_posters.each_with_index do |lp,i|
        if lp.votable_id.to_s == params[:item_id]
          @next_item = like_posters[i+1].nil? ? "" : Poster.find_by_id(like_posters[i+1].votable_id)
          @prev_item = Poster.find_by_id(like_posters[i-1].votable_id)
          break
        end
      end
    elsif params[:item_type] == "Video"
      like_videos = @user_profile.like_videos
      like_videos.each_with_index do |lv,i|
        if lv.votable_id.to_s == params[:item_id]
          @next_item = like_videos[i+1].nil? ? "" : Video.find_by_id(like_videos[i+1].votable_id)
          @prev_item = Video.find_by_id(like_videos[i-1].votable_id)
          break
        end
      end
    end
    if params[:item_type] == "Celebrity"
      render :partial => "user_profiles/profile_celeb_detail", :locals=>{:item=>@item,:type=>params[:block_type], :prev_item => @prev_item, :next_item => @next_item}
    elsif params[:item_type] == "Movie"
      render :partial => "user_profiles/profile_movie_detail", :locals=>{:item=>@item,:type => params[:block_type], :prev_item => @prev_item, :next_item => @next_item}
    else
      render :partial => "user_profiles/poster_video_detail", :locals=>{:item=>@item, :type => params[:block_type], :prev_item => @prev_item, :next_item => @next_item}
    end

  end
  def fetch_movie
    movies = []
    term = params[:term].strip.gsub(/[']/, '\\\\\'')
    @movie_id = UserMovieList.find_by_id(params[:list_id]).movie_id
    @mov_search = Movie.solr_search do
                      fulltext term
                      without(:id, @movie_id)
                      paginate page: 1, per_page: 5
                  end
    @movies = @mov_search.results
    unless @movies.blank?
      @movies .each do |movie|
        movies << {:label => movie.name.truncate(40), :id => movie.id,:thumb => "#{POSTER_URL}#{movie.banner_image_medium}",:story=>movie.story}
      end
    end
    render :json => movies.to_json

  end
  def url_activity
    @user = User.find_by_authentication_token(params[:auth_token])
    if params[:activity] == "have_seen" || params[:activity] == "wanna_see"  || params[:activity] == "add_activity"
      @movie = Movie.find_by_id(params[:movie_id])
    elsif params[:activity] == "follow_list"
      @list = UserMovieList.find_by_id(params[:list_id])
    elsif params[:activity] == "follow_celeb"
      @celeb = Celebrity.find_by_id(params[:celeb_id])
    end
  end

  def upload_image
    render :partial => "upload_image"
  end

end


