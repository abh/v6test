/*! Copyright 2010 Ask Bjørn Hansen
    see http://www.v6test.develooper.com/
 */

  v6s.escape_html = function(text) {
    return text.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
  }

  v6s.unescape_html = function(text) {
    return text.replace(/&lt;/g,'<').replace(/&gt;/g,'>').replace(/&amp;/g,'&');
  }

  $.fn.template = function(str, data) {
    var fn = new Function('obj',
      'var p=[],print=function(){p.push.apply(p,arguments);};' +
      'with(obj){p.push(\'' +
      str
        .replace(/[\r\t\n]/g, " ")
        .split("<%").join("\t")
        .replace(/((^|%>)[^\t]*)'/g, "$1\r")
        .replace(/\t==(.*?)%>/g, "',$1,'")
        .replace(/\t=(.*?)%>/g, "', YP.escape_html($1),'")
        .split("\t").join("');")
        .split("%>").join("p.push('")
        .split("\r").join("\\'")
    + "');}return p.join('');");
    return data ? fn(data) : fn;
  };


$(document).ready(function () {
   $('#link-add-site').click(function(event) {
      event.preventDefault();
      $('#add-site-wrapper').show();
      $('#add-site-form').find('input:first').focus();
   });

   var $add_site_form = $("#add-site-form");
   $add_site_form.find('input:submit').click(function(event) {
      event.preventDefault();
      var name = $add_site_form.find('input[name="name"]').val();
      $.getJSON('/account/add',
                { 'token': v6s.token, 'name': name },
                function(data, textStatus) {
                    $('#site_list').html(data.site_list);
                    // console.log("data", data);
                }
      );
   });


   if ($('#tabs').length) {
      var selected = $('#tabs').attr('data-selected') || 0;

      $('#tabs').tabs({
         selected: selected,
         load: function(event, ui) {
            if ($('p.ip64stats').length) {
                  $(ui.panel).find('p.ip64stats').show();
                  $(ui.panel).find('p.ip64stats a').click( function(event) {
                      event.preventDefault();
                      $(ui.panel).find('.ip64stats').show();
                  });
            }
         }
      });
      $('#loading').hide();
      $('#tabs').removeClass('page_flash');
   }

   if ($('#code_config').length) {
       var form_options =
           { success: function(response, status, xhr, $form) {
                          var code = response.code;
                          $('textarea.code').html( v6s.escape_html(code) );
             },
             beforeSubmit: function() {
                 $('textarea.code').html('Loading ...');
             }
           };

       $('#code_config').change(function() {
           $('#code_config').ajaxSubmit(form_options);
       });
   }

   if ($('#site_options').length) {
       var form_options =
           { success: function(response, status, xhr, $form) {
                 if (response.updated) {
                     $('#settings_status').html( 'Saved!' );
                 }
                 else {
                     $('#settings_status').html( response.error || 'Error saving' );
                 }
             },
             beforeSubmit: function(arr, $form, options) {
                 // console.log(arr);
                 arr.push({ name: 'token', 'value': v6s.token});
                 $('#settings_status').html( 'Saving ...' );
             }
           };

       $('#site_options').change(function() {
           $('#site_options').ajaxSubmit(form_options);
       });
   }


});