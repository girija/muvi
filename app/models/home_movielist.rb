class HomeMovielist < ActiveRecord::Base
  set_table_name 'homepage_movielists'
  set_primary_key :id
  belongs_to :movie
end
