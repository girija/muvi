  //var url = window.location
  //var url_arr = url.toString().split("/") 
  //var name = (url_arr[url_arr.length - 1]).split(".");
  //window.location = 'http://192.168.2.8:3000/movies/'+name[0]+'/muvimeter/';
  var url = window.location.pathname;
  var filename = url.substring(url.lastIndexOf('/')+1);
  var name = filename.split(".");
  var muvi_name = name[0].toLowerCase();

  var url = 'http://192.168.2.8:3040/movies/'+muvi_name+'/muvimeter/';
function iecheck() {
  if (navigator.platform == "Win32" && navigator.appName == "Microsoft Internet Explorer" && window.attachEvent) {
    var rslt = navigator.appVersion.match(/MSIE (\d+\.\d+)/, '');
    var iever = (rslt != null && Number(rslt[1]) >= 5.5 && Number(rslt[1]) <= 7 );
  }
  return iever;
}

MyXssMagic = new function() {
  var BASE_URL = 'http://192.68.2.8:3040/movies/i-am/muvimeter';
  //var STYLESHEET = BASE_URL + "xss_magic.css"
  var CONTENT_URL = '192.168.2.8:3040/javascripts/muvimeter.js';
  //var ROOT = 'my_xss_magic';

  function requestStylesheet(stylesheet_url) {
    stylesheet = document.createElement("link");
    stylesheet.rel = "stylesheet";
    stylesheet.type = "text/css";
    stylesheet.href = stylesheet_url;
    stylesheet.media = "all";
    document.lastChild.firstChild.appendChild(stylesheet);
  }

  function requestContent( local ) {
    var script = document.createElement('script');
    // How you'd pass the current URL into the request
    // script.src = CONTENT_URL + '&url=' + escape(local || location.href);
    script.src = CONTENT_URL;
    document.getElementsByTagName('head')[0].appendChild(script);
  }

	this.init = function() {
	  this.serverResponse = function(data) {
	    if (!data) return;
	    var div = document.getElementById(ROOT);
	    var txt = "";
	    for (var i = 0; i < data.length; i++) {
	      if (txt.length > 0) { txt += ", "; }
	      txt += data[i];
	    }
	    div.innerHTML = "<strong>Names:</strong> " + txt;  // assign new HTML into #ROOT
	    div.style.display = 'block'; // make element visible
	    div.style.visibility = 'visible'; // make element visible
	  }
	
	  requestStylesheet(STYLESHEET);
	  document.write("<div id='" + ROOT + "' style='display: none'></div>");
	  requestContent();
	  var no_script = document.getElementById('no_script');
	  if (no_script) { no_script.style.display = 'none'; }
	}
}
MyXssMagic.init();
