class CelebrityHomeSetting < ActiveRecord::Base
 
  def self.save_celebrity_settings(params)
    #MUVIMETER
    begin
      CelebrityHomeSetting.where("item_id = 1 and item_name='celeb_theater' and subject_type_id=1").destroy_all
    rescue
    end

    count = 0
    params[:theater_id].each do |theater|
      unless params[:theater_item][count].blank?
        if theater.to_i != 0
          @celeb_home_page_setting = CelebrityHomeSetting.new
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
      CelebrityHomeSetting.where("item_id = 2 and item_name='celeb_nextweek' and subject_type_id=1").destroy_all
    rescue
    end

    count = 0
    params[:nextweek_id].each do |nextweek|
      unless params[:nextweek_item][count].blank?
        if nextweek.to_i != 0
          @celeb_home_page_setting = CelebrityHomeSetting.new
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
      CelebrityHomeSetting.where("item_id = 3 and item_name='celeb_trending' and subject_type_id=1").destroy_all
    rescue
    end

    params[:celeb_trending_id].each do |trending|
      count = 0
      unless params[:celeb_trending_item][count].blank?
        if trending.to_i != 0
          @celeb_home_page_setting = CelebrityHomeSetting.new
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
