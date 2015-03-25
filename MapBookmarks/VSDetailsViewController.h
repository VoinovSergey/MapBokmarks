//
//  VSDetailsViewController.h
//  MapBookmarks
//
//  Created by Sergey Voinov on 3/24/15.
//  Copyright (c) 2015 Sergey Voinov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VSBookmark.h"
#import "SAMHUDView.h"
#import "ViewController.h"

@interface VSDetailsViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray * placeArray;
@property (nonatomic, strong) VSBookmark * bookmark;

@property (nonatomic, strong) SAMHUDView* progressIndicator;

- (IBAction)tapOnTrashButton:(id)sender;
- (IBAction)tapOnBuildRouteButton:(id)sender;

@property (nonatomic, assign) id<MainScreenDelegate> delegate;

@end
