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
    
    MKMapPoint * pointsArray = malloc(sizeof(CLLocationCoordinate2D)*2);
    pointsArray[0] = MKMapPointForCoordinate(userLocation.location.coordinate);
    pointsArray[1] = MKMapPointForCoordinate(CLLocationCoordinate2DMake(0.03, 0.04));
    
    MKPolyline *  routeLine = [MKPolyline polylineWithPoints:pointsArray count:2];
    
    [self.mapView addOverlay:routeLine];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    [self updateMapView:locations[0]];
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
    [context save:nil];
    
    [self updateMapAnnotations];
    [self.mapView setRegion:region animated:YES];
    [self.mapView regionThatFits:region];
}

- (void)updateMapAnnotations {
    NSArray * bookmarks = [[_fetchedResultsController sections] objectAtIndex:0];
    NSArray * annotations = [self generateAnnotationsFromBookmarks:bookmarks];
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView addAnnotations:annotations];
}

- (void)addAnnotationForBookmark:(VSBookmark *)bookmark {
    TTMapAnnotation * annotation = [[TTMapAnnotation alloc] initWithCoordinate:((CLLocation *)bookmark.coordinates).coordinate andBookmarkID:bookmark.objectID];
    annotation.title = ((VSBookmark *)bookmark).title;
    
    [self.mapView addAnnotation:annotation];
}

- (void)removeAnnotationForBookmark:(VSBookmark *)bookmark {
    TTMapAnnotation * foundAnnotation = nil;
    for (TTMapAnnotation * annotation in self.mapView.annotations) {
        if (annotation.bookmarkID == bookmark.objectID) {
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
    NSManagedObjectContext * context = [((AppDelegate *)[[UIApplication sharedApplication] delegate]) managedObjectContext];
    VSBookmark * bookmark = (VSBookmark *)[context existingObjectWithID:bookmarkID
                                                    error:nil];
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
    
    self.selectedBookmark = (VSBookmark *)bookmark;
    [self performSegueWithIdentifier:@"OpenDetailsSegueIdentifier" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender {
    if ([[sender class] isSubclassOfClass:[ViewController class]]) {
        ViewController * mainScreenController = (ViewController *)sender;
        VSDetailsViewController *vc = [segue destinationViewController];
        vc.bookmark = mainScreenController.selectedBookmark;
    }
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    MKOverlayView* overlayView = nil;
    
    
    MKPolylineView  * _routeLineView = [[MKPolylineView alloc] initWithPolyline:overlay];
    _routeLineView.fillColor = [UIColor whiteColor];
    _routeLineView.strokeColor = [UIColor blueColor];
    _routeLineView.lineWidth = 15;
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

@end
