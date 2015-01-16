class MovieStream < ActiveRecord::Base
  $config = YAML.load_file(File.join(File.dirname(__FILE__), '../../config/database.yml'))
  self.establish_connection  $config["muvi_extract"]

  belongs_to :movie
  validates :movie_id, uniqueness: true
  #validates :pay_per_view, numericality: true
  #validates :pay_per_view, numericality: {:greater_than_or_equal_to => 0.50}
  #validates :movie_id, format: { with: /\A[0-9]+\z/,message: " name can't be blank"}
  #validates :time_limit_start, presence: true
  #validates :time_limit_end, presence: true
  # attr_accessible :title, :body
end
