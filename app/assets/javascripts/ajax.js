 function add_more_row(host){
   var total_section = document.getElementById("total_sections").value;
   $.post('/admin/movie/addmore/'+(parseInt(total_section)+1), function(data) {
      var newdiv = document.createElement("div");
      newdiv.className = "actor";
      newdiv.innerHTML = data
      var parentdiv = document.getElementById("actors_crews")
      parentdiv.appendChild(newdiv);

      var head= document.getElementsByTagName('head')[0];
      var script= document.createElement('script');
      script.type= 'text/javascript';
      script.src= 'http://'+host+'/javascripts/ajax.js';
      head.appendChild(script);

      var head= document.getElementsByTagName('head')[0];
      var script= document.createElement('script');
      script.type= 'text/javascript';
      script.src= 'https://ajax.googleapis.com/ajax/libs/jquery/1.5.1/jquery.min.js';
      head.appendChild(script);

      var head= document.getElementsByTagName('head')[0];
      var script= document.createElement('script');
      script.type= 'text/javascript';
      script.src= 'https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.10/jquery-ui.min.js';
      head.appendChild(script);

      $("#total_sections").val(parseInt(total_section)+ 1);
   });
 }

 function delete_row(sub){
   var subdiv = document.getElementById(sub);
   subdiv.parentNode.removeChild(subdiv);

 }

 function swapCells(idA,idB,div_prefix){
   var cellA=document.getElementById(div_prefix+idA);
   var cellB=document.getElementById(div_prefix+idB);
   if(cellA&&cellB)
   {
     var temp=cellA.innerHTML;
     cellA.innerHTML=cellB.innerHTML;
     cellB.innerHTML=temp;
   }
 }


 $(function() {
   $( "#actors_crews" ).sortable();
 });

  $(document).ready(function() {
    $(".moviecastName").autocomplete({
      source: '/celebrityAutocomplete',
      select: function( event, ui ) {
      $(this).val(ui.item.label);
      $(this).prev().val( ui.item.value );
      return false;}
    });
  });                  

 var trailer_id_array = new Array;
 function validate_video_checkbox(id){
   var existing_trailer = $("#total_trailer").val();
   for(var j = 0; j < existing_trailer; j++){
     if($("#movie_video_attributes_"+j+"_default_video").attr('checked') == true){
       trailer_id_array.push("movie_video_attributes_"+j+"_default_video");
     }
   }
   trailer_id_array.push(id);
   for(var k = 0; k < trailer_id_array.length; k++){
     if(id != trailer_id_array[k]){
       $("#"+trailer_id_array[k]).removeAttr('checked');
     }
   }
 }


 var poster_id_array = new Array;
 function validate_poster_checkbox(id){
   var existing_poster = $("#total_poster").val();
   for(var j = 0; j < existing_poster; j++){
     if($("#movie_poster_attributes_"+j+"_default_poster").attr('checked') == true){
       poster_id_array.push("movie_poster_attributes_"+j+"_default_poster");
     }
   }
   poster_id_array.push(id);
   for(var k = 0; k < poster_id_array.length; k++){
     if(id != poster_id_array[k]){
       $("#"+poster_id_array[k]).removeAttr('checked');
     }
   }
 }

$(document).ready(function() {
  function split( val ) {
    return val.split( /,\s*/ );
  }
  function extractLast( term ) {
    return split( term ).pop();
  }
  var posterTags = ["poster","still","ontheset", "profilepic","twitpic","dating","friends","paparazzi","funny","fashion","airport","young","family", "makeup","god","politics","cricket"];
  var videoTags = ["fullmovie", "trailer", "scene", "dialogue", "song", "qwiki", "interview", "funny", "concert"];
	
  $(".admin_home_page_div input[id^=muvimeter_item_], .admin_home_page_div input[id^=trendingnow_item_], .admin_home_page_div input[id^=tweeterbuzz_item_], .admin_home_page_div input[id^=hot_today_item_],.admin_home_page_div input[id^=featured_movie]").autocomplete({
    source:'/movieAutocomplete',
    minLength:2,
    select: function( event, ui ) {
      $("#id_"+$(this).attr("id")).val(ui.item.id);
    }
  })
   $('.movieAutocomplete').live("keydown.autocomplete", function() {
     $(this).autocomplete({
       source:'/movieAutocomplete',
       minLength:2,
       select: function( event, ui ) {
         $(this).next().val(ui.item.id);
       }
     });
   });
   $( ".movieAutocompleteMulti" )
   .bind( "keydown", function( event ) {
     if ( event.keyCode === $.ui.keyCode.TAB && $( this ).data( "autocomplete" ).menu.active ) {
       event.preventDefault();
     }
   })
   .autocomplete({
     source: function( request, response ) {
       $.getJSON( "/movieAutocomplete", {
         term: extractLast( request.term )
       }, response );
     },
     search: function() {
       var term = extractLast( this.value );
       if ( term.length < 2 ) {
         return false;
       }
     },
     focus: function() {
	return false;
     },
     select: function( event, ui ) {
       var terms = split( this.value );
       // remove the current input
       terms.pop();
       // add the selected item
       terms.push( ui.item.value );
       // add placeholder to get the comma-and-space at the end
       terms.push( "" );
       this.value = terms.join( ", " );
       return false;
     }
   });
   $( ".starAutocompleteMulti" )
   .bind( "keydown", function( event ) {
     if ( event.keyCode === $.ui.keyCode.TAB && $( this ).data( "autocomplete" ).menu.active ) {
       event.preventDefault();
     }
   })
   .autocomplete({
     source: function( request, response ) {
       $.getJSON( "/celebrityAutocomplete", {
         term: extractLast( request.term )
       }, response );
     },
     search: function() {
       var term = extractLast( this.value );
       if ( term.length < 2 ) {
         return false;
       }
     },
     focus: function() {
        return false;
     },
     select: function( event, ui ) {
       var terms = split( this.value );
       // remove the current input
       terms.pop();
       // add the selected item
       terms.push( ui.item.label );
       // add placeholder to get the comma-and-space at the end
       terms.push( "" );
       this.value = terms.join( ", " );
       return false;
     }
   });
    $( ".posterAutocomplete" )
   .bind( "keydown", function( event ) {
     if ( event.keyCode === $.ui.keyCode.TAB && $( this ).data( "autocomplete" ).menu.active ) {
       event.preventDefault();
     }
   })
   .autocomplete({
     source: function( request, response ) {
       response( $.ui.autocomplete.filter(posterTags, extractLast( request.term ) ) );
     },
     focus: function() {
        return false;
     },
     select: function( event, ui ) {
       var terms = split( this.value );
       // remove the current input
       terms.pop();
       // add the selected item
       terms.push( ui.item.value );
       // add placeholder to get the comma-and-space at the end
       terms.push( "" );
       this.value = terms.join( ", " );
       return false;
     }
   });
   $( ".videoAutocomplete" )
   .bind( "keydown", function( event ) {
     if ( event.keyCode === $.ui.keyCode.TAB && $( this ).data( "autocomplete" ).menu.active ) {
       event.preventDefault();
     }
   })
   .autocomplete({
     source: function( request, response ) {
       response( $.ui.autocomplete.filter(videoTags, extractLast( request.term ) ) );
     },
     focus: function() {
        return false;
     },
     select: function( event, ui ) {
       var terms = split( this.value );
       // remove the current input
       terms.pop();
       // add the selected item
       terms.push( ui.item.value );
       // add placeholder to get the comma-and-space at the end
       terms.push( "" );
       this.value = terms.join( ", " );
       return false;
     }
   });

  
  $(".admin_home_page_div input[id^=featured_celebrity], .admin_home_page_div input[id^=celebrity_tweet_item_],.admin_home_page_div input[id^=theater], .admin_home_page_div input[id^=nextweek], .admin_home_page_div input[id^=celeb_trending]").autocomplete({
    source:'/home_celebrityAutocomplete',
    minLength:2,
    select: function( event, ui ) {
      $("#id_"+$(this).attr("id")).val(ui.item.id);
    }
  })

  $(".admin_home_page_div input[id^=featured_member]").autocomplete({
    source:'/userAutocomplete',
    minLength:2,
    select: function( event, ui ) {
      $("#id_"+$(this).attr("id")).val(ui.item.id);
    }
  })

  $(".admin_home_page_div input[id^=featured_topten]").autocomplete({
    source:'/toptenAutocomplete',
    minLength:2,
    select: function( event, ui ) {
      $("#id_"+$(this).attr("id")).val(ui.item.id);
    }
  })
    $(".clearIT").live("click", function() {
        $(this).parent().remove();
    });

});
function clearIT(){
 $('.movieAutocomplete:first').val('');
 $("input[name='related_movies_id[]']:first").val('');
}
function appendMore() {
  var box = $('<div><label for="">&nbsp;</label><input type="text" class="movieAutocomplete"  name="related_movies[]"> <input type="hidden" name="related_movies_id[]">  <select name="relation_type[]"><option>Sequel</option><option>Remake</option><option>Similar Plot</option><option>Other</option></select>&nbsp;<a href="#r" class="clearIT" >Remove</a><div class="clear"></div></div>');
  $('#related').append(box);
}

function fetchReviews(){
  var link = $("#movie_rotten_tomatoes_link").val();
  $.post("/rottenReviews", {link: link},
    function(data){
      $.each( data, function(i, l){
        $("#add_review > a").click();
        $(".critics_review:last input[name='critics_name[]']").val(data[i]["name"]);
        $(".critics_review:last textarea").val(data[i]["description"]);
        $(".critics_review:last input[type=hidden]").val(data[i]["id"]);
        $(".critics_review:last input[name$='[link]']").val(data[i]["link"]);
        $(".critics_review:last select").val(data[i]["score"]);
     });
    }, "json");
}

