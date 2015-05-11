function set_class( css_class, ui_id ) {
  $control = $('#' + ui_id);
  $control.addClass( css_class );
  return;
}
function set_background( imageUrl, ui_id ) {
  $control = $('#' + ui_id);
  $control.css({'background-image': 'url(' + imageUrl + ')'});
  return;
}
