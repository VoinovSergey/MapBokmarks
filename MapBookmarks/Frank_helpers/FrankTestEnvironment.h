//
//  FrankTestEnvironment.h
//  MapBookmarks
//
//  Created by Sergey Voinov on 4/3/15.
//  Copyright (c) 2015 Sergey Voinov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FrankTestEnvironment : NSObject
// Get bool value for bypass/or to not bypass gps location check.
// This prevents from alert dialogue to show up that cannot be dismissed.
+ (void)bypassAcknowledgeLocationServiceWithClass:(Class)clazz;
+ (void)bypassAcknowledgeUserLocationWithClass:(Class)clazz;
@end
