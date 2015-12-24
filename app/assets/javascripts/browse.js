// Methods which add/remove elements to the form
$(document).ready(function () {

    // Called when the user chooses a folio from the menu drop-down list
    $('body').on('change', '.choose_folio', function(e) {
        var id = $(this).val();
        var input = $("<input>").attr("type", "hidden").attr("name", "folio").val(id);
        $("#choose_folio").append($(input));
        $("#choose_folio").submit();
    });

    $('body').on('click', '.show_hide', function(e) {
        //$(this)
        $(this).next(".tog").toggle();
    });
});
