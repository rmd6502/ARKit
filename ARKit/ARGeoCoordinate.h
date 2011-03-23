//
//  ARGeoCoordinate.h
//  iPhoneAugmentedRealityLib
//
//  Created by Haseman on 8/1/09.
//  Copyright 2009 Zac White. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "ARCoordinate.h"

@interface ARGeoCoordinate : ARCoordinate {
	CLLocation *geoLocation;
}

@property (nonatomic, retain) CLLocation *geoLocation;


+ (ARGeoCoordinate *)coordinateWithLocation:(CLLocation *)location locationTitle:(NSString*) titleOfLocation;
+ (ARGeoCoordinate *)coordinateWithLocation:(CLLocation *)location fromOrigin:(CLLocation *)origin;

- (void)calibrateUsingOrigin:(CLLocation *)origin;

@end
