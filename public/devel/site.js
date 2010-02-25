/*! Copyright 2010 Ask Bjørn Hansen
    see http://www.v6test.develooper.com/
 */

$(document).ready(function () {
   $('#link-add-site').click(function(event) {
      event.preventDefault();
      $('#add-site-wrapper').show();
      $('#add-site-form').find('input:first').focus();
   });

   var $add_site_form = $("#add-site-form");
   $add_site_form.find('input:submit').click(function(event) {  
      event.preventDefault();
      var url = $add_site_form.find('input[name="url"]').val();
      $.getJSON('/account/add',
                { 'token': v6s.token, 'url': url },
                function(data, textStatus) { 
                console.log("data", data); }
      );
   });
});