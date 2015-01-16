class UserBadge < ActiveRecord::Base
  include UtilityHelper
  require 'open-uri'
  belongs_to :user

  def self.points
    {'activity' => 1, 'rating'=> 1, 'fan'=> 1, 'unfan' => 1,  'watch' => 1, 'unwatch'=> 1, 'follow' => 1, 'unfollow' => 1, 'comment' => 1,  'like_video' => 1, 'dislike_video' => 1, 'like_poster' => 1, 'dislike_poster' => 1}
  end

  def add_badge_points(current_user_id, type= '', item_id='')
     badge_points = {}
     new_celeb_badge = {}
     super_fan = []
     mega_fan = []
     @ub = UserBadge.find_by_user_id(current_user_id)
     bpns = UserBadge.points['activity']
     unless @ub.blank?
       puts "Existing "
       @badge_points =  ActiveSupport::JSON.decode(@ub.badge_points)
       if type == 'like'
         badge_points["movie"] =  @badge_points["movie"].to_i
       elsif type == 'dislike'
         badge_points["movie"] =  @badge_points["movie"].to_i
       else
         badge_points["movie"] =  @badge_points["movie"].to_i + bpns.to_i
       end
       @celeb_badges = @badge_points["celeb"]
       celeb = []
       item = {}
       unless @celeb_badges.blank?
         @celeb_badges.each do |celeb_badge|
           celeb << celeb_badge
         end
       end
       if type == 'fan' 
         item[:id] = item_id
         item[:points] = UserBadge.points['fan']
         celeb << item
       end
       badge_points['celeb'] =  celeb
       if type == "unfan"       
         celeb_points = celeb
         celeb = []
         item = {}
         celeb_points.each do |celeb_point|   
           if celeb_point["id"].to_i != item_id.to_i
              celeb << celeb_point
           end
         end
         badge_points['celeb'] =  celeb
       end
       if type == "like"
         celeb_points = celeb
         celeb = []
         item = {}
         movie = Movie.find(item_id)
         movie_cast = movie.movie_casts
         cast_ids = []
         movie_cast.each do |cast|
           cast_ids << cast.celebrity_id
         end
         celeb_points.each do |celeb_point|
            if cast_ids.include?(celeb_point["id"].to_i)
              celeb_point["points"] = celeb_point["points"].to_i + 1
              if celeb_point["points"] == 3
                 super_fan << celeb_point['id'].to_i
                 puts "3 #{celeb_point['points']} **  #{celeb_point['id']}"
              end
              if celeb_point["points"] == 5 
                 mega_fan << celeb_point['id'].to_i
                 puts "5 #{celeb_point['points']} **  #{celeb_point['id']}"
              end
   
              celeb << celeb_point
            else
              celeb << celeb_point
            end
         end
         badge_points['celeb'] =  celeb
       end
       if type == "dislike"
         celeb_points = celeb
         celeb = []
         item = {}
         movie = Movie.find(item_id)
         movie_cast = movie.movie_casts
         cast_ids = []
         movie_cast.each do |cast|
           cast_ids << cast.celebrity_id
         end
         celeb_points.each do |celeb_point|
            if cast_ids.include?(celeb_point["id"].to_i)
              if celeb_point["points"].to_i > 1 
                celeb_point["points"] = celeb_point["points"].to_i - 1
              end
              celeb << celeb_point
            else
              celeb << celeb_point
            end
         end
         badge_points['celeb'] =  celeb
       end
       @ub.badge_points = badge_points.to_json
     else
       puts "New"
       @ub = UserBadge.new
       @ub.user_id = current_user_id.to_i
       badge_points['movie'] = bpns.to_i
       celeb = []
       item = {}
       if type == 'fan'
         item[:id] = item_id
         item[:points] = UserBadge.points['fan']
         celeb << item
         badge_points['celeb'] =  celeb
       end
       @ub.badge_points = badge_points.to_json
     end
     @ub.save
     new_celeb_badge["super_fan"]  = super_fan
     new_celeb_badge["mega_fan"] = mega_fan
     return new_celeb_badge
  end
  def xxx_add_badge_points(current_user_id, type, item_id = '', rating_points = 0, selected_celeb_ids = '')
 
    badge_points = {}
    selected_celeb_ids = selected_celeb_ids.split(',') 
    @ub = UserBadge.find_by_user_id(current_user_id)
    @bps = UserBadge.points[type]
    bpns = UserBadge.points['activity']
    unless @ub.blank?
      unless @ub.badge_points.blank?
        stars = []
        @badge_points =  ActiveSupport::JSON.decode(@ub.badge_points)
        badge_points["movie"] =  @badge_points["movie"].to_i + bpns.to_i
        badge_points["celeb"]  =  @badge_points["celeb"]
        celebs =[]
        if type == 'fan' or rating_points.to_f >= 3
          is_new = true
          celebrity =  @badge_points["celeb"]
          celeb_temp = []
          in_celeb = []
          celebrity.each do |celeb|
            is_new == true
            if type == 'rating' and UserBadge.is_actor_in_movie(item_id, celeb['id'])
              puts "case 1"
              item = {}
              in_celeb[celeb['id'].to_i] = true
              item[:id] = celeb['id']
              item['points'] = celeb['points'] + UserBadge.points['fan']
              is_new = false
              celeb_temp << item
            else
              puts "case 2"
              puts in_celeb
              if in_celeb[celeb['id'].to_i].blank?
                item = {}
                in_celeb[celeb['id'].to_i] = true
                item[:id] = celeb['id']
                item['points'] = celeb['points']
                celeb_temp << item
              end
              if type == 'fan' and is_new == true
                puts "case 3" 
                item = {}
                in_celeb[item_id.to_i] = true
                item[:id] = item_id
                item[:points] = 0
                celeb_temp << item
                is_new = false
              end
            end
            if selected_celeb_ids != 0
            selected_celeb_ids.each do |selected_celeb_id|
                puts "case 4" 
                puts selected_celeb_id 
                if selected_celeb_id.to_i != 0 and in_celeb[selected_celeb_id.to_i].blank?
                  item = {} 
                  item[:id] = selected_celeb_id.to_i
                  item['points'] = UserBadge.points['fan']
                  is_new =false
                  UserBadge.save_fan(current_user_id, selected_celeb_id)
                  celeb_temp << item
                  in_celeb[selected_celeb_id.to_i] = true
               end
            end
            end
          end
        end
        if is_new == true and type == 'fan'
          item = {}
          item[:id] = item_id
          #item[:points] = UserBadge.points['fan']
          item[:points] = 0
          celeb_temp << item
        end
        unless celeb_temp.blank?
          badge_points["celeb"] = celeb_temp
        end
        @ub.badge_points = badge_points.to_json
      else
        @ub = UserBadge.new
        @ub.user_id = current_user_id.to_i
        movie =  bpns.to_i
        badge_points['movie'] = movie
        celeb = [] 
        if selected_celeb_id.to_i > 0
          item[:id] =  selected_celeb_id
          item[:points] = UserBadge.points['fan']
          celeb << item
        end
        if type == 'fan'
         item = {}
         item[:id] =  item_id
         item[:points] = 0
         UserBadge.save_fan(current_user_id, item_id)
         celeb << item
        end
        badge_points['celeb'] =  celeb
        @ub.badge_points = badge_points.to_json
      end
    else
      @ub = UserBadge.new
      @ub.user_id = current_user_id.to_i
      movie =  bpns.to_i
      badge_points['movie'] = movie
      celeb = []
      item = {}
      if selected_celeb_ids.size > 0
        selected_celeb_ids.each do |selected_celeb_id|
          if selected_celeb_id.to_i > 0 
          item[:id] =  selected_celeb_id.to_i
          item[:points] = UserBadge.points['fan']
          celeb << item
          end
        end
      end
      if type == 'fan'
        item[:id] =  item_id 
        item[:points] = 0
        UserBadge.save_fan(current_user_id, item_id)
        celeb << item
      end
      badge_points['celeb'] =  celeb
      @ub.badge_points = badge_points.to_json
    end
     @ub.save
  end
  
  def self.update_muvi_badge(current_user_id, point_type)
  
  end
  def self.is_actor_in_movie(movie, actor_id)
     stars = UserBadge.get_actors(movie)
     stars.each do |star|
       if star.to_i == actor_id.to_i
        return true
       end
     end
    return false
  end
  def self.get_actors(movie)
     UtilityHelper.get_actors(movie)   
  end

  def UserBadge.is_fan_of(current_user_id, celeb_id)
     @ub = UserBadge.find_by_user_id(current_user_id)
     unless @ub.blank?
       @badge_points =  ActiveSupport::JSON.decode(@ub.badge_points)
       celebrity  =  @badge_points["celeb"]
       celebrity.each do |celeb|
        if celeb['id'].to_i == celeb_id.to_i
          return true
        end
       end
     end
     return false 
  end
  def self.save_fan(current_user_id, celeb_id)
    @count = Fan.find(:all, :select => ["id"], :conditions =>["user_id = ? AND celebrity_id = ?", current_user_id, celeb_id])
    if @count.size == 0
      @fan = Fan.new
      @fan.user_id = current_user_id
      @fan.celebrity_id = celeb_id
       puts "sadsasa sd"
      if @fan.save
        @celeb = Celebrity.find_by_id(celeb_id)
        @activity = Activity.new
        @activity.user_id = current_user_id
        @activity.secondary_subject_type = "Celebrity"
        @activity.secondary_subject_id = celeb_id
        @activity.subject_type = "Fan"
        @activity.action = "Is a fan of <a href='/celebrities/#{@celeb.permalink}'>#{@celeb.name}.</a>"
        @activity.save
      end
    end

  end

  def self.update_badges
    UserBadge.all.each  do |ub|
       badge_points = {}
       badge_points['movie'] = Activity.count(:conditions => "user_id = #{ub.user_id}")
       celebs = []
       fan_of = Fan.find(:all, :conditions =>["user_id = ? AND is_fan = ?", ub.user_id, true], :order => "created_at desc")
       fan_of.each do |celeb|
         item = {}
         item[:id] = celeb.celebrity_id
         item[:points] = 1
         celebs << item
       end
       badge_points['celeb'] =  celebs
       ub.badge_points = badge_points.to_json
       ub.save
    end
  end
  def self.update_celeb_points
    UserBadge.all.each  do |ub|
      celebs = []
      reviews = Review.find(:all, :conditions => ["user_id = ? and rating > 3", ub.user_id], :order => "created_at desc")
      badge_points = ActiveSupport::JSON.decode(ub.badge_points)
      badge_points["celeb"].each do |points|
        pnts = 0
        item = {}
        item[:id] = points["id"]
        item[:points] = points["points"]
        reviews.each do |review|
           movie = Movie.find_by_id(review.movie_id)
           unless movie.blank?
             movie.movie_casts.each do |mc|
               if  mc.celebrity_id == points["id"].to_i
                 pnts = pnts + 1
                 item[:points] = pnts
               end
             end
           end
        end
        celebs << item
      end
      badge_points['celeb'] =  celebs
      ub.badge_points = badge_points.to_json
      ub.save
    end
    ub.user_id
  end

end
