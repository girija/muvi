class TopBoxOffice < ActiveRecord::Base
  belongs_to :movie
  default_scope :order => 'position ASC'
end

