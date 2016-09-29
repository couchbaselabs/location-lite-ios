//
//  ViewController.m
//  LocationLite
//
//  Created by Pasin Suriyentrakorn on 9/29/16.
//  Copyright © 2016 Couchbase. All rights reserved.
//

#import "ViewController.h"
#import <CouchbaseLite/CouchbaseLite.h>
#import <CoreLocation/CoreLocation.h>


@interface ViewController () <CLLocationManagerDelegate>

@property (nonatomic, strong) CBLManager *manager;
@property (nonatomic, strong) CBLDatabase *database;
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSError *error;
    CBLManagerOptions options = {NO, NSDataWritingFileProtectionCompleteUntilFirstUserAuthentication};
    self.manager = [[CBLManager alloc] initWithDirectory:[CBLManager defaultDirectory]
                                                 options:&options
                                                   error:&error];
    
    if (!self.manager) {
        NSLog(@"Cannot create a CBL manager: %@", error);
        return;
    }
    
    self.database = [self.manager databaseNamed:@"db" error:&error];
    if (!self.database) {
        NSLog(@"Cannot create or get a database: %@", error);
        return;
    }
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.allowsBackgroundLocationUpdates = YES;
    self.locationManager.delegate = self;
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestAlwaysAuthorization];
    } else {
        [self.locationManager startUpdatingLocation];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.locationManager startUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    for (CLLocation *location in locations) {
        CBLDocument *doc = [self.database createDocument];
        NSDictionary *props = @{
                                @"latitude" : @(location.coordinate.latitude),
                                @"longitude" : @(location.coordinate.longitude),
                                @"timestamp": [CBLJSON JSONObjectWithDate:location.timestamp]};
        NSError *error;
        if (![doc putProperties:props error:&error]) {
            NSLog(@" > Cannot save location into the database: %@", error);
        } else {
            NSLog(@" > %@, %@ at %@", doc.properties[@"latitude"], doc.properties[@"longitude"], doc.properties[@"timestamp"]);
        }
    }
}

@end
