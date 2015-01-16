class FeedHistory < ActiveRecord::Base

  def self.update_history(user_id, action, object_id)
    @chk_user = FeedHistory.find_by_user_id(user_id)
    unless @chk_user.blank?
      @chk_user.update_attributes(:activity_type => "#{action}",
                                  :object_type => object_id)
    else
      fh = FeedHistory.new
      fh.user_id = user_id
      fh.activity_type = action
      fh.object_type = object_id
      fh.save
    end
  end

end
