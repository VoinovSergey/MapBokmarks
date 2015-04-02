//
//  ViewController.h
//  MapBookmarks
//
//  Created by Sergey Voinov on 3/23/15.
//  Copyright (c) 2015 Sergey Voinov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "VSBookmark.h"

@protocol MainScreenDelegate <NSObject>

- (void)goToRouteModeWithBookmark:(VSBookmark *)bookmark;
- (void)centerInMapBookmark:(VSBookmark *)bookmark;

@end

@interface ViewController : UIViewController<MKMapViewDelegate, CLLocationManagerDelegate, MainScreenDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) IBOutlet MKMapView * mapView;
@property (nonatomic, strong) IBOutlet UIBarButtonItem * routeButton;

- (IBAction)tapOnRouteButton:(id)sender;

@end



