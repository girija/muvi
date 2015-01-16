class Tagging < ActiveRecord::Base
  #include ActsAsTaggable::Tagging

  belongs_to :feed
  belongs_to :video
  belongs_to :discussion, :foreign_key => "taggable_id"
  #default_scope :order => 'created_at DESC'

end

