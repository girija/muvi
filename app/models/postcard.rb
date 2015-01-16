class Postcard < ActiveRecord::Base
  belongs_to :user
  belongs_to :poster
  set_table_name 'post_card'
  
end
