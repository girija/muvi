$(function() {
  /*if ($.cookie('tour_current_step') == null) {    
  var tour = new Tour();

    tour.addStep({
      element: "#all_movie_icon",
      placement: "right",
      title: "Your !",
      content: "Your movie activies will be shown here",
      reflex: true
    });


    tour.addStep({
        element: "#seen_icon",
        placement: "right",
        title: "All your seen movies!",
        content: "Your seen movies will be shown here. <br/> Click this to view."
     });

     tour.addStep({
        element: "#wanna_see_icon",
        placement: "right",
        title: "All your wanna see movies!",
        content: "Your wanna see movies will be shown here. <br/> Click this to view."
     });

     tour.addStep({
       element: ".btn-discover",
       placement: "top",
       title: "Find out more!",
       content: "Click here to see the movies"
     });
		
     tour.restart();
     $(this).parents(".alert").alert("close");
   }*/   		

   $(".btn-feed-login").live("click", function(e){
     e.preventDefault();
     is_logged_in('default');
     return false;
   });	
   $(".recent_poster").live({ mouseenter: function(){
    $(this).children(".poster-meta").fadeTo('slow', 1);
   }, mouseleave: function(){
    $(this).children(".poster-meta").fadeTo('slow', 0);
   }});

   $('.scroll-pane').jScrollPane();
   reinitialiseScrollPane = function(){
     $('.scroll-pane').jScrollPane();
   }
	
  $("div#show_button").click(function(){
    $("div#panel").animate({width: "300px"})
    _gaq.push(['_trackEvent', 'Drawer', 'Open', 'Drawer opened']);
    //.animate({width: "400px"}, "fast");
    $("div.panel_button").toggle();
  });
  

   $("div#hide_button").click(function(){
     $("div#panel").animate({width: "20px"});
     $("div.panel_button").toggle();
   });

  //$("#drawer_box").css( "left", - $("#drawer_box").width() + 20);
  //$("#handle").click(function(){
  //  $("#drawer_box").animate({
  //    left : parseInt($("#drawer_box").css('left'),10) == 0 ? - $("#drawer_box").width()+ 20  :  0
  //  });
  //});

  $('#myTab a').click(function (e) {
    e.preventDefault();
    $(this).tab('show');
  })
  $(".btn-seen").live("click", function(e){
    e.preventDefault();
    if ($(this).hasClass('btn-dis')){
      return false;
    }
    _gaq.push(['_trackEvent', 'Discovery', 'Seen', $("#movie_name").html()]);

    disableButtons();
    addItem("seenit");
  });
  $(".btn-wanna-see").live("click", function(e){
    e.preventDefault();
    if ($(this).hasClass('btn-dis')){
      return false;
    }
    _gaq.push(['_trackEvent', 'Discovery', 'Wanna See', $("#movie_name").html()]);
    disableButtons();
    addItem("wannasee");
  });
  $(".btn-pass").live("click", function(e){
    if ($(this).hasClass('btn-dis')){
      return false;
    }
    _gaq.push(['_trackEvent', 'Discovery', 'Pass', $("#movie_name").html()]);
    disableButtons();
    passIT(false);
  });
  $(".btn-discover").live("click", function(e){
    e.preventDefault();
    if ($(this).hasClass('btn-dis')){
      return false;
    }
    _gaq.push(['_trackEvent', 'Discovery', 'Discovery', 'Discover button clicked']);
    disableButtons();
    passIT(false, true);

    $(this).parents(".row-fluid:first").fadeOut(3000,function(){
      $(this).next().show().fadeIn(3000);
    });
  });

  $(".btn-seen-list").live("click", function(){
    _gaq.push(['_trackEvent', 'Drawer', 'Seen', 'Drawer seen clicked']);
    var movie_id = $(this).attr("data-id");
    $(this).parents(".gradient_class:first").slideUp("slow", function(){
       var user_id = $("#logged_in_user_id").val(); //1275;
      $.getScript("/wannasee_seen?user_id=" + user_id + "&movie_id=" + movie_id);
      reloadItem("seenit", movie_id);
    });
    /********************************************/
    var v = $("#loggedin_user_seenit_movie").val();
    $("#loggedin_user_seenit_movie").val(v +","+ $("#movie_id").val());
    /********************************************/

  });
  $("#movie_link").live("click", function(){
    _gaq.push(['_trackEvent', 'Discovery', 'Learn more', $("#movie_name").html()]);
  });
  $("#movie_image").live("click", function(){
    _gaq.push(['_trackEvent', 'Discovery', 'Poster click', "Clicked on poster of " + $("#movie_name").html()]);
  });
  $(".btn_view_trailer").live("click", function(){
    _gaq.push(['_trackEvent', 'Discovery', 'View trailer', "Clicked on view trailer of " + $("#movie_name").html()]);
  });
  $(".btn-follow").live("click", function(e){
    e.preventDefault();
    if ($(this).hasClass('disabled')){
      return false;
    }
    $(this).addClass("disabled");
    _button = $(this);
     _gaq.push(['_trackEvent', 'Profile', 'Follow', "Clicked on follow " + list_id + " by " + $("#logged_in_user_id").val() ]);
    var list_id = $(this).attr("data-id");
    $.post("/follow?list_id=" + list_id + "&user_id=" + $("#logged_in_user_id").val(), function(data) {
     $('#followers-'+list_id).html(data); 
     _button.removeClass("btn-follow").addClass("btn-following").html("Following");
    });
    return false;
  });
  $(".btn-following").live("click", function(e){
    e.preventDefault();
    if ($(this).hasClass('disabled')){
      //return false;
    }
    _button = $(this);
    var list_id = $(this).attr("data-id");
    $.post("/unfollow?list_id=" + list_id + "&user_id=" + $("#logged_in_user_id").val(), function(data) {
      _button.removeClass("disabled").removeClass("btn-following").addClass("btn-follow").html("Follow");
    });
    return false;
  });
  $(".btn-following").live({ mouseenter: function(){
    $(this).removeClass("disabled").html("Unfollow");
  }, mouseleave: function(){
    $(this).addClass("disabled").html("Following");
  }});
  $(".poster").live({ mouseenter: function(){
    $(this).children(".poster-meta").fadeTo('slow', 1);
  }, mouseleave: function(){
    $(this).children(".poster-meta").fadeTo('slow', 0);
  }});

  $(".btn-follow-all").live("click", function(e){
    e.preventDefault();
    if ($(this).hasClass('disabled')){
      return false;
    }
    $(this).addClass("disabled");
    _gaq.push(['_trackEvent', 'Profile', 'Follow', "Clicked on follow on all seen list by " + $("#logged_in_user_id").val() ]);
    var list_id = $(this).attr("data-id");
    $.post("/follow_all?list_id=" + list_id + "&user_id=" + $("#logged_in_user_id").val(), function(data) {
     $('#followers-all-'+list_id).html(data);
    });
    return false;
  });
  $(".btn-follow-star").live("click", function(e){
    e.preventDefault();
    if ($(this).hasClass('disabled')){
      return false;
    }
    $(this).addClass("disabled");
    //_gaq.push(['_trackEvent', 'Profile', 'Follow', "Clicked on follow on all seen list by " + $("#logged_in_user_id").val() ]);
    var list_id = $(this).attr("data-id");
    $.post("/follow_star?list_id=" + list_id + "&user_id=" + $("#logged_in_user_id").val(), function(data) {
     $('#followers-star').html(data);
    });
    return false;
  });

  $(".container-tagged").live("click", function(){
    $(this).hide("slow");
    $(this).next().show();
  });
  $(".btn-seen-profile").live("click", function(e){
    e.preventDefault();
    if ($(this).hasClass('disabled')){
      return false;
    }
    if ($(this).hasClass('btn-warning')){
      return false;
    }
    _gaq.push(['_trackEvent', 'Profile', 'Seen', "Clicked on seen on" + $(this).attr("data-id") + " by " + $("#logged_in_user_id").val() ]);
    $.getScript("/seenit_add?user_id=" + $("#logged_in_user_id").val() + "&movie_id=" + $(this).attr("data-id"));
    $(this).next('.btn-wanna-see-profile').addClass("disabled");
    $(this).next('.btn-wanna-see-profile').removeClass("btn-primary");
    $(this).next('.btn-wanna-see-profile').removeClass("btn-success");
    $(this).parent().next().children('.btn-wanna-see-profile').addClass("disabled");
    $(this).parent().next().children('.btn-wanna-see-profile').removeClass("btn-primary");
    $(this).parent().next().children('.btn-wanna-see-profile').removeClass("btn-success");
    //$(this).addClass("btn-warning");
    //eval($(this).prev('.rate-block').children("div").children("a").attr('onclick'));
    //$("#rateModal").modal("show");

    $(this).hide();
    $(this).prev('.rate-block').css('display', 'inline-block');

  });
  $(".btn-wanna-see-profile").live("click", function(e){
    e.preventDefault();
    if ($(this).hasClass('disabled')){
      return false;
    }

    if ($(this).hasClass('btn-warning')){
      return false;
    }
    _gaq.push(['_trackEvent', 'Profile', 'Seen', "Clicked on wanna seen on" + $(this).attr("data-id") + " by " + $("#logged_in_user_id").val() ]);
    //$(this).prev('.btn-seen-profile').addClass("disabled")
    $(this).removeClass("btn-primary");
    $(this).addClass("btn-success");
    $.getScript("/wannasee_add?user_id=" + $("#logged_in_user_id").val() + "&movie_id=" + $(this).attr("data-id"));
    //$(this).addClass("btn-warning");
  });
  $(".btn_view_trailer-profile").live("click", function(e){
    $("#video_player").attr("href" , $(this).attr("data-url"));
  });
  $(".btn-follow-login").live("click", function(e){
    e.preventDefault();
    is_logged_in('');
    return false;
  });
  $(".btn-seen-login").live("click", function(e){
    e.preventDefault();
    is_logged_in('');
    return false;
  });
  $(".btn-wanna-see-login").live("click", function(e){
    e.preventDefault();
    is_logged_in('');
    return false;
  });

  $(".btn-email-join").live("click", function(e){
    e.preventDefault();
    email_join();
    return false;
  });

  $(".btn-fb-join").live("click", function(e){
    e.preventDefault();
    fb_join();
    return false;
  });

  /*$(".row-list-header").live("click", function(){
    var id = $(this).attr("data-id");
    $(this).next().slideToggle("slow",function() {
        if ($(this).is(':hidden'))
        {
	  $("#poster_"+id).show("slow");
          $("#share_"+id).hide("slow");
          $("#marker" + id ).attr("class", "icon-chevron-down");
	  _gaq.push(['_trackEvent', 'User Profile', 'Closed', '']);
        }
        else
        {
	  $("#poster_"+id).hide("slow");
          $("#share_"+id).show("slow");
          $("#marker" + id ).attr("class", "icon-chevron-up");
	  _gaq.push(['_trackEvent', 'User Profile', 'Opened', '']);
        }
    });
  });*/
});

function disableButtons(){
 $(".btn-wanna-see").addClass("btn-dis");
 $(".btn-seen").addClass("btn-dis");
 $(".btn-pass").addClass("btn-dis");
 $(".btn-discover").addClass("btn-dis");
}
function enableButtons(){
 $(".btn-wanna-see").removeClass("btn-dis");
 if ($(".btn-seen").hasClass('btn-primary')){
   $(".btn-seen").removeClass("btn-dis");
 }
 $(".btn-pass").removeClass("btn-dis");
 $(".btn-discover").removeClass("btn-dis");

}
function updateWannaSee(){
   var user_id = $("#user_id").val(); //1275;
  //var after = $("#want_to_see > .want_to_see:first-child").attr("data-time");
  var after = 1;
  $.getScript("/want_to_see?user_id=" + user_id + "&after=" + after);
  setTimeout(updateWannaSee, 20000);dd
}

function updateSeen(){
  var user_id = $("#user_id").val(); //1275;
  var after = 1;
  $.getScript("/seen?user_id=" + user_id + "&after=" + after);
  setTimeout(updateSeen, 20000);
}

function addItem(type){
  var user_id = $("#user_id").val(); //1275;
  //var user_id = $("#current_user_id").val();

  $.getScript("/"+ type + "_add?user_id=" + user_id + "&movie_id=" + $("#movie_id").val());
  //passIT(false);
  animateDrawer(type);
  passIT(false);
  
  /********************************************/  
  var v = $("#loggedin_user_"+type+"_movie").val(); 
  $("#loggedin_user_"+type+"_movie").val(v +","+ $("#movie_id").val());
  /********************************************/
}

function remove_block(div_id, notification_id, current_user_id, target_user_id, movie_id, activity_type){
  $("#"+div_id).fadeOut(500).slideUp();
  $("#"+div_id).animate({"opacity" : "0"},{"complete" : function() {$('#'+div_id).remove();}});
  _gaq.push(['_trackEvent', 'Feed', activity_type, activity_type]);

  if(activity_type == 'asked') {
  } else if (activity_type == 'has recommended') {
  } else if (activity_type == 'has not recommended'){
  }
  $.post('/add_activity', {notification_id : notification_id, current_user_id : current_user_id, target_user_id : target_user_id, movie_id : movie_id, activity_type: activity_type}, function(data) {
    $('.result').html(data);
  });
}

function add_kudos(current_user_id, target_user_id, movie_id, list_id){
  $.post('/add_activity', {notification_id : 0, current_user_id : current_user_id, target_user_id : target_user_id, movie_id : movie_id, activity_type: "kudos",list_id : list_id}, function(data) {
    $('.result').html(data);
  });
}

function remove_block_ok(div_id, notification_id){
  $("#"+div_id).fadeOut(500).slideUp();
  $("#"+div_id).animate({"opacity" : "0"},{"complete" : function() {$('#'+div_id).remove();}});
  $.post('/close_activity', {notification_id : notification_id}, function(data) {
  });
  _gaq.push(['_trackEvent', 'Feed', 'Thanks on feed', 'Clicked on "Thank" button']);
}

function remove_feed_block(div_id, btn_type){
  $("#"+div_id).fadeOut(500).slideUp();
  $("#"+div_id).animate({"opacity" : "0"},{"complete" : function() {$('#'+div_id).remove();}});
  _gaq.push(['_trackEvent', 'Feed', btn_type, btn_type]);
}

var cuurent_movie_id, current_movie_name, current_movie_image, cuurent_movie_link;

function passIT(isFistTime, isDiscover){
	$("#load_div").show();
	$("#discovery_div").hide();

	//var user_id = $("#current_user_id").val();
	var user_id = $("#user_id").val();
        $.post("/movie_pass?user_id=" + user_id + "&movie_id=" + $("#movie_id").val(), function(data) {
                $("#load_div").hide();
                $("#discovery_div").html(data);
                $("#discovery_div").show();

		current_movie_id = $("#movie_id").val();
	        current_movie_name = $("#movie_name").html();
                current_movie_image = $("#movie_image").attr("src");
                current_movie_link = $("#movie_link").attr("href");
        });

}
function passIT_old(isFistTime, isDiscover){
  var user_id = $("#user_id").val();
  var user_id = $("#user_id").val();
  var movie_id = $("#next_movie_id").val();
  var movie_name = $("#next_movie_title").val();
  var movie_cast = $("#next_movie_cast").val();
  var movie_story = $("#next_movie_story").val();
  var movie_add_info = $("#next_movie_add_info").val();
  var movie_image = $("#next_movie_image").val();
  var movie_link = $("#next_movie_link").val();
  var movie_trailer_url = $("#next_movie_trailer_url").val();
  var rel_dt = $("#next_movie_released").val();
  var release_dt = new Date(rel_dt);
  var today = new Date();


  $("#more_info").html("");
  current_movie_id = $("#movie_id").val();
  current_movie_name = $("#movie_name").html();
  current_movie_image = $("#movie_image").attr("src");
  current_movie_link = $("#movie_link").attr("href");
  $.getScript("/movie_pass?user_id=" + user_id + "&movie_id=" + $("#movie_id").val() + "&next_movie_id=" + movie_id + "&first_time=" + isFistTime);

  if( isFistTime == false ) {
   if(isDiscover == true){
      $("#movie_id").val(movie_id);
      $("#movie_name").html(movie_name);
      $("#movie_cast").html(movie_cast);
      $("#movie_story").html(movie_story);
      $("#movie_add_info").html(movie_add_info);
      $("#movie_image").attr({src : movie_image, alt : movie_name});
      $("#movie_link").attr({href : movie_link});

      $("#movie_page_link").attr({href : movie_link});
      if(movie_trailer_url== ""){
	$(".play_icon").hide();
        $(".btn_view_trailer").hide();
        $(".btn_view_trailer").attr({"data-id" : ""});

      } else {
	$(".play_icon").show();
        $(".btn_view_trailer").show();
        $(".btn_view_trailer").attr({"data-id" : movie_trailer_url});
        $("#video_player").attr({href : movie_trailer_url});
      }
      
   } else {
    $("#movie_image").attr({src : "http://dfquahprf1i3f.cloudfront.net/public/images/no-image.png", alt : movie_name});
    $("#movie_block").fadeTo(3000, 0.001, function(){
      $("#movie_id").val(movie_id);
      $("#movie_name").html(movie_name);
      $("#movie_cast").html(movie_cast);
      $("#movie_story").html(movie_story);
      $("#movie_add_info").html(movie_add_info);
      $("#movie_image").attr({src : movie_image, alt : movie_name});
      $("#movie_link").attr({href : movie_link});
      $("#movie_page_link").attr({href : movie_link});
      if(movie_trailer_url == ""){
	$(".play_icon").hide();
        $(".btn_view_trailer").hide();
        $(".btn_view_trailer").attr({"data-id" : ""});
      } else {
	$(".play_icon").show();
        $(".btn_view_trailer").show();
        $(".btn_view_trailer").attr({"data-id" : movie_trailer_url});
        $("#video_player").attr({href : movie_trailer_url});
      }
    });
   }
  }
  if(rel_dt == ""){
    $(".btn-seen").addClass("btn-dis");
    $(".btn-seen").removeClass("btn-primary");
  }else if(today < release_dt){
    $(".btn-seen").addClass("btn-dis");
    $(".btn-seen").removeClass("btn-primary");
  }else{
    $(".btn-seen").addClass("btn-primary");
    //$(".btn-seen").removeClass("btn-dis");
  }

}
function animateDrawer(type){
  //var perma = current_movie_link.split("/");
  //var permalink = perma[2];

  var movie_id = current_movie_id;
  var movie_name = current_movie_name;
  var movie_link = current_movie_link;
  var movie_image = current_movie_image;

  var perma = movie_link.split("/");
  var permalink = perma[2];


  $.post("/get_movie_cast?movie_id=" + movie_id , function(data) {
    var panel = "";
    $('#'+type+'Tab').tab('show');
    if(type == 'seenit'){
      panel = "seen";
      btn = '<div id="rate_'+movie_id+'"><a role="button" onclick="populate_data(\''+movie_name+'\', \''+movie_id+'\', \''+permalink+'\');" data-toggle="modal" class="btn btn-primary" href="#rateModal"><i class="icon-star"></i> Rate</a></div>';
    } else {
      panel = "wanna_see"
     
      var release_dt = $("#movie_released").val();
      var new_release_dt = new Date($("#movie_released").val());
      var today = new Date();
     
      if(release_dt == "" || (new_release_dt > today)){
	      btn = '<a class="btn disabled" href="#"><i class="icon-ok"></i> Have Seen</a>';
      }else{
		btn = '<a class="btn btn-seen-list btn-primary" href="#" data-id="'+ movie_id  +'"><i class="icon-ok"></i> Have Seen</a>';
      }
    }
    
    $('<div class="gradient_class" style="padding:5px; font-size:12px; background-color: #FFFFFF"><a class="pull-left" href="'+movie_link+'"><img src="'+ movie_image.replace('standard', 'thumb')+'" alt="'+ movie_name  +'" class="image_class"></a><div class="media-body" style="min-height:90px;"><h5 class="media-heading"><a href="'+movie_link+'">'+ movie_name  +'</a></h5>'+data+'<div class="clear"></div><div class="right" style="margin-top:18px;">' + btn + '</div></div></div>")').hide().prependTo("."+panel+"_pannel .media .items .jspContainer .jspPane").css({opacity:0}).slideDown(1000).animate({opacity:1},500);

    if($("."+panel+"_pannel").is(":visible") == false){
      $("#"+panel+"_icon").css({color: '#333333'});
      setTimeout(function(){$("#"+panel+"_icon").css({color: '#CCCCCC'})}, "1000");
    }
 
  });
  //}).delay(1600).animate({width: "20px"}, 1000);
}
function reloadItem(type, movie_id){
  var user_id = $("#user_id").val(); //1275;

  $.getScript("/"+ type + "_reload?user_id=" + user_id + "&movie_id=" + movie_id);
}

function include(arr, obj) {
    for(var i=0; i<arr.length; i++) {
        if (arr[i] == obj) {
          return true;
        }
    }
}

function show_hide_div(hide_div, show_div, show_div_1, hide_div_1){
  $("#"+hide_div).hide();
  $("#"+show_div).show();

  $("#"+show_div_1).show();
  $("#"+hide_div_1).hide();
}

function show_hide_signup_div(hide_div, show_div){
  $("#"+hide_div).hide();
  $("#"+show_div).show();
}

 var tmp = 0;
 function show_fb_reg(){
      if(tmp == 0){
        if($("#user_user_profile_attributes_display_name").val() != ""){
          $("#fb_register").show();
          $("#errors").show();
          $("#errors").html("Enter a password and click on Join");
          $('#errors').css("float", "none");
          $('#errors').css("color", "red");
          $('#errors').css("background", "none");
          $('#errors').css("display", "inline");
          $('#errors').css("font-weight", "bold");
          $('#errors').css("font-size", "12px");
          $("#email_reg_form").hide();
          tmp = 1;
        }
      }
    }

  function validate_fb_signup(){
    if($("#fb_password").val() === ""){
      $("#errors").show();
      $("#errors").html("Please enter password");
      $('#errors').css("float", "none");
      $('#errors').css("color", "red");
      $('#errors').css("background", "none");
      $('#errors').css("display", "inline");
      $(".buffer-signin").show('shake', 55);
      return false;
    }else{
      disable_btn("fb_submit");
      var hid_fb_pw = base64_encode($("#fb_password").val());
      $("#hid_fb_password").val(hid_fb_pw);
      $("#errors").hide();
    }
  }

   function disable_btn(btn_id){
     $("#"+btn_id).attr('disabled','disabled');
     $("#"+btn_id).val("");
     $("#"+btn_id).attr("style", "background:url(http://www.muvi.com/images/loading.gif); height:15px; width:125px");
     $("#errors").html("");
     return true;
  }

  function follow_list(list_id, notification_id){
    $.post("/follow?list_id=" + list_id + "&user_id=" + $("#current_user_id").val() + "&notification_id="+ notification_id, function(data) {
    });
    //_gaq.push(['_trackEvent', 'Feed', 'Follow list', 'Clicked on "Follow" a list"']);
  }

  function follow_filmography(list_id, notification_id){
    $.post("/follow_star?list_id=" + list_id + "&user_id=" + $("#current_user_id").val() + "&notification_id="+ notification_id, function(data) {
    });
    //_gaq.push(['_trackEvent', 'Feed', 'Follow list', 'Clicked on "Follow" a list"']);
  }

  function is_logged_in(arg){
    $.get('/users/sign_in', function(data){
      $("#loginModal .modal-body").html(data);
      $("#loginModal").modal("show");
      if(arg == ''){
        $("#register").show();
      }
    });
  }

  function email_join(){
    $.get('/email_join', function(data){
      $("#joinModal .modal-body").html(data);
      $("#joinModal").modal("show");
      $("#loginModal .modal-header .pull-right").click();
    });
  }

  function fb_join(){
    var x = screen.width/2 - 800/2;
    window.open("/auth/facebook", "", "width=800,height=500,left="+x);

    $.get('/fb_join', function(data){
	$("#email_join_div").hide();
        $("#fb_join_div").show();

      	//$("#joinModal .modal-body").html(data);
      	//$("#joinModal").modal("show");
    });
  }


  function send_invite(list_id, notification_id){
    $.post("/send_list_invite?list_id=" + list_id + "&notification_id="+notification_id+"&user_id=" + $("#current_user_id").val(), function(data) {
    });
    //_gaq.push(['_trackEvent', 'Feed', 'Invitation to follow list', 'Sending invitation to follow list"']);
  }

  function wanna_see_and_seen_movie(user_id, movie_id, type, notification_id){
    $.post("/wanna_see_and_seen_movie?user_id=" + user_id + "&movie_id="+movie_id+"&type=" + type+"&notification_id="+notification_id, function(data) {
    });
    //_gaq.push(['_trackEvent', 'Feed', type, 'Clicked on "'+type+'" in feed"']);
  } 
  
  function delete_activity(user_id, notification_id){
    $.post("/delete_activity?user_id=" + user_id + "&notification_id="+notification_id, function(data) {
    });
  }

  function show_close(th){
    var close_id = "close_"+th.id;
    $("#"+close_id).css("visibility", "visible");
    $("#"+close_id).html("&nbsp;");
    $("#"+close_id).css("background", "url(http://www.muvi.com/images/popup_close.png) no-repeat");
    $("#"+close_id).css("width", "15px");

    $(th).css("background-color", "#F9F9F9");

  }

  function hide_close(th){
    var close_id = "close_"+th.id;
    $("#"+close_id).css("visibility", "hidden");
   
    $(th).css("background-color", "#FFFFFF");
  }
  
  function update_feed_history(user_id, activity_type, object_id){
    $.post("/update_feed_history?user_id=" + user_id + "&activity_type="+activity_type+ "&object_id="+ object_id, function(data) {
    });
  }

 function validateEmail(elementValue){
    var emailPattern = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9][a-zA-Z0-9.-]*[\.]{1}[a-zA-Z]{2,4}$/;
    return emailPattern.test(elementValue);
 }

  function show(div){
    //window.location.href = "/show_"+div;
    /*$("#invite_div").hide();
    $("#language_div").hide();
    $("#add_movie_div").hide();

    $("#invite_tab").css("opacity", "0.5");
    $("#language_tab").css("opacity", "0.5");
    $("#add_movie_tab").css("opacity", "0.5");


    $("#"+div).show();
    */
    if(div == "add_movie_div"){
      $("#first_movie_div").html("<img src='/images/loading.gif'>");

      $.post("/show_movie", function(data) {
        $("#first_movie_div").html(data);
	$("#close_muvi_modal").show();

        $("#modal-9").removeClass("md-show");
	$("#modal-10").addClass("md-show");
      });
      //$("#add_movie_tab").css("opacity", "1");
    }
    /*if(div == "invite_div"){
      $("#invite_tab").css("opacity", "1");
    }
    if(div == "language_div"){
      //$("#eng_chk").removeAttr("checked");
      //$("#hindi_chk").removeAttr("checked");
      //$("#tamil_chk").removeAttr("checked");
      //$("#telugu_chk").removeAttr("checked");

      $("#language_tab").css("opacity", "1");
    }*/

  }

  function show_feed(cur_user){
   window.location.href = "/show_feed/"+cur_user;
  }

  function show_textbox(id){
    $("#"+id+"_link").hide();
    $("#"+id+"_text").hide();
    $("#"+id).show();
    $("#"+id).focus();
  }
  function hide_textbox(id){
    var val = $("#"+id+"_text").html();
    if (val == ""){
      $("#"+id+"_link").show();
    }else{
      $("#"+id+"_text").show();
    }
    $("#"+id).hide();
  }

  function saveuser_data(id,evt,profile_id){
    if(evt.keyCode == 13){
      if($("#logged_in_user_id").length > 0){
        var txt_val = $("#"+id).val();
        if (txt_val == ""){
          txt_val = "nil";
        }
        var url = "/user_profiles/save_data";
        $.post(url,{id:profile_id,content:txt_val,field:id},function(res){
          $("#"+id).hide();
          $("#"+id+"_text").show();
          if (txt_val != "nil"){
            $("#"+id+"_text").html(txt_val);
          }else{
            $("#"+id+"_text").html("");
            $("#"+id+"_link").show();
          }
        });
      }else{
        is_logged_in('');
        return false;
      }
    }
  }

  function load_seen_wanna_see(){
    $.post("/load_seen_wanna_see",function(res){
      $("#seen_wanna_see_container").html(res);
      //$("#seen_wanna_see_container").show();
   
      $(".seen_pannel").hide();
      $(".wanna_see_pannel").hide();

      if($("#seen_icon").css("color") == "rgb(51, 51, 51)"){
        $(".seen_pannel").show();
      }
      else if($("#wanna_see_icon").css("color") == "rgb(51, 51, 51)"){
        $(".wanna_see_pannel").show();
      }
      $("#seen_icon").show();
      $("#wanna_see_icon").show();
      $("img").lazyload();
    });
  }
  function add_movie_to_list(list_id){
    var movie_id = $("#movie_id_"+list_id).val();
    var url = "/save_movietolist";
    $.post(url,{list_id:list_id,movie_id:movie_id},function(res){
      $("#movie_list_"+list_id).append(res);
    });
    $("#movie_id_"+list_id).val("");
    $("#movie_name_"+list_id).val("");
  }
  function remove_movie_fromlist(movie_id,list_id){
    if($("#logged_in_user_id").length > 0){
      var url = "/remove_movie_fromlist";
      $("#movie_block_"+movie_id+"_"+list_id).hide();
      $.post(url,{movie_id:movie_id,list_id:list_id},function(res){
      });
    }else{
      is_logged_in('');
      return false;
    }
  }

  function get_all_movie(celeb_id){
    $(".tip_hint").tooltip({
      placement: "bottom",
      html: true
    });
    $("#lnk-all").removeClass("subtab_active");
    $("#lnk-top").removeClass("subtab_active");
    $("#lnk-upcoming").removeClass("subtab_active");
    $("#lnk-all").addClass("subtab_active");

    $("#all-movie-block").show();
    $("#all-movie-block").html("<img src='/images/loading.gif' style='padding:50px 350px;'>");
    $.post("/get_all_movies?celeb_id="+celeb_id+"&page=1", function(data){
      $("#all-movie-block").html(data);
      fetch_next_movie(1, celeb_id);
    });
  }
  function fetch_next_movie(page, celeb_id){
    var prev_page = page;
    var next_page = parseInt($("#hid_page_"+page).val()) + 1;
    console.log(next_page);
    try{
      if(isNaN(next_page) == false){
        $.post("/get_all_movies?celeb_id="+celeb_id+"&page="+next_page, function(data){
          $("#all-movie-block").append(data);
          fetch_next_movie(next_page, celeb_id);
        });
      }
    }catch(E){}
  }
  function fetch_list(){
    var url = document.URL.split("/");
    var uid = url[4];

    if(uid != ""){
      $.post("/get_all_lists?user_id="+uid+"&page=1", function(data){
        $("#all_lists").html(data);
        fetch_next_list(1, uid);
      });

      $.post("/get_all_seen_lists?user_id="+uid, function(data){
        $("#all_seen_lists").html(data);
      });
    }
  }
  function fetch_next_list(page, user_id){
    var prev_page = page;
    var next_page = parseInt(page) + 1;
    try{
      if(isNaN(next_page) == false){
        $.post("/get_all_lists?user_id="+user_id+"&page="+next_page, function(data){
          $("#all_lists").append(data);
          if(data == ""){
            return;
          }
          else{
            fetch_next_list(next_page, user_id);
          }
        });
      }
    }catch(E){}
  }

  ////////////////////////////
  var back, back_content;
  var cur_url = document.URL;

  function open_movie_list(list_id, show_fb_form){
    var front = document.getElementById('list_header_'+list_id);
    back_content = document.getElementById('movie_list_back_'+list_id).innerHTML;
    back = flippant.flip(front, back_content, 'modal');
    $("#flip_back").val('#movie_list_back_'+list_id);
    $('#movie_list_back_'+list_id).html("");
    $(".close_list").show();
    $("#selected_list_id").val(list_id);
    $(".tip_hint").tooltip({
      placement: "bottom",
      html: true
    });
    if (typeof(show_fb_form) === "undefined") { show_fb_form = 1; }
    if(show_fb_form == 1){
      $.post("/get_fb_share?list_id="+list_id,function(res){
        $("#fb_div_"+list_id).html(res);
      });
    }
  }
    
