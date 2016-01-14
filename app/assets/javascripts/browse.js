// Methods which add/remove elements to the form
$(document).ready(function () {

    // Called when the user chooses a folio from the menu drop-down list
    $('body').on('change', '.choose_folio', function(e) {
        $("#choose_folio").submit();
    });

    $('body').on('click', '.show_hide', function(e) {
        $(this).next(".tog").toggle();
        if ($(this).hasClass('fa-plus')) {
            $(this).removeClass('fa-plus').addClass('fa-minus');
        }
        else if ($(this).hasClass('fa-minus')) {
            $(this).removeClass('fa-minus').addClass('fa-plus');
        }

        if ($(this).text() == 'Show Details') {
            $(this).text('Hide Details');
        }
        else if ($(this).text() == 'Hide Details') {
            $(this).text('Show Details');
        }

    });
});
