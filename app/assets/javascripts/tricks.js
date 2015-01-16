function save_wanna_see_tab(movie_id,user_id){
        if(user_id == ""){
                check_login();
        }else{
                _gaq.push(['_trackEvent', 'Movie Tab', 'Wanna see', movie_id]);
                var url = "/wannasee_add";
                $.post(url,{movie_id:movie_id,user_id:user_id},function(res){
                });
        }
}
function save_wanna_see(movie_id,user_id){
	if(user_id == ""){
                var url = $("#hidden_reply_login").attr('href');
                $("#hidden_reply_login").attr('href',url+"&login_for=want_to_see&refer_id="+movie_id+"&refer_type=Movie");
                $("#hidden_reply_login").click();
        }else{
		_gaq.push(['_trackEvent', 'Movie Inside Page', 'Wanna see', movie_id]);
		var url = "/wannasee_add";
		$.post(url,{movie_id:movie_id,user_id:user_id},function(res){
  		});
		display_block("want_it");
	}
}
function follow_user(flw_user_id,display_name){
  var url = "/connections/follow";
  $("#sugg_"+flw_user_id).hide("slow");
  successMessage("You followed "+ display_name);
  $.post(url,{sug_user:flw_user_id,own_profile:true},function(res){
  });
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
  var user_id = $("#user_id").val();
  if(evt.keyCode == 13){
    if(user_id == ""){
      var url = $("#hidden_reply_login").attr('href');
      $("#hidden_reply_login").attr('href',url+"?login_for=profile_update&refer_cls=UserProfile");
      $("#hidden_reply_login").click();
    }else{
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
    }
  }
}

function goto_block(block){
    window.location.hash='';
    window.location.hash='#'+block;
}

function check_login_review_movie(id,block,cont_id,p_cls,p_id,type){
  var user_id = $("#user_id").val();
  if(user_id == ""){
    var url = $("#hidden_reply_login").attr('href');
    $("#hidden_reply_login").attr('href',url+"&login_for=discussion_like&refer_cls="+cls+"&refer_id="+id);
    $("#hidden_reply_login").click();
  }else{
    $("#"+type+"_review_"+id).attr("href","/reviews/save_review?movie_id="+id+"&rating="+type+"&block="+block+"&refer_cls="+p_cls+"&refer_id="+p_id);
  }
}
function check_inner_like_login(id,cls,cont_id,p_cls,p_id,type){
  var user_id = $("#user_id").val();
  if(user_id == ""){
    var url = $("#hidden_reply_login").attr('href');
    $("#hidden_reply_login").attr('href',url+"&login_for=discussion_like&refer_cls="+cls+"&refer_id="+id);
    $("#hidden_reply_login").click();
  }else{
    $("#"+cont_id+id).attr("href","/discussion/vote/"+id+"?item_class="+cls+"&inner_page=true&p_cls="+p_cls+"&p_id="+p_id+"&type="+type);
  }
}

function check_profile_like_login(profile_id,id,cls,type){
  var user_id = $("#user_id").val();
  if(user_id == ""){
    var url = $("#hidden_reply_login").attr('href');
    $("#hidden_reply_login").attr('href',url+"&login_for=discussion_like&refer_cls="+cls+"&refer_id="+id);
    $("#hidden_reply_login").click();
  }else{
    $("#"+type+"_"+cls+"_"+id).attr("href","/discussion/vote/"+id+"?item_class="+cls+"&profile_page=true&profile_id="+profile_id+"&type="+type);
  }
}

function celeb_fan_unfan(id,action,user_id){
  if(user_id != ""){
    if(action == "fan"){
      var url = "/fan/create";
      $.post(url,{celebrity_id:id,inner_ajax:1},function(res){
        var counter = res.split("-");
        $("#fan_cnt_"+id).html(counter[0]);
        $("#unfan_cnt_"+id).html(counter[1]);
      });
    }else{
      var url = "/fans/not_a_fan";
      $.post(url,{celebrity_id:id,inner_ajax:1},function(res){
        var counter = res.split("-");
        $("#fan_cnt_"+id).html(counter[0]);
        $("#unfan_cnt_"+id).html(counter[1]);
      });
    }
  }
}

function show_muvi_block_item(item_type,item_id,refer_type,refer_id,action,block_type){
  var url = "/show_item_detail";
  $.post(url,{item_type:item_type,item_id:item_id,refer_type:refer_type,refer_id:refer_id,type:action,block_type:block_type},function(res){
    if(res != ""){
      if(block_type == "related_movies"){
	var response_div = "Related_movie_detail";
      }else if (block_type == "upcomming"){
        var response_div = "UpMovie_detail";
      }else{
        var response_div = "TopMovie_detail";
      }
      $("#"+response_div).html(res);
    }
  });
}

function show_profile_block_item(item_type,item_id,action,container_id,block_type,profile_id){
  var url = "/profile_block_detail";
  $.post(url,{item_type:item_type,item_id:item_id,type:action,page_name:"profile",block_type:block_type,profile_id:profile_id},function(res){
    if(res != ""){
      $("#"+container_id).html(res);
    }
  });
}

function show_block_item(item_type,item_id,refer_type,refer_id,action){
  var url = "/show_item_detail";
  $.post(url,{item_type:item_type,item_id:item_id,refer_type:refer_type,refer_id:refer_id,type:action},function(res){
    if(res != ""){
      $("#"+item_type+"_detail").html(res);
    }
  });
}

function check_event_and_submit_review(evt,user_id){
  if(evt.keyCode == 13){
    if(user_id != ""){
      $("#user_review_form").submit();
    }else{
      var url = $("#hidden_reply_login").attr('href');
      $("#hidden_reply_login").attr('href',url+"&login_for=discussion_reply&refer_type=discussion&refer_id="+id);
      $("#hidden_reply_login").click();
    }
  }
}
function check_event_profile_review(evt,user_id,block){
  if(evt.keyCode == 13){
    if(user_id != ""){
      $("#"+block+"_review_form").submit();
    }else{
      var url = $("#hidden_reply_login").attr('href');
      $("#hidden_reply_login").attr('href',url+"&login_for=discussion_reply&refer_type=discussion&refer_id="+id);
      $("#hidden_reply_login").click();
    }
  }
}
function profile_reviewblock_submit(movie_id,rating,act_type){
    var user_id = $("#user_id").val();
    $('#'+act_type+'_rating').val(rating);
    if(user_id == "" || typeof user_id == 'undefined'){
      var url = $("#hidden_reply_login").attr('href');
      $("#hidden_reply_login").attr('href',url+"&login_for=like&refer_id="+movie_id+"&refer_type=Movie");
      $("#hidden_reply_login").click();
    } else {
      $("#"+act_type+"_review_form").submit();
      return false;
    }
}

function form_reviewblock_submit(movie_id,like){
    var user_id = $("#user_id").val();
    if(like != 0){
      $('#review_rating_block').val(like);
    }
    if(user_id == "" || typeof user_id == 'undefined'){
      var url = $("#hidden_reply_login").attr('href');
      $("#hidden_reply_login").attr('href',url+"&login_for=like&refer_id="+movie_id+"&refer_type=Movie");
      $("#hidden_reply_login").click();
    } else {
      $("#user_review_form").submit();
      return false;
    }
  }

function filter_engage(id,permalink){
  var filter = $("#engage_filter").val()
  var url = "/stars/"+permalink+"?engage=1&filter="+filter;
  $("#discussion_data").html("<div align='center' style='padding-top:130px;'><img src='/images/loader.gif'></div>");
  $.get(url,function(res){
    $("#engage").html(res);
  });
}

/*function check_login_wanttosee(movie_id,type){
  var user_id = $("#user_id").val();
  $("#action_type").val(type);
  if(user_id == "" || typeof user_id == 'undefined'){
    var url = $("#hidden_reply_login").attr('href');
    $("#hidden_reply_login").attr('href',url+"&login_for=want_to_see&refer_id="+movie_id+"&refer_type=Movie");
    $("#hidden_reply_login").click();
  }
}*/


function check_login_wanttosee(fb_appid, movie_id,type){
     var user_id = $("#user_id").val();
     $("#action_type").val(type);
     $("#action_type_inner_page").val(type);
     $("#action_type_notwant_see").val(type);
     $("#action_type_wantsee").val(type);

     FB.init({
       appId      : fb_appid, // App ID
       //channelUrl : '//WWW.YOUR_DOMAIN.COM/channel.html', // Channel File
       status     : true,
       cookie     : true,
       xfbml      : true
     });
     FB.getLoginStatus(function(response) {
       if (response.status === 'connected') {
         var params = "&login_for=want_to_see&refer_id="+movie_id+"&refer_type=Movie";
         $.post('/check_user_login?user_id='+response.authResponse.userID+params, function(data) {
           if(data == 0){
             registration();
           } else{
             //alert("logged in");
           }

         });
       }else{
         if(user_id == "" || typeof user_id == 'undefined'){
            var url = $("#hidden_reply_login").attr('href');
            $("#hidden_reply_login").attr('href',url+"&login_for=want_to_see&refer_id="+movie_id+"&refer_type=Movie");
            $("#hidden_reply_login").click();
         }
       }
     });
}

/*function check_login_be_a_fan(celeb_id, type){
  var user_id = $("#user_id").val();
  $("#action_type").val(type);
  if(user_id == "" || typeof user_id == 'undefined'){
    var url = $("#hidden_reply_login").attr('href');
    $("#hidden_reply_login").attr('href',url+"&login_for="+type+"&refer_id="+celeb_id+"&refer_type=Celebrity");
    $("#hidden_reply_login").click();
  }
}*/

  function check_login_be_a_fan(fb_appid, celeb_id, type){
    var user_id = $("#user_id").val();
    $("#action_type").val(type);

     FB.init({
       appId      : fb_appid, // App ID
       //channelUrl : '//WWW.YOUR_DOMAIN.COM/channel.html', // Channel File
       status     : true,
       cookie     : true,
       xfbml      : true
     });
     FB.getLoginStatus(function(response) {
       if (response.status === 'connected') {
         var params = "&login_for="+type+"&refer_id="+celeb_id+"&refer_type=Celebrity";
         $.post('/check_user_login?user_id='+response.authResponse.userID+params, function(data) {
           if(data == 0){
             registration();
           } else{
             //alert("logged in");
           }

         });
       }else{
         if(user_id == "" || typeof user_id == 'undefined'){
           var url = $("#hidden_reply_login").attr('href');
           $("#hidden_reply_login").attr('href',url+"&login_for="+type+"&refer_id="+celeb_id+"&refer_type=Celebrity");
           $("#hidden_reply_login").click();
         }
       }
     });
}


/*function check_login_in_homepage(path, id, method_name, message, status, flag_detail){
  var url = $("#hidden_reply_login_homepage").attr('href');
  $("#hidden_reply_login_homepage").attr('href',url+"?home_refer_type=home_page&path="+path+"&id="+id+"&method_name="+method_name+"&message="+message+"&status="+status+"&flag="+flag_detail);
  $("#hidden_reply_login_homepage").click();
}*/

function check_login_in_homepage(fb_appid, path, id, method_name, message, status, flag_detail){
   //window.fbAsyncInit = function() {
     FB.init({
       appId      : fb_appid, // App ID
       //channelUrl : '//WWW.YOUR_DOMAIN.COM/channel.html', // Channel File
       status     : true,
       cookie     : true,
       xfbml      : true
     });
     FB.getLoginStatus(function(response) {
       if (response.status === 'connected') {
         var params = "&home_refer_type=home_page&path="+path+"&id="+id+"&method_name="+method_name+"&message="+message+"&status="+status+"&flag="+flag_detail;
         $.post('/check_user_login?user_id='+response.authResponse.userID+params, function(data) {
           if(data == 0){
             registration();
           } else{
             //alert("logged in");
           }

         });
       }else{
         var url = $("#hidden_reply_login_homepage").attr('href');
         $("#hidden_reply_login_homepage").attr('href',url+"?home_refer_type=home_page&path="+path+"&id="+id+"&method_name="+method_name+"&message="+message+"&status="+status+"&flag="+flag_detail);
         $("#hidden_reply_login_homepage").click();
       }
     });
   //};
  }



function check_userid_in_homepage(path, id, method_name, user_id, message, status, flag_detail){
  post_to_service_url(path, id, method_name, user_id, message, status, flag_detail);
}


function post_to_service_url(path, id, method_name, user_id, message, status, flag_detail){
  successMessage(message);

  if ($.browser.msie && window.XDomainRequest) {
    var xdr = new XDomainRequest();
    var url = serviceUrl+"/muvi/"+path+"/"+id+"/"+method_name+"/"+user_id+".json";
    var refresh_path = path;

    xdr.open("post", url);

    if(method_name == "likes" || method_name == "dislikes"){
      xdr.send("status="+status);

    }else if(method_name == "comment" || method_name == "discussion" ){
      var comment = $("#video_poster_comment_"+id).val();
      xdr.send("comment="+comment);

    }else{
      xdr.send();
    }

    if(path == "movies" && (method_name == "likes" || method_name == "dislikes")){
      refresh_path = "movie";
    }

    if(method_name == "comment" || method_name == "discussion" || method_name == "likes" || method_name == "dislikes"){
      $.post("/home_display/refresh_comment",{type: refresh_path, id: id, flag_detail: flag_detail}, function(data){
        if(data != ""){$("#box_"+id).html(data);}
      });
    }
    else if (method_name == "wanttosee" || method_name == "notanymore"){
      $.post("/home_display/refresh_comment",{type: "movie", id: id}, function(data){
        if(data != ""){
          $("#box_"+id).html(data);
        }
      });
    }
  }
  else{
    var xmlhttp;
    if (window.XMLHttpRequest){
      xmlhttp=new XMLHttpRequest();
    }else{
      xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
    }
    xmlhttp.onreadystatechange=function(){
      if (xmlhttp.readyState==4){

        var refresh_path = path;
        if(path == "movies" && (method_name == "likes" || method_name == "dislikes")){
          refresh_path = "movie";
        }

        if(method_name == "comment" || method_name == "discussion" || method_name == "likes" || method_name == "dislikes"){
          $.post("/home_display/refresh_comment",{type: refresh_path, id: id, flag_detail: flag_detail}, function(data){
            if(data != ""){$("#box_"+id).html(data);}
          });
        }
        else if (method_name == "wanttosee" || method_name == "notanymore"){
          $.post("/home_display/refresh_comment",{type: "movie", id: id}, function(data){
            if(data != ""){
              $("#box_"+id).html(data);
             }
          });
        }
      }
    }
    xmlhttp.open("POST", serviceUrl+"/muvi/"+path+"/"+id+"/"+method_name+"/"+user_id+".json",true);
    if(method_name == "likes" || method_name == "dislikes"){
      xmlhttp.send("status="+status);
    }else if(method_name == "comment" || method_name == "discussion"){
      var comment = $("#video_poster_comment_"+id).val();
      xmlhttp.setRequestHeader("Content-type","application/x-www-form-urlencoded");
      xmlhttp.send("comment="+comment);

    }else{
      xmlhttp.setRequestHeader("Content-type","application/x-www-form-urlencoded");
      xmlhttp.send();
    }
  }
  adjust_boxes();
}


function check_login_poster_video_comment(evt,id){
  if(evt.keyCode == 13){
    var user_id = $("#user_id").val();
    if(user_id == "" || typeof user_id == 'undefined'){
      if($("#hidden_reply_login").length > 0){
        var url = $("#hidden_reply_login").attr('href');
        $("#hidden_reply_login").attr('href',url+"&login_for=poster_vid_com&refer_id="+id+"&refer_type=Poster_Video");
        $("#hidden_reply_login").click();
      }
      else if($("#hidden_reply_login_homepage").length > 0){
        var url = $("#hidden_reply_login_"+id).attr('href');
        $("#hidden_reply_login_"+id).attr('href',url+"&login_for=poster_vid_com&refer_id="+id+"&refer_type=Poster_Video");
        $("#hidden_reply_login_"+id).click();
      }
      return false;
    }else{
      $("#comment_form_"+id).submit();
    }
  }
}
function check_login_poster_video_lik_disl(id,type){
  var user_id = $("#user_id").val();
  if(user_id == "" || typeof user_id == 'undefined'){
    if($("#hidden_reply_login").length > 0){
      var url = $("#hidden_reply_login").attr('href');
      $("#hidden_reply_login").attr('href',url+"&login_for=poster_vid_"+type+"&refer_id="+id+"&refer_type=Poster_Video");
      $("#hidden_reply_login").click();
    }

    else if($("#hidden_reply_login_homepage").length > 0){
      var url = $("#hidden_reply_login_"+id).attr('href');
      $("#hidden_reply_login_"+id).attr('href',url+"&login_for=poster_vid_"+type+"&refer_id="+id+"&refer_type=Poster_Video");
      $("#hidden_reply_login_"+id).click();
    }

    return false;
  }
}

function celebrity_engage_page(permalink){
    $("#reviews").hide();
    $("#first_block").hide();
    $("#celeb_other_info").hide();
    $("#engage").show();
    url = "/stars/"+permalink;
    $.get(url,{engage:1},function(res){
        $("#engage").html(res);
        $("#info_li").removeClass("current");
        $("#engage_li").addClass("current");
    });
}
function celebrity_detail_page(hash){
    $("#first_block").show();
    $("#celeb_other_info").show();
    $("#reviews").show();
    $("#engage").hide();
    go_to_top();
}
function tweet_block(){
    $("#first_block").show();
    $("#celeb_other_info").show();
    $("#reviews").show();
    $("#engage").hide();
    go_to_tab(0);
}

function call_login(form_id){
  var user_id = $("#user_id").val();
  if (user_id == ""){
    $("#hidden_reply_login").click();
  }else{
    $("#"+form_id).submit();
  }

}
function show_full_discussion_form(){
  $("#discussion_form_detail").slideDown("slow");
  $("#discussion_question").css('height','40px');

}
function hide_full_discussion_form(){
  var question = $("#discussion_question").val();
  if(question == ""){
    $("#discussion_question").css('height','20px');
  }
}

function show_all_reply(id){
  $("#latest_two_discussion_reply_"+id).hide();
  $("#all_discussion_reply_"+id).show();
  $("#more_reply_link_"+id).hide();
}
function check_like_login(id,cls){
  var user_id = $("#user_id").val();
  if(user_id == ""){
    var url = $("#hidden_reply_login").attr('href');
    $("#hidden_reply_login").attr('href',url+"&login_for=discussion_like&refer_cls="+cls+"&refer_id="+id);
    $("#hidden_reply_login").click();
  }else{
    $("#discussion_like_link_"+id).attr("href","/discussion/vote/"+id+"?item_class="+cls);
    $("#discussion_like_link_"+id).removeAttr("onclick");
    //$("#discussion_like_link_"+id).click();
  }
}
function check_event_and_submit_discussion_reply(evt,id,user_id){
        if(evt.keyCode == 13){
                if(user_id != ""){
                        var comment = $("#item_comment_"+id).val();
                        var parent_id = $("#parent_id_"+id).val();
                        $("#parent_id").val(parent_id);
                        $("#discu_comment_form_"+id).submit();
                }else{
                        var url = $("#hidden_reply_login").attr('href');
                        $("#hidden_reply_login").attr('href',url+"&login_for=discussion_reply&refer_type=discussion&refer_id="+id);
                        $("#hidden_reply_login").click();
                }
        }
}

function show_discussion_comment(discussion_id){
  $("#item_comments_"+discussion_id).show();
  $("#item_likes_"+discussion_id).hide();
  show_all_reply(discussion_id);
}
function show_likes_popup(id,cls,type,cnt,width,container_id){
  if(cnt > 0){
    var url = "/show_popup";
    $.post(url,{id:id,cls:cls,type:type},function(res){
      if(res != ""){
	$('#'+container_id).html(res);
        $('#'+container_id).dialog({
          modal: true,
          buttons: { "OK": function() { $(this).dialog("close"); } },
          resizable: false,
          maxHeight: 400,
          width: width,
          open: function() { $(".ui-dialog-titlebar").hide(); }
        });
	$('#'+container_id).parent().css("z-index","5000");
      }
    });
  }else{
    return false;
  }
}

function show_rating_popup_tab(container_id,movie_id,user_id){
        if(user_id == ""){
		check_login();
        }else{
		$("#rating_popup").load("/movie_rating_popup/"+movie_id);
                _gaq.push(['_trackEvent', 'Movie Inside Page', 'Seen', movie_id]);
                var url = "/seenit_add";
                $.post(url,{user_id:user_id,movie_id:movie_id},function(res){
                });
                $('#'+container_id).dialog({
                        modal: true,
                        resizable: false,
                        maxHeight: 400,
                        width: 620,
                        open: function() { $(".ui-dialog-titlebar").hide(); }
                });
        }
}

function show_rating_popup(container_id,movie_id,user_id){
        if(user_id == ""){
                var url = $("#hidden_reply_login").attr('href');
                $("#hidden_reply_login").attr('href',url+"&login_for=like&refer_type=movie&refer_id="+movie_id);
                $("#hidden_reply_login").click();
        }else{
		_gaq.push(['_trackEvent', 'Movie Inside Page', 'Seen', movie_id]);
                var url = "/seenit_add";
                $.post(url,{user_id:user_id,movie_id:movie_id},function(res){
                });
                $('#'+container_id).dialog({
                        modal: true,
                        resizable: false,
                        maxHeight: 400,
                        width: 620,
                        open: function() { $(".ui-dialog-titlebar").hide(); }
                });
		display_block("like_it");
        }
}

function append_new_discussion(permalink){
  var question = $("#discussion_question").val();
  if (question == ""){
    $("#discussion").removeAttr("data-remote");
    return false;
  }else{
    $("#discussion").attr("data-remote","true");
    return true;
  }
}
function muvi_new_engage_page(permalink){
    $(".first_sec").hide();
    $("#first_block").hide();
    $("#muvi_other_info").hide();
    $(".first_col").css("height","auto");
    $(".first_col").css("width","1103px");
    $("#engage").show();
    url = "/movies/"+permalink;
    $.get(url,{engage:1},function(res){
        $("#engage").html(res);
    });
}
function muvi_new_detail_page(hash){
    $("#first_block").show();
    $("#muvi_other_info").show();
    $(".first_col").css("width","837px");
    $(".first_sec").show();
    $("#engage").hide();
    go_to_top();
}

function new_review_block(){
    $("#first_block").show();
    $("#muvi_other_info").show();
    $(".first_col").css("width","837px");
    $(".first_sec").show();
    $("#engage").hide();
    go_to_tab(0);
}

function muvi_engage_page(permalink){
    $("#reviews").hide();
    $("#first_block").hide();
    $("#muvi_other_info").hide();
    $("#engage").show();
    url = "/movies/"+permalink;
    $.get(url,{engage:1},function(res){
        $("#engage").html(res);
    });
}
function muvi_detail_page(hash){
    $("#first_block").show();
    $("#muvi_other_info").show();
    $("#reviews").show();
    $("#engage").hide();
    go_to_top();
}

function review_block(){
    $("#first_block").show();
    $("#muvi_other_info").show();
    $("#reviews").show();
    $("#engage").hide();
    go_to_tab(0);
}
function go_to_top(){
    window.location.hash='';
    window.location.hash='#top';
}
function go_to_news(){
    window.location.hash='';
    window.location.hash='#news';
}

function show_all_other(container_id){
    $('#'+container_id).modal({
        minHeight:434,
        minWidth:631
    });
}
function show_all_news(permalink,type){
    if(type == "celebrity"){
        var url = "/stars/"+permalink+"/news?ajax=1";
    }else{
         var url = "/movies/"+permalink+"/news?ajax=1";
    }
    var all_news =  $("#all_news").html();
    if (all_news == ""){
        $.get(url,function(res){
            $("#latest_news").hide();
            $("#all_news").html(res);
        });
    }else{
        $("#latest_news").hide();
        $("#all_news").show();
    }

}

function show_latest_news(){
    $("#latest_news").show();
    $("#all_news").hide();
}
function getUrlAnchor() {
    var hash = ((window.location.hash).replace(/^#/, ''));
    try {
        return $.browser.mozilla ? hash : decodeURIComponent(hash);
    } catch (error) {
        return hash;
    }
}
function gotoTopTen(){
   //location.href = '/top_ten/default/'+ $('#release_year').val() + '/all/' + $('#celebrity').val();
   location.href = '/top_ten/default/'+ $('#release_year').val() + '/all/all';
}
$(function() {
  $("#slider").easySlider();    
$("#load_your_network").click(function(){
  $("#result_your_network").html("Loading...").load('/user_profiles/your_network');
});
$("#load_followers").click(function(){
  $("#result_followers").html("Loading...").load('/user_profiles/followers');
});
 
    if($.browser.msie && $.browser.version == "7.0"){
        var sfiq = $("#search > form > input#q").offset();
        //var y = sfiq.top;
        //var x = sfiq.left;
        $("#search > form > div.btn").css({
            "position": "absolute", 
            "padding-left": "5px"
        });
    }
     
});
 
$(function(){
    $("#login_required").each(function(){
        $(".star-rating").click(function(){
            $("#login_required").click();
        });
    });
    $(".star-rating, .star-rating a, .rating-cancel").css({
        "margin-top": "0px",
        "height": "17px"
    });
    $(".star-rating-control").css({
        "background-color": "#eee"
    });
    $(".star-rating a").click(function() {
        $("#review_area_1").removeAttr('disabled')
        .removeClass("ui-state-disabled")
        .addClass("ui-state-active");

        $(".auto-height-div").fadeIn("slow");
        $("#review_area_1").focus();
    });

    //$(".auto-height-div").hide();
    //$("#new_review").hide();

    $('.auto-height').each(function(){
        var title = $(this).attr("placeholder");
        $(this).val(title);
        $(this).focus(function(){
            var titt = $(this).attr("placeholder");
            var titv = $(this).val();
            if(titv == titt){
                $(this).val("");
            }
        });
        $(this).blur(function(){
            var titt = $(this).attr("placeholder");
            var titv = $(this).val();
            if(titv == titt || titv == ""){
                $(this).val(titt);
            }
        });
    });
	
    $("#review_area_1").val(jQuery.trim($("#my_rating_text").html()));

    //$("#review_submit_button").button();
	
    $('.auto-height').each(function() {
        /*var $this       = $(this);
        var shadow = $('<div class="auto-height"></div>').css({
            position:   'absolute',
            top:        -1000,
            left:       -1000,
            width:      ($(this).width()),
            resize:     'none'
        }).appendTo(document.body);

        var update = function() {
            var val = this.value.replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/&/g, '&amp;')
            .replace(/\n/g, '<br/>');
            shadow.html(val);
            $(this).css('height', Math.max(shadow.height()+20, 20));
            shadow.width($(this).width());
        }

        $(this).change(update).keyup(update).keydown(update);
        update.apply(this);
        */
  

        $('textarea#review_area_1').autoResize({
          onResize : function() {
            $(this).css({opacity:0.8});
          },
          animateCallback : function() {
            $(this).css({opacity:1});
          },
          animateDuration : 300,
            extraSpace : 40
          });

        $('textarea#bio_area').autoResize({
          //onResize : function() {
          //  $(this).css({opacity:0.8});
          //},
          animateCallback : function() {
            $(this).css({opacity:1});
          },
          animateDuration : 300,
            extraSpace : 10
          });
    });
	
    /*$("form#new_review").submit(function(){
        var review_rating = $('input:radio[name=review[rating]]:checked').val();
        var review_description = $('textarea#review_area_1').val();
	if(review_rating == 0 || jQuery.trim(review_description) == ""){
            return false;
        }else{
            return true;
        }
    });*/
	
});

$(function($) {
    $('.bubble-popup').each(function () {
                    
        // options
        var distance = 10;
        var time = 250;
        var hideDelay = 500;

        var hideDelayTimer = null;

        // tracker
        var beingShown = false;
        var shown = false;
    
        var trigger = $('.trigger', this);
        var popup = $('.popup', this).css('opacity', 0);
        popup.addClass("ui-widget ui-state-default ui-corner-all");
        popup.append('<div class="arrow ui-icon ui-icon-triangle-1-s"></div>');
        var arrow = $('.arrow', popup);

        $([trigger.get(0), popup.get(0)]).mouseover(function () {
            if (hideDelayTimer) clearTimeout(hideDelayTimer);

            if (beingShown || shown) {
                return;
            } else {
                beingShown = true;

                var offset = $(this).offset();
                var height = popup.height()+36;
                            
                var width = popup.width();
                var iWidth = $(this).width();
                            
                var leftCentered = (offset.left+iWidth/2)-width/2;

                arrow.css({
                    top: popup.height()+20,
                    left: width/2
                });

                popup.css({
                    top: (offset.top)-height+distance+"px",
                    left: (leftCentered)+"px",
                    display: 'block'
                }).animate({
                    top: (offset.top-height) + 'px',
                    opacity: 1
                }, time, 'swing', function() {
                    beingShown = false;
                    shown = true;
                });
            }
        }).mouseout(function () {
            if (hideDelayTimer) clearTimeout(hideDelayTimer);
            var offset = $(this).offset();      
            var height = popup.height()+36;
            var width = popup.width();
            var iWidth = $(this).width();
            var leftCentered = (offset.left+iWidth/2)-width/2;
            hideDelayTimer = setTimeout(function () {
                hideDelayTimer = null;
                popup.animate({
                    top: (offset.top-height+distance) + 'px',
                    opacity: 0
                }, time, 'swing', function () {
                    popup.css('display', 'none');
                    shown = false;
                });
            }, hideDelay);
        });
    });
                
});

$(function(){
    if($.browser.msie){
        //$('.MovieTrailerLink').html('<img src="images/viewTrailerBtn.png">');
        $('.MovieTrailerLink').removeClass('gradient-button2');
        
        //$('.trailerLink').html('<img src="/images/viewTrailerBtn.png">');
        $('.trailerLink').removeClass('gradient-button2');
        
        $('#profile_save').html('<input type="image" src="/images/save.jpg" complete="complete"/>').removeClass('gradient-button2');
        
        /*$('#new_comment > .field > .actions.right > .gradient-input-button.ui-corner-all')
            .html('<input type="image" src="/images/postCommentButton.png">')
            .removeClass('gradient-input-button ui-corner-all');*/
        $('.new_comment').each(function(){
            $(this).find(".gradient-input-button")
                .html('<input type="image" src="/images/postCommentButton.png">')
                .removeClass('gradient-input-button ui-corner-all');
        });
            
        //$('.actions.right.gradient-input-button.ui-corner-all')
        //    .html('<input type="image" src="/images/submit.png">')
        //    .removeClass('gradient-input-button ui-corner-all');
            
        //$('#fan_div > .actions.right > .gradient-input-button')
        //    .addClass('ui-corner-all left')
        //    .html('<div class="gradient-input-button ui-corner-all"><input type="submit" value="'+$('#fan_div > .actions.right > .gradient-input-button').html()+'" name="commit" id="comment_submit" class="label"></span></div>');
            
        //$('#fan_div > .actions.left.gradient-input-button.ui-corner-all')
        //    .html('<input type="image" src="/images/submit.png">')
        //    .removeClass('gradient-input-button ui-corner-all');

        //$('#fan_div > .actions.left > .gradient-input-button')
        //    .addClass('ui-corner-all left')
        //    .html('<div class="gradient-input-button ui-corner-all"><input type="submit" value="'+$('#fan_div > .actions.left > .gradient-input-button').html()+'" name="commit" id="comment_submit" class="label"></span></div>');
            
    }else
    if($.browser.safari && !/chrome/.test(navigator.userAgent.toLowerCase())){
        //$('.MovieTrailerLink').html('<img src="/images/viewTrailerBtn.png">');
        //$('.MovieTrailerLink').removeClass('gradient-button');
        
        //$('.actions.right > .gradient-input-button')
        //    .addClass('ui-corner-all left')
        //    .html('<div class="gradient-input-button ui-corner-all"><input type="submit" value="'+$('.actions.right > .gradient-input-button').html()+'" name="commit" id="comment_submit" class="label"></span></div>');
            
        //$('#fan_div > .actions.left > .gradient-input-button')
        //    .addClass('ui-corner-all left')
        //    .html('<div class="gradient-input-button ui-corner-all"><input type="submit" value="'+$('#fan_div > .actions.left > .gradient-input-button').html()+'" name="commit" id="comment_submit" class="label"></span></div>');
            
    }else{
        $('.gradient-button').addClass('ui-corner-all');
        $('.gradient-button').html('<div class="gradient-button ui-corner-all"><span class="label">'+$('.gradient-button').html()+'</span></div>');
        
        //$('.gradient-input-button').addClass('ui-corner-all');
        //var inhtml = $('.gradient-input-button').html();
        //$('.gradient-input-button').html('<div class="gradient-input-button ui-corner-all"><input type="submit" value="'+inhtml+'" name="commit" id="comment_submit" class="label"></div>');
        
        //$('.actions.right > .gradient-input-button')
        //    .addClass('ui-corner-all left')
        //    .html('<div class="gradient-input-button ui-corner-all"><input type="submit" style="font-size: 13px;" value="'+$('.actions.right > .gradient-input-button').html()+'" name="commit" id="comment_submit" class="label"></span></div>');
            
        //$('#fan_div > .actions.left > .gradient-input-button')
        //    .addClass('ui-corner-all left')
        //    .html('<div class="gradient-input-button ui-corner-all"><input type="submit" style="font-size: 13px;" value="'+$('#fan_div > .actions.left > .gradient-input-button').html()+'" name="commit" id="comment_submit" class="label"></span></div>');
            
        $('.gradient-input-button3').addClass('ui-corner-all');
        
    }
});



// Hyperlink Gradient Button 
$(function(){
    $('.gradient-button2').addClass('ui-corner-all');
    
    $('.gradient-button3').addClass('ui-corner-all');
    $('.gradient-button3').html('<div class="gradient-button3 ui-corner-all"><span class="label">'+$('.gradient-button3').html()+'</span></div>');
});


// Star rating steeps
$(function(){
   var rating_steps = 0;
   /*$('#rating-steps > button').button({
            icons: {
                primary: "ui-icon-help"
            }
        });*/
   //$('#seen_already').fadeTo('fast', 0.5);
   
   
   $('#seen_already2').hover(function(){
       $('#seen_already2').css({"color": "#555555"});
   }, function(){
       $('#seen_already2').css({"color": "#aaaaaa"});
   });
   $('#seen_already').hover(function(){
       if(rating_steps == 0) $('#seen_already').css({"color": "#555555"});
       else $('#seen_already').css({"color": "#A8006D"});
   }, function(){
       if(rating_steps == 0) $('#seen_already').css({"color": "#aaaaaa"});
       else $('#seen_already').css({"color": "#D649A5"});
   });
   
   $('#want-to-see').click(function(){
       if(rating_steps == 0){
            $('#seen_already').css({"color": "#D649A5"});
            //$('#seen_already').fadeTo(250, 1.0);
            
            $('#rating-steps > #want-to-see > .gradient-button2')
                .addClass('gradient-button2-gray')
                .removeClass('gradient-button2');
            $('#rating-steps > #want-to-see')
                .addClass('gradient-button2-gray')
                .removeClass('gradient-button2');
            $('#rating-steps > #want-to-see > .gradient-button2-gray > .label').css({
                "background" : "url('/images/tick_mark.png') no-repeat scroll 7px center transparent",
                "padding-left" : "25px"
            });
            $(this).hover(function(){
                $('#rating-steps > #want-to-see > .gradient-button2-gray > .label').html("Not anymore");
                $('#rating-steps > #want-to-see > .gradient-button2-gray > .label').css({
                    "background" : "none",
                    "padding-left" : "10px"
                });
            }, function(){
                $('#rating-steps > #want-to-see > .gradient-button2-gray > .label').html("Want to see");
                $('#rating-steps > #want-to-see > .gradient-button2-gray > .label').css({
                    "background" : "url('/images/tick_mark.png') no-repeat scroll 7px center transparent",
                    "padding-left" : "25px"
                });
            });
            rating_steps = 1;
       }else
       if(rating_steps == 1){
            $('#rating-steps > #want-to-see > .gradient-button2-gray')
                .addClass('gradient-button2')
                .removeClass('gradient-button2-gray');
            $('#rating-steps > #want-to-see')
                .addClass('gradient-button2')
                .removeClass('gradient-button2-gray');
            $('#rating-steps > #want-to-see > .gradient-button2 > .label').css({
                "background" : "none",
                "padding-left" : "10px"
            });
            $(this).hover(function(){
                $('#rating-steps > #want-to-see > .gradient-button2 > .label').html("Want to see");
            }, function(){
                $('#rating-steps > #want-to-see > .gradient-button2 > .label').html("Want to see");
            });
            $('#rating-steps > #want-to-see > .gradient-button2 > .label').html("Want to see");
            
            $('#seen_already').css({"color": "#ccc"});
            //$('#seen_already').fadeTo(250, 0.5);
            rating_steps = 0;
       }
       return false;
   });
   $('#seen_already').click(function(){
       $('#rating-steps').fadeOut("slow", function(){
           //$(".auto-height-div").fadeIn("slow");
           $("#review_area_1").focus();
           
           $("#review_area_1").removeAttr('disabled')
            .removeClass("ui-state-disabled")
            .addClass("ui-state-active");
           $("#new_review").fadeIn("slow");
       });
       return false;
   });
});


$(function(){
   try {
     //$(".tagManager").tagsManager();
   } catch(e){
   }
   $('#personal-info-cast').css({"max-height" : "33px", "overflow": "hidden"});
   var personal_info_cast_height = $('<div></div>').css({
            position:   'absolute',
            top:        -1000,
            left:       -1000,
            width:      ($('#personal-info-cast').width()),
            resize:     'none'
        }).appendTo(document.body).html($('#personal-info-cast').html()).height();
    if(personal_info_cast_height > 65){
        $('#personal-info-cast').after('<div class="right"><a href="#" id="more_personal_info_cast" style="font-size: 11px; font-decoration: none">more...</a></div><div class="clear"></div>');
        $('#more_personal_info_cast').click(function(){
            $(this).remove();
            $('#personal-info-cast').css({"max-height" : "", "overflow": "hidden"});
            return false;
        });
    }
});

var errorIntervalCount = 0;
function enableLoginError(flag){
    $('#login > .login > .heading > div.heading_label').show();
    if(errorIntervalCount < 5){
        var t=setTimeout("enableLoginError(false)", 1000);
        errorIntervalCount++;
    }else{
        errorIntervalCount = 0;
    }
}

var __tmpMsg = "";
function enableLoginError(flag, msg){
    __tmpMsg = msg;
    $('#login > .login > .heading > div.heading_label').show();
    $('#login > .login > .heading > div.heading_label').html(__tmpMsg);
    if(errorIntervalCount < 10){
        var t=setTimeout("enableLoginError2()", 1000);
        errorIntervalCount++;
    }else{
        errorIntervalCount = 0;
    }
}
function enableLoginError2(){
    enableLoginError(false, __tmpMsg);
}

var enableLoginErrorHideCounter = 0;
function enableLoginErrorHide(){
    $("#user_user_profile_attributes_display_name").keypress(function() {
        /*if($('#errors').is(":visible")){
            $('#errors').slideUp(500);
        }*/
        $('#message').html("");
        $('#message').hide();
    });
    $("#user_email").keypress(function() {
        /*if($('#login > .login > .heading > div.heading_label').is(":visible")){
            $('#login > .login > .heading > div.heading_label').slideUp(500);
        }
        if($('#errors').is(":visible")){
            $('#errors').slideUp(500);
        }*/
        $('#message').html("");
        $('#message').hide();
    });
    $("#user_password").keypress(function() {
        /*if($('#login > .login > .heading > div.heading_label').is(":visible")){
            $('#login > .login > .heading > div.heading_label').slideUp(500);
        }
        if($('#errors').is(":visible")){
            $('#errors').slideUp(500);
        }*/
        $('#message').html("");
        $('#message').hide();
    });
    if(enableLoginErrorHideCounter < 5) {
        enableLoginErrorHideCounter++;
        var t=setTimeout("enableLoginErrorHide();", 5000);
    }else{
        enableLoginErrorHideCounter = 0;
    }    
}

function validateEmail(elementValue){  
    var emailPattern = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9][a-zA-Z0-9.-]*[\.]{1}[a-zA-Z]{2,4}$/;  
    return emailPattern.test(elementValue);
}  
     
$(function(){
    $(document.body).ajaxError(function() {
        //$('#login > .login > .heading > div.heading_label').show();
        //$('#login > .login > .heading > div.heading_label').text( 'Invalid email or password!' );
    });
});

function addMovieTrailerClickEvent(){
    $('.trailerLink').click(function(event){
        event.preventDefault();
        $('#trailer').modal({
            minHeight:330,
            minWidth:520,
            containerId:'videoPlayer'
        });
        $f().play();
        return false;
    });

    $('.MovieTrailerLink').click(function(event){
        event.preventDefault();
        movie_id=this.id.split('movie_link_')[1];

        flowplayer("movie_video_"+movie_id, "/flash/flowplayer.commercial-3.2.7.swf", { key: '#$8fe04ea70c52430ec72',logo: {url: '/images/flowplayerLogo.png',fullscreenOnly: false, top: 278, right: 2, opacity: 0.5  },clip: {autoPlay: false, autoBuffering: false  }  });

        $("#movie_"+movie_id).modal({
            minHeight:330,
            minWidth:520,
            containerId:'videoPlayer'
        });
        var player_id="movie_video_"+movie_id;
        $f(player_id).play();
        return false;
    });

    $('.remote_trailerLink').click(function(event){
        event.preventDefault();
        $('#trailer').modal({
            minHeight:330,
            minWidth:560,
            containerId:'videoPlayer'
        });
        $("#player").show();
        return false;
    });

    $('.remote_MovieTrailerLink').click(function(event){
        event.preventDefault();
        movie_id=this.id.split('movie_link_')[1];
        $("#movie_"+movie_id).modal({
            minHeight:330,
            minWidth:560,
            containerId:'videoPlayer'
        });
        //var player_id="movie_video_"+movie_id;

        var remote_video_id = $("#remote_video_id_"+movie_id).val();
        $("#player_"+movie_id).attr("src","http://www.youtube.com/embed/"+remote_video_id+"?wmode=opaque&autoplay=1&modestbranding=1")
        $("#player_"+movie_id).show();
        return false;
    });

}

$(function(){
    if($('#movie_release_date').length <= 0 && $('#top_bar > .headerLeft > .tabs > li.active > a').html() == "Reviews"){
        $('.friendsLink.right').css({"min-height": "187px"});
    }
    /////// TEMP TAB FIX
    if($('#movie_release_date').length == 1 && $('#top_bar > .headerLeft > .tabs > li.active > a').html() == "Reviews"){
        $('#top_bar > .headerLeft > .tabs > li.active').removeClass('active').next().addClass('active');
    }
    /////// TEMP TAB FIX
});

function validate_rating_form(){
  var review_rating = $('#review_rating').val();
  var review_description = $('textarea#review_area_1').val();
  
  $('textarea#review_area_1').removeAttr("placeholder")
  if(review_rating == 0){
    $("#new_review").removeAttr('data-remote');
    return false;
  }else{
    $("#new_review").attr('data-remote',true)
    return true;
  }
}


$(document).ready(function() {
  if($("#logged_in").val() == 0){
    $(".star-rating a").attr("data-remote",true);
    $(".star-rating a").attr("href","/users/sign_in");
    $(".star-rating a").click(function() {
       enableLoginError(registration(), "You need to login");
    });
  }else{
    $(".star-rating a").click(function(){
      if($("#logged_in").val() != 0){
        if($("#rating_text").css("display") == "none"){
          $("#want-to-see").hide();
          $("#want_to_see_div").hide();
          $("#rating_text").fadeIn();
        }
      } 
    });
  }
});


function show_button(cnt){
  $("#not_anymore_"+cnt).show();
}

function hide_button(cnt){
  $("#not_anymore_"+cnt).hide();
}

function show_fan_button(cnt){
  $("#fan_"+cnt).show();
}

function hide_fan_button(cnt){
  $("#fan_"+cnt).hide();
}

var total_invite = 1;
function count_checkbox(th){
  if(th.checked == true){
    if(total_invite > 10){
      alert("You can select 10 per day");
      th.checked = false;
      return false;
    }
    else{
      total_invite++;
    }
  }
  else{
    total_invite--;
  }
}

function send_invitation(){
  var cnt = document.inviteform.invite.length;
  var arr = new Array();
  for(var v = 0; v < cnt; v++){
    if($("#invite_"+v).checked == true){
      arr.push(v);
    }
  }
  if(v.length == 0){
    alert("Please select at least a user to send invitation");
    return false;
  }
}

function check_event_and_submit(evt,id){
  if(evt.keyCode == 13){
    //$("#"+frm).submit(); 
    var comment = $("#comment_"+id).val();
    var parent_id = $("#parent_id_"+id).val();
    $("#comment_comment").val(comment);
    $("#parent_id").val(parent_id);
    //return false;
    $("#comment_form_"+id).submit();
  }
}

function check_event_submit_review_comment(evt,id){
  if(evt.keyCode == 13){
    var comment = $("#review_comment_"+id).val();
    var parent_id = $("#review_parent_id_"+id).val();
    //$("#comment_comment").val(comment);
    //$("#parent_id").val(parent_id);
    $("#review_comment_form_"+id).submit();
  }
}


$(document).ready(function () {
$('.parent').hover(
  function () {
    $('.parent ul.children').show();
    //$('#fshare').hide();
  },function () {
    $('.parent ul.children').hide();			
    //$('#fshare').show();
  }		
);
$('.parent_1').hover(
  function () {
    $('.parent_1 ul.children_1').show();
    //$('#fshare').hide();
  },function () {
    $('.parent_1 ul.children_1').hide();
    //$('#fshare').show();
  }
);

});

var fl = 0;
function show_change_bio(){
  if(fl == 0){
    $('#add_bio').slideDown();
    $('#bio_text').html("Cancel");
    fl = 1;
  }else{
    $('#add_bio').slideUp();
    $('#bio_text').html("Change")
    fl = 0;
  }
}

function validate_email(){
  var email = jQuery.trim($('#email_invite').val());
  var msg = "";
  if(email == ""){
    msg = "Please enter email"
  }
  else if(!validateEmail(email)){
    msg = "Please enter valid email";
  }
  if(msg != ""){
    $("#message").html(msg);
    $("#email_invite_form").removeAttr('data-remote')
    return false;
  }else{
    $("#email_invite_form").attr('data-remote',true)
    return true;
  }
}

function validate_fb_registration(th){
  var provider = $("#user_user_tokens_attributes_0_provider").val();
  if(provider == ""){
    $(th).removeAttr('data-remote');
    $("#errors").html("Registration is currently open through Facebook only. Please click on the 'Register Using Facebook' button above and proceed.");
    $("#errors").show();
    return false;
  }else{
    $("#errors").html("");
    $("#errors").hide();
    $(th).attr('data-remote',true);
  }
}
$(document).ready(function() {
    //Tooltips
    $(".tip_trigger").hover(function(){
        tip = $(this).find('.tip');
        tip.show(); //Show tooltip
    }, function() {
        tip.hide(); //Hide tooltip
    }).mousemove(function(e) {
        tip = $(this).find('.tip');
        var mousex = e.pageX + 20; //Get X coodrinates
        var mousey = e.pageY + 20; //Get Y coordinates
        var tipWidth = tip.width(); //Find width of tooltip
        var tipHeight = tip.height(); //Find height of tooltip

        //Distance of element from the right edge of viewport
        var tipVisX = $(window).width() - (mousex + tipWidth);
        //Distance of element from the bottom of viewport
        var tipVisY = $(window).height() - (mousey + tipHeight);

        if ( tipVisX < 20 ) { //If tooltip exceeds the X coordinate of viewport
            mousex = e.pageX - tipWidth - 40;
        } if ( tipVisY < 20 ) { //If tooltip exceeds the Y coordinate of viewport
            mousey = e.pageY - tipHeight - 20;
        }
        //Absolute position the tooltip according to mouse position
        tip.css({  top: mousey, left: mousex });
    });
});

function disable_button(formid, activate, inactivate){
  $("#"+activate).css("cursor", "pointer");
  $("#"+activate).removeAttr('disabled');

  $("#"+inactivate).css("cursor", "default");
  $("#"+inactivate).attr('disabled', 'disabled');

  $("#"+formid).submit();
}

function slide(){
  self.setInterval("slideshow()", 30000);
}

function slideshow(action){
  if ($("#selected_div")) {
    if ($("#timer").val() == 0) {
      $("#selected_div").val(parseInt($("#selected_div").val()) + 1);
      if ($("#selected_div").val() < total_slide_div) {
        var id = $("#selected_div").val();
      }
      else{
        var id = 0;
        $("#selected_div").val(id);
      }
      if (id == (parseInt(total_slide_div))) {
        $("#selected_div").val(0);
      }
      else{
        $("#selected_div").val(id);
      }
      var div_auto = div_arr[id];
      for(var x = 1; x <= total_slide_div; x++){
        if(div_auto == "slide_div_"+x){
          //$("#"+div_auto).hide().fadeIn(1000);
          $("#"+div_auto).fadeTo(1000, 1);
          $("#"+div_auto).css("z-index", "1000");

          $("#"+(x - 1)).addClass("slide_div_class_active");
        }
        else{
          //$("#slide_div_"+x).hide();
          $("#slide_div_"+x).fadeTo(1000, 0);
          //$("#slide_div_"+x).hide();
          $("#slide_div_"+x).css("z-index", "0px");
          $("#"+(x - 1)).removeClass("slide_div_class_active");
          $("#"+(x - 1)).addClass("slide_div_class")
        }
      }

    }
    else {
      //$("timer").val(parseInt($("#timer").val()) - 1);
      document.getElementById("timer").value = parseInt(document.getElementById("timer").value)-1;
    }
  }
}

function playslide(id){
  play = 0;
  if(id == (parseInt(total_slide_div))){
    $("#selected_div").val(0);
  }else{
    $("#selected_div").val(id);
  }

  var div_auto = div_arr[id];
  for(var x = 1; x <= total_slide_div; x++){
    if(div_auto == "slide_div_"+x){
      //$("#"+div_auto).hide().fadeIn(1000);
      $("#"+div_auto).fadeTo(1000, 1);
      $("#"+div_auto).css("z-index", "1000");

      $("#"+id).addClass("slide_div_class_active");
    }
    else{
      //$("#slide_div_"+x).hide();
      $("#slide_div_"+x).fadeTo(1000, 0);
      //$("#slide_div_"+x).hide();
      $("#slide_div_"+x).css("z-index", "0");

      $("#"+(x - 1)).removeClass("slide_div_class_active");
      $("#"+(x - 1)).addClass("slide_div_class")
    }
  }
  $("#timer").val(1);
}
              
$(function() {
  //var $j = jQuery.noConflict();
  $("ul.info_tabs").tabs("div.panes > div");
  $("ul.dropdown").click(function(){
   $('ul.dropdown ul').removeAttr('style');
  });
  $(".main").click(function(){
   $('ul.dropdown ul').removeAttr('style');
  });
});

  function show_loading_page(){
    var x = (window.innerWidth / 2) - 200;
    var y = 200;
    $("#loading_div").offset({ top: y, left: x})
    $("#loading_div").fadeIn();
  }
  function close_loading_page(){
    $("#loading_div").fadeOut();
  }

  function close_language_hint(){
    $('#language_hint').fadeOut();
    $('ul.dropdown ul').css('visibility','visible');
    //$('#language_select').show();
    $.cookie('muvi_language_selected', 'yes', { expires: 365, path : "/"});
  }


function showCongratulations(super_fan, mega_fan){
  var url = "/show_cangratulations";
  $.post(url,{super_fan:super_fan,mega_fan:mega_fan},function(res){
    $('#badge_success').html(res);
    $('#badge_success').dialog({
      modal: true,
      buttons: { "OK": function() { $(this).dialog("close"); } },
      resizable: false,
      maxHeight: 400,
      width: 636,
      open: function() { $(".ui-dialog-titlebar").hide(); }
    });
    $('#fancybox-outer').css('background','transparent');
    $('#badge_success').parent().css("z-index","5000");
    $('#badge_success').parent().css({'background-image':'url("/images/badge-congratulations.png")', 'background-color':'transparent' , 'border':'0'});
    $('.ui-dialog-buttonpane').css({'width':'614px', 'margin-left':'2px'});

  });
}

