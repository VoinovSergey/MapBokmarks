//
//  FrankTestEnvironment.m
//  MapBookmarks
//
//  Created by Sergey Voinov on 4/3/15.
//  Copyright (c) 2015 Sergey Voinov. All rights reserved.
//

#import "FrankTestEnvironment.h"
#import <objc/runtime.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@implementation FrankTestEnvironment
+ (void)bypassAcknowledgeLocationServiceWithClass:(Class)clazz {
#if defined(FRANKIFIED)
    [self swizzleToEnableDeviceLocationWithClass:clazz];
#endif
}

+ (void)bypassAcknowledgeUserLocationWithClass:(Class)clazz {
#if defined(FRANKIFIED)
    [self swizzleToConstUserLocationWithClass:clazz];
#endif
}

+ (int)acknowledgeLocationService {
    return kCLAuthorizationStatusAuthorizedWhenInUse;
}

+ (void)swizzleToEnableDeviceLocationWithClass:(Class)clazz {
    SEL originalSelector = @selector(authorizationStatus);
    SEL swizzledSelector = @selector(acknowledgeLocationService);
    
    Method originalMethod = class_getClassMethod([clazz class], originalSelector);
    Method swizzledMethod = class_getClassMethod([FrankTestEnvironment class], swizzledSelector);
    IMP swizzImpl = method_getImplementation(swizzledMethod);
    
    method_setImplementation(originalMethod, swizzImpl);
}

+ (CLLocation *)constUserLocation {
    CLLocation * userLocation = [[CLLocation alloc] initWithLatitude:51.50998 longitude:-0.1337];
    NSLog(@"\nUser location swizzle %@\n", userLocation);
    return userLocation;
}

+ (void)swizzleToConstUserLocationWithClass:(Class)clazz {
    SEL originalSelector = @selector(location);
    SEL swizzledSelector = @selector(constUserLocation);
    
    Method originalMethod = class_getInstanceMethod([clazz class], originalSelector);
    Method swizzledMethod = class_getClassMethod([FrankTestEnvironment class], swizzledSelector);
    IMP swizzImpl = method_getImplementation(swizzledMethod);
    
    method_setImplementation(originalMethod, swizzImpl);
}

@end
