class Video < ActiveRecord::Base
  require 'youtube_utils'
   
  $config = YAML.load_file(File.join(File.dirname(__FILE__), '../../config/database.yml'))
  self.establish_connection  $config["muvi_extract"]
  scope :todays_trailer, where(:trailer_updated_at => (Date.today.beginning_of_day)..Date.today.end_of_day)
  scope :all_latest_trailer, where(:created_at => (Date.today - 2.days)..(Date.today))
  scope :diff_score_nonzero, where("diff_score > 0")
  scope :five_days_video, where("created_at > '#{(Date.today - 4.days)}'")

  belongs_to :movie
  #has_attached_file :trailer,:processors => [:video_thumbnail]
  has_attached_file :trailer,
              :storage => :s3,
              :s3_credentials => File.expand_path('config/s3.yml', Rails.root),
              :s3_permissions => 'public-read',
              :path => "/public/system/:attachment/:id/:style/:basename.:extension"

  acts_as_commentable
  acts_as_taggable
  acts_as_taggable_on :videos
  acts_as_votable
 
  validates_presence_of :video_remote_url, :if => :video_url_provided?, :message => 'is invalid or inaccessible'
  validates_presence_of :trailer_file_name, :unless => :video_remote_url?
  has_many :activities , :conditions => [ "secondary_subject_type = ?", 'Video' ], :dependent => :destroy,:foreign_key => "secondary_subject_id"
  has_many :like_votes, :conditions => [ "vote_flag = ?", 'true' ], :dependent => :destroy, :class_name => 'Vote',:foreign_key => "votable_id"
  has_many :dislike_votes, :conditions => [ "vote_flag = ?", 'false' ], :dependent => :destroy, :class_name => 'Vote',:foreign_key => "votable_id"
  #after_create :download_youtube
  after_save :download_youtube

  def self.latest_trailer
    latest_trailer = []
    Video.all_latest_trailer.each do |trailer|
      tag = Tagging.where("taggable_type = 'Video' AND taggable_id = #{trailer.id} AND tagger_type = 'trailer'").first
      if !tag.nil?
        latest_trailer << trailer
      end
    end
    return latest_trailer
  end

  def self.movie_trailer(movie_id)
      videos = ""
      videoids = ""
      trailer = ""
      video_id = ""

      tagging = Tagging.find(:all, :conditions => ["tagger_id = ?  and taggable_type = 'Video' and tagger_type = 'Movie'",movie_id], :select => "taggable_id")
      unless tagging.blank?
        tagging.each do |t|
          unless t.taggable_id.blank?
            if video_id.blank?
              video_id = t.taggable_id
            else
              video_id = video_id.to_s + "," + t.taggable_id.to_s
            end
          end
        end
      end
      video = Tagging.where("taggable_id IN (#{video_id})").find(:all, :conditions => ["lower(tagger_type) = 'trailer'"], :select => "taggable_id", :order => ["id desc"]) unless video_id.blank?
      unless video.blank?
        videoids = ""
        video.each do |v|
          if videoids.blank?
            videoids = v.taggable_id
          else
            videoids = videoids.to_s + "," + v.taggable_id.to_s
          end
        end
        videos = Video.where("id IN (#{videoids})").find(:all,:conditions => ["rank = 1"]).last
      end
      unless videos.blank?
        trailer = videos
      else
        trailer = ""
      end
      return trailer
  end


  def self.get_video(tagger_id, tagger_type, taggable_type)
    @video = []
    Tagging.where("taggable_type = '#{taggable_type}' and tagger_id = '#{tagger_id}' and tagger_type = '#{tagger_type}'").find(:all).each do |tag|
      video = Video.find_by_id(tag.taggable_id, :conditions => ["rank != 0 and (trailer_file_name IS NOT NULL or video_remote_url IS NOT NULL)"])
      @video << video unless video.blank?
    end 
    unless @video.blank?
      @video.sort!{|a,b| (a.rank) <=> (b.rank)}
    end
    @video = @video.uniq
    return @video
  end

  def self.check_vote(video_id, user_id)
    @vote = Vote.where("votable_id = #{video_id} and voter_id = #{user_id} and votable_type = 'Video' and voter_type = 'User'").find(:all, :select => ["vote_flag"]).first
    unless @vote.blank?
      return @vote.vote_flag    
    else
      return ""
    end
  end

  def self.create_thumnail_test(id, oiginal_filename)
    Paperclip.run('ffmpeg', '-itsoffset -4 -i "http://dfquahprf1i3f.cloudfront.net/public/system/trailers/101/original/Ghayal%20Returns.flv" -y -vcodec mjpeg -vframes 1 -an -f rawvideo -s 120x90 "g.jpg"')
  end

  def self.create_thumbnail(id, original_filename)
    #@file_path = "public/system/trailers/#{id}/original/#{original_filename}"
    #@destination_path = "public/system/trailer_thumbnails/#{id}"
    #Dir.mkdir( "#{@destination_path}")
    #command = <<-end_command
    #  -itsoffset -4 -i "#{@file_path}" -y -vcodec mjpeg -vframes 1 -an -f rawvideo -s 120x90 "#{@destination_path}/1.jpg"
    #end_command
    #command.gsub!(/\s+/, " ")
    #  success = Paperclip.run('ffmpeg', command)

    #### New S3 starts
    #@file_path = "public/system/trailers/#{id}/original/#{original_filename}"
    #@destination_path = "tmp/#{id}"
    #Dir.mkdir( "#{@destination_path}")
    #command = <<-end_command
    #  -itsoffset -4 -i "#{@file_path}" -y -vcodec mjpeg -vframes 1 -an -f rawvideo -s 120x90 "#{@destination_path}/1.jpg"
    #end_command
    #command.gsub!(/\s+/, " ")
    #  success = Paperclip.run('ffmpeg', command)
    #if system ("s3cmd put --acl-public #{@destination_path}/1.jpg s3://#{BUCKET}/public/system/trailer_thumbnails/#{id}/1.jpg")
    #  system("rm -rf #{@dir}")
    #end

    #### New S3 ends

    ### FOR S3
    @dir = "tmp/#{id}"
    @file_path = "#{@dir}/#{original_filename}"
    Dir.mkdir( "#{@dir}")

    system ("s3cmd get s3://#{BUCKET}/public/system/trailers/#{id}/original/#{original_filename} tmp/#{id}/#{original_filename}")

    @destination_path = @dir

    command = <<-end_command
      -itsoffset -4 -i "#{@file_path}" -y -vcodec mjpeg -vframes 1 -an -f rawvideo -s 120x90 "#{@destination_path}/1.jpg"
    end_command
    command.gsub!(/\s+/, " ")
      success = Paperclip.run('ffmpeg', command)

    if system ("s3cmd put --acl-public #{@destination_path}/1.jpg s3://#{BUCKET}/public/system/trailer_thumbnails/#{id}/1.jpg")
      system("rm -rf #{@dir}")
    end
    ### Old S3 code ends

  end

  def self.log_video_activity(current_user,video, action, object, path)
     @activity = Activity.new
     @user = UserProfile.find_by_user_id(current_user.id)
     @activity.user_id = current_user.id
     @activity.secondary_subject_type = "Video"
     @activity.subject_type = action
     @activity.secondary_subject_id = video.id
     unless @user.blank?
       @activity.action = "#{@user.display_name} #{action.downcase} <a href='/#{path}/#{object.permalink}/videos/#{video.id}#video'>#{video.name}.</a>"
     else
       @activity.action = "#{action.downcase} <a href='/#{path}/#{object.permalink}/videos/#{video.id}#video'>#{video.name}.</a>"
     end
     @activity.save!
  end
  def self.post_to_wall(current_user, video, action, object, path)
    if current_user.user_profile &&  current_user.user_profile.post_to_social_media && current_user.facebook_omniauth
      begin
        client = Koala::Facebook::GraphAPI.new(current_user.facebook_token)
        begin
         client.delay.put_wall_post("",{:name => "#{current_user.display_name} #{action.downcase}  #{video.name}.",:link => "#{SITE_URL}/#{path}/#{object.permalink}/video/#{video.id}",:description => "Want to watch the video?", :picture => "#{SITE_URL}/system/trailer_thumbnails/#{video.id}/1.jpg"},profile_id="#{current_user.facebook_id}")
        rescue
        end
      rescue Koala::Facebook::OAuthException
          # getting this strange exception. (#506) Duplicate status message
          #TODO handle this exception
      end
    end
  end

  def self.save_comment(current_user, video, comment)
    @comment = video.comments.new({:comment =>  comment,:user_id => current_user})
    @comment.save
    return @comment
  end
  def self.get_top_score_record(datas)
    top_datas = []
    top_score = 1 
    datas.each do |data|
      if data.score && data.score >= top_score
        top_datas << data
      end
    end
    return top_datas
  end
  def self.create_thumbnail_remote(id,s3_path)
    @dir = "tmp/#{id}"
    puts id
    original_filename = s3_path.split("/").last
    @file_path = "#{@dir}/#{original_filename}"
    Dir.mkdir( "#{@dir}")
    system ("s3cmd get #{s3_path} #{@dir}/#{original_filename}")
    @destination_path = @dir

    command = <<-end_command
      -itsoffset -4 -i "#{@file_path}" -y -vcodec mjpeg -vframes 1 -an -f rawvideo -s 120x90 "#{@destination_path}/1.jpg"
    end_command
    command.gsub!(/\s+/, " ")
      success = Paperclip.run('ffmpeg', command)
    if system ("s3cmd put --acl-public #{@destination_path}/1.jpg s3://#{BUCKET}/public/system/trailer_thumbnails/#{id}/1.jpg")
      system("rm -rf #{@dir}")
    else
      puts "no thumbnail generated"
    end
  end

  def self.download_all_youtube
    all_videos = Video.where("video_remote_url like '%youtu%'").order("id desc").limit(500)
    all_videos.each do |video|
      id = video.id
      video_id =  Video.get_video_id(video.video_remote_url)
      unless video_id.blank?
        begin
          urls = YoutubeUtils.new.get_videos "http://www.youtube.com/watch?v=#{video_id}"
          urls.each do |url|
            if url["quality"] == "360p" and url["type"]["video/mp4"]  == "video/mp4"
              @video_url = url["url"]
            end
          end
          thumbnail_url = "http://img.youtube.com/vi/#{video_id}/1.jpg"
          Dir.mkdir( "tmp/#{id}")
          system("wget '#{@video_url}' -O tmp/#{id}/#{video_id}.mp4")
          system ("s3cmd put --acl-public tmp/#{id}/#{video_id}.mp4  s3://#{BUCKET}/public/system/trailers/#{id}/original/#{video_id}.mp4")
          puts "#{video_id} video uploaded"
          system("wget '#{thumbnail_url}' -O tmp/#{id}/1.jpg")
          if system ("s3cmd put --acl-public tmp/#{id}/1.jpg  s3://#{BUCKET}/public/system/trailer_thumbnails/#{id}/1.jpg")
            system("rm -rf tmp/#{id}")
          end
          puts "#{video_id} image uploaded"

          video.trailer_file_name = "#{video_id}.mp4"
          video.trailer_content_type = "video/mp4"
          video.video_remote_url = ""
          video.save
        rescue
           puts "http://www.youtube.com/watch?v=#{video_id} NOT FOUND"
        end
      end
    end
  end

  def self.get_video_id(source_url)
      video_regexp = /(youtu\.be\/|youtube\.com\/(watch\?(.*&)?v=|(embed|v)\/))([^\?&"'>]+)/
      video_regexp.match(source_url)[5]
  end

  private

    def video_url_provided?
      !self.video_remote_url.blank?
      if !self.video_remote_url.blank?
        url = self.video_remote_url
        unless url["youtu"] == 'youtu'
          download_remote_video(url)
        end
      end
    end
    def download_remote_video(source_url)
        io = open(URI.parse(source_url).to_s)
        def io.original_filename; base_uri.path.split('/').last; end
        self.trailer = io.original_filename.blank? ? nil : io
        io.close
    end

    def download_youtube
      unless self.video_remote_url.blank?
        id = self.id
        video_id = video_id(self.video_remote_url)
        unless video_id.blank?
          puts video_id
          @urls = YoutubeUtils.new.get_videos "https://www.youtube.com/watch?v=#{video_id}"
          #@urls = YoutubeUtils.new.get_videos self.video_remote_url
          @urls.each do |url|
            if url["quality"] == "360p" and url["type"]["video/mp4"]  == "video/mp4"
               @video_url = url["url"]
               puts @video_url
            end
          end
          #thumbnail_url = "https://img.youtube.com/vi/#{video_id}/1.jpg"
          begin
            Dir.mkdir( "tmp/#{id}")
          rescue
          end

          system("wget '#{@video_url}' -O tmp/#{id}/#{video_id}.mp4")
          system ("s3cmd put --acl-public tmp/#{id}/#{video_id}.mp4  s3://#{BUCKET}/public/system/trailers/#{id}/original/#{video_id}.mp4")
          puts "video completed"
          #system("wget '#{thumbnail_url}' -O tmp/#{id}/1.jpg")
          #if system ("s3cmd put --acl-public tmp/#{id}/1.jpg  s3://#{BUCKET}/public/system/trailer_thumbnails/#{id}/1.jpg")
          system("rm -rf tmp/#{id}")
          #end


          self.trailer_file_name = "#{video_id}.mp4"
          self.trailer_content_type = "video/mp4"
          self.video_remote_url = ""
          self.save
        end
      end
    end

    def video_id(source_url)
      video_regexp = /(youtu\.be\/|youtube\.com\/(watch\?(.*&)?v=|(embed|v)\/))([^\?&"'>]+)/
      video_regexp.match(source_url)[5]
    end

  def self.bharat_movies
    urls = ["hindi", "telugu","tamil"]

    urls.each do |url|
      page_arr = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
      div_ids = [1,2]
      page_arr.each do|p|
        div_ids.each do |num|
          if p != "a"
            html  = Nokogiri::HTML(open("http://www.bharatmovies.com/#{url}/movies/list-#{p}.htm"))
          else
            html  = Nokogiri::HTML(open("http://www.bharatmovies.com/#{url}/movies/list.htm"))
          end
          content = html.xpath(".//*[@id='cmain']/div[@id='L#{num}']/a")
          unless content.nil?
            content.each do |movie_link|
              #movie name
              movie_name = movie_link.text()
              movie_page_url = movie_link.xpath('./@href').to_s
              m_html  = Nokogiri::HTML(open("http://www.bharatmovies.com/#{url}/movies/#{movie_page_url}"))
              m_content = m_html.xpath(".//*[@id='vidcontainer']/embed")
              embed_link = m_content.xpath('./@src').to_s
              embed_link_arr = (embed_link.split("&")[0]).split("/")
              youtube_link = "http://youtu.be/"+embed_link_arr[embed_link_arr.size.to_i - 1]
              puts movie_name + "___"+ youtube_link
              file = CSV.generate do |csv|
                  csv << [
                    movie_name,
                    youtube_link
                  ]
              end
              File.open("bharat_movies_#{url}.csv", 'a') do |f|
                f.write(file)
              end
              #############
            end
          end
        end
      end
    end
  end

end
