Then (/^I see Bookmark Details$/) {
  wait_until( :timeout => 30, :message => "waited to see a navigation bar titled Bookmarks" ) {
    element_exists( "navigationItemView marked:'Details:'" )
  }
  tableview_selector = "view:'UITableView'"
  wait_for_element_to_exist(tableview_selector)
}