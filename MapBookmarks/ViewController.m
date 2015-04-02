//
//  ViewController.m
//  MapBookmarks
//
//  Created by Sergey Voinov on 3/23/15.
//  Copyright (c) 2015 Sergey Voinov. All rights reserved.
//

#import "ViewController.h"
#import "SAMHUDView.h"
#import "VSMapAnnotation.h"
#import "AppDelegate.h"
#import "VSDetailsViewController.h"
#import "VSBookmarkListController.h"
#import "RegexKitLite.h"

#define kcMAP_REGION_SIZE 0.1f
#define kcMAP_REGION_SIZE_CLOSE 0.01f

@interface ViewController ()

@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) VSBookmark * selectedBookmark;
@property (nonatomic, strong) VSBookmark * routeBookmark;
@property (nonatomic, assign) BOOL routingMode;
@property (nonatomic, strong) MKPolyline * routeOverlay;
@property (nonatomic, assign) BOOL wasFirstGoodLocationReceived;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSError * error;
    if (![self.fetchedResultsController performFetch:&error]) {
        NSLog(@"Fetch returns error:%@, User info:%@", error, [error userInfo]);
    }
    [self setupGestureRecognaizer];
    [self updateMapAnnotations];
}

# pragma mark Screen navigation flow

- (IBAction)tapOnRouteButton:(id)sender {
    if (self.routingMode) {
        [self.routeButton setTitle:@"Route"];
        self.routingMode = !self.routingMode;
        [self clearRoute];
        self.routeBookmark = nil;
        self.fetchedResultsController = nil;
        [self updateMapAnnotations];
    } else {
        [self performSegueWithIdentifier:@"bookmarkListSegueIdentifier" sender:self];
    }
}

- (void)tapOnDisclosureButton:(id)sender {
    UIButton * button = (UIButton *)sender;
    UIView * parentView = button;
    // Find AnnotationView - parent of disclosure button
    while (! [[parentView class] isSubclassOfClass:[MKAnnotationView class]]) {
        parentView = [parentView superview];
    }
    VSMapAnnotation * annotation = ((MKAnnotationView *)parentView).annotation;
    NSManagedObjectID * bookmarkID = annotation.bookmarkID;
    VSBookmark * bookmark = (VSBookmark *)[self.managedObjectContext existingObjectWithID:bookmarkID
                                                                                    error:nil];
    
    [self openDetailsScreen:bookmark];
}

- (void)openDetailsScreen:(VSBookmark *)bookmark {
    NSError *error = nil;
    if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    self.selectedBookmark = (VSBookmark *)bookmark;
    
    [self performSegueWithIdentifier:@"OpenDetailsSegueIdentifier" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender {
    if ([[segue.destinationViewController class] isSubclassOfClass:[VSDetailsViewController class]]) {
        ViewController * mainScreenController = (ViewController *)sender;
        VSDetailsViewController *vc = [segue destinationViewController];
        vc.bookmark = mainScreenController.selectedBookmark;
        vc.delegate = self;
    } else if ([[[segue destinationViewController] class] isSubclassOfClass:[VSBookmarkListController class]] && [segue.identifier isEqualToString:@"bookmarkListSegueIdentifier"]) {
        DECLARE_WEAK_SELF;
        ((VSBookmarkListController *)[segue destinationViewController]).selectionCellBlock = ^(VSBookmark * bookmark){
            [weak_self goToRouteModeWithBookmark:bookmark];
        };
    } else if ([[[segue destinationViewController] class] isSubclassOfClass:[VSBookmarkListController class]] && [segue.identifier isEqualToString:@"bookmarkListPushSegueIdentifier"]) {
        DECLARE_WEAK_SELF;
        ((VSBookmarkListController *)[segue destinationViewController]).selectionCellBlock = ^(VSBookmark * bookmark){
            [weak_self openDetailsScreen:bookmark];
        };
    }
}

#pragma mark Add pin annotation by long tap on map

- (void)setupGestureRecognaizer
{
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    [self.mapView addGestureRecognizer:longPressGesture];
}

-(void)handleLongPressGesture:(UIGestureRecognizer*)sender
{
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (!self.routingMode) {
            CGPoint point = [sender locationInView:self.mapView];
            CLLocationCoordinate2D coordinate = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
            CLLocation * curLocation = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
            [self addBookmarkOnMapView:curLocation];
        }
    }
}

#pragma mark Location Manager delegate methods

- (CLLocationManager *)locationManager {
    if (_locationManager) {
        return _locationManager;
    }
    
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    
    // Set a movement threshold for new events.
    _locationManager.distanceFilter = 50; // meters
    
    return _locationManager;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSLog(@"Location manager updated status to %i", status);
    if (status == kCLAuthorizationStatusDenied) {
        NSLog(@"Location services denied");
        // show alert that user location won't be displayed until the app gets access in settings
        [self dismissPreviousAlertAndShowAlert];
    } else if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [manager startUpdatingLocation];
        // dismiss alert about location settings
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"User location error = %@", error);
    self.wasFirstGoodLocationReceived = NO;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    NSLog(@"Manager %@, locations %@, selected = %@", manager, locations, self.selectedBookmark);
    CLLocation * userLocation = locations[0];
    if (self.routingMode) {
        [self updateRouteOverlay];
    } else {
        // Any handling of user location changes i.e. centering map to user pin
        // self.mapView.centerCoordinate = userLocation.location.coordinate;
        if (CLLocationCoordinate2DIsValid(userLocation.coordinate) && fabs(userLocation.coordinate.latitude) >= 0.0001 && !self.wasFirstGoodLocationReceived) {
            // set flag that no need the map to follow user location
            self.wasFirstGoodLocationReceived = YES;
            // Move map center to user location at the beginning
            MKCoordinateRegion region;
            MKCoordinateSpan span;
            span.latitudeDelta = kcMAP_REGION_SIZE;
            span.longitudeDelta = kcMAP_REGION_SIZE;
            region.span = span;
            if (CLLocationCoordinate2DIsValid(userLocation.coordinate)) {
                region.center = userLocation.coordinate;
            } else {
                region.center = CLLocationCoordinate2DMake(45.0, 52.0);
            }
            [self.mapView setRegion:region animated:YES];
            [self.mapView regionThatFits:region];
        }
    }
}

#pragma mark Alert

- (void)dismissPreviousAlertAndShowAlert {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self showAlert];
        }];
    } else {
        [self showAlert];
    }
}

- (void)showAlert {
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Location"
                                          message:@"Please verify Privacy Location access for MapBookmarks app in settings if you don't see user location."
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action) {
                                       NSLog(@"Cancel action");
                                   }];
    
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:@"Ok"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action) {
                                   NSLog(@"Dismiss alert");
                                   // Send the user to the Settings for this app
                                   NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                   [[UIApplication sharedApplication] openURL:settingsURL];
                               }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    
    [self.navigationController presentViewController:alertController animated:YES completion:nil];
}

# pragma mark - Update map annotations

- (void)updateMapAnnotations {
    [self.fetchedResultsController performFetch:nil];
    NSArray * bookmarks = self.fetchedResultsController.fetchedObjects;
    NSArray * annotations = [self generateAnnotationsFromBookmarks:bookmarks];
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView addAnnotations:annotations];
}

- (void)addAnnotationForBookmark:(VSBookmark *)bookmark {
    NSError *error = nil;
    if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    VSMapAnnotation * annotation = [[VSMapAnnotation alloc] initWithCoordinate:((CLLocation *)bookmark.coordinates).coordinate andBookmarkID:bookmark.objectID];
    annotation.title = ((VSBookmark *)bookmark).title;
    
    [self.mapView addAnnotation:annotation];
}

- (void)removeAnnotationForBookmark:(VSBookmark *)bookmark {
    VSMapAnnotation * foundAnnotation = nil;
    for (VSMapAnnotation * annotation in self.mapView.annotations) {
        if (![annotation isMemberOfClass:[MKUserLocation class]] && annotation.bookmarkID == bookmark.objectID) {
            foundAnnotation = annotation;
            break;
        }
    }
    if (foundAnnotation != nil) {
        [self.mapView removeAnnotation:foundAnnotation];
    }
}

- (NSArray *)generateAnnotationsFromBookmarks:(NSArray *)bookmarks {
    NSMutableArray * annotations = [[NSMutableArray alloc] initWithCapacity:bookmarks.count];
    for (VSBookmark * bookmark in bookmarks) {
        VSMapAnnotation * annotation = [[VSMapAnnotation alloc] initWithCoordinate:((CLLocation *)bookmark.coordinates).coordinate andBookmarkID:bookmark.objectID];
        annotation.title = ((VSBookmark *)bookmark).title;
        [annotations addObject:annotation];
    }
    return [NSArray arrayWithArray:annotations];
}

- (void)addBookmarkOnMapView:(CLLocation *)location
{
    // Insert Bookmark object into current context. FetchedResultsController callback - didChangeObject will create annotation view for it. Ensure that self.fetchedResultsController is not nil
    if (self.fetchedResultsController == nil) {
        NSLog(@"Error of fetchedResultsController initializing");
    }
    VSBookmark * newBookmark = (VSBookmark *)[NSEntityDescription
                                              insertNewObjectForEntityForName:@"VSBookmark"
                                              inManagedObjectContext:self.managedObjectContext];
    newBookmark.coordinates = location;
    newBookmark.named = NO;
    newBookmark.title = @"Unnamed";
    NSError *error = nil;
    if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    // Move map center to a new bookmark
    [self moveCenterToLocation:location];
}

# pragma mark Annotation View and Overlay View

- (void)mapViewWillStartLocatingUser:(MKMapView *)mapView
{
    // Check authorization status (with class method)
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];

    // User has never been asked to decide on location authorization
    if (status == kCLAuthorizationStatusNotDetermined) {
        NSLog(@"Requesting when in use auth");
        if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [self.locationManager requestWhenInUseAuthorization];
        }
    }
    // User has denied location use (either for this app or for all apps
    else if (status == kCLAuthorizationStatusDenied) {
        NSLog(@"Location services denied");
        // show alert that user location won't be displayed until the app gets access in settings
        [self dismissPreviousAlertAndShowAlert];
        [self.locationManager startUpdatingLocation];
    } else if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
        [self.locationManager startUpdatingLocation];
    }
}

- (MKAnnotationView *) mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    if ([annotation isMemberOfClass:[MKUserLocation class]]) {
        return nil;
    }
    MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:@"currentlocation"];
    if (annotationView == nil) {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"currentlocation"];
    }
    
    annotationView.draggable = YES;
    annotationView.pinColor = MKPinAnnotationColorGreen;
    annotationView.animatesDrop = YES;
    annotationView.canShowCallout = YES;
    // Disclosure button setup as right callout view
    UIButton * disclosureButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [disclosureButton addTarget:self action:@selector(tapOnDisclosureButton:) forControlEvents:UIControlEventTouchUpInside];
    [disclosureButton setTitle:annotation.title forState:UIControlStateNormal];
    annotationView.rightCalloutAccessoryView = disclosureButton;
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    if (newState == MKAnnotationViewDragStateEnding) {
        CLLocationCoordinate2D coordinate = annotationView.annotation.coordinate;
        CLLocation * curLocation = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
        NSManagedObjectID * bookmarkID = ((VSMapAnnotation * )annotationView.annotation).bookmarkID;
        VSBookmark * bookmark = (VSBookmark *)[self.managedObjectContext existingObjectWithID:bookmarkID
                                                                                        error:nil];
        bookmark.coordinates = curLocation;
        NSError *error = nil;
        if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        }
        if (self.routingMode) {
            [self updateRouteOverlay];
        }
    }
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    MKAnnotationView *aV;
    for (aV in views) {
        if ([aV.annotation isKindOfClass:[MKUserLocation class]]) {
            MKAnnotationView* annotationView = aV;
            annotationView.canShowCallout = NO;
            annotationView.enabled = NO;
        }
    }
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
    MKOverlayView* overlayView;
    if ([[overlay class] isSubclassOfClass:[MKPolyline class]]) {
        MKPolylineView  * _routeLineView = [[MKPolylineView alloc] initWithPolyline:overlay];
        _routeLineView.fillColor = [UIColor whiteColor];
        _routeLineView.strokeColor = [UIColor blueColor];
        _routeLineView.lineWidth = 4;
        _routeLineView.lineCap = kCGLineCapSquare;
        
        overlayView = _routeLineView;
    }
    
    return overlayView;
}

#pragma mark - NSFetchedResultsController Delegate

- (void)saveContext {
    NSError *error = nil;
    if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
}

- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext == nil) {
        self.managedObjectContext = [((AppDelegate *)[[UIApplication sharedApplication] delegate]) managedObjectContext];
    }
    return _managedObjectContext;
}

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (_fetchedResultsController == nil) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription
                                       entityForName:@"VSBookmark" inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        
        NSSortDescriptor *sort = [[NSSortDescriptor alloc]
                                  initWithKey:@"title" ascending:NO];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
        
        [fetchRequest setFetchBatchSize:20];
        if (self.routingMode) {
            VSBookmark * bookmark = self.routeBookmark;
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"self == %@", bookmark]];
        }
        [NSFetchedResultsController deleteCacheWithName:@"Root"];
        NSFetchedResultsController *theFetchedResultsController =
        [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                            managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil
                                                       cacheName:@"Root"];
        self.fetchedResultsController = theFetchedResultsController;
        _fetchedResultsController.delegate = self;
    }
    
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self addAnnotationForBookmark:anObject];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self removeAnnotationForBookmark:anObject];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self updateMapAnnotations];
            break;
            
        case NSFetchedResultsChangeMove:
            [self updateMapAnnotations];
            break;
    }
}

# pragma mark - Centering

- (void)moveCenterToLocation:(CLLocation *)location {
    // Move map center to a new bookmark
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    span.latitudeDelta = kcMAP_REGION_SIZE_CLOSE;
    span.longitudeDelta = kcMAP_REGION_SIZE_CLOSE;
    region.span = span;
    region.center = location.coordinate;
    [self.mapView setRegion:region animated:YES];
    [self.mapView regionThatFits:region];
}

- (void)centerInMapBookmark:(VSBookmark *)bookmark {
    [self moveCenterToLocation:bookmark.coordinates];
}

#pragma mark - Build route

- (void)goToRouteModeWithBookmark:(VSBookmark *)bookmark {
    self.routingMode = YES;
    [self.routeButton setTitle:@"Clear route"];
    self.routeBookmark = bookmark;
    
    // Remove and add again a route overlay from user location to bookmark location
    NSArray *routePoints = [self updateRouteOverlay];
    
    // Update map region to view whole route from the start to the end.
    MKCoordinateRegion region = [self calculateRegionForLocations:routePoints];
    [self.mapView setRegion:region animated:YES];
    
    // Recreate fetchedResultsController and update map annotations
    self.fetchedResultsController = nil;
    [self updateMapAnnotations];
}

// Return: NSArray of CLLocation objects
- (NSArray *)updateRouteOverlay {
    NSArray *routePoints = [self calculateRoutePointsFrom:self.mapView.userLocation.location.coordinate to:((CLLocation *)self.routeBookmark.coordinates).coordinate];
    // Remove an old overlay
    [self clearRoute];
    // Add a new overlay for route and save it to property
    self.routeOverlay = [self addPolylineOnMap:routePoints];
    return routePoints;
}

- (void)clearRoute {
    if (self.routeOverlay) {
        [self.mapView removeOverlay:self.routeOverlay];
        self.routeOverlay = nil;
    }
}

- (MKPolyline *)addPolylineOnMap:(NSArray *)routePoints {
    NSInteger numberOfSteps = routePoints.count;

    CLLocationCoordinate2D coordinates[numberOfSteps];
    for (NSInteger index = 0; index < numberOfSteps; index++)
    {
        CLLocation *location = [routePoints objectAtIndex:index];
        CLLocationCoordinate2D coordinate = location.coordinate;
        coordinates[index] = coordinate;
    }
    MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:coordinates count:numberOfSteps];
    [self.mapView addOverlay:polyLine];
    return polyLine;
}

- (MKCoordinateRegion)calculateRegionForLocations:(NSArray *)routePoints {
    MKCoordinateRegion region;
    CLLocationDegrees maxLat = -90.0;
    CLLocationDegrees maxLon = -180.0;
    CLLocationDegrees minLat = 90.0;
    CLLocationDegrees minLon = 180.0;
    for(int idx = 0; idx < routePoints.count; idx++)
    {
        CLLocation* currentLocation = [routePoints objectAtIndex:idx];
        if(currentLocation.coordinate.latitude > maxLat)
            maxLat = currentLocation.coordinate.latitude;
        if(currentLocation.coordinate.latitude < minLat)
            minLat = currentLocation.coordinate.latitude;
        if(currentLocation.coordinate.longitude > maxLon)
            maxLon = currentLocation.coordinate.longitude;
        if(currentLocation.coordinate.longitude < minLon)
            minLon = currentLocation.coordinate.longitude;
    }
    region.center.latitude  = (maxLat + minLat) / 2.0;
    region.center.longitude = (maxLon + minLon) / 2.0;
    region.span.latitudeDelta = kcMAP_REGION_SIZE_CLOSE;
    region.span.longitudeDelta = kcMAP_REGION_SIZE_CLOSE;
    
    region.span.latitudeDelta  = ((maxLat - minLat)<0.0) ? 100.0 : (maxLat - minLat);
    region.span.longitudeDelta = ((maxLon - minLon)<0.0) ? 100.0 : (maxLon - minLon);
    return region;
}

#pragma mark - API request and parsing

/* This function returns array of locations that were parsed from string */
- (NSMutableArray *)decodePolyLine: (NSMutableString *)encoded
{
    [encoded replaceOccurrencesOfString:@"\\\\" withString:@"\\" options:NSLiteralSearch range:NSMakeRange(0, [encoded length])];
    NSInteger len = [encoded length];
    NSInteger index = 0;
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSInteger lat=0;
    NSInteger lng=0;
    while (index < len)
    {
        NSInteger b;
        NSInteger shift = 0;
        NSInteger result = 0;
        do
        {
            b = [encoded characterAtIndex:index++] - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);
        NSInteger dlat = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lat += dlat;
        shift = 0;
        result = 0;
        do
        {
            b = [encoded characterAtIndex:index++] - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);
        NSInteger dlng = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lng += dlng;
        NSNumber *latitude = [[NSNumber alloc] initWithFloat:lat * 1e-5];
        NSNumber *longitude = [[NSNumber alloc] initWithFloat:lng * 1e-5];
        CLLocation *loc = [[CLLocation alloc] initWithLatitude:[latitude floatValue] longitude:[longitude floatValue]];
        [array addObject:loc];
    }
    return array;
}

/* This function sends get request to google API to build route from point to point. Return only points coordinates matching regex */
- (NSArray*)calculateRoutePointsFrom:(CLLocationCoordinate2D) f to: (CLLocationCoordinate2D) t
{
    NSString* saddr = [NSString stringWithFormat:@"%f,%f", f.latitude, f.longitude];
    NSString* daddr = [NSString stringWithFormat:@"%f,%f", t.latitude, t.longitude];
    
    NSString* apiUrlStr = [NSString stringWithFormat:@"http://maps.google.com/maps?output=dragdir&saddr=%@&daddr=%@", saddr, daddr];
    NSURL* apiUrl = [NSURL URLWithString:apiUrlStr];
    NSError* error = nil;
    NSString *apiResponse = [NSString stringWithContentsOfURL:apiUrl encoding:NSASCIIStringEncoding error:&error];
    NSString *encodedPoints = [apiResponse stringByMatching:@"points:\\\"([^\\\"]*)\\\"" capture:1L];
    return [self decodePolyLine:[encodedPoints mutableCopy]];
}

@end
