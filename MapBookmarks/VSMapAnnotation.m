//
//  VSMapAnnotation.m
//  MapBookmarks
//
//  Created by Sergey Voinov on 3/23/15.
//  Copyright (c) 2015 Sergey Voinov. All rights reserved.
//

#import "VSMapAnnotation.h"

@implementation VSMapAnnotation

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate andBookmarkID:(NSManagedObjectID *)bookmarkID {
    self = [super init];
    if (self) {
        self.coordinate = coordinate;
        self.bookmarkID = bookmarkID;
    }
	return self;
}

@end
