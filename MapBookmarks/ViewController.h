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

@interface ViewController : UIViewController<MKMapViewDelegate, CLLocationManagerDelegate>

@property(nonatomic, retain) IBOutlet MKMapView * mapView;
@property (strong, nonatomic) CLLocationManager *locationManager;

@end

