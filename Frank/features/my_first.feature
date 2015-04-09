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
	Then I see a route on map

Scenario: Routing mode button
  Given I launch the app using iOS 8.2 and the ipad simulator
  When I touch "Route"
	And I tap on first bookmark in popup
  Then I see a route on map
	And I should see a "Clear route" button
  When I touch "Clear route"
  Then I see no routes on map
    And I should see a "Route" button

Scenario: Pin touch
  Given I launch the app using iOS 8.2 and the ipad simulator
  When I touch "Unnamed"
    And I touch a pin
  Then I see Bookmark Details