//
//  AugmentedRealityController.h
//  iPhoneAugmentedRealityLib
//
//  Created by Niels W Hansen on 12/20/09.
//  Copyright 2009 Agilite Software All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

@class ARCoordinate;

@interface AugmentedRealityController : NSObject <UIAccelerometerDelegate, CLLocationManagerDelegate> {
@private
	NSMutableArray		*coordinates;
}

@property (nonatomic, assign) BOOL scaleViewsBasedOnDistance;
@property (nonatomic, assign) BOOL rotateViewsBasedOnPerspective;

@property (nonatomic, assign) double maximumScaleDistance;
@property (nonatomic, assign) double minimumScaleFactor;
@property (nonatomic, assign) double maximumRotationAngle;
@property (nonatomic, assign) double degreeRange;
@property (nonatomic, assign) double latestHeading;
@property (nonatomic, assign) float  viewAngle;

@property (readonly)          NSArray        *coordinates;
@property (nonatomic, retain) NSMutableArray *coordinateViews;

@property (nonatomic, retain) UIAccelerometer         *accelerometerManager;
@property (nonatomic, retain) CLLocationManager       *locationManager;
@property (nonatomic, retain) ARCoordinate            *centerCoordinate;
@property (nonatomic, retain) CLLocation              *centerLocation;
@property (nonatomic, retain) UIView                  *displayView;
@property (nonatomic, retain) UIViewController        *rootViewController;
@property (nonatomic, retain) UIImagePickerController *cameraController;
@property (nonatomic, assign) UIDeviceOrientation	  currentOrientation;

@property (nonatomic, assign) BOOL    debugMode;
@property (nonatomic, retain) UILabel *debugView;


- (id)initWithViewController:(UIViewController *)theView;
- (void)displayAR;
- (void)updateLocations;

- (void)setupDebugPostion;

// Adding coordinates to the underlying data model.
- (void)addCoordinate:(ARCoordinate *)coordinate augmentedView:(UIView *)agView animated:(BOOL)animated ;

// Removing coordinates
- (void)removeCoordinate:(ARCoordinate *)coordinate;
- (void)removeCoordinate:(ARCoordinate *)coordinate animated:(BOOL)animated;
- (void)removeCoordinates:(NSArray *)coordinateArray;

@end
