class TeluguStar < ActiveRecord::Base
  require 'open-uri'
  require 'nokogiri'

  set_table_name 'telugu_star_data'

  def self.add_posters_to_stars
    ctr = 1
    celebs = Celebrity.where("id > 14403").order('id asc')
    celebs.each do |celeb|
      telugu_star = TeluguStar.where("name = ?",celeb.name).first
      if telugu_star
        if telugu_star.poster_path
          puts "#{ctr} | #{celeb.id}  | #{celeb.name} | #{telugu_star.poster_path}"
          @poster = Poster.new(:poster_remote_url => telugu_star.poster_path, :name => celeb.name, :rank => 1)
          @poster.save
          tagname = Tag.where("lower(name) = ?", celeb.name.downcase)
          if tagname.blank?
            @tag = Tag.new
            @tag.id = Tag.last.id + 1
            @tag.name =  celeb.name

            @tag.save

            @tag_id = @tag.id
          else
            @tag_id = tagname[0].id
          end
          @tagging = Tagging.new(:tag_id => @tag_id, :taggable_id => @poster.id, :taggable_type => 'Poster', :tagger_id => celeb.id,:tagger_type => 'Celebrity', :context =>'tags')
          @tagging.save
          @tagging = Tagging.new(:tag_id => 343, :taggable_id => @poster.id, :taggable_type => 'Poster', :tagger_type => 'profilepic', :context =>'tags')
          @tagging.save
          ctr += 1
          telugu_star.import_status = true
          telugu_star.save
        end
      end
      puts "#{celeb.id} | #{celeb.name}"
    end
  end

end
