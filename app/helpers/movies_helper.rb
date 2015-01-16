module MoviesHelper

  def no_of_pepople_liked(movie)
    if current_user
      unless movie.fb_friends_liked(current_user).to_i == 0
        value = '<h4>'
        value += link_to(movie.fb_friends_liked(current_user).to_s + ' friends liked it!', path_for_movie(movie))
        value += '<span> <img alt="Bthumbicon" src="/images/BthumbIcon.jpg"> </span></h4>'
        return value.html_safe
      end
    else
      ''
    end
  end

  def option_for_genre
    [['Drama', 'drama'], ['Romance', 'romance'], ['Comedy', 'comedy'], ['Action', 'action'], ['Thriller', 'thriller'], ['Horror','horror']  ]
  end

  def no_of_pepople_interest(movie)
    if current_user
      unless movie.fb_friends_liked(current_user).to_i == 0
        value = "<h4 class='friends_interest'>"
        value += link_to(movie.fb_friends_liked(current_user).to_s + ' friends are interested', path_for_movie(movie))
        value += '<span> <img alt="Bthumbicon" src="/images/BthumbIcon.jpg"> </span></h4>'
        return value.html_safe
      end
    else
      ''
    end
  end

  def option_for_cast_type
    [['Actor','actor'],['Producer','producer'], ['Director','director'], ['Musics','musics'], ['Writer','writer'], ['Cinematographer','cinematographer'], ['Distributor','distributor'], ['Editor','editor'],['Special Effects Supervisor','special effects supervisor'],['Art Director','art director'], ['Stunt Director','stunt director'],['Casting Director','casting director'], ['Location Manager','location manager'],['Dialogue Director','dialogue director'], ['Sound Designer','sound designer'], ['Makeup Artist','makeup artist'], ['Costume Designer','costume designer'], ['Music Director','music director'], ['Lyricist','lyricist'],['Choreographer','choreographer'], ['Singer','singer']]
  end

end

