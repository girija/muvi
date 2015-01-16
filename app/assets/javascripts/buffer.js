$(function() {	
	var openBufferSignin = function(ev){
		var height = "270px";
		ev.preventDefault();
		var $signin = "";
		if(ev.currentTarget.id == "form"){
			height = "170px";
			$signin = $('.email-buffer-signin');
			$('.buffer-signin').removeClass('expanded').animate({height: '40px'}, 500);
                } else{                 
			$signin = $('.buffer-signin');
			$('.email-buffer-signin').removeClass('expanded').animate({height: '40px'}, 500);
		}
		var expanded = $signin.hasClass('expanded');

		if (!expanded) {
			$signin.addClass('expanded').animate({
				height: height
			}, 500); //, postOpenSignin);
		} else {
			$signin.removeClass('expanded').animate({
				height: '40px'
			}, 500);
		}
	}
	
        $('.email-signin-button.buffer').click(openBufferSignin);
        $('.signin-button.buffer').click(openBufferSignin);

        var openBlock = function(ev){
                ev.preventDefault();
				var div_id = ev["currentTarget"].id;				
                var $block = $("#"+div_id);
                var expanded = $block.hasClass('expanded');
                if (!expanded) {
                   $block.addClass('expanded').stop().animate({height: '300px'}, 500);
                } else {
                   $block.removeClass('expanded').stop().animate({height: '160px'}, 500);
                }
       }
       

       $('#div_1').hover(openBlock);
       $('#div_2').hover(openBlock);
	   $('#div_3').hover(openBlock);
       $('#div_4').hover(openBlock);
	   $('#div_5').hover(openBlock);
});
