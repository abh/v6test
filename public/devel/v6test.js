/*! Copyright 2009-2010 Ask Bjørn Hansen
    see http://www.v6test.develooper.com/
 */
"use strict";

/*
function(globals){
    "use strict";
    globals.v6 = {};
}(this));
*/

var v6 = v6 || {};
v6.version = "1.25";
v6.hosts   = ['ipv4', 'ipv6', 'ipv64'];
v6.timeout = 4;
v6.api_server = 'http://www.v6test.develooper.com/';

var $target;

v6.check_timeout = function() {
   var now = (new Date).getTime();
   if (now - v6.start_timer > (v6.timeout * 1000)) {
       v6.submit_results();
   }
   else {
       v6.timer = setTimeout(function() { v6.check_timeout() }, 500);
   }
};

v6.submit_results = function() {

    var q = "version=" + v6.version;
    for (var i=0; i < v6.hosts.length; i++) {
        var host = v6.hosts[i];
        q += '&' + host + '=';
        if (v6.status[host] && v6.status[host] == 'ok') {
           var response_time = v6.times[host];
           q += response_time; 
           q += '&' + host + '_ip=' + v6.ip[host];
           if ($target) {
              $target.append(host + ": " + 'ok<br>');
               /* (' + response_time + 'ms) */
           }
        }
        else {
           q += v6.status[host];
           if ($target) {
              $target.append(host + ": failed<br>");
           }
        }
    }

    var v6uq = $.cookie('v6uq');
    if (!v6uq) {
	v6uq = v6.uuid();
    }

    q += '&v6uq=' + v6uq;
    q += '&site=' + v6.site;

    jQuery.getJSON( v6.api_server + '/c/json?callback=?', q,
      function(json) {
          if (json.ok && $target) {
             $target.append('<br>Results submitted, thanks!');
          }

	  var cookie_path = v6.path || '/';
	  $.cookie('v6uq', v6uq, { expires: 10, path: cookie_path });
      }
    );
}

v6.get_ip = function(host) {
   var url = 'http://' + host + '.v6test.develooper.com/c/ip?callback=?';
   jQuery.getJSON( url, "",
      function(json) {
         if (json.ip) {
           v6.ip[host] = json.ip;
         }
      }
   );
}

v6.check_count = function() {
    if (v6.images_loaded == v6.images) {
        for (var i=0; i < v6.hosts.length; i++) {
           var host = v6.hosts[i];
           if (v6.status[host] == 'ok' && !v6.ip[host]) {
              return;
           }
        }    
        if (v6.timer) clearTimeout(v6.timer);
        v6.submit_results();
    }
}

v6.test = function() {

   setTimeout(function() {
      (new Image()).src = "http://" + v6.uuid() + ".mapper.ntppool.org/none";
   }, 3200);

   if (v6.only_once) {
      if ($.cookie('v6uq')) return;
   }

   document.write('<div id="v6test"></div>');

   v6.times  = {};
   v6.status = {};
   v6.ip     = {};

   $(window).load(function() {
      if (v6.target) {
         $target = $(v6.target);
         $target.append('Testing ipv4 and ipv6 connectivity:');
      }
      v6.images = v6.hosts.length;
      v6.images_loaded = 0;
      var img_tags = "";
      for (var i=0; i < v6.hosts.length; i++) {
	  var host = v6.hosts[i]; 
          img_tags += '<img id="v6test_img_' + host + '"'
                       + ' class="v6test_test_img" '
		       + ' src="http://' + host + '.v6test.develooper.com/i/t.gif"'
                       + ' width="1" height="1">';
      }
      $('#v6test').append(img_tags);
      v6.start_timer = (new Date).getTime();

      $('img.v6test_test_img').load(function() {
           var time = (new Date).getTime();
           var id = $(this).attr('id');
	   var host = id.slice(11);
	   v6.times[host] = time - v6.start_timer;
	   v6.status[host] = 'ok';
           $(this).data('isLoaded',true);
	   v6.images_loaded++;
	   v6.check_count();
           v6.get_ip(host);
      });

      $('img.v6test_test_img').error(function(){
           var id = $(this).attr('id');
           var host = id.slice(11);
	   v6.status[host] = 'error';
           v6.images_loaded++;
	   /* $(this).attr('src', '/i/1x1.gif'); */
	   v6.check_count();
      });

      v6.timer = setTimeout(function() { v6.check_timeout() }, 1000);
   });

   /* onload=\'v6.timer["' + host + '"] = (new Date).getTime();\' */
};

v6.uuid = function() {

  var chars = '0123456789abcdef'.split('');

   var uuid = [], rnd = Math.random, r;
   uuid[8] = uuid[13] = uuid[18] = uuid[23] = '-';
   uuid[14] = '4'; // version 4

   for (var i = 0; i < 36; i++) {
      if (!uuid[i]) {
         r = 0 | rnd()*16;
         uuid[i] = chars[(i == 19) ? (r & 0x3) | 0x8 : r & 0xf];
      }
   }

   return uuid.join('');
}
