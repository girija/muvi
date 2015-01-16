var JSON;
if (!JSON) {
    JSON = {};
}

(function () {
    'use strict';

    function f(n) {
        // Format integers to have at least two digits.
        return n < 10 ? '0' + n : n;
    }

    if (typeof Date.prototype.toJSON !== 'function') {

        Date.prototype.toJSON = function (key) {

            return isFinite(this.valueOf()) ?
                this.getUTCFullYear()     + '-' +
                f(this.getUTCMonth() + 1) + '-' +
                f(this.getUTCDate())      + 'T' +
                f(this.getUTCHours())     + ':' +
                f(this.getUTCMinutes())   + ':' +
                f(this.getUTCSeconds())   + 'Z' : null;
        };

        String.prototype.toJSON      =
            Number.prototype.toJSON  =
            Boolean.prototype.toJSON = function (key) {
                return this.valueOf();
            };
    }

    var cx = /[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,
        escapable = /[\\\"\x00-\x1f\x7f-\x9f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,
        gap,
        indent,
        meta = {    // table of character substitutions
            '\b': '\\b',
            '\t': '\\t',
            '\n': '\\n',
            '\f': '\\f',
            '\r': '\\r',
            '"' : '\\"',
            '\\': '\\\\'
        },
        rep;


    function quote(string) {


        escapable.lastIndex = 0;
        return escapable.test(string) ? '"' + string.replace(escapable, function (a) {
            var c = meta[a];
            return typeof c === 'string' ? c :
                '\\u' + ('0000' + a.charCodeAt(0).toString(16)).slice(-4);
        }) + '"' : '"' + string + '"';
    }


    function str(key, holder) {
        var i,          // The loop counter.
            k,          // The member key.
            v,          // The member value.
            length,
            mind = gap,
            partial,
            value = holder[key];

        if (value && typeof value === 'object' &&
                typeof value.toJSON === 'function') {
            value = value.toJSON(key);
        }
        if (typeof rep === 'function') {
            value = rep.call(holder, key, value);
        }

        switch (typeof value) {
        case 'string':
            return quote(value);

        case 'number':
            return isFinite(value) ? String(value) : 'null';
        case 'boolean':
        case 'null':
            return String(value);
        case 'object':
            if (!value) {
                return 'null';
            }
            gap += indent;
            partial = [];
            if (Object.prototype.toString.apply(value) === '[object Array]') {
                length = value.length;
                for (i = 0; i < length; i += 1) {
                    partial[i] = str(i, value) || 'null';
                }
                v = partial.length === 0 ? '[]' : gap ?
                    '[\n' + gap + partial.join(',\n' + gap) + '\n' + mind + ']' :
                    '[' + partial.join(',') + ']';
                gap = mind;
                return v;
            }

            if (rep && typeof rep === 'object') {
                length = rep.length;
                for (i = 0; i < length; i += 1) {
                    k = rep[i];
                    if (typeof k === 'string') {
                        v = str(k, value);
                        if (v) {
                            partial.push(quote(k) + (gap ? ': ' : ':') + v);
                        }
                    }
                }
            } else {
                for (k in value) {
                    if (Object.prototype.hasOwnProperty.call(value, k)) {
                        v = str(k, value);
                        if (v) {
                            partial.push(quote(k) + (gap ? ': ' : ':') + v);
                        }
                    }
                }
            }
            v = partial.length === 0 ? '{}' : gap ?
                '{\n' + gap + partial.join(',\n' + gap) + '\n' + mind + '}' :
                '{' + partial.join(',') + '}';
            gap = mind;
            return v;
        }
    }

    if (typeof JSON.stringify !== 'function') {
        JSON.stringify = function (value, replacer, space) {

            var i;
            gap = '';
            indent = '';

            if (typeof space === 'number') {
                for (i = 0; i < space; i += 1) {
                    indent += ' ';
                }

            } else if (typeof space === 'string') {
                indent = space;
            }

            rep = replacer;
            if (replacer && typeof replacer !== 'function' &&
                    (typeof replacer !== 'object' ||
                    typeof replacer.length !== 'number')) {
                throw new Error('JSON.stringify');
            }
            return str('', {'': value});
        };
    }


// If the JSON object does not yet have a parse method, give it one.

    if (typeof JSON.parse !== 'function') {
        JSON.parse = function (text, reviver) {
            var j;
            function walk(holder, key) {

                var k, v, value = holder[key];
                if (value && typeof value === 'object') {
                    for (k in value) {
                        if (Object.prototype.hasOwnProperty.call(value, k)) {
                            v = walk(value, k);
                            if (v !== undefined) {
                                value[k] = v;
                            } else {
                                delete value[k];
                            }
                        }
                    }
                }
                return reviver.call(holder, key, value);
            }

            text = String(text);
            cx.lastIndex = 0;
            if (cx.test(text)) {
                text = text.replace(cx, function (a) {
                    return '\\u' +
                        ('0000' + a.charCodeAt(0).toString(16)).slice(-4);
                });
            }
            if (/^[\],:{}\s]*$/
                    .test(text.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g, '@')
                        .replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']')
                        .replace(/(?:^|:|,)(?:\s*\[)+/g, ''))) {
                j = eval('(' + text + ')');

                return typeof reviver === 'function' ?
                    walk({'': j}, '') : j;
            }


            throw new SyntaxError('JSON.parse');
        };
    }

    /*if (!Object.prototype.toJSONString) {
        Object.prototype.toJSONString = function (filter) {
            try{
				return JSON.stringify(this, filter);
			}catch(E){}
        };
        Object.prototype.parseJSON = function (filter) {
			try{
				return JSON.parse(this, filter);
			}catch(E){}
        };
    }*/

}());

function muvi_widget(divid){
  var url = "http://www.muvi.com";

	$.ajax({
		url: url+"/publish/msn_widget/generate?format=json&divid="+divid, 
		dataType: "jsonp",
                success: jsonpcallback
        });
}

        function redirect_to_muvipage(id){
          try{
            var host = $("#host").val();
            var link = $("#link_"+id).val();
            var url = host+"/msn_embed/movies/"+link;
            window.open(url, '_blank');
            window.focus();
          }catch(E){}
        }

        function jsonpcallback(data){
			var html = "";
			var host = ""
			html += "<div class='parent chrome23 single1 customcontainer black'>";
			/*html += "  <div class='heading alignright' style='display:block;'>";
			html += "    <span class='text'>Muvimeter: Movie Ratings</span>";
			html += "  </div>";
                        */
			html += "  <div class='content'>";
			html += "    <div style='font-family:lucida grande, tahoma, verdana, arial, sans-serif;font-size: 12px;background-color:#FFFFFF; padding:12px 4px 4px 0px'>";

			var divid = "";
			var cnt = 1;
			var border = "";
			var total = JSON.parse(data).items;
			for(var i = 0; i < total.length; i++){
				divid = total[i]["divid"];
				var host = total[i]["host"];
				var meter = total[i]["meter"];
				var link = total[i]["link"];
				var image = total[i]["image"];
				var name = total[i]["name"];
				
				if(cnt == total.length){
				  border = "";
				}
				else{
					border = 'border-bottom: 1px dashed #D3D3D3';
					cnt = cnt + 1;
				}
				
                                 html += "<input type='hidden' id='link_"+i+"' value='"+link+"'>";
                                 html += "<input type='hidden' id='host' value='"+host+"'>";

				 html += "  <DIV style='cursor:pointer;float:left;"+border+"' onclick='redirect_to_muvipage("+i+");'>";
				  html += "    <div style='float:left;width:38px;height:40px'><a href='"+host+"/msn_embed/movies/"+link+"' target='_blank'><img style='border:0px; width:35px; height:35px;' src='"+host+image+"' /></a>&nbsp;</div>";
 
                                  if(name.length > 16){
                                    html += "    <div style='float:left;width:100px;margin-right:4px;'><a href='"+host+"/msn_embed/movies/"+link+"' style='text-decoration:none' target='_blank'>"+name+"</a></div>";
                                  }
                                  else{
  				    html += "    <div style='float:left;width:100px;margin-right:4px; margin-top:7px;'><a href='"+host+"/msn_embed/movies/"+link+"' style='text-decoration:none' target='_blank'>"+name+"</a></div>";
                                  }

				  if(meter >= 60){
					  html += "  <div style='margin-top:7px; background-color: #D8D8D8; border: 1px solid #BECBD4;border-radius: 3px; -moz-border-radius: 3px; -webkit-border-radius: 3px; height: 15px; padding: 0px 2px 2px 1px; width: 77px;float:left;margin-right:2px'>";

					  html += "    <div style='width:"+meter+"%; ; background:url(\""+host+"/images/G-RatingBar.jpg\") repeat-x scroll 0 1px transparent; border-radius:7px; -moz-border-radius: 7px; -webkit-border-radius: 7px; height:17px;'>&nbsp;</div>";
					  html += "  </div>";
				  }
				  else if(meter < 60){
					html += "  <div style='margin-top:7px; background-color: #D8D8D8; border: 1px solid #BECBD4;border-radius: 3px; -moz-border-radius: 3px; -webkit-border-radius: 3px; height: 15px; padding: 0px 2px 2px 1px; width: 77px;float:left;margin-right:3px'>";
					html += "    <div style='width:"+meter+"%; background:url(\""+host+"/images/R-RatingBar.jpg\") repeat-x scroll 0 1px transparent; border-radius:7px; -moz-border-radius: 7px; -webkit-border-radius: 7px; height:17px;'>&nbsp;</div>";
					html += "  </div>";
				  }

				  html += "    <div style='float:left;margin-top:7px;'><a href='"+host+"/msn_embed/movies/"+link+"#critics' target='_blank'>"+meter+"%</a></div>";
				  html += " </DIV>";
				  html += "  <div style='clear:both;height:5px'></div>";
			}
			html += "    <div style='clear:both; height:10px'></div>";
			html += " 	<div id='logo_div' style='width:280px;float:left;margin-top:-5px;'>";
			html += " 	  <span style='color:#ABABAB; font-size:10px; font-weight:bold'>Powered by </span> <img src='"+host+"/images/msn_img.png' style='width:1px; height:1px;'>";
			html += " 	  <div style='clear:both; height:4px'></div>";
			html += " 	  <div style='border-top:1px solid #d3d3d3; float:left; width:80%'>&nbsp;</div>";
			html += " 	  <div style='float:left;margin-top:-12px; margin-left:2px'>";
			html += " 		<a href='"+host+"/msn_embed/home' target='_blank'><img border='0' src='"+host+"/images/logo_small.png'></a>";
			html += " 	  </div>";
			html += " 	</div>";
			html += " 	<div style='clear:both'></div>";
			html += "   </div>";
			html += "  </div>";
			html += " </div>";
			$("#"+divid).html(html);
		}

		



