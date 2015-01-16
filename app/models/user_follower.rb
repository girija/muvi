class UserFollower < ActiveRecord::Base
 require 'open-uri'
 belongs_to :user

 def add_follower(current_user_id, follower_id,options = {})
   @follower = []
   @uf = UserFollower.find_by_user_id(current_user_id)
   unless @uf.blank?
    unless @uf.followers.blank?
     @follower =  ActiveSupport::JSON.decode(@uf.followers)
       if !@follower.include?(follower_id.to_i)
          @follower << follower_id.to_i
       end
      @uf.followers = @follower
     else
      @follower << follower_id.to_i
      @uf.followers = @follower.to_json 
    end
   else
    @uf= UserFollower.new
    @uf.user_id = current_user_id.to_i
    @follower << follower_id.to_i
    @uf.followers = @follower.to_json 
   end
    @uf.save
    puts @uf.followers
 end

 def remove_follower(current_user_id, follower_id,options = {})
   @uf = UserFollower.find_by_user_id(current_user_id)
   @follower =  ActiveSupport::JSON.decode(@uf.followers)
   @follower.delete_if{|i| i.to_i == follower_id.to_i}
   @uf.update_attribute("followers", @follower)
 end

 def self.get_follower(current_user_id) 
   @uf = UserFollower.find_by_user_id(current_user_id)
   @follower = []
   if !@uf.blank?
     @follower =  ActiveSupport::JSON.decode(@uf.followers)
   end
   return @follower
 end

end
