//
//  LocationTracker.h
//  Seekr
//
//  Created by Andy on 11/1/16.
//  Copyright (c) 2016 Seekr. All rights reserved.
//


#import "LocationTracker.h"

#define LATITUDE @"latitude"
#define LONGITUDE @"longitude"
#define ACCURACY @"theAccuracy"

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

NSString *sacredName;
NSString *attributeName;
BOOL bNewLocation;
NSString *attributeNames[5] = {@"Presence", @"Peace", @"Joy", @"Strength", @"Love"};
NSString *sacredNames[6] = {@"GOD", @"ALLAH", @"JESUS", @"SELF", @"UNIVERSE", @"ANCESTORS"};

@implementation LocationTracker

+ (CLLocationManager *)sharedLocationManager {
	static CLLocationManager *_locationManager;
	
	@synchronized(self) {
		if (_locationManager == nil) {
			_locationManager = [[CLLocationManager alloc] init];
            _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
			_locationManager.allowsBackgroundLocationUpdates = YES;
			_locationManager.pausesLocationUpdatesAutomatically = NO;
		}
	}
	return _locationManager;
}

- (id)init {
	if (self==[super init]) {
        //Get the share model and also initialize myLocationArray
        self.shareModel = [LocationShareModel sharedModel];
        self.shareModel.myLocationArray = [[NSMutableArray alloc]init];
        bNewLocation = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
	}
	return self;
}

-(void)applicationEnterBackground{
    _bBackgroundMode = YES;
    
    CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    
    if(IS_OS_8_OR_LATER) {
        [locationManager requestAlwaysAuthorization];
    }
    [locationManager startUpdatingLocation];
    
    //Use the BackgroundTaskManager to manage all the background Task
    self.shareModel.bgTask = [BackgroundTaskManager sharedBackgroundTaskManager];
    [self.shareModel.bgTask beginNewBackgroundTask];
}

- (void) restartLocationUpdates
{
    NSLog(@"restartLocationUpdates");
    
    if (self.shareModel.timer) {
        [self.shareModel.timer invalidate];
        self.shareModel.timer = nil;
    }
    
    CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    
    if(IS_OS_8_OR_LATER) {
        [locationManager requestAlwaysAuthorization];
    }
    [locationManager startUpdatingLocation];
}


- (void)startLocationTracking {
    NSLog(@"startLocationTracking");

	if ([CLLocationManager locationServicesEnabled] == NO) {
        NSLog(@"locationServicesEnabled false");
		UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled" message:@"You currently have all location services for this device disabled" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[servicesDisabledAlert show];
	} else {
        CLAuthorizationStatus authorizationStatus= [CLLocationManager authorizationStatus];
        
        if(authorizationStatus == kCLAuthorizationStatusDenied || authorizationStatus == kCLAuthorizationStatusRestricted){
            NSLog(@"authorizationStatus failed");
        } else {
            NSLog(@"authorizationStatus authorized");
            CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
            locationManager.delegate = self;
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
            locationManager.distanceFilter = kCLDistanceFilterNone;
            
            if(IS_OS_8_OR_LATER) {
              [locationManager requestAlwaysAuthorization];
            }
            [locationManager startUpdatingLocation];
        }
	}
}


- (void)stopLocationTracking {
    NSLog(@"stopLocationTracking");
    
    if (self.shareModel.timer) {
        [self.shareModel.timer invalidate];
        self.shareModel.timer = nil;
    }
    
	CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
	[locationManager stopUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate Methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    NSLog(@"locationManager didUpdateLocations");
    
    for(int i=0;i<locations.count;i++){
        CLLocation * newLocation = [locations objectAtIndex:i];
        CLLocationCoordinate2D theLocation = newLocation.coordinate;
        
        CLLocationAccuracy theAccuracy = newLocation.horizontalAccuracy;
        
        NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
        
        if (locationAge > 30.0)
        {
            continue;
        }
        
        //Select only valid location and also location with good accuracy
        if(newLocation!=nil&&theAccuracy>0
           &&theAccuracy<2000
           &&(!(theLocation.latitude==0.0&&theLocation.longitude==0.0))){
            
            self.myLastLocation = theLocation;
            self.myLastLocationAccuracy= theAccuracy;
            
            NSMutableDictionary * dict = [[NSMutableDictionary alloc]init];
            [dict setObject:[NSNumber numberWithFloat:theLocation.latitude] forKey:@"latitude"];
            [dict setObject:[NSNumber numberWithFloat:theLocation.longitude] forKey:@"longitude"];
            [dict setObject:[NSNumber numberWithFloat:theAccuracy] forKey:@"theAccuracy"];
            
            //Add the vallid location with good accuracy into an array
            //Every 1 minute, I will select the best location based on accuracy and send to server
            [self.shareModel.myLocationArray addObject:dict];
        }
    }
    
    //If the timer still valid, return it (Will not run the code below)
    if (self.shareModel.timer) {
        return;
    }
    
    self.shareModel.bgTask = [BackgroundTaskManager sharedBackgroundTaskManager];
    [self.shareModel.bgTask beginNewBackgroundTask];
    
    //Restart the locationMaanger after 1 minute
    self.shareModel.timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self
                                                           selector:@selector(restartLocationUpdates)
                                                           userInfo:nil
                                                            repeats:NO];
    
    if (!self.shareModel.timerCounter) {
        self.shareModel.timerCounter = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(timerCount) userInfo:nil repeats:YES];
        
    }
    
    //Will only stop the locationManager after 10 seconds, so that we can get some accurate locations
    //The location manager will only operate for 10 seconds to save battery
    if (self.shareModel.delay10Seconds) {
        [self.shareModel.delay10Seconds invalidate];
        self.shareModel.delay10Seconds = nil;
    }
    
    self.shareModel.delay10Seconds = [NSTimer scheduledTimerWithTimeInterval:10 target:self
                                                    selector:@selector(stopLocationDelayBy10Seconds)
                                                    userInfo:nil
                                                     repeats:NO];

    
}

int timeCount = 0;
int interval = 30; // 30;


- (void) timerCount
{
    timeCount++;
    if (_oldLocation.latitude == 0 && _oldLocation.longitude == 0) {
        _oldLocation = _myLocation;
    }

//    if (timeCount % interval != 0) {
//        return;
//    }
    CLLocation * location1 = [[CLLocation alloc] initWithLatitude:self.oldLocation.latitude longitude:self.oldLocation.longitude];
    
    CLLocation * location2 = [[CLLocation alloc] initWithLatitude:self.myLocation.latitude longitude:self.myLocation.longitude];
    
    if ([self isLocation:location2 inRangeWith:location1]) {
        if (timeCount % interval != 0) {
            return;
        }
        timeCount = 0;
        interval = 360; // 360 = 1 hours
        
        NSString *message;
        

        if (bNewLocation == NO) {
            if ([sacredName isEqualToString:@"God"] || [sacredName isEqualToString:@"Allah"]) {
                message = [NSString stringWithFormat:@"You're still here. %@'s %@ is still here.", sacredName, attributeName];
            }
            else if([sacredName isEqualToString:@"Jesus"])
                message = [NSString stringWithFormat:@"You're still here. %@' %@ is still here.", sacredName, attributeName];
            else if([sacredName isEqualToString:@"Self"])
            {
                message = [NSString stringWithFormat:@"You're still here. The %@ residing within you is too.", attributeName];
            }
            else if ([sacredName isEqualToString:@"Universe"] || [sacredName isEqualToString:@"Ancestors"]) {
                message = [NSString stringWithFormat:@"You're still here. the %@ of the %@ is still here.",  attributeName, sacredName];
            }
        }
        else
        {
            if ([sacredName isEqualToString:@"God"] || [sacredName isEqualToString:@"Allah"]) {
                message = [NSString stringWithFormat:@"You're in a new space. Take 5 deep breaths and know that %@'s %@ is with you.", sacredName, attributeName];
            }
            else if([sacredName isEqualToString:@"Jesus"])
                message = [NSString stringWithFormat:@"You're in a new space. Take 5 deep breaths and know that %@' %@ is with you.", sacredName, attributeName];

            else if([sacredName isEqualToString:@"Self"])
            {
                message = [NSString stringWithFormat:@"You're in a new space. Take 5 deep breaths and know that %@ already residing within you is here", attributeName];
                
            }
            else if ([sacredName isEqualToString:@"Universe"] || [sacredName isEqualToString:@"Ancestors"]) {
                message = [NSString stringWithFormat:@"You're in a new space. Take 5 deep breaths and know that the %@ of the %@ is with you.", attributeName, sacredName];
            }

        }
        

        
        bNewLocation = NO;

        if (_bBackgroundMode == NO) {
            UIAlertView *notificationView = [[UIAlertView alloc] initWithTitle:@"Seekrbot" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [notificationView show];
        }
        else{
            NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
            int bades = (int)[userDefault integerForKey:@"badges"];
            bades++;
            [userDefault setInteger:bades forKey:@"badges"];
            [userDefault synchronize];
            
            UILocalNotification *notification = [UILocalNotification new];
            notification.alertBody = message;
            notification.alertTitle = @"Seekrbot";
            notification.applicationIconBadgeNumber=bades;
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        }
    }
    else{
        interval = 30;
        timeCount = 0;
        bNewLocation = YES;
    }
    
    self.oldLocation = self.myLocation;
}


-(BOOL)isLocation:(CLLocation*)location inRangeWith:(CLLocation*)otherLocation{
    CLLocationDistance delta = [location distanceFromLocation:otherLocation];
    CLLocationDistance threshold = 100.0;  // threshold distance in meters
    
    // note: userLocation and otherLocation are CLLocation objects
    if (delta <= threshold) {
        // same location
        return YES;
    }
    return NO;

}

//Stop the locationManager
-(void)stopLocationDelayBy10Seconds{
    CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
    [locationManager stopUpdatingLocation];
    
    NSLog(@"locationManager stop Updating after 10 seconds");
}


- (void)locationManager: (CLLocationManager *)manager didFailWithError: (NSError *)error
{
   // NSLog(@"locationManager error:%@",error);
    
    switch([error code])
    {
        case kCLErrorNetwork: // general, network-related error
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Please check your network connection." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
            break;
        case kCLErrorDenied:{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enable Location Service" message:@"You have to enable the Location Service to use this App. To enable, please go to Settings->Privacy->Location Services" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
            break;
        default:
        {
            
        }
            break;
    }
}


//Send the location to Server
- (void)updateLocationToServer {
    
    NSLog(@"updateLocationToServer");
    
    // Find the best location from the array based on accuracy
    NSMutableDictionary * myBestLocation = [[NSMutableDictionary alloc]init];
    
    for(int i=0;i<self.shareModel.myLocationArray.count;i++){
        NSMutableDictionary * currentLocation = [self.shareModel.myLocationArray objectAtIndex:i];
        
        if(i==0)
            myBestLocation = currentLocation;
        else{
            if([[currentLocation objectForKey:ACCURACY]floatValue]<=[[myBestLocation objectForKey:ACCURACY]floatValue]){
                myBestLocation = currentLocation;
            }
        }
    }
    NSLog(@"My Best location:%@",myBestLocation);
    
    //If the array is 0, get the last location
    //Sometimes due to network issue or unknown reason, you could not get the location during that  period, the best you can do is sending the last known location to the server
    if(self.shareModel.myLocationArray.count==0)
    {
        NSLog(@"Unable to get location, use the last known location");

        self.myLocation=self.myLastLocation;
        self.myLocationAccuracy=self.myLastLocationAccuracy;
        
    }else{
        CLLocationCoordinate2D theBestLocation;
        theBestLocation.latitude =[[myBestLocation objectForKey:LATITUDE]floatValue];
        theBestLocation.longitude =[[myBestLocation objectForKey:LONGITUDE]floatValue];
        self.myLocation=theBestLocation;
        self.myLocationAccuracy =[[myBestLocation objectForKey:ACCURACY]floatValue];
    }
    
    NSLog(@"Send to Server: Latitude(%f) Longitude(%f) Accuracy(%f)",self.myLocation.latitude, self.myLocation.longitude,self.myLocationAccuracy);
    
    //TODO: Your code to send the self.myLocation and self.myLocationAccuracy to your server
    
    //After sending the location to the server successful, remember to clear the current array with the following code. It is to make sure that you clear up old location in the array and add the new locations from locationManager
    [self.shareModel.myLocationArray removeAllObjects];
    self.shareModel.myLocationArray = nil;
    self.shareModel.myLocationArray = [[NSMutableArray alloc]init];
}




@end
