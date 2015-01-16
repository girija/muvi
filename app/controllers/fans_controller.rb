class FansController < ApplicationController
  skip_before_filter :authenticate_user!
  #layout 'website'
  def create
    celeb_id = params[:celebrity_id] ? params[:celebrity_id] : params[:fans][:celebrity_id]
    @celeb = Celebrity.find_by_id(celeb_id)
    params[:celebrity_id] = celeb_id
    @count = Fan.check_user(current_user.id,celeb_id)
    if params[:block_type] == "fan"
      fans = current_user.user_profile.fan_celebs
      @prev_item = fans.last.celebrity
      @next_item = fans.count > 1 ? fans[1].celebrity : ""
    elsif params[:block_type] == "unfan"
      unfans = current_user.user_profile.unfan_celebs
      @prev_item = unfans.last.celebrity
      @next_item = unfans.count > 1 ? unfans[1].celebrity : ""
    end

    if @count.blank?
      @fan = Fan.new
      @fan.user_id = current_user.id
      @fan.celebrity_id = celeb_id
      @fan.is_fan = true
      if @fan.save
        @user_badge =  UserBadge.new
        @user_badge.add_badge_points(current_user.id,'fan', @fan.celebrity_id)
      end
    else
      if !@count.is_fan
        @count.update_attribute('is_fan', true)
        @user_badge =  UserBadge.new
        @user_badge.add_badge_points(current_user.id,'fan', celeb_id)
      end
    end
    if params[:inner_ajax] == "1"
      render :text => "#{@celeb.fans.count}-#{@celeb.not_fans.count}"
      return
    end
    respond_to do |format|
     format.html  {redirect_to root_path}
     format.js
    end
  end

 def not_a_fan
    celeb_id = params[:celebrity_id] ? params[:celebrity_id] : params[:fans][:celebrity_id]
    @celeb = Celebrity.find_by_id(celeb_id)
    params[:celebrity_id] = celeb_id
    @count = Fan.check_user(current_user.id,celeb_id)
    if params[:block_type] == "fan"
      fans = current_user.user_profile.fan_celebs
      @prev_item = fans.last.celebrity
      @next_item = fans.count > 1 ? fans[1].celebrity : ""
    elsif params[:block_type] == "unfan"
      unfans = current_user.user_profile.unfan_celebs
      @prev_item = unfans.last.celebrity
      @next_item = unfans.count > 1 ? unfans[1].celebrity : ""
    end
    if @count.blank?
      @fan = Fan.new
      @fan.user_id = current_user.id
      @fan.celebrity_id = celeb_id
      @fan.is_fan = false
      if @fan.save
        @user_badge =  UserBadge.new
        @user_badge.add_badge_points(current_user.id,'unfan', celeb_id)
      end
    else
      if @count.is_fan
        @count.update_attribute('is_fan', false)
        @user_badge =  UserBadge.new
        @user_badge.add_badge_points(current_user.id,'unfan', celeb_id)
      end
    end
    if params[:inner_ajax] == "1"
      render :text => "#{@celeb.fans.count}-#{@celeb.not_fans.count}"
      return
    end
    if params[:fan] && params[:fans][:type] == "profile"
     @fan = Fan.find(:all,:conditions =>["user_id = ?", current_user.id])
     @user = User.find_by_id(current_user.id)
     @user_profile = @user.user_profile
    end
    respond_to do |format|
     format.html  {redirect_to root_path}
     format.js
    end   
 end
end
