$('#button_calendar_add').click(function(e){
  if ($('input:radio[name="calendar-radios"]:checked').length > 0) {
    $('#button_calendar_add').val($('input:radio[name="calendar-radios"]:checked').val());
  } else {
    window.alert("Must Select One!");
    e.preventDefault();
  }
});

$('#button_calendar_edit').click(function(){
  $('#calendar_check').modal('show');
});
