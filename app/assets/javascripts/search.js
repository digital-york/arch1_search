// Check that the search value s greater or equal to 3 characters
// Note that '*' searches for anything at the moment (for testing) - this could be removed from the live code

function validate_advanced_search_fields() {

	let search_form = document.forms["search_form"];
	let search_value = "";
	
	if (search_form["search_term"] != undefined) {
		search_value += search_form["search_term"].value;
	}
	
	if (search_form["all_sterms"] != undefined) {
		search_value += search_form["all_sterms"].value;
	}
	
	if (search_form["exact_sterms"] != undefined) {
		search_value += search_form["exact_sterms"].value;
	}
	
	if (search_form["any_sterms"] != undefined) {
		search_value += search_form["any_sterms"].value;
	}
    
	if (search_value != '*' && search_value.length < 3) {
	    alert("Please enter three or more characters into the search box");
	    return false;
	}
}

function clear_advanced_search_fields() {
	// console.log("Clearing all field ...");
	// document.forms["search_form"]["all_sterms"].value = ""
	$('#all_sterms').val("");
	$('#exact_sterms').val("");
	$('#any_sterms').val("");
	$('#none_sterms').val("");
	$('#search_term').val("");
	$('#archival_repository').val("all");
	$('#end_date').val("");
	$('#start_date').val("");
}