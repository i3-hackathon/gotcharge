//
//  DashBoardViewController.m
//  GotCharge
//
//  Created by Hemen Chhatbar on 1/9/15.
//  Copyright (c) 2015 appforcause. All rights reserved.
//

#import "DashBoardViewController.h"
#import "RNFrostedSidebar.h"
#import "BMWClient.h"
#import "BMWVehicle.h"
#import "KAProgressLabel.h"
#import <MapKit/MapKit.h>
#import <MapKit/MKAnnotation.h>
#import "ChargepointClient.h"
#import "Annotation.h"

@interface DashBoardViewController ()
@property (nonatomic, strong) NSMutableIndexSet *optionIndices;
@property (nonatomic, strong) BMWClient         *bmwClient;
@property (nonatomic, strong) ChargepointClient *chargePointClient;

@property (weak, nonatomic) IBOutlet KAProgressLabel *batteryLevelProgress;
@property (weak, nonatomic) IBOutlet KAProgressLabel *rangeLevelProgress;
@property (retain, nonatomic) IBOutlet MKMapView *mapView;
@property(nonatomic, retain) CLLocationManager *locationManager;
@property (strong,nonatomic) BMWVehicle *vehicleStats;

@end

@implementation DashBoardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.optionIndices = [NSMutableIndexSet indexSetWithIndex:1];
    self.bmwClient = [[BMWClient alloc] init];
    self.chargePointClient = [[ChargepointClient alloc] init];
    self.chargePointClient.delegate = self;
    
    [self.chargePointClient chargeStationsWithSuccess:^(NSArray *stations) {
        NSLog(@"success");
        
    } failure:^(NSError *error) {
         NSLog(@"failure");
    }];
     
    NSLog(@"dash view controlled view did load");
    
    self.batteryLevelProgress.progressLabelVCBlock = ^(KAProgressLabel *label, CGFloat progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [label setText:[NSString stringWithFormat:@"%.0f%%", (progress*100)]];
        });
    };
    
    [self.batteryLevelProgress setBackBorderWidth: 10.0];
    [self.batteryLevelProgress setFrontBorderWidth: 9.8];
    [self.batteryLevelProgress setColorTable: @{
                                  NSStringFromProgressLabelColorTableKey(ProgressLabelTrackColor):[UIColor redColor],
                                  NSStringFromProgressLabelColorTableKey(ProgressLabelProgressColor):[UIColor greenColor]
                                  }];
    [self.batteryLevelProgress setProgress:0.4];
    
    
    self.rangeLevelProgress.progressLabelVCBlock = ^(KAProgressLabel *label, CGFloat progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [label setText:[NSString stringWithFormat:@"%.0f%%", (progress*100)]];
        });
    };
    
    [self.rangeLevelProgress setBackBorderWidth: 10.0];
    [self.rangeLevelProgress setFrontBorderWidth: 9.8];
    [self.rangeLevelProgress setColorTable: @{
                                                NSStringFromProgressLabelColorTableKey(ProgressLabelTrackColor):[UIColor redColor],
                                                NSStringFromProgressLabelColorTableKey(ProgressLabelProgressColor):[UIColor greenColor]
                                                }];
    [self.rangeLevelProgress setProgress:0.6];
    
    // *********************************************************
    
      self.vehicleStats = [BMWVehicle currentVehicle];
    self.vehicleStats = [BMWVehicle currentVehicleWithSuccess:^(BMWVehicle *vehicle) {
        [self.batteryLevelProgress setProgress:[vehicle lastBatteryLevel]/100];
        [self.rangeLevelProgress   setProgress:[vehicle lastRange]/100];
    } failure:^(NSError *error) {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
    }];
    
    //***********************************************************
    
    self.mapView.delegate = self;
    [self.mapView setMapType:MKMapTypeStandard];
    [self.mapView setZoomEnabled:YES];
    [self.mapView setScrollEnabled:YES];
    
    
    
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [self.locationManager startUpdatingLocation];
    //NSLog(@"%@", [self deviceLocation]);
    
    //View Area
  /* MKCoordinateRegion region = { { 0.0, 0.0 }, { 0.0, 0.0 } };
    region.center.latitude = 37.7833; //self.locationManager.location.coordinate.latitude;
    region.center.longitude = 122.4167; //self.locationManager.location.coordinate.longitude;
    region.span.longitudeDelta = 0.005f;
    region.span.longitudeDelta = 0.005f;
    [_mapView setRegion:region animated:YES];*/
    
    
    MKCoordinateRegion startupRegion;
    startupRegion.center = CLLocationCoordinate2DMake(37.7833, -122.4167);
    startupRegion.span = MKCoordinateSpanMake(0.2, 0.297129);
    startupRegion.span.longitudeDelta = 0.005f;
    startupRegion.span.longitudeDelta = 0.005f;
    [self.mapView setRegion:startupRegion animated:YES];
    
    CLLocationDistance fenceDistance = 300;
   
    CLLocationCoordinate2D circleMiddlePoint = CLLocationCoordinate2DMake(37.773575, -122.403352);
    MKCircle *circle = [MKCircle circleWithCenterCoordinate:circleMiddlePoint radius:fenceDistance];
    [self.mapView addOverlay: circle];

    
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id < MKOverlay >)overlay
{
    MKCircleRenderer *circleR = [[MKCircleRenderer alloc] initWithCircle:(MKCircle *)overlay];
    circleR.fillColor = [UIColor greenColor];
    
    return circleR;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - RNFrostedSidebarDelegate

- (void)sidebar:(RNFrostedSidebar *)sidebar didTapItemAtIndex:(NSUInteger)index {
    NSLog(@"Tapped item at index %i",index);
    
    if (index == 2) {
        [sidebar dismissAnimated:YES completion:nil];
    }
//    [self.bmwClient getRangeWithcompletionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//        NSLog(@"response recieved for getRange: data '%@'  error: '%@'", data, [error description]);
//    }];
  
}



- (void)sidebar:(RNFrostedSidebar *)sidebar didEnable:(BOOL)itemEnabled itemAtIndex:(NSUInteger)index {
    if (itemEnabled) {
        [self.optionIndices addIndex:index];
    }
    else {
        [self.optionIndices removeIndex:index];
    }
}

#pragma mark - FrostedMenuBarTap

- (void)launchSideBarMenu {
    
    NSArray *images = @[
                        [UIImage imageNamed:@"gear"],
                        [UIImage imageNamed:@"profile"],
                        [UIImage imageNamed:@"star"],
                        ];
    NSArray *colors = @[
                        [UIColor colorWithRed:240/255.f green:159/255.f blue:254/255.f alpha:1],
                        [UIColor colorWithRed:126/255.f green:242/255.f blue:195/255.f alpha:1],
                        [UIColor colorWithRed:119/255.f green:152/255.f blue:255/255.f alpha:1],
                        ];
    
    RNFrostedSidebar *callout = [[RNFrostedSidebar alloc] initWithImages:images selectedIndices:self.optionIndices borderColors:colors];
    //    RNFrostedSidebar *callout = [[RNFrostedSidebar alloc] initWithImages:images];
    callout.delegate = self;
    //    callout.showFromRight = YES;
    [callout show];
}

- (IBAction) menuBarTapped:(UITapGestureRecognizer *) tapGesture {
    NSLog(@"Side bar tapped");
    [self launchSideBarMenu];
}

- (IBAction)MenuClick:(id)sender {
     NSLog(@"Side bar tapped");
}

- (IBAction)HamburgerMenuClick:(id)sender {
     NSLog(@"Side bar tapped");
     [self launchSideBarMenu];
}

- (void) plotMap:(NSArray *)chargeStations{
    
    for ( ChargeStation *station in chargeStations)
    {
        CLLocationCoordinate2D coord;
        
        coord.latitude= station.latitude;
        coord.longitude= station.longtitude;
        MKCoordinateRegion region1;
        region1.center=coord;
        region1.span.longitudeDelta=20 ;
        region1.span.latitudeDelta=20;
        [self.mapView setRegion:region1 animated:YES];
        
        NSString *titleStr = station.stationName; //[namesArr objectAtIndex:i] ;
        // NSLog(@"title is:%@",titleStr);
        
        Annotation*  annotObj =[[Annotation alloc]initWithCoordinate:coord title:titleStr];
        [self.mapView addAnnotation:annotObj];
        
    }
    
}




#pragma mark - delegate

- (void)progressLabel:(KAProgressLabel *)label progressChanged:(CGFloat)progress
{
    [label setText:[NSString stringWithFormat:@"%.0f%%", (progress*100)]];
}

- (void) parseDoneWithArray:(NSArray *)parsedList {
 
    NSLog(@"XML parsing done with charge stations %@", parsedList);
      [self plotMap:parsedList];
}

@end
