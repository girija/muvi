module DisplayHelper
  def show_feed_sidebar(current_user_id)
    @all_activity = AllActivityHelper.display_notification(0, current_user_id)
    render :partial => "/home/show_feed_sidebar", :locals => {:all_activity => @all_activity}
  end

  def self.admin_feed_for_new_user(cur_user)
    # Add 5 admin feeds for newly registered users
    if cur_user.sign_in_count == 0 or cur_user.sign_in_count == 1
      admin_feed = AllActivity.where("user_id IS NULL").order("id desc").limit(10).find(:all)

     admin_feed_cnt = 1
      unless admin_feed.blank?
        admin_feed.each do |a|
	  begin
            if admin_feed_cnt <= 5
              if AllActivityHelper.add_admin_notification(1, cur_user.id, a)
                admin_feed_cnt = admin_feed_cnt + 1
	      end
            else
              break
            end          
          rescue
          end
        end
      end
    end
  end

  def self.get_result(cache_val, page_no, page_type)
    @result_arr = []
    cache_page_no = ""

    if page_type == "movies"
      cache_page_no = "10,20,30,40"

    elsif page_type == "star" or page_type == "stars"
      cache_page_no = "11,21,31,41"

    elsif page_type == "released"
      cache_page_no = "12,22,32,42"

    elsif page_type == "upcoming"
      cache_page_no = "13,23,33,43"
    
    elsif page_type == "trailer" or page_type == "trailers"
      cache_page_no = "14,24,34,44"
    elsif page_type == "picture" or page_type == "pictures"
      cache_page_no = "16,26,36,46"

    end
    unless cache_page_no.blank?
      #@res = Rails.cache.fetch("#{cache_val}"){HomePageSetting.find(:all, :conditions => ["page_no IN (#{cache_page_no})"], :order => ["page_no"])}
      @res = HomePageSetting.find(:all, :conditions => ["page_no IN (#{cache_page_no})"], :order => ["page_no"])
      unless @res.blank?
        @res.each do |res|
          if page_no =~ /#{res.page_no}/
            @result_arr << res
          end
        end
      end
    end
    return @result_arr
  end


  def self.get_location(ip)
    loc_language = "hindi"
    begin
      if Geocoder.search("#{ip}")[0].country_code == "IN"
        loc_language = "hindi"
      else
        loc_language = "english"
      end
    rescue
    end
    return loc_language
  end

  def self.get_location_old(ip)
    loc_language = "english"
    begin
      #if Geocoder.search("#{ip}")[0].country_code == "US"
      #  loc_language = "english"
      if Geocoder.search("#{ip}")[0].country_code == "IN"   
        state_code = Geocoder.search("#{ip}")[0].state_code
        unless state_code.blank?
          if state_code == "TN"
            loc_language = "tamil"
          elsif state_code == "AP" or state_code == "02"
            loc_language = "telugu"
          else
            loc_language = "hindi"
          end
        else
          loc_language = "hindi"
        end
      else
        loc_language = "english"
      end
    rescue
    end

    return loc_language
  end

  def self.get_page_number(type, params, cookies)
    page_no = ""
    second_no = ""

    if type == "movies"
      second_no = 0
    elsif type == "stars"
      second_no = 1
    elsif type == "released"
      second_no = 2
    elsif type == "upcoming"
      second_no = 3
    elsif type == "trailers"
      second_no = 4
    elsif type == "pictures"
      second_no = 6
    end

    unless params[:lang].blank?
      if params[:lang].scan(",")
        lang = params[:lang].split(",")
        for i in 0..(lang.size)
          if lang[i] == "hindi"
            page_no += 1.to_s + second_no.to_s + ","
          end
          if lang[i] == "english"
            page_no += 2.to_s + second_no.to_s + ","
          end
          if lang[i] == "tamil"
            page_no += 3.to_s + second_no.to_s + ","
          end
          if lang[i] == "telugu"
            page_no += 4.to_s + second_no.to_s + ","
          end
        end
      end

    else
      if cookies[:hindi] == "yes"
        page_no += 1.to_s + second_no.to_s + ","
      end
      if cookies[:english] == "yes"
        page_no += 2.to_s + second_no.to_s + ","
      end
      if cookies[:tamil] == "yes"
        page_no += 3.to_s + second_no.to_s + ","
      end
      if cookies[:telugu] == "yes"
        page_no += 4.to_s + second_no.to_s + ","
      end
    end
  
    if page_no.scan(",")
      page_no = page_no.chop
    end
    return page_no

  end

  def display_homepage_block(options)
    render :partial => "/home_display/home_page_boxes", :locals => {:options => options}
  end

	def self.notify(activity, cur_user_id)
		@activity = activity
		ApplicationHelper.broadcast("/home/index/#{cur_user_id}", activity)
	end

end
