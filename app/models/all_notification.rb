class AllNotification < ActiveRecord::Base
  validates :object_id, :presence => true
  #validates_uniqueness_of :feed_user, :scope => [:activity_type, :object_id]
  validates_uniqueness_of :feed_user, :scope => [:object_type, :object_id]
  #after_save :display_notification

  def display_notification
    all_activity = []
    notification_qry = AllNotification.find(:all, :conditions => ["id = #{self.id} and viewed = 'f'"])
    unless notification_qry.blank?
      notification_qry.each do|notify|
        no_1 = ActiveSupport::JSON.decode(notify.notification)
        unless no_1.blank?
          no_1.each do |no|
            no["notification_id"] = notify.id
            no["activity_id"] = notify.activity_id
            all_activity << no
          end
        end
      end
    end

    u = AllActivity.select("distinct user_id").find(:all) #.where("user_id NOT IN (#{user_id})").find(:all)
    unless u.blank?
      u.each do |c|
        conn = c.user_id
        DisplayHelper.notify(all_activity, conn)
      end
    end
  end

  def self.update_blank_object_type
    @an = AllNotification.find(:all, :order => ["id desc"], :conditions => ["object_type IS NULL"])
    unless @an.blank?
      @an.each do|an|
        if an.activity_type == "has recommended" or an.activity_type == "saw" or an.activity_type == "released movie" or an.activity_type == "asked" or an.activity_type == "thanked" or an.activity_type == "want to see" or an.activity_type == "next movie" or an.activity_type == "rated" or an.activity_type == "added movie to list" or an.activity_type == "has not recommended"
          an.update_attribute("object_type", "movie")

        elsif an.activity_type == "follow celeb filmography" or an.activity_type == "follow filmography"
           an.update_attribute("object_type", "filmography")

        elsif an.activity_type == "invited" or an.activity_type == "follow this list" or an.activity_type == "added list"
		#or an.activity_type == "follow"
          an.update_attribute("object_type", "list")

	elsif an.activity_type == "follow"
		an.update_attribute("object_type", "list")
        end
      end
    end
  end

  def self.update_release_date
    @allnotif = AllNotification.select("*, object_id as oid").find(:all, :order => ["id desc"], :conditions => ["object_type='movie' and object_id IS NOT NULL and release_date IS NULL"])
    unless @allnotif.blank?
      @allnotif.each do|an|
	begin
	        m = Movie.select("release_date").find_by_id(an.oid)
        	unless m.blank?
			new_n = AllNotificatoin.find_by_id(an.id)
	          	new_n.update_attribute("release_date", "#{m.release_date}")
        	end
	rescue
	end
      end
    end
  end

end
