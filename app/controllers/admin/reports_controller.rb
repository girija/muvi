class Admin::ReportsController < ApplicationController
  before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token
  before_filter :admin?
  layout 'admin'


  def index
  end


  def scheduler_updates
    @search = ActivityUpdate.scheduler_updates.latest.search(params[:search])
    @scheduler_updates = @search.paginate(:page => params[:page], :per_page => 50)
  end

  def admin_updates
    @search = ActivityUpdate.admin_updates.latest.search(params[:search])
    @admin_updates = @search.paginate(:page => params[:page], :per_page => 50)
  end
  
  def download_activity
    activity_date = params[:activity_date].to_date
    @activities = Activity.find(:all,:conditions=>["created_at BETWEEN ? AND ?",activity_date,activity_date+1])
    @outfile = "activities_" + activity_date.strftime("%m-%d-%Y") + ".csv"
    require 'csv'

    file = CSV.generate do |csv|
      csv << [
        "Username",
        "Email",
        "Activity",
        "Activity Time"
      ]
      @activities.each do |activity|
        user_name = activity.user.display_name
        email = activity.user.email
        action =  activity.action.gsub( %r{</?[^>]+?>}, '' )
        activity_time = activity.created_at.strftime("%m-%d-%Y %I:%M %p")
        csv << [
          user_name,
          email,
          action,
          activity_time
        ]
      end
    end

    send_data file, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment;filename=#{@outfile}"

  end

  def show_report
    @unique_reg = User.select("count(*) as total").find(:first)
    @unique_reg_this_month = User.select("count(*) as total").find(:first, :conditions => ["(Extract(month from created_at) = Extract(month from NOW())) AND (Extract(year from created_at) = Extract(year from NOW())) "])
    @unique_reg_last_month = User.select("count(*) as total").find(:first, :conditions => ["(Extract(month from created_at) = Extract(month from (CURRENT_DATE - INTERVAL '1 months'))) AND (Extract(year from created_at) = Extract(year from (CURRENT_DATE - INTERVAL '1 months')))"])
    @unique_reg_last_2month = User.select("count(*) as total").find(:first, :conditions => ["(Extract(month from created_at) = Extract(month from (CURRENT_DATE - INTERVAL '2 months'))) AND (Extract(year from created_at) = Extract(year from (CURRENT_DATE - INTERVAL '2 months')))"])

    #########
    @unique_logins_total = User.select("count(*) as total").find(:first, :conditions => ["sign_in_count > 0"])
    @unique_login_this_month = User.select("count(*) as total").find(:first, :conditions => ["sign_in_count > 0 and (Extract(month from last_sign_in_at) = Extract(month from NOW())) and (Extract(year from last_sign_in_at) = Extract(year from NOW()))"]) 
    @unique_login_last_month = User.select("count(*) as total").find(:first, :conditions => ["sign_in_count > 0 and (Extract(month from last_sign_in_at) = Extract(month from (CURRENT_DATE - INTERVAL '1 months'))) and (Extract(year from last_sign_in_at) = Extract(year from (CURRENT_DATE - INTERVAL '1 months')))"])
    @unique_login_last_2month = User.select("count(*) as total").find(:first, :conditions => ["sign_in_count > 0 and (Extract(month from last_sign_in_at) = Extract(month from (CURRENT_DATE - INTERVAL '2 months'))) and (Extract(year from last_sign_in_at) = Extract(year from (CURRENT_DATE - INTERVAL '2 months')))"])


    ########
    @youtube = MovieStream.select("count(*) as total").find(:first, :conditions => ["studio_user_id IS NULL"])
    @youtube_this_month = MovieStream.select("count(*) as total").find(:first, :conditions => ["studio_user_id IS NULL AND (Extract(month from created_at) = Extract(month from NOW())) and (Extract(year from created_at) = Extract(year from NOW()))"])
    @youtube_last_month = MovieStream.select("count(*) as total").find(:first, :conditions => ["studio_user_id IS NULL AND (Extract(month from created_at) = Extract(month from (CURRENT_DATE - INTERVAL '1 months'))) and (Extract(year from created_at) = Extract(year from (CURRENT_DATE - INTERVAL '1 months')))"])
    @youtube_last_2month = MovieStream.select("count(*) as total").find(:first, :conditions => ["studio_user_id IS NULL AND (Extract(month from created_at) = Extract(month from (CURRENT_DATE - INTERVAL '2 months'))) and (Extract(year from created_at) = Extract(year from (CURRENT_DATE - INTERVAL '2 months')))"])

    #######
    @cps = MovieStream.select("count(*) as total").find(:first, :conditions => ["studio_user_id IS NOT NULL"])
    @cps_this_month = MovieStream.select("count(*) as total").find(:first, :conditions => ["studio_user_id IS NOT NULL AND (Extract(month from created_at) = Extract(month from NOW())) and (Extract(year from created_at) = Extract(year from NOW()))"])
    @cps_last_month = MovieStream.select("count(*) as total").find(:first, :conditions => ["studio_user_id IS NOT NULL AND (Extract(month from created_at) = Extract(month from (CURRENT_DATE - INTERVAL '1 months'))) and (Extract(year from created_at) = Extract(year from (CURRENT_DATE - INTERVAL '1 months')))"])
    @cps_last_2month = MovieStream.select("count(*) as total").find(:first, :conditions => ["studio_user_id IS NOT NULL AND (Extract(month from created_at) = Extract(month from (CURRENT_DATE - INTERVAL '2 months'))) and (Extract(year from created_at) = Extract(year from (CURRENT_DATE - INTERVAL '2 months')))"])

    #######
    @youtube_view = 0
    @youtube_view_this_month = 0
    @youtube_view_last_month = 0
    @youtube_view_last_2month =0 

    @cp_youtube_view = 0
    @cp_youtube_view_this_month = 0
    @cp_youtube_view_last_month = 0
    @cp_youtube_view_last_2month =0

    @video_log = VideoLog.select("movie_id, lpad (cast((EXTRACT(MONTH from created_at)) as varchar), 2, '0'), EXTRACT(YEAR from created_at) as yr").find(:all, :conditions => ["user_id != 5"])
    @video_log.each do|log|
      @movie_stream = MovieStream.find(:first, :conditions => ["movie_id = #{log.movie_id}"])
      unless @movie_stream.blank?
        unless @movie_stream.studio_user_id.blank?
          @cp_youtube_view = @cp_youtube_view + 1
          if (log.lpad == Date.today.strftime("%m")) and (log.yr == Date.today.strftime("%Y"))
            @cp_youtube_view_this_month = @cp_youtube_view_this_month + 1
          elsif (log.lpad == (Date.today - 30).strftime("%m")) and (log.yr == Date.today.strftime("%Y"))
            @cp_youtube_view_last_month = @cp_youtube_view_last_month + 1
          elsif (log.lpad == (Date.today - 60).strftime("%m")) and (log.yr == Date.today.strftime("%Y"))
            @cp_youtube_view_last_2month = @cp_youtube_view_last_2month + 1
          end
        else
          @youtube_view = @youtube_view + 1
          if (log.lpad == Date.today.strftime("%m")) and (log.yr == Date.today.strftime("%Y"))
            @youtube_view_this_month = @youtube_view_this_month + 1
          elsif (log.lpad == (Date.today - 30).strftime("%m")) and (log.yr == Date.today.strftime("%Y"))
            @youtube_view_last_month = @youtube_view_last_month + 1
          elsif (log.lpad == (Date.today - 60).strftime("%m")) and (log.yr == Date.today.strftime("%Y"))
            @youtube_view_last_2month = @youtube_view_last_2month + 1
          end

        end
      end
    end

    #@movie_stream = MovieStream.select("movie_id, studio_user_id").find(:all)
    #@movie_stream.each do |stream|
    #  if stream.studio_user_id.blank?
    #    video_log = VideoLog.select("lpad (cast((EXTRACT(MONTH from created_at)) as varchar), 2, '0'), EXTRACT(YEAR from created_at) as yr").find(:first, :conditions => ["movie_id = #{stream.movie_id}"])
    #    unless video_log.blank?
    #      @youtube_view = @youtube_view + 1
    #      if (video_log.lpad == Date.today.strftime("%m")) and (video_log.yr == Date.today.strftime("%Y"))
    #        @youtube_view_this_month = @youtube_view_this_month + 1
    #      elsif (video_log.lpad == (Date.today - 30).strftime("%m")) and (video_log.yr == Date.today.strftime("%Y"))
    #        @youtube_view_last_month = @youtube_view_last_month + 1     
    #      elsif (video_log.lpad == (Date.today - 60).strftime("%m")) and (video_log.yr == Date.today.strftime("%Y"))
    #        @youtube_view_last_2month = @youtube_view_last_2month + 1
    #      end
    #    end        
    #  else
        ##############CP uploaded video log
    #    cp_video_log = VideoLog.select("lpad (cast((EXTRACT(MONTH from created_at)) as varchar), 2, '0'), EXTRACT(YEAR from created_at) as yr").find(:first, :conditions => ["movie_id = #{stream.movie_id}"])
    #    unless cp_video_log.blank?
    #      @cp_youtube_view = @cp_youtube_view + 1
    #      if (cp_video_log.lpad == Date.today.strftime("%m")) and (cp_video_log.yr == Date.today.strftime("%Y"))
    #        @cp_youtube_view_this_month = @cp_youtube_view_this_month + 1
    #      elsif (cp_video_log.lpad == (Date.today - 30).strftime("%m")) and (cp_video_log.yr == Date.today.strftime("%Y"))
    #        @cp_youtube_view_last_month = @cp_youtube_view_last_month + 1
    #      elsif (cp_video_log.lpad == (Date.today - 60).strftime("%m")) and (cp_video_log.yr == Date.today.strftime("%Y"))
    #        @cp_youtube_view_last_2month = @cp_youtube_view_last_2month + 1
    #      end
    #    end

    #  end
    #end



  end

end
