class HomePageSetting < ActiveRecord::Base
  attr_accessor :heading
 
  def self.save_movie_settings(params)
    #MUVIMETER
    begin
      HomePageSetting.where("page_no = 1 and item_id = 1 and item_name='muvimeter' and subject_type_id=1").destroy_all
    rescue
    end

    count = 0
    params[:muvimeter_id].each do |muvimeter|
      unless params[:muvimeter_item][count].blank?
        if muvimeter.to_i != 0
          @home_page_setting = HomePageSetting.new
          @home_page_setting.page_no = 1
          @home_page_setting.item_id = 1
          @home_page_setting.item_name = "muvimeter"
          @home_page_setting.subject_type_id = 1
          @home_page_setting.subject_type = "Movie"
          @home_page_setting.subject_id = muvimeter
          if params[:start] == "muvimeter"
            @home_page_setting.start = "t"
          end
          @home_page_setting.save
        end
      end
      count = count + 1
    end


    #UPCOMING
    begin
      HomePageSetting.where("page_no = 1 and item_id = 2 and item_name='tweeterbuzz' and subject_type_id=1").destroy_all
    rescue
    end

    count = 0
    params[:tweeterbuzz_id].each do |tweeterbuzz|
      unless params[:tweeterbuzz_item][count].blank?
        if tweeterbuzz.to_i != 0
          @home_page_setting = HomePageSetting.new
          @home_page_setting.page_no = 1
          @home_page_setting.item_id = 2
          @home_page_setting.item_name = "tweeterbuzz"
          @home_page_setting.subject_type_id = 1
          @home_page_setting.subject_type = "Movie"
          @home_page_setting.subject_id = tweeterbuzz
          if params[:start] == "tweeterbuzz"
            @home_page_setting.start = "t"
          end
          @home_page_setting.save
        end
      end
      count = count + 1
    end


    #TRENDING NOW
    begin
      HomePageSetting.where("page_no = 1 and item_id = 3 and item_name='trendingnow' and subject_type_id=1").destroy_all
    rescue
    end

    params[:trendingnow_id].each do |trendingnow|
      count = 0
      unless params[:trendingnow_item][count].blank?
        if trendingnow.to_i != 0
          @home_page_setting = HomePageSetting.new
          @home_page_setting.page_no = 1
          @home_page_setting.item_id = 3
          @home_page_setting.item_name = "trendingnow"
          @home_page_setting.subject_type_id = 1
          @home_page_setting.subject_type = "Movie"
          @home_page_setting.subject_id = trendingnow
          if params[:start] == "trendingnow"
            @home_page_setting.start = "t"
          end
          @home_page_setting.save
        end
      end
      count = count + 1
    end


  end
  
  def self.save_celebrity_settings(params)
    begin
      HomePageSetting.where("page_no = 1 and item_id = 5 and item_name='featured_celebrity' and subject_type_id=2").destroy_all
    rescue
    end

    if !params[:featured_celebrity_id].blank? and params[:featured_celebrity_id].to_i != 0
      unless params[:featured_celebrity].blank?
        @home_page_setting = HomePageSetting.new
        @home_page_setting.page_no = 1
        @home_page_setting.item_id = 5
        @home_page_setting.item_name = "featured_celebrity"
        @home_page_setting.subject_type_id = 2
        @home_page_setting.subject_type = "Celebrity"
        @home_page_setting.subject_id = params[:featured_celebrity_id]
        @home_page_setting.save
      end
    end


    begin
      HomePageSetting.where("page_no = 1 and item_id = 7 and item_name='celebrity_tweet' and subject_type_id=2").destroy_all
    rescue
    end
 
    count = 0
    params[:celebrity_tweet_id].each do |celebrity_tweet|
      unless params[:celebrity_tweet_item][count].blank?
        if celebrity_tweet.to_i != 0
          @home_page_setting = HomePageSetting.new
          @home_page_setting.page_no = 1
          @home_page_setting.item_id = 7
          @home_page_setting.item_name = "celebrity_tweet"
          @home_page_setting.subject_type_id = 2
          @home_page_setting.subject_type = "Celebrity"
          @home_page_setting.subject_id = celebrity_tweet
          @home_page_setting.save
        end
      end
      count = count + 1
    end

  end


  def self.save_featured_movie(params)
    begin
      HomePageSetting.where("page_no = 1 and item_id = 10 and item_name='featured_movie' and subject_type_id=1").destroy_all
    rescue
    end

    if !params[:featured_movie_id].blank? and params[:featured_movie_id].to_i != 0
      unless params[:featured_movie].blank?
        @home_page_setting = HomePageSetting.new
        @home_page_setting.page_no = 1
        @home_page_setting.item_id = 10
        @home_page_setting.item_name = "featured_movie"
        @home_page_setting.subject_type_id = 1
        @home_page_setting.subject_type = "Movie"
        @home_page_setting.subject_id = params[:featured_movie_id]
        @home_page_setting.save
      end
    end
  end 

  def self.save_user_settings(params)
    begin
      HomePageSetting.where("page_no = 1 and item_id = 9 and item_name='featured_member' and subject_type_id=3").destroy_all
    rescue
    end

    if !params[:featured_member_id].blank? and params[:featured_member_id].to_i != 0
      unless params[:featured_member].blank?
        @home_page_setting = HomePageSetting.new
        @home_page_setting.page_no = 1
        @home_page_setting.item_id = 9
        @home_page_setting.item_name = "featured_member"
        @home_page_setting.subject_type_id = 3
        @home_page_setting.subject_type = "User"
        @home_page_setting.subject_id = params[:featured_member_id]
        @home_page_setting.save
      end
    end

  end

  def self.save_featured_topten(params)
    begin
      HomePageSetting.where("page_no = 1 and item_id = 11 and item_name='featured_topten' and subject_type_id=4").destroy_all
    rescue
    end

    if !params[:featured_topten_id].blank? and params[:featured_topten_id].to_i != 0
      unless params[:featured_topten].blank?
        @home_page_setting = HomePageSetting.new
        @home_page_setting.page_no = 1
        @home_page_setting.item_id = 11
        @home_page_setting.item_name = "featured_topten"
        @home_page_setting.subject_type_id = 4
        @home_page_setting.subject_type = "Topten"
        @home_page_setting.subject_id = params[:featured_topten_id]
        @home_page_setting.save
      end
    end
  end

  def self.save_celebrity_home_settings(params)
    #MUVIMETER
    begin
      HomePageSetting.where("page_no = 2 and item_id = 1 and item_name='celeb_theater' and subject_type_id=1").destroy_all
    rescue
    end

    count = 0
    params[:theater_id].each do |theater|
      unless params[:theater_item][count].blank?
        if theater.to_i != 0
          @celeb_home_page_setting = HomePageSetting.new
          @celeb_home_page_setting.page_no = 2
          @celeb_home_page_setting.item_id = 1
          @celeb_home_page_setting.item_name = "celeb_theater"
          @celeb_home_page_setting.subject_type_id = 1
          @celeb_home_page_setting.subject_type = "Celebrity"
          @celeb_home_page_setting.subject_id = theater
          @celeb_home_page_setting.save
        end
      end
      count = count + 1
    end


    #UPCOMING
    begin
      HomePageSetting.where("page_no = 2 and item_id = 2 and item_name='celeb_nextweek' and subject_type_id=1").destroy_all
    rescue
    end

    count = 0
    params[:nextweek_id].each do |nextweek|
      unless params[:nextweek_item][count].blank?
        if nextweek.to_i != 0
          @celeb_home_page_setting = HomePageSetting.new
          @celeb_home_page_setting.page_no = 2
          @celeb_home_page_setting.item_id = 2
          @celeb_home_page_setting.item_name = "celeb_nextweek"
          @celeb_home_page_setting.subject_type_id = 1
          @celeb_home_page_setting.subject_type = "Celebrity"
          @celeb_home_page_setting.subject_id = nextweek
          @celeb_home_page_setting.save
        end
      end
      count = count + 1
    end


    #TRENDING NOW
    begin
      HomePageSetting.where("page_no = 2 and item_id = 3 and item_name='celeb_trending' and subject_type_id=1").destroy_all
    rescue
    end

    params[:celeb_trending_id].each do |trending|
      count = 0
      unless params[:celeb_trending_item][count].blank?
        if trending.to_i != 0
          @celeb_home_page_setting = HomePageSetting.new
          @celeb_home_page_setting.page_no = 2
          @celeb_home_page_setting.item_id = 3
          @celeb_home_page_setting.item_name = "celeb_trending"
          @celeb_home_page_setting.subject_type_id = 1
          @celeb_home_page_setting.subject_type = "Celebrity"
          @celeb_home_page_setting.subject_id = trending
          @celeb_home_page_setting.save
        end
      end
      count = count + 1
    end


  end

end
