//
//  VSDetailsViewController.m
//  MapBookmarks
//
//  Created by Sergey Voinov on 3/24/15.
//  Copyright (c) 2015 Sergey Voinov. All rights reserved.
//

#import "VSDetailsViewController.h"
#import "ViewController.h"
#import "AFNetworking.h"
#import "AFHTTPRequestOperationManager.h"
#import <MapKit/MapKit.h>
#import "AppDelegate.h"

#define ClientId @"BZXGWMJYKEG0PFMDOFYCJUFTXVGQR1NSAIZFHVVY0JQM1EVE"
#define ClientSecret @"MC4HMGP4R44KCQLHLFJVP5EO4DVDPBJCP0IJOJ5RKWDCU51G"

@implementation VSDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.bookmark.named) {
        self.tableView.separatorColor = [UIColor clearColor];
    } else {
        [self retriveLocationDescriptionForCoordinate:((CLLocation *)self.bookmark.coordinates).coordinate];
    }
}

#pragma mark Table methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.bookmark.named = YES;
    self.bookmark.title = self.placeArray[indexPath.row];
    self.tableView.separatorColor = [UIColor clearColor];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.bookmark.named) {
        return 0;
    }
    if ([self.placeArray count] == 0) {
        return 1;
    }
    return [self.placeArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.bookmark.named) {
        return 60;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView * headerView = nil;
    if (self.bookmark.named) {
        headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 768, 60)];
        headerView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:0.5];
        UIButton * showPlacesButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [showPlacesButton addTarget:self action:@selector(makeUnnamedAndShowPlaces) forControlEvents:UIControlEventTouchUpInside];
        [showPlacesButton setTitle:@"Load nearby places" forState:UIControlStateNormal];
        [headerView addSubview:showPlacesButton];
        showPlacesButton.frame = CGRectMake(300, 10, 200, 40);
    }
    return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"DetailsCellIdentifier"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DetailsCellIdentifier"];
    }
    if (self.bookmark.named) {
        cell.textLabel.text = @"";
    } else {
        if ([self.placeArray count] == 0) {
            cell.textLabel.text = @"No found any places using API";
        } else {
            cell.textLabel.text = self.placeArray[indexPath.row];
        }
    }
    return cell;
}

# pragma mark - Action

- (IBAction)tapOnTrashButton:(id)sender {
    [self showAlert];
}

- (IBAction)tapOnBuildRouteButton:(id)sender {
    NSLog(@"Build route");
    [self.delegate goToRouteModeWithBookmark:self.bookmark];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)tapOnCenterInMapButton:(id)sender {
    NSLog(@"Center in map");
    [self.delegate centerInMapBookmark:self.bookmark];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)makeUnnamedAndShowPlaces {
    self.bookmark.named = NO;
    self.tableView.separatorColor = [UIColor lightGrayColor];
    [self retriveLocationDescriptionForCoordinate:((CLLocation *)self.bookmark.coordinates).coordinate];
}

#pragma mark Remove Alert

- (void)showAlert {
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Attention."
                                          message:@"Please confirm removing a bookmark"
                                          preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *resetAction = [UIAlertAction
                                  actionWithTitle:@"Delete"
                                  style:UIAlertActionStyleDestructive
                                  handler:^(UIAlertAction *action)
                                  {
                                      NSLog(@"Reset action");
                                      // Delete NSManagedObject
                                      NSManagedObjectContext * context = [((AppDelegate *)[[UIApplication sharedApplication] delegate]) managedObjectContext];
                                      [context deleteObject:self.bookmark];
                                      
                                      [((AppDelegate *)[[UIApplication sharedApplication] delegate]) saveContext];
                                      
                                      [self.navigationController popViewControllerAnimated:YES];
                                  }];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action) {
                                       NSLog(@"Cancel action");
                                   }];
    
    [alertController addAction:resetAction];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

# pragma mark Get places using API

- (void)retriveLocationDescriptionForCoordinate:(CLLocationCoordinate2D)coordinate
{
    if (self.progressIndicator == nil) {
        self.progressIndicator = [[SAMHUDView alloc] initWithTitle:@"Loading" loading:YES];
    }
    
    [self.view addSubview:self.progressIndicator];
    
    // Following URL should work but returns 500 error code now. Foursquare Venues API problem. Used google API instead
    //NSString *urlString = [NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/search?ll=%f,%f&radius=1000&client_id=%@&client_secret=%@", coordinate.latitude, coordinate.longitude, ClientId, ClientSecret];
    
    NSString *urlString = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/geocode/json?latlng=%f,%f&sensor=true", coordinate.latitude, coordinate.longitude];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    DECLARE_WEAK_SELF;
    [manager GET:urlString parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"JSON: %@, %@", responseObject, [responseObject class]);
        NSMutableArray * placeArray = [[NSMutableArray alloc] initWithCapacity:5];
        NSArray * results = [responseObject objectForKey:@"results"];
        if (results != nil) {
            for (NSDictionary * place in results) {
                NSString * formattedAddress = [place objectForKey:@"formatted_address"];
                if (formattedAddress != nil) {
                    [placeArray addObject:formattedAddress];
                }
            }
        }
        [weak_self.progressIndicator removeFromSuperview];
        weak_self.placeArray = placeArray;
        [weak_self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        [weak_self.progressIndicator removeFromSuperview];
    }];
}

@end
