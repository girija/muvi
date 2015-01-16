/*$(function() {
  var faye = new Faye.Client('http://192.168.1.22:9292/faye');
  faye.subscribe("/home/index", function(res) {    
      var data = eval(res);
      console.log(data);
      var html = '';
      html += '<div data-time="1" class="activity">';
      html +=    '<a class="pull-left" href="#"><img style="height: 140px;" src="'+data[0]["object"][0]["image"].url+'" class="media-object img-rounded"></a>';
      html +=     '<div class="media-body" style="min-height:140px;">';
      html +=       '<h5 class="media-heading"> '+data[0]["object"][0]["displayName"]+'</h5>';
      html +=       '<a href="#">'+data[0]["actor"][0].displayName+'</a> '+ data[0].verb + ' '+data[0]["object"][0]["displayName"];
      html +=       '<br>';
      //html +=       'Do you want to recommend?';

      if(data.length > 1){
        html +=       'Do you want to recommend?';
        html +=       '<div class="btn-group">';
        html +=       '  <a class="btn btn-warning" href="#">Yes</a>';
        html +=       '  <a class="btn btn-warning" href="#">No</a>';
        html +=       '</div>';
      }
      else{
        if(data[0]["verb"] == "seen"){
          html +=       'Ask for recommendation';
          html +=       '<div class="btn-group">';
          html +=       '  <a class="btn btn-success" href="#">Ask</a>';
          html +=       '</div>';
        }else if(data[0]["verb"] == "want to see"){
          html +=       '<br>';
          html +=       '<div class="btn-group">';
          html +=       '</div>';
        }
      }
      //html +=       '  <a class="btn btn-warning" href="#">Recommend</a>';
      //html +=       '  <a class="btn btn-warning" href="#">No</a>';
      html +=     '</div>';
      html +=     '<hr>';
      html +=   '</div>';

      if(data.length > 1){
        $(html).hide().prependTo("#seen_activity .items").css({opacity:0}).slideDown("100").animate({opacity:1},"100");
      }else{
        $(html).hide().prependTo("#wanna_see_activity .items").css({opacity:0}).slideDown("100").animate({opacity:1},"100");
      }

  });

});*/
                                              
 $(document).ready(function($) {
    try {
    $("#reviews").tabs({ spinner: '<img src="/images/spinner.gif"/>' });
   //$('.star').rating({readOnly: false,required: true});
    $('input:text[placeholder]').placeholderLabel();
    $('#review_description').limit('250','#reviewCharsLeft');
    } catch (err){}

    //$("#q").autocomplete({source: '/autocomplete', minLength: 3});
    $("#pagination a").live("click", function() {
       $.getScript(this.href); return false;
     });

    $("#coming_soon_sort").live("change", function() {
       $.get('/coming_soon_movies', 'sort='+ $('#coming_soon_sort').val(), null, "script");
       return false;
     });
});

function critics_reviews_sort(movie_id, value) {
  var url = '/critics_reviews?id=' + movie_id + '&sort=' + value ;
  $.getScript(url); return false;
}


function go_to_tab(index){
  $("#reviews").tabs("select", index );
  window.location.hash = '#reviews';

}



function popupCenter(url, width, height, name) {
  var left = (screen.width/2)-(width/2);
  var top = (screen.height/2)-(height/2);
  return window.open(url, name, "menubar=no,toolbar=no,status=no,width="+width+",height="+height+",toolbar=no,left="+left+",top="+top);
}


function registration() {
  $('#registration').html('');
  $('#registration').modal({minHeight: 450, minWidth: 636, containerId: 'register_from' });
  return false;
}



function login() {
  $('#registration').html('');
  $('#registration').modal({minHeight: 434, minWidth:631, containerId: 'login_from'});
  return false;
}



$(document).ready(function($) {
  $("a.popup").click(function(e) {
    popupCenter($(this).attr("href"), $(this).attr("data-width"), $(this).attr("data-height"), "authPopup");
    e.stopPropagation(); return false;
  });
});


$(document).ready(function(){

   $('.trailerLink').click(function(event){
        event.preventDefault();
       $('#trailer').modal({minHeight: 330, minWidth:520, containerId: 'videoPlayer' });
        $f().play();
        return false;
    });
    $('.MovieTrailerLink').click(function(event){
        event.preventDefault();
        movie_id = this.id.split('movie_link_')[1];
        $("#movie_"+movie_id).modal({minHeight: 330, minWidth:520, containerId: 'videoPlayer' });
        var player_id = "movie_video_"+ movie_id;
        $f(player_id).play();
        return false;
    });

 });

