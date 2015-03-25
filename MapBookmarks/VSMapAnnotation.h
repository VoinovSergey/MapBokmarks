//
//  VSMapAnnotation.h
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreData/CoreData.h>

typedef enum {
    AnnotationStandart = 1,
	AnnotationCarLocation = 2
} AnnotationType;

@interface VSMapAnnotation : NSObject <MKAnnotation>

@property (nonatomic, readwrite ,assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSManagedObjectID * bookmarkID;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate andBookmarkID:(NSManagedObjectID *)bookmarkID;

@end

