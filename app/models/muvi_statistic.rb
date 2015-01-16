class MuviStatistic < ActiveRecord::Base
  # attr_accessible :title, :body

  def self.count_list_for_movie
    list = UserMovieList.order("id").find(:all)
    list.each do|l|
      unless l.tag.blank?
         user = User.find_by_id(l.user_id)
         unless user.blank?
           up = user.user_profile
           unless up.profile_image_file_name.blank?
             user_image = "/system/profile_images/#{up.id}/small/#{up.profile_image_file_name.gsub(' ', '%20')}"
           else
             unless user.facebook_id.blank?
               user_image = "http://graph.facebook.com/#{user.facebook_id}/picture?type=normal"
             else
               user_image = "/images/no-profile.png"
             end
           end


          movie_id_arr = ActiveSupport::JSON.decode(l.movie_id)
          movie_id_arr.each do |m|
            @final_arr = []
            ml = MuviStatistic.find_by_movie_id(m)
            unless ml.blank?
              list_info_arr =  ActiveSupport::JSON.decode(ml.list_json)
              new_list_arr = {:list_name => l.tag,:list_id => l.id,:image => user_image, :profile_page => "/profile/#{l.user_id}/#{User.convert_to_seo_url(up.display_name)}"}
              #list_info_arr << new_list_arr.to_json
              list_info_arr << new_list_arr

              ml.list_json = list_info_arr.to_json
              ml.list_count = ml.list_count + 1
              ml.save
            else
              ms = MuviStatistic.new
              ms.movie_id = m
              ms.list_count = 1
              list_info = []

              list_arr = {:list_name => l.tag,:list_id => l.id,:image => user_image, :profile_page => "/profile/#{l.user_id}/#{User.convert_to_seo_url(up.display_name)}"}
              @final_arr << list_arr
              ms.list_json = @final_arr.to_json

              ms.save
            end
          end
        end
      end
    end
  end

end
