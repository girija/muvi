class FilmCritic < ActiveRecord::Base
  has_many :critics_reviews
  belongs_to :user

  #has_attached_file :thumbnail_image, :styles => { :thumb=> "45x45#", :small  => "150x150#" }

  has_attached_file :thumbnail_image, :styles => { :thumb=> "45x45#", :small  => "150x150#"},
              :url => "/system/:attachment/:id/:style/:filename",
              :storage => :s3,
              :s3_credentials => File.expand_path('config/s3.yml', Rails.root),
              :s3_permissions => 'public-read',
              :path => "public/system/:attachment/:id/:style/:basename.:extension"


  scope :order_by_name, order('name asc nulls last')

  def self.option_list
    l ||= self.order_by_name.all.collect{|fc| [fc.name, fc.id] }
  end

  def profile_image
    return (self.thumbnail_image.url(:thumb).to_s rescue '/images/no-logo.png')
  end

end

