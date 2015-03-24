//
//  VSBookmark.h
//  MapBookmarks
//
//  Created by Sergey Voinov on 3/24/15.
//  Copyright (c) 2015 Sergey Voinov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface VSBookmark : NSManagedObject

@property (nonatomic, strong) id coordinates;
@property (nonatomic, readwrite) BOOL named;
@property (nonatomic, strong) NSString * title;

@end

@interface Coordinates : NSValueTransformer

@end
