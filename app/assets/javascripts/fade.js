function fader(userOptions) {
op = { //Preset values of the parameter
'CSS_selector':"#fadeanim ul li img", //The CSS selection of the image where you want the sliding effect
'fadeInDuration':600, // Time taken [in ms] for the FadeIn animation on mouse hover
'fadeOutDuration':400, //Time taken for the FadeOut animation
'opacityChange':0.4 //Change of Opacity
};
op = $.extend({}, op, userOptions); //We extend the user Options using jQuery
$(op.CSS_selector).hover(
function() { //This is the hover in function
$(this).stop(); //Stops any animation being done on the button
$(this).css({opacity:1}); //Changes the opacity back to not if not already
$(this).animate({opacity:op.opacityChange},op.fadeOutDuration); //Now animates the opacity to the user defined value
},
function() { //This is the hover out function
$(this).animate({opacity:1},op.fadeInDuration); //Animates the opacity back to 1
}
)
}
$(document).ready( //Now call the function when document is ready
function() {
fader();
}
);

