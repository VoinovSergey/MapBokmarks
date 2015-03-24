//
//  ViewController.m
//  MapBookmarks
//
//  Created by Sergey Voinov on 3/23/15.
//  Copyright (c) 2015 Sergey Voinov. All rights reserved.
//

#import "ViewController.h"
#import "SAMHUDView.h"
#import "TTMapAnnotation.h"
#import <FacebookSDK/FacebookSDK.h>
#import "VSBookmark.h"
#import "AppDelegate.h"
#import "VSDetailsViewController.h"
#import "VSBookmarkListController.h"
#import "RegexKitLite.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    self.mapView.showsUserLocation = TRUE;
    // Do any additional setup after loading the view, typically from a nib.
    [self setupGestureRecognaizer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //self.popoverPresentationController
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    self.mapView.centerCoordinate = userLocation.location.coordinate;
    
    [self updateMapAnnotations];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    
}

- (void)setupGestureRecognaizer
{
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    [self.mapView addGestureRecognizer:longPressGesture];
}

-(void)handleLongPressGesture:(UIGestureRecognizer*)sender
{
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGPoint point = [sender locationInView:self.mapView];
        CLLocationCoordinate2D coordinate = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
        CLLocation * curLocation = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
        [self updateMapView:curLocation];
    }
}

- (void)updateMapView:(CLLocation *)location
{
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    span.latitudeDelta = 0.01f;
    span.longitudeDelta = 0.01f;
    
    CLLocationCoordinate2D coordinate = location.coordinate;
    
    region.span = span;
    region.center = coordinate;
    
    NSManagedObjectContext * context = [((AppDelegate *)[[UIApplication sharedApplication] delegate]) managedObjectContext];
    NSManagedObject *newBookmark = [NSEntityDescription
                                    insertNewObjectForEntityForName:@"VSBookmark"
                                    inManagedObjectContext:context];
    ((VSBookmark *)newBookmark).coordinates = location;
    ((VSBookmark *)newBookmark).named = NO;
    ((VSBookmark *)newBookmark).title = @"Unnamed";
    
    [self.mapView setRegion:region animated:YES];
    [self.mapView regionThatFits:region];
}

- (void)updateMapAnnotations {
    [self.fetchedResultsController performFetch:nil];
    NSLog(@"self.fetchedResultsController %@\n ", [self.fetchedResultsController sections]);
    NSObject<NSFetchedResultsSectionInfo> * bookmarks = [[self.fetchedResultsController sections] objectAtIndex:0];
    NSArray * annotations = [self generateAnnotationsFromBookmarks:bookmarks.objects];
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView addAnnotations:annotations];
}

- (void)addAnnotationForBookmark:(VSBookmark *)bookmark {
    [self.managedObjectContext save:nil];
    TTMapAnnotation * annotation = [[TTMapAnnotation alloc] initWithCoordinate:((CLLocation *)bookmark.coordinates).coordinate andBookmarkID:bookmark.objectID];
    annotation.title = ((VSBookmark *)bookmark).title;
    
    [self.mapView addAnnotation:annotation];
}

- (void)removeAnnotationForBookmark:(VSBookmark *)bookmark {
    TTMapAnnotation * foundAnnotation = nil;
    for (TTMapAnnotation * annotation in self.mapView.annotations) {
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
        TTMapAnnotation * annotation = [[TTMapAnnotation alloc] initWithCoordinate:((CLLocation *)bookmark.coordinates).coordinate andBookmarkID:bookmark.objectID];
        annotation.title = ((VSBookmark *)bookmark).title;
        [annotations addObject:annotation];
    }
    return [NSArray arrayWithArray:annotations];
}

- (MKAnnotationView *) mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    //[self setupGestureRecognaizer];
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
    annotationView.calloutOffset = CGPointMake(-5, 5);
    annotationView.canShowCallout = YES;
    UIButton * disclosureButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [disclosureButton addTarget:self action:@selector(tapOnDisclosureButton:) forControlEvents:UIControlEventTouchUpInside];
    [disclosureButton setTitle:annotation.title forState:UIControlStateNormal];
    annotationView.rightCalloutAccessoryView = disclosureButton;
    return annotationView;
}

- (void)tapOnDisclosureButton:(id)sender {
    NSLog(@"%@", sender);
    UIButton * button = (UIButton *)sender;
    NSLog(@" %@", button.titleLabel.text);
    UIView * parentView = button;
    while (! [[parentView class] isSubclassOfClass:[MKAnnotationView class]]) {
        parentView = [parentView superview];
    }
    TTMapAnnotation * annotation = ((MKAnnotationView *)parentView).annotation;
    NSManagedObjectID * bookmarkID = annotation.bookmarkID;
    VSBookmark * bookmark = (VSBookmark *)[self.managedObjectContext existingObjectWithID:bookmarkID
                                                    error:nil];
    
    NSLog(@"Location to bookmarks saved = %@\n Bookmark ID = %@", bookmark.coordinates, bookmarkID);
    
    [self openDetailsScreen:bookmark];
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
    if (newState == MKAnnotationViewDragStateEnding)
    {
        CLLocationCoordinate2D coordinate = annotationView.annotation.coordinate;
        CLLocation * curLocation = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
        //[self retriveLocationDescriptionForCoordinate:curLocation.coordinate];
    }
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    MKAnnotationView *aV;
    for (aV in views)
    {
        if ([aV.annotation isKindOfClass:[MKUserLocation class]])
        {
            MKAnnotationView* annotationView = aV;
            annotationView.canShowCallout = NO;
            annotationView.enabled = NO;
        }
    }
}

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
    //[mapView selectAnnotation:self.annotationView animated:FALSE];
}

- (void)openDetailsScreen:(VSBookmark *)bookmark {
    [self.managedObjectContext save:nil];
    
    self.selectedBookmark = (VSBookmark *)bookmark;
    
    [self performSegueWithIdentifier:@"OpenDetailsSegueIdentifier" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender {
    if ([[segue.destinationViewController class] isSubclassOfClass:[VSDetailsViewController class]]) {
        ViewController * mainScreenController = (ViewController *)sender;
        VSDetailsViewController *vc = [segue destinationViewController];
        vc.bookmark = mainScreenController.selectedBookmark;
    } else if ([[[segue destinationViewController] class] isSubclassOfClass:[VSBookmarkListController class]] && [segue.identifier isEqualToString:@"bookmarkListSegueIdentifier"]) {
        NSLog(@"list open\n");
        ((VSBookmarkListController *)[segue destinationViewController]).selectionCellBlock = ^(VSBookmark * bookmark){
            [self goToRouteModeWithBookmark:bookmark];
        };
    }
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    MKOverlayView* overlayView = nil;
    
    
    MKPolylineView  * _routeLineView = [[MKPolylineView alloc] initWithPolyline:overlay];
    _routeLineView.fillColor = [UIColor whiteColor];
    _routeLineView.strokeColor = [UIColor blueColor];
    _routeLineView.lineWidth = 4;
    _routeLineView.lineCap = kCGLineCapSquare;
    
    
    overlayView = _routeLineView;
    
    return overlayView;
}

#pragma mark - NSFetchedResultsController Delegate
- (NSFetchedResultsController *)fetchedResultsController {
    
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    self.managedObjectContext = [((AppDelegate *)[[UIApplication sharedApplication] delegate]) managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"VSBookmark" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sort = [[NSSortDescriptor alloc]
                              initWithKey:@"title" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    [fetchRequest setFetchBatchSize:20];
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil
                                                   cacheName:@"Root"];
    self.fetchedResultsController = theFetchedResultsController;
    _fetchedResultsController.delegate = self;
    
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

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
}

- (void)reloadAnnotations {
    
}

- (void)goToRouteModeWithBookmark:(VSBookmark *)bookmark {
    self.routingMode = YES;
    [self.routeButton setTitle:@"Clear route"];
    
    NSArray *routes = [self calculateRoutesFrom:self.mapView.userLocation.location.coordinate to:((CLLocation *)bookmark.coordinates).coordinate];
    NSInteger numberOfSteps = routes.count;
    
    CLLocationCoordinate2D coordinates[numberOfSteps];
    for (NSInteger index = 0; index < numberOfSteps; index++)
    {
        CLLocation *location = [routes objectAtIndex:index];
        CLLocationCoordinate2D coordinate = location.coordinate;
        coordinates[index] = coordinate;
    }
    MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:coordinates count:numberOfSteps];
    self.route = polyLine;
    [self.mapView addOverlay:polyLine];
    
    MKCoordinateRegion region;
    CLLocationDegrees maxLat = -90.0;
    CLLocationDegrees maxLon = -180.0;
    CLLocationDegrees minLat = 90.0;
    CLLocationDegrees minLon = 180.0;
    for(int idx = 0; idx < routes.count; idx++)
    {
        CLLocation* currentLocation = [routes objectAtIndex:idx];
        if(currentLocation.coordinate.latitude > maxLat)
            maxLat = currentLocation.coordinate.latitude;
        if(currentLocation.coordinate.latitude < minLat)
            minLat = currentLocation.coordinate.latitude;
        if(currentLocation.coordinate.longitude > maxLon)
            maxLon = currentLocation.coordinate.longitude;
        if(currentLocation.coordinate.longitude < minLon)
            minLon = currentLocation.coordinate.longitude;
    }
    region.center.latitude     = (maxLat + minLat) / 2.0;
    region.center.longitude    = (maxLon + minLon) / 2.0;
    region.span.latitudeDelta = 0.01;
    region.span.longitudeDelta = 0.01;
    
    region.span.latitudeDelta  = ((maxLat - minLat)<0.0)?100.0:(maxLat - minLat);
    region.span.longitudeDelta = ((maxLon - minLon)<0.0)?100.0:(maxLon - minLon);
    [self.mapView setRegion:region animated:YES];
}

- (IBAction)tapOnRouteButton:(id)sender {
    if (self.routingMode) {
        [self.routeButton setTitle:@"Route"];
        self.routingMode = !self.routingMode;
        [self clearRoute];
    } else {
        [self performSegueWithIdentifier:@"bookmarkListSegueIdentifier" sender:self];
    }
}

- (void)clearRoute {
    [self.mapView removeOverlay:self.route];
}

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

-(NSArray*) calculateRoutesFrom:(CLLocationCoordinate2D) f to: (CLLocationCoordinate2D) t
{
    NSString* saddr = [NSString stringWithFormat:@"%f,%f", f.latitude, f.longitude];
    NSString* daddr = [NSString stringWithFormat:@"%f,%f", t.latitude, t.longitude];
    
    NSString* apiUrlStr = [NSString stringWithFormat:@"http://maps.google.com/maps?output=dragdir&saddr=%@&daddr=%@", saddr, daddr];
    NSURL* apiUrl = [NSURL URLWithString:apiUrlStr];
    //NSLog(@"api url: %@", apiUrl);
    NSError* error = nil;
    NSString *apiResponse = [NSString stringWithContentsOfURL:apiUrl encoding:NSASCIIStringEncoding error:&error];
    NSString *encodedPoints = [apiResponse stringByMatching:@"points:\\\"([^\\\"]*)\\\"" capture:1L];
    return [self decodePolyLine:[encodedPoints mutableCopy]];
}

@end
