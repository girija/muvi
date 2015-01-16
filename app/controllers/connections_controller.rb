class ConnectionsController < ApplicationController
  skip_before_filter :authenticate_user!
  before_filter :authenticate_user!, :only => :list
  #layout 'website' 
  layout:check

  def index
    unless current_user.blank?
      @connection_activity = ""
      @connections = current_user.user_connection
      @conn_id = ""
      unless @connections.blank?
        unless @connections.connections.blank?
          @conn =  ActiveSupport::JSON.decode(@connections.connections)
          unless @conn.blank?
            @conn.each do |conn|
              if @conn_id.blank?
                @conn_id = conn
              else
                @conn_id = @conn_id.to_s + "," + conn.to_s
              end
            end
          end
          @connection_activity = User.get_activities(current_user)
        end
      end

      #if @connection_activity.blank? or @connections.blank?
      #  if !@conn_id.blank?
      #    @sort_by_activity = Activity.select("user_id, count(*) as activity_count").where("user_id IS NOT NULL and user_id NOT IN (#{@conn_id})").find(:all, :group => ["user_id"], :order => ["activity_count desc"])
      #  else
      #    @sort_by_activity = Activity.select("user_id, count(*) as activity_count").where("user_id IS NOT NULL").find(:all, :group => ["user_id"], :order => ["activity_count desc"])
      #  end
      #end

      #@connections = current_user.user_connection
      #@show_login = 0
      #@user_profile = current_user.user_profile rescue current_user.build_user_profile

      #@suggested_friend = User.get_suggested_user(current_user)
      #@latest_activities = User.get_activities(current_user)
      #@watch_movies = User.get_activities(current_user,'Watch','Movie')
      #@review_movies = User.get_activities(current_user,'Review','Movie')
      #@celebrity_fans = User.get_activities(current_user,'Fan','Celebrity')
      #@follows = User.get_activities(current_user,'Follow','Follow')
      #@your_network = User.get_user_connections(current_user)
    end
  end

  def list
    unless current_user.blank?
      @user = current_user
      @connections = current_user.user_connection #.paginate(:page => params[:page], :per_page => 12)
      @registered_user = []
      @unregistered_user = []
      unless @connections.blank?
        unless @connections.connections.blank?
          @conn =  ActiveSupport::JSON.decode(@connections.connections)
          unless @conn.blank?
            @conn.each do |conn|
              user = UserProfile.find(:first,:conditions => ["user_id = ?",conn])
              unless user.blank?
                if UserToken.find_by_user_id(conn).blank?
                  @user = User.find(conn)
                  unless @user.facebook_id.blank? and @user.facebook_id.nil?
                    if @user.invited_at.blank? or (@user.invited_at < (Date.today - 10))
                      @unregistered_user << conn
                    end
                  end
                else
                  @registered_user << conn
                end
              end
            end
          end
        end
      end
        @connections = current_user.user_connection
        @show_login = 0
        @user_profile = current_user.user_profile rescue current_user.build_user_profile
  
        @suggested_friend = User.get_suggested_user(current_user)
        @latest_activities = User.get_activities(current_user)
        @watch_movies = User.get_activities(current_user,'Watch','Movie')
        @review_movies = User.get_activities(current_user,'Review','Movie')
        @celebrity_fans = User.get_activities(current_user,'Fan','Celebrity')
        @follows = User.get_activities(current_user,'Follow','Follow')
        @your_network = User.get_user_connections(current_user)
        @followers = UserFollower.get_follower(current_user.id)
    end
  end

  def index_old
    @user = current_user
    @connections = current_user.user_connection #.paginate(:page => params[:page], :per_page => 12)
    @registered_user = []
    @unregistered_user = []
    @remind_user = []
    unless @connections.blank?
      unless @connections.connections.blank?
        @conn =  ActiveSupport::JSON.decode(@connections.connections)
        unless @conn.blank?
          @conn.each do |conn|
            user = UserProfile.find(:first,:conditions => ["user_id = ?",conn])
            unless user.blank?
              if UserToken.find_by_user_id(conn).blank?
                @user = User.find(conn)
                unless @user.facebook_id.blank? and @user.facebook_id.nil?
                  if @user.invited_at.blank? or (@user.invited_at < (Date.today - 10))
                    @unregistered_user << conn
                  else                  
                    @remind_user << conn
                  end
                end
              else
                @registered_user << conn
              end
            end
          end
        end
      end
    end
    @show_login = 0
    @user_profile = current_user.user_profile rescue current_user.build_user_profile

    @suggested_friend = User.get_suggested_user(current_user)
    @latest_activities = User.get_activities(current_user)
    @watch_movies = User.get_activities(current_user,'Watch','Movie')
    @review_movies = User.get_activities(current_user,'Review','Movie')
    @celebrity_fans = User.get_activities(current_user,'Fan','Celebrity')
    @follows = User.get_activities(current_user,'Follow','Follow')
    @your_network = User.get_user_connections(current_user)
    @followers = UserFollower.get_follower(current_user.id)
  end

  def follow
    #@user_connection = UserConnection.find_by_user_id(current_user.id)
    @user_connection = UserConnection.new
    following_user = params[:connections] ? params[:connections][:user_id].to_i : params[:sug_user]
    @user_connection.add_user_connection(current_user.id.to_i, following_user, :from_fb => false)
    @user_follower = UserFollower.new
    @user_follower.add_follower(following_user,current_user.id)
    @user_badge =  UserBadge.new
    @user_badge.add_badge_points(current_user.id,'follow')
    User.post_to_wall(current_user, following_user)

    respond_to do |format|
     format.html  {redirect_to root_path}
     format.js
    end and return   
  end

  def unfollow
    #@follower = params[:connections][:user_id]
    session[:action_type] = 1
    @user_connection = UserConnection.find_by_user_id(current_user.id.to_i)
    unless @user_connection.blank? 
      @user_connection.remove_user_connection(current_user.id.to_i, params[:connections][:user_id].to_i, :from_fb => false)
      @user_follower = UserFollower.find_by_user_id(params[:connections][:user_id])
      @user_follower.remove_follower(params[:connections][:user_id],current_user.id)
      @user_badge =  UserBadge.new
      @user_badge.add_badge_points(current_user.id,'unfollow')
    end and return

    respond_to do |format|
     format.html  {redirect_to root_path}
     format.js
    end and return
  end

  def send_invitation
    unless params[:connections_invite].blank?
      params[:connections_invite].each do |user|
        invited_user = User.find_by_id(user)
        unless invited_user.facebook_id.blank?
          #if current_user.send_fb_invite(invited_user)  
          #  invited_user.update_attribute("invited_at", Time.now())
          #end
          current_user.delay.send_fb_invite(invited_user)
          invited_user.update_attribute("invited_at", Time.now())
        end
      end
    end

    @connections = current_user.user_connection #.paginate(:page => params[:page], :per_page => 12)
    @unregistered_user = []
    unless @connections.blank?
      unless @connections.connections.blank?
        @conn =  ActiveSupport::JSON.decode(@connections.connections)
        unless @conn.blank?
          @conn.each do |conn|
            user = UserProfile.find(:first,:conditions => ["user_id = ?",conn])
            unless user.blank?
              if UserToken.find_by_user_id(conn).blank?
                @user = User.find(conn)
                unless @user.facebook_id.blank? and @user.facebook_id.nil?
                  if @user.invited_at.blank? or (@user.invited_at < (Date.today - 10))
                    @unregistered_user << conn
                  end
                end
              end
            end
          end
        end
      end
    end

    respond_to do |format|
     format.html  {redirect_to root_path}
     format.js
    end and return
  end

  def email_invite
    @email = params[:email_invite]
    @subject = " Muvi is awesome to be in."
    @content = "#{current_user.display_name} has invited you to join <a href='http://www.muvi.com'>Muvi.com</a>.<br>
                <a href='http://www.muvi.com/invite/#{current_user.id}'>Join Muvi.com</a>"
    UserMailer.delay.send_email_invitation(@email, @subject, @content)
    respond_to do |format|
     format.html  {redirect_to root_path}
     format.js
    end and return

  end
 def activities
    if current_user 
      @show_login = false 
      @show_header = true

      @suggested_friend = User.get_suggested_user(current_user)
      @your_network = User.get_user_connections(current_user)
      @followers = UserFollower.get_follower(current_user.id)
      @user_profile = current_user.user_profile
      @latest_activities = User.get_activities(current_user)
      @watch_movies = User.get_activities(current_user,'Watch','Movie')
      @review_movies = User.get_activities(current_user,'Review','Movie')
      @celebrity_fans = User.get_activities(current_user,'Fan','Celebrity')
      @follows = User.get_activities(current_user,'Follow','Follow')
      @show_tab = false
       if !params[:lastID].blank?
        lastId = params[:lastID]
      else
        lastId = Activity.last.id
      end

      if params[:type] == 'all'
        subject_types = ['Watch','Review', 'Fan', 'UnFan' ,'Follow','TopTen','Likes', 'Dislikes']
        @activities = @latest_activities.where('subject_type in (?) and id < ?',subject_types, lastId).limit(15)
        respond_to do |format|
          format.html { render :layout => (params['layout'].blank? ? false : params['layout'])}
          format.js {}
        end and return
      elsif params[:type] == 'movies'
        subject_types = ['Watch','Review'] 
        @activities = @latest_activities.where('subject_type in (?) and id < ?',subject_types, lastId).limit(10)
        respond_to do |format|
          format.html { render :layout => (params['layout'].blank? ? false : params['layout'])}
          format.js {}
        end and return
      elsif params[:type] == 'celebrities'
        subject_types = ['Fan','Unfan']
        @activities =  @latest_activities.where('subject_type in (?) and id < ?',subject_types, lastId).limit(10)
        respond_to do |format|
          format.html { render :layout => (params['layout'].blank? ? false : params['layout'])}
          format.js {}
        end and return
      elsif params[:type] == 'connections'
        subject_types = ['Follow']
        @activities = @latest_activities.where('subject_type in (?) and id < ?',subject_types, lastId).limit(10)
        respond_to do |format|
          format.html { render :layout => (params['layout'].blank? ? false : params['layout'])}
          format.js {}
        end and return
      elsif params[:type] == 'topten' 
        secondary_subject_ids = ['Celebrity', 'Movie']      
        @activities = @latest_activities.where('subject_type in (?) and id < ?','TopTen', lastId).limit(10)
        respond_to do |format|
          format.html { render :layout => (params['layout'].blank? ? false : params['layout'])}
          format.js {}
        end and return
      else
        @show_tab = true
        render :layout => (params['layout'].blank? ? "website" : params['layout'])
      end
     else
       @show_login = true
       if params["layout"] == 'none'
         render :partial => 'register'
       else
         render :layout => (params['layout'].blank? ? "website" : params['layout'])
       end
     end
  end

  def invite_friends
    unless current_user.blank?
      @user = current_user
      @connections = current_user.user_connection #.paginate(:page => params[:page], :per_page => 12)
      @unregistered_user = []
      unless @connections.blank?
        unless @connections.connections.blank?
          @conn =  ActiveSupport::JSON.decode(@connections.connections)
          unless @conn.blank?
            @conn.each do |conn|
              user = UserProfile.find(:first,:conditions => ["user_id = ?",conn])
              unless user.blank?
                if UserToken.find_by_user_id(conn).blank?
                  @user = User.find(conn)
                  unless @user.facebook_id.blank? and @user.facebook_id.nil?
                    if @user.invited_at.blank? or (@user.invited_at < (Date.today - 10))
                      @unregistered_user << conn
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    unless @unregistered_user.blank?
      render :partial => "show_unregistered"
    else
      render :text => "No User present. Please invite using email"
    end
  end

end
