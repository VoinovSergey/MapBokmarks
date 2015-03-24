//
//  TTMapAnnotation.m
//


#import "TTMapAnnotation.h"

@implementation TTMapAnnotation

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate andBookmarkID:(NSManagedObjectID *)bookmarkID {
    self = [super init];
    if (self) {
        self.coordinate = coordinate;
        self.bookmarkID = bookmarkID;
    }
	return self;
}

@end
