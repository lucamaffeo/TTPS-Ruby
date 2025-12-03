// This file is automatically compiled by the asset pipeline, along with any other files
// in this directory. You're free to add application-wide JavaScript here, and it'll
// automatically be included in the compiled file accessible from the web.
//
// To reference this file in your layout, add <%= javascript_include_tag "application" %>
// to the <head> of your HTML document.
//
// It's generally a good idea to place any JavaScript code that you want to be run
// on every page in here. If you have any JavaScript code that is specific to a
// certain controller or action, you can place it in the corresponding view file
// instead.

//= require jquery3
//= require popper
//= require bootstrap-sprockets
//= require_tree .

document.addEventListener("DOMContentLoaded", function() {
  document.querySelectorAll('.producto-img-zoom').forEach(function(img) {
    img.addEventListener('mouseenter', function() {
      img.style.transform = 'scale(1.12)';
      img.style.transition = 'transform 0.25s';
      img.style.zIndex = 10;
    });
    img.addEventListener('mouseleave', function() {
      img.style.transform = 'scale(1)';
      img.style.zIndex = 1;
    });
  });
});