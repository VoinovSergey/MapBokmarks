Feature: 
  Open the app and initaial tests

Scenario: Bookmarks open
  Given I launch the app using iOS 8.2 and the ipad simulator
  When I touch "Bookmarks"
  Then I see Bookmarks list

Scenario: Long tap
  Given I launch the app using iOS 8.2 and the ipad simulator
	When I made long tap on map
	Then I see a bookmark pin added

Scenario: Route to bookmark
  Given I launch the app using iOS 8.2 and the ipad simulator
	When I made long tap on map
	Then I see a bookmark pin added
	When I touch "Route"
	  And I tap on first bookmark in popup