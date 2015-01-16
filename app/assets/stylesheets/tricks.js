function getUrlAnchor() {
    var hash = ((window.location.hash).replace(/^#/, ''));
    try {
        return $.browser.mozilla ? hash : decodeURIComponent(hash);
    } catch (error) {
        return hash;
    }
}

$(function() {
     
    if($.browser.msie && $.browser.version == "7.0"){
        var sfiq = $("#search > form > input#q").offset();
        var y = sfiq.top;
        var x = sfiq.left;
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

    $(".auto-height-div").hide();

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
        var $this       = $(this);
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

    });
	
    $("form#new_review").submit(function(){
        var review_rating = $('input:radio[name=review[rating]]:checked').val();
        var review_description = $('textarea#review_area_1').val();
	if(review_rating == 0 || jQuery.trim(review_description) == ""){
            return false;
        }else{
            return true;
        }
    });
	
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
        $('.MovieTrailerLink').html('<img src="http://muvi.com/images/viewTrailerBtn.png">');
        $('.MovieTrailerLink').removeClass('gradient-button');
        
        $('.trailerLink').html('<img src="http://muvi.com/images/viewTrailerBtn.png">');
        $('.trailerLink').removeClass('gradient-button');
        
        $('.actions.right.gradient-input-button.ui-corner-all')
            .html('<input type="image" src="/images/postCommentButton.jpg?1310746789">')
            .removeClass('gradient-input-button ui-corner-all');
            
        $('.actions.gradient-input-button.ui-corner-all')
            .html('<input type="image" src="/images/submit.png">')
            .removeClass('gradient-input-button ui-corner-all');
    }else
    if($.browser.safari && !/chrome/.test(navigator.userAgent.toLowerCase())){
        $('.MovieTrailerLink').html('<img src="http://muvi.com/images/viewTrailerBtn.png">');
        $('.MovieTrailerLink').removeClass('gradient-button');
    }else{
        $('.gradient-button').addClass('ui-corner-all left');
        $('.gradient-button').html('<div class="gradient-button"><span class="label">'+$('.gradient-button').html()+'</span></div>');
    }
});