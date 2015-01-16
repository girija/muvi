class CriticsReview < ActiveRecord::Base
  belongs_to :movie, :counter_cache => true
  belongs_to :film_critic
  after_save :update_muvimeter
  before_destroy :update_muvimeter
  acts_as_commentable
  acts_as_votable

  set_primary_key "id"

  def update_muvimeter
    Movie.delay.update_one_movie_percentage(self.movie)
  end
  #in latest copy remove the film_critic_name, movie_name column
  has_many :like_votes, :conditions => [ "vote_flag = ?", 'true' ], :dependent => :destroy, :class_name => 'Vote',:foreign_key => "votable_id"
  has_many :dislike_votes, :conditions => [ "vote_flag = ?", 'false' ], :dependent => :destroy, :class_name => 'Vote',:foreign_key => "votable_id"
  
  scope :latest, where("created_at IS NOT NULL").order('review_date desc nulls last')
  scope :draft, where("state = ?", 'draft')
  scope :published, where("state = ?", 'publish')
  scope :find_user_id, lambda {|user_id| where("user_id = ?", user_id) }
  scope :find_film_critic_id, lambda {|fc_id| where("film_critic_id = ?", fc_id) }
  scope :todays, where(:created_at => (Date.today.beginning_of_day)..Date.today.end_of_day)
  scope :positive_rating, where("rating >= 3")
  scope :negative_rating, where("rating < ?", 3)
  def critic_image
    #(self.rating.to_f >= 3)? '/images/thumbUp.png' : '/images/thumbDown.png'
    (self.rating.to_f >= 3)? '/images/good.png' : '/images/bad.png'
  end


end

