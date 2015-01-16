class Poster < ActiveRecord::Base
  $config = YAML.load_file(File.join(File.dirname(__FILE__), '../../config/database.yml'))
  self.establish_connection  $config["muvi_extract"]
  #belongs_to :movie
  acts_as_commentable
  acts_as_taggable
  acts_as_taggable_on :poster
  acts_as_votable

  scope :all_latest_poster, where(:created_at => (Date.today - 1.days)..(Date.today + 1.days))
  scope :diff_score_nonzero, where("diff_score > 0")
  scope :three_days_poster, where("created_at > '#{(Date.today - 2.days)}'")


  #has_attached_file :poster, :styles => { :thumb=> "35x35#", :medium  => "130x200#", :standard => "185x"},
  #            :url => "/system/:attachment/:id/:style/:filename",
  #            :storage => :s3,
  #            :s3_credentials => File.expand_path('config/s3.yml', Rails.root),
  #            :s3_permissions => 'public-read',
  #            :path => "public/system/:attachment/:id/:style/:basename.:extension",
  #            :convert_options => { :all => '-limit memory 64mb -limit map 128mb' }


  has_attached_file :poster,
              :styles => lambda { |attachment| attachment.instance.set_styles }, :processors => [:cropper],
              :storage => :s3,
              :s3_credentials => File.expand_path('config/s3.yml', Rails.root),
              :s3_permissions => 'public-read',
              :path => "public/system/:attachment/:id/:style/:basename.:extension",
              :convert_options => { :all => '-limit memory 64mb -limit map 128mb' }



  validates_presence_of :poster_remote_url, :if => :poster_url_provided?, :message => 'is invalid or inaccessible'
  validates_presence_of :poster_file_name, :unless => :poster_url_provided?
  has_many :activities , :conditions => [ "secondary_subject_type = ?", 'Poster' ], :dependent => :destroy,:foreign_key => "secondary_subject_id"
  has_many :like_votes, :conditions => [ "vote_flag = ?", 'true' ], :dependent => :destroy, :class_name => 'Vote',:foreign_key => "votable_id"
  has_many :dislike_votes, :conditions => [ "vote_flag = ?", 'false' ], :dependent => :destroy, :class_name => 'Vote',:foreign_key => "votable_id"


  attr_accessor :crop_x, :crop_y, :crop_w, :crop_h
  before_save :set_styles
  after_update :set_styles 
  #after_update :reprocess_poster, :if => :cropping?


  def set_styles
    #if :cropping?
    if !crop_x.blank? && !crop_y.blank? && !crop_w.blank? && !crop_h.blank?
      styles = { :crop_thumb=> "77x76", :crop_medium  => "188x285", :crop_standard => "210x235", :crop_original => "#{crop_w}x#{crop_h}>"}
    else
      styles = {:thumb=> "35x35#", :medium  => "130x200#", :standard => "185x"}
    end
    styles

  end

  def rename_poster
    extension = File.extname(poster_file_name).downcase
    new_name = self.name.gsub(" ", "-").downcase
    self.poster_file_name = "#{new_name}#{extension}"
    self.poster.instance_write :file_name, "#{new_name}#{extension}"
  end

  def self.rename_existing_poster    
    poster = Poster.find(:all, :conditions => ["date(created_at) = '#{Date.today.strftime("%Y-%m-%d")}'"], :order => ["id asc"])
    poster.each do |p|
      new_name = "#{p.name.gsub(" ", "-").downcase}#{File.extname(p.poster_file_name).downcase}"

      #if p.update_attribute("poster_file_name", "#{new_name}")
        #if p.poster_file_name != new_name
          begin
            system("sudo s3cmd mv 's3://muviassets/public/system/posters/#{p.id}/original/#{p.poster_file_name}' 's3://muviassets/public/system/posters/#{p.id}/original/#{new_name}'") 
            system("sudo s3cmd mv 's3://muviassets/public/system/posters/#{p.id}/medium/#{p.poster_file_name}' 's3://muviassets/public/system/posters/#{p.id}/medium/#{new_name}'")
            system("sudo s3cmd mv 's3://muviassets/public/system/posters/#{p.id}/thumb/#{p.poster_file_name}' 's3://muviassets/public/system/posters/#{p.id}/thumb/#{new_name}'")
            system("sudo s3cmd mv 's3://muviassets/public/system/posters/#{p.id}/standard/#{p.poster_file_name}' 's3://muviassets/public/system/posters/#{p.id}/standard/#{new_name}'") 
            system("sudo s3cmd mv 's3://muviassets/public/system/posters/#{p.id}/crop_original/#{p.poster_file_name}' 's3://muviassets/public/system/posters/#{p.id}/crop_original/#{new_name}'")
            system("sudo s3cmd mv 's3://muviassets/public/system/posters/#{p.id}/crop_medium/#{p.poster_file_name}' 's3://muviassets/public/system/posters/#{p.id}/crop_medium/#{new_name}'") 
            system("sudo s3cmd mv 's3://muviassets/public/system/posters/#{p.id}/crop_thumb/#{p.poster_file_name}' 's3://muviassets/public/system/posters/#{p.id}/crop_thumb/#{new_name}'")
            system("sudo s3cmd mv 's3://muviassets/public/system/posters/#{p.id}/crop_standard/#{p.poster_file_name}' 's3://muviassets/public/system/posters/#{p.id}/crop_standard/#{new_name}'")

            system("s3cmd setacl --acl-public s3://muviassets/public/system/posters/#{p.id}/original/#{new_name}")
            system("s3cmd setacl --acl-public s3://muviassets/public/system/posters/#{p.id}/medium/#{new_name}")
            system("s3cmd setacl --acl-public s3://muviassets/public/system/posters/#{p.id}/thumb/#{new_name}")
            system("s3cmd setacl --acl-public s3://muviassets/public/system/posters/#{p.id}/standard/#{new_name}") 
            system("s3cmd setacl --acl-public s3://muviassets/public/system/posters/#{p.id}/crop_original/#{new_name}")
            system("s3cmd setacl --acl-public s3://muviassets/public/system/posters/#{p.id}/crop_medium/#{new_name}")
            system("s3cmd setacl --acl-public s3://muviassets/public/system/posters/#{p.id}/crop_thumb/#{new_name}")
            system("s3cmd setacl --acl-public s3://muviassets/public/system/posters/#{p.id}/crop_standard/#{new_name}")

            p.update_attribute("poster_file_name", "#{new_name}")
          rescue Exception  => exc
            puts exc.message
          end
        #end
      #end
    end
  end

  def self.crop_existing
    #poster = Poster.find(110)    
    @p = Poster.where("id < 69020").find(:all, :order => ["id desc"])
    @p.each do |poster|
      puts poster.id
      puts poster.poster_file_name
      begin
        width = poster.poster_geometry(:original).width
        height = poster.poster_geometry(:original).height
        square_size = ""

        if width < height
          square_size = width

        elsif width > height
          square_size = height

        elsif width == height
          square_size = width
        end

        poster.crop_x = 0
        poster.crop_y = 0
        poster.crop_w = square_size
        poster.crop_h = square_size

        puts "#######"
        puts poster.id
        poster.update_attributes(poster)
      
      rescue Exception => exc
        puts exc.message
      end
    end
  end

  def poster_geometry(style = :original)
    @geometry ||= {}
    #@geometry[style] ||= Paperclip::Geometry.from_file(poster.to_file(style))
    @geometry[style] ||= Paperclip::Geometry.from_file(Paperclip.io_adapters.for(poster))
  end

  def cropping?
    !crop_x.blank? && !crop_y.blank? && !crop_w.blank? && !crop_h.blank?
  end

  def self.check_tagging(item,tagger_type)
    tagg = Tagging.where("taggable_id = #{item.id} AND taggable_type = '#{item.class.to_s}' AND tagger_type = '#{tagger_type}'")
    if !tagg.blank?
      return true
    else
      return false
    end
  end
  
  def self.latest_poster
    latest_poster = []
    Poster.all_latest_poster.each do |poster|
      tag = Tagging.where("taggable_type = 'Poster' AND taggable_id = #{poster.id} AND tagger_type = 'poster'").first
      if !tag.nil?
        latest_poster << poster
      end
    end
    return latest_poster
  end

  def self.get_poster(tagger_id, tagger_type, taggable_type)
    @poster = []
    Tagging.where("taggable_type = '#{taggable_type}' and tagger_id = '#{tagger_id}' and tagger_type = '#{tagger_type}'").find(:all).each do |tag|
      poster = Poster.find_by_id(tag.taggable_id, :conditions => ["rank != 0 and poster_file_name IS NOT NULL"])
      @poster << poster unless poster.blank?
    end
    unless @poster.blank?
      @poster.sort!{|a,b| (a.rank) <=> (b.rank)}
    end
    return @poster
  end

  def self.check_for_default_poster(tagger_id, tagger_type, taggable_type, context)
    id = ""
    poster = Tagging.where("t2.taggable_type = '#{taggable_type}' and t2.tagger_id='#{tagger_id}' and t2.tagger_type='#{tagger_type}'").find(:all, :select => ["t2.taggable_id"], :joins => ["inner join taggings t2 on taggings.taggable_id = t2.taggable_id"], :conditions => ["lower(taggings.tagger_type)='#{context}'"], :group => ["t2.taggable_id"])
    unless poster.blank?
      poster.each do |pos|
        if id.blank?
          id = pos.taggable_id
        else
          id = id.to_s + "," + pos.taggable_id.to_s
        end
      end
    end
    unless id.blank?
      return id
    else
      return false
    end
  end
  def self.log_poster_activity(current_user,poster, action, object, path)
     @activity = Activity.new
     @user = UserProfile.find_by_user_id(current_user.id)
     @activity.user_id = current_user.id
     @activity.secondary_subject_type = "Poster"
     @activity.subject_type = action
     @activity.secondary_subject_id = poster.id
     unless @user.blank?
       @activity.action = "#{@user.display_name} #{action.downcase} <a href='/#{path}/#{object.permalink}/posters/#{poster.id}#poster'>#{poster.name}.</a>"
     else
       @activity.action = "#{action.downcase} <a href='/#{path}/#{object.permalink}/poster/#{video.id}#poster'>#{poster.name}.</a>"
     end
     @activity.save!
  end
  def self.post_to_wall(current_user, poster, action, object, path)
    if current_user.user_profile &&  current_user.user_profile.post_to_social_media && current_user.facebook_omniauth
      begin
        client = Koala::Facebook::GraphAPI.new(current_user.facebook_token)
        begin
         client.delay.put_wall_post("",{:name => "#{current_user.display_name} #{action.downcase}  #{poster.name}.",:link => "#{SITE_URL}/#{path}/#{object.permalink}/poster/#{poster.id}",:description => "Want to watch the poster?", :picture => "#{SITE_URL}/system/posters/#{poster.id}/medium/#{poster.poster_file_name.gsub(" ", "%20")}"},profile_id="#{current_user.facebook_id}")
        rescue
        end
      rescue Koala::Facebook::OAuthException
          # getting this strange exception. (#506) Duplicate status message
          #TODO handle this exception
      end
    end
  end

  def self.save_comment(current_user, poster, comment)
    @comment = poster.comments.new({:comment => comment ,:user_id => current_user})
    @comment.save
    return @comment
  end

  def self.save_vote(current_user, poster)
    poster.vote :voter =>User.find_by_id(current_user.id), :vote => 'like'
  end
  private

    def poster_url_provided?
      !self.poster_remote_url.blank?
      if !self.poster_remote_url.blank?
        url = self.poster_remote_url
        #self.poster = open(url)
        download_remote_image(url)
      end
    end

    def download_remote_image(source_url)
      begin
        io = open(URI.parse(source_url).to_s)
        def io.original_filename; base_uri.path.split('/').last; end
        self.poster = io.original_filename.blank? ? nil : io
        self.poster_remote_url = source_url
        io.close
      rescue
      end
    end
  def self.reprocess
    #@poster = Poster.find(:all, :order => ["id asc"])
    @poster = Poster.find(:all, :conditions => ["id >= 78133"], :order => ["id desc"])
    @poster.each do |poster|
      unless poster.poster_file_name.blank?
        begin
          url = URI.parse(POSTER_URL + "/system/posters/#{poster.id}/standard/#{poster.poster_file_name.gsub(" ", "%20")}")
          req = Net::HTTP::Get.new(url.path)
          result = Net::HTTP.start(url.host, url.port) { |http| http.get(url.path) }
          if result.code == "200"

          else
            puts "____________________"
            puts poster.id.to_s+"/thumb/"+poster.poster_file_name.to_s
            if Poster.find(:all,:conditions => ["id = #{poster.id}"]).each {|p| p.poster.reprocess!}
              puts "Success"
            end
          end
        rescue
        end
      end
    end
  end

  def reprocess_poster
    poster.reprocess!
  end

 
  def self.tag_old_movie
    movie = Movie.find(:all, :conditions => ["poster_file_name IS NOT NULL"])
    #movie = Movie.find(:all, :conditions => ["id=9169"])
    unless movie.blank?
      movie.each do |m|
        tagging = Tagging.find(:all, :conditions => ["tagger_id=#{m.id} and taggable_type='Poster' and tagger_type='Movie'"])
	if tagging.blank?
	  tag = Tag.find_by_name(m.name)
	  unless tag.blank?
            tg = tag.id
          else
            t1 = Tag.new
            t1.name = m.name
            t1.save
            tg = t1.id
          end

          if !tg.blank?
            poster = Poster.new
            poster.poster_file_name = m.poster_file_name
            poster.poster_content_type = m.poster_content_type
            poster.poster_file_size = m.poster_file_size
            poster.name = m.name
            poster.rank = 1
            poster.save

	    t = Tagging.new	
            t.tag_id = tg
            t.taggable_id = poster.id
            t.taggable_type = 'Poster'
            t.tagger_id = ""
            t.tagger_type = 'poster'
            t.context = "tags"	
            t.save

            t1 = Tagging.new
            t1.tag_id = tg
            t1.taggable_id = poster.id
            t1.taggable_type = 'Poster'
            t1.tagger_id = m.id
            t1.tagger_type = 'Movie'
            t1.context = "tags"
            t1.save

            if system ("sudo s3cmd get s3://#{BUCKET}/public/system/posters/#{m.id}/original/#{m.poster_file_name} old_poster/#{poster.id}/#{m.poster_file_name}")

              if system ("sudo s3cmd put --acl-public old_poster/#{poster.id}/#{m.poster_file_name} s3://#{BUCKET}/public/system/posters/#{poster.id}/original/#{m.poster_file_name}")
                system("sudo rm -rf old_poster/#{poster.id}")
              end
            end

	  end
          
          
	end
      end
    end
  end

end

