require 'open-uri'
class UserProfile < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :display_name,  :message => "Full name can't be blank"

  #has_attached_file :profile_image, :styles => { :thumb=> "100x100#", :small  => {:geometry => "150x150>", :processors => [:cropper]} }
  has_permalink [:display_name],:update => true
  has_attached_file :profile_image, :styles =>lambda { |attachment| attachment.instance.set_styles }, :processors => [:cropper],
              :storage => :s3,
              :s3_credentials => File.expand_path('config/s3.yml', Rails.root),
              :s3_permissions => 'public-read',
              :path => "public/system/:attachment/:id/:style/:basename.:extension"
  has_many :reviews,:dependent => :destroy, :class_name => 'Review',:foreign_key => "user_id",:primary_key => "user_id",:order=>"updated_at desc"

  has_many :liked_movies ,:dependent => :destroy, :class_name => 'Review',:foreign_key => "user_id",:primary_key => "user_id", :conditions => [ "rating > 3"],:order => "created_at desc",:order=>"updated_at desc"

  has_many :disliked_movies ,:dependent => :destroy, :class_name => 'Review',:foreign_key => "user_id",:primary_key => "user_id", :conditions => [ "rating < 3"],:order =>"created_at desc",:order=>"updated_at desc"

  has_many :not_want_to_sees , :conditions => [ "is_want_to_see = ?", 'false' ], :dependent => :destroy, :class_name => 'WantToSee',:foreign_key => "user_id",:primary_key => "user_id",:order=>"updated_at desc"

  has_many :want_to_sees , :conditions => [ "is_want_to_see = ?", 'true' ], :dependent => :destroy, :class_name => 'WantToSee',:foreign_key => "user_id",:primary_key => "user_id",:order=>"updated_at desc"


  has_many :unfan_celebs, :conditions => [ "is_fan = ?", 'false' ], :dependent => :destroy, :class_name => 'Fan',:foreign_key => "user_id",:primary_key => "user_id",:order=>"updated_at desc"

  has_many :fan_celebs, :conditions => [ "is_fan = ?", 'true' ], :dependent => :destroy, :class_name => 'Fan',:foreign_key => "user_id",:primary_key => "user_id",:order=>"updated_at desc"

  has_many :like_posters, :conditions => [ "vote_flag = ? and votable_type = 'Poster'", 'true' ], :dependent => :destroy, :class_name => 'Vote',:foreign_key => "voter_id",:primary_key => "user_id",:order=>"updated_at desc"

  has_many :like_videos, :conditions => [ "vote_flag = ? and votable_type = 'Video'", 'true' ], :dependent => :destroy, :class_name => 'Vote',:foreign_key => "voter_id",:primary_key => "user_id",:order=>"updated_at desc"
  has_many :top_tens,:foreign_key => "voter_id",:primary_key => "user_id"

  has_many :activities,:dependent => :destroy, :class_name => 'Activity',:foreign_key => "user_id",:primary_key => "user_id",:order=>"created_at desc"

  attr_accessor :profile_image_url
  attr_accessor :crop_x, :crop_y, :crop_w, :crop_h
  before_save :set_styles
  after_update :set_styles
  after_update :reprocess_profile_image, :if => :cropping?
  before_validation :download_remote_image, :if => :image_url_provided?
  
  def to_param
    permalink
  end
  
  def self.find_for_sitemap
    find(:all, :order => "id")
  end  
  def set_styles
    if !crop_x.blank? && !crop_y.blank? && !crop_w.blank? && !crop_h.blank?
      styles = { :thumb=> "100x100", :small  => "150x150"}
    else
      styles = {:thumb=> "100x100#", :small  => "150x150#"}
      #styles = {}
    end
    styles
  end

  def image_url_provided?
    !self.profile_image_url.blank?
  end

  def download_remote_image
    self.profile_image = do_download_remote_image
  end

  def do_download_remote_image
    io = open(URI.parse(profile_image_url))
    def io.original_filename; base_uri.path.split('/').last; end
    io.original_filename.blank? ? nil : io
  rescue # catch url errors with validations instead of exceptions (Errno::ENOENT, OpenURI::HTTPError, etc...)
  end
  
  def self.find_or_create_muvi_user_profile_facebook(usr_id)
    if (user_profile = UserProfile.find(:first,:conditions => ['user_id = ?',usr_id]))
       return user_profile
    else
      user_profile = UserProfile.new
      user_profile.user_id = usr_id
      if user_profile.save(false)
         return user_profile
      else
         return nil
      end
    end
  end

  def profile_image_geometry(style = :original)
    @geometry ||= {}
    #@geometry[style] ||= Paperclip::Geometry.from_file(profile_image.path(style))
    #@geometry[style] ||= Paperclip::Geometry.from_file(profile_image.to_file(style))
    @geometry[style] ||= Paperclip::Geometry.from_file(Paperclip.io_adapters.for(profile_image))
  end

  def cropping?
    !crop_x.blank? && !crop_y.blank? && !crop_w.blank? && !crop_h.blank?
  end

  def rename_file_db(id)
    user_profile = UserProfile.find_by_id(id)
    timestamp = DateTime.now.strftime("%Y%m%d%H%M%S")
    old_name = user_profile.profile_image_file_name
    user_profile.profile_image_file_name = "#{timestamp}_#{old_name}"
    user_profile.save
    system("sudo s3cmd mv 's3://muviassets/public/system/profile_images/#{user_profile.id}/original/#{old_name}' 's3://muviassets/public/system/profile_images/#{user_profile.id}/original/#{user_profile.profile_image_file_name}'")
    system("sudo s3cmd mv 's3://muviassets/public/system/profile_images/#{user_profile.id}/small/#{old_name}' 's3://muviassets/public/system/profile_images/#{user_profile.id}/small/#{user_profile.profile_image_file_name}'")
    system("sudo s3cmd mv 's3://muviassets/public/system/profile_images/#{user_profile.id}/thumb/#{old_name}' 's3://muviassets/public/system/profile_images/#{user_profile.id}/thumb/#{user_profile.profile_image_file_name}'")
    system("s3cmd setacl --acl-public s3://muviassets/public/system/profile_images/#{user_profile.id}/original/#{user_profile.profile_image_file_name}")
    system("s3cmd setacl --acl-public s3://muviassets/public/system/profile_images/#{user_profile.id}/small/#{user_profile.profile_image_file_name}")
    system("s3cmd setacl --acl-public s3://muviassets/public/system/profile_images/#{user_profile.id}/thumb/#{user_profile.profile_image_file_name}")
  end

  def delete_tmp_files(id)
    user_profile = UserProfile.find_by_id(id)
    system("s3cmd del s3://muviassets/public/system/profile_images/#{user_profile.id}/tmp_small/#{user_profile.profile_image_file_name}")
    system("s3cmd del s3://muviassets/public/system/profile_images/#{user_profile.id}/tmp_thumb/#{user_profile.profile_image_file_name}")
  end
  private
  def reprocess_profile_image
    #system("s3cmd del s3://muviassets/public/system/profile_images/#{self.id}/small/*")
    #system("s3cmd del s3://muviassets/public/system/profile_images/#{self.id}/thumb/*")
    profile_image.reprocess!
    #delete_tmp_files(self.id)
  end

end

