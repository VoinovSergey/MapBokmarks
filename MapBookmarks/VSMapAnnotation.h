//
//  VSMapAnnotation.h
//  MapBookmarks
//
//  Created by Sergey Voinov on 3/23/15.
//  Copyright (c) 2015 Sergey Voinov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreData/CoreData.h>

@interface VSMapAnnotation : NSObject <MKAnnotation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSManagedObjectID * bookmarkID;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate andBookmarkID:(NSManagedObjectID *)bookmarkID;

@end

