When (/^I made long tap on map$/) {
	map_selector = "view:'MKMapView'"
	tap_and_hold(map_selector)
}

Then (/^I see a bookmark pin added$/) {
	pin_selector = "view:'MKPinAnnotationView' marked:'Unnamed'"
	wait_for_element_to_exist(pin_selector)
}
