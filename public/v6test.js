v6 = {};
v6.hosts   = ['ipv4', 'ipv6', 'ipv64'];
v6.timeout = 3;
v6.api_server = 'http://example.com/';

v6.check_timeout = function() {
   if (v6.images_loaded == v6.images) {
       v6.submit_results();
       return;
   }
   var now = (new Date).getTime();
   if (now - v6.start_timer > (v6.timeout * 1000)) {
       console.log('Timeout');
       v6.submit_results();
   }
   else {
       v6.timer = setTimeout(function() { v6.check_timeout() }, 1000);
   }
};

v6.submit_results = function() {

    var q = "";
    for (var i=0; i < v6.hosts.length; i++) {
        var host = v6.hosts[i];
        q += host + '=';
        if (v6.status[host] && v6.status[host] == 'ok') {
           q += v6.times[host];
        }
        else {
           q += v6.status[host];
        }
        if (i < v6.hosts.length) { q += '&' };
    }

    jQuery.getJSON( v6.api_server + '/c/json?callback=?', q,
      function(json) {
          if (json.ok) { 
             $('#v6test-results').html('Thanks!');
          }
      }
    );
}

v6.check_count = function() {
    if (v6.images_loaded == v6.images) {
        if (v6.timer) clearTimeout(v6.timer);
        v6.check_timeout();
    }
}

v6.test = function() {

   document.write('<div id="v6test"></div><div id="v6test-results"></div>');

   v6.times  = {};
   v6.status = {};

   $(window).load(function() {
      if (v6.hidden) { $('#v6test').hide() }
      $('#v6test').append('Testing ipv4 and ipv6 connectivity ...');
      v6.images = v6.hosts.length;
      v6.images_loaded = 0;
      var img_tags = ""; 
      for (var i=0; i < v6.hosts.length; i++) {
	  var host = v6.hosts[i]; 
	  img_tags += '<img id="v6test_img_' + host + '"'
                              + ' class="v6test_test_img" '
			      + ' src="http://' + host + '.v6test.develooper.com/i/t.gif"'
			      + ' width="1" height="1"><br>';
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


