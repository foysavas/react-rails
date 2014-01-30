(function($, undefined) {

/**
 * Unobtrusive scripting adapter for React
 *
 * Requires jQuery 1.7.0 or later.
 *
 * Released under the MIT license
 *
 */

  // Cut down on the number of issues from people inadvertently including react_ujs twice
  // by detecting and raising an error when it happens.
  if ( $.react !== undefined ) {
    $.error('react-ujs has already been loaded!');
  }

  // Turbolinks uses page:load
  $(document).on('ready page:load', function () {
    $("[data-react]").each(function() {
      var args = $(this).data();
      var componentName = args['react'];
      delete args['react'];
      React.renderComponent(window[componentName](args), this)
    })
  })

})( jQuery );