class UserConnection < ActiveRecord::Base
  require 'open-uri'
  belongs_to :user
  def add_user_connection(current_user_id, follower_id,options = {})
    @connection = []
    @uc = UserConnection.find_by_user_id(current_user_id)
    unless @uc.blank?
      unless @uc.connections.blank?
        @connection =  ActiveSupport::JSON.decode(@uc.connections)
        if !@connection.include?(follower_id.to_i)  
          @connection << follower_id.to_i
        end
        @uc.connections = @connection
      else
        @connection << follower_id.to_i
        @uc.connections = @connection.to_json
      end
    else
      @uc = UserConnection.new
      @uc.user_id = current_user_id.to_i
      @connection << follower_id.to_i
      @uc.connections = @connection.to_json
    end
    if @uc.save
       if options[:from_fb] == false
         @user = UserProfile.find_by_user_id(current_user_id)
         @follower_user = UserProfile.find_by_user_id(follower_id)
         @activity = Activity.new
         @activity.user_id = current_user_id
         @activity.secondary_subject_type = "Follow"
         @activity.subject_type = "Follow"
         @activity.secondary_subject_id = follower_id
         unless @user.blank?
           @activity.action = "#{@user.display_name} is now following <a href='/profile/#{follower_id}/#{@follower_user.display_name}'>#{@follower_user.display_name}.</a>"
         else
           @activity.action = "Following <a href='/profile/#{follower_id}/#{@follower_user.display_name}'>#{@follower_user.display_name}.</a>"
         end
         @activity.save!
       end
    end
  end


  def remove_user_connection(current_user_id, follower_id,options = {})
      @uc = UserConnection.find_by_user_id(current_user_id)
      @connection =  ActiveSupport::JSON.decode(@uc.connections)
      @connection.delete_if{|i| i.to_i == follower_id.to_i}
      if @uc.update_attribute("connections", @connection)
        if options[:from_fb] == false
          @user = UserProfile.find_by_user_id(current_user_id)
          @follower_user = UserProfile.find_by_user_id(follower_id)
          @activity = Activity.new
          @activity.user_id = current_user_id
          @activity.secondary_subject_type = "Follow"
          @activity.subject_type = "Unfollow"
          @activity.secondary_subject_id = follower_id
          unless @user.blank?
            @activity.action = "#{@user.display_name} unfollowed  <a href='/profile/#{follower_id}/#{@follower_user.display_name}'>#{@follower_user.display_name}.</a>"
          else
           @activity.action = "Unfollowed <a href='/profile/#{follower_id}/#{@follower_user.display_name}'>#{@follower_user.display_name}.</a>"
          end
          @activity.save!
        end
     end
  end

  def self.check_connection(current_user, user_id)
    user_connection = UserConnection.find_by_user_id(current_user.id)
    unless user_connection.blank?
      unless user_connection.connections.blank?
        if ActiveSupport::JSON.decode(user_connection.connections).include?user_id
          return true
        else
          return false
        end
      end
    end
  end

end

