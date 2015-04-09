//
//  MKMapView+overlays.m
//  MapBookmarks
//
//  Created by Sergey Voinov on 4/6/15.
//  Copyright (c) 2015 Sergey Voinov. All rights reserved.
//

#import "MKMapView+overlays.h"

@implementation MKMapView (overlays)

- (NSArray *)allOverlaysOnMap {
    return self.overlays;
}

@end
