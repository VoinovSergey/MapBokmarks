Then (/^I see Bookmarks list$/) {
  wait_until( :timeout => 30, :message => "waited to see a navigation bar titled Bookmarks" ) {
    element_exists( "navigationItemView marked:'Bookmarks'" )
  }
  tableview_selector = "view:'UITableView'"
  wait_for_element_to_exist(tableview_selector)
}

When (/^I tap on first bookmark in popup$/) {
  cell_selector = "view:'UITableViewCell' index:0"
  touch(cell_selector)
  wait_for_nothing_to_be_animating()
}

Then (/^I see a route on map$/) {
	map_selector = "view:'MKMapView'"
	wait_until_with_buffer(timeout: 10, message: "Unexpected number of overlays on map. Expected 1)") {
      overlays = frankly_map(map_selector, 'allOverlaysOnMap')[0]
      overlays && overlays.count == 1
  	}
}