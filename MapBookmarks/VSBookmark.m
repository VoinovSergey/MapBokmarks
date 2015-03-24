//
//  VSBookmark.m
//  MapBookmarks
//
//  Created by Sergey Voinov on 3/24/15.
//  Copyright (c) 2015 Sergey Voinov. All rights reserved.
//

#import "VSBookmark.h"
#import <MapKit/MapKit.h>

@implementation VSBookmark

@dynamic coordinates;
@dynamic named;
@dynamic title;

@end

@implementation Coordinates

+ (Class)transformedValueClass
{
    return [CLLocation class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(id)value
{
    return [NSKeyedArchiver archivedDataWithRootObject:value];
}

- (id)reverseTransformedValue:(id)value
{
    return [NSKeyedUnarchiver unarchiveObjectWithData:value];
}

@end
