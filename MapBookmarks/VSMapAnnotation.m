//
//  VSMapAnnotation.m
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
