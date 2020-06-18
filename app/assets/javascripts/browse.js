// Methods which add/remove elements to the form
$(document).ready(function () {

    var path = window.location.pathname;
    var page = path.split("/").pop();
    if (page === 'subjects' && sessionStorage.open != undefined) {
        if (sessionStorage.open.length != 0) {
            var ids = sessionStorage.open.split(",")
            for (var i = 0; i < ids.length; i++) {
                $('#' + ids[i]).toggle();
                $('#' + ids[i]).prev().removeClass('fa-plus').addClass('fa-minus');
            }
        }
    }

    // Replace the spinner with a go button when searching
    $('body').on('click', '#spin-me', function (e) {
        $(".go_text").toggle();
        $(".fa-spin").toggle();
    });

    // Called when the user chooses a folio from the menu drop-down list
    $('body').on('change', '.choose_folio', function(e) {
        $("#choose_folio").submit();
    });

    $('body').on('click', '.show_hide', function(e) {

        $(this).next().next(".tog").toggle();
        if ($(this).hasClass('fa-plus')) {
            $(this).removeClass('fa-plus').addClass('fa-minus');
            if (sessionStorage.open != null) {
                var ids = sessionStorage.open.split(",")
            } else {
                var ids = new Array();
            }
            ids.push($(this).next(".tog").attr('id'));
            sessionStorage.setItem('open',ids);
        }
        else if ($(this).hasClass('fa-minus')) {
            $(this).removeClass('fa-minus').addClass('fa-plus');

            if (sessionStorage.open != null) {
                var ids = sessionStorage.open.split(",")
            } else {
                var ids = new Array();
            }
            for(var i = 0; i < ids.length; i++) {
                if(ids[i] === $(this).next(".tog").attr('id')) {
                    ids.splice(i, 1);
                }
            }
            sessionStorage.setItem('open',ids);
        }

        if ($(this).text() == 'Show Details') {
            $(this).text('Hide Details');
        }
        else if ($(this).text() == 'Hide Details') {
            $(this).text('Show Details');
        }

    });

    $('body').on('click', '.show_hide_all', function(e) {

        $(".show_hide").next(".tog").toggle();

        if ($(".show_hide").hasClass('fa-plus')) {
            $(".show_hide").removeClass('fa-plus').addClass('fa-minus');
        }
        else if ($(".show_hide").hasClass('fa-minus')) {
            $(".show_hide").removeClass('fa-minus').addClass('fa-plus');
        }

        if ($(this).text() == 'Expand All') {
            $(this).text('Close All');
            if (sessionStorage.open != undefined) {
                if (sessionStorage.open.length != 0) {
                    var ids = sessionStorage.open.split(",")
                    for (var i = 0; i < ids.length; i++) {
                        $('#' + ids[i]).toggle();
                        $('#' + ids[i]).prev().removeClass('fa-plus').addClass('fa-minus');
                        sessionStorage.setItem("open",undefined);
                    }
                }
            }
        }
        else if ($(this).text() == 'Close All') {
            $(this).text('Expand All');
        }
    });
});
