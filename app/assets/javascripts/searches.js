// Pop-up for the image zoom
function popup(page, folio_image) {

    page = page + "?folio_id=" + folio_image

    var popup_id = Math.floor(Math.random() * 100000) + 1;

    var popupWidth = 0;
    var popupHeight = 0;
    var top = 0;
    var left = 0;

    popupWidth = 1200;
    popupHeight = 800;
    left = (screen.width - popupWidth) / 2;

    window.open(page, "image_zoom_large_" + popup_id, 'status = 1, location = 1, top = ' + top + ', left = ' + left + ', height = ' + popupHeight + ', width = ' + popupWidth + ', scrollbars=yes');
}

// Check that the search value s greater or equal to 3 characters
// Note that '*' searches for anything at the moment (for testing) - this could be removed from the live code
function validate_search_field() {

    var search_value = document.forms["search_form"]["search_box"].value;

    if (search_value != '*' && search_value.length < 3) {
        alert("Please enter three or more characters into the search box");
        return false;
    }
}
