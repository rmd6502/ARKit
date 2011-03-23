//
//  AugmentedRealityController.m
//  iPhoneAugmentedRealityLib
//
//  Created by Niels W Hansen on 12/20/09.
//  Copyright 2009 Agilite Software. All rights reserved.
//

#import "AugmentedRealityController.h"
#import "ARCoordinate.h"
#import "ARGeoCoordinate.h"
#import <MapKit/MapKit.h>
#import <QuartzCore/QuartzCore.h>

#define kFilteringFactor 0.05
#define degreesToRadian(x) (M_PI * (x) / 180.0)
#define radianToDegrees(x) ((x) * 180.0/M_PI)

#pragma mark -

@interface AugmentedRealityController (Private) 
- (void) updateCenterCoordinate;
- (void) startListening;
- (double) findDeltaOfRadianCenter:(double*)centerAzimuth coordinateAzimuth:(double)pointAzimuth betweenNorth:(BOOL*) isBetweenNorth;
- (CGPoint) pointInView:(UIView *)realityView withView:(UIView *)viewToDraw forCoordinate:(ARCoordinate *)coordinate;
- (BOOL) viewportContainsView:(UIView *)viewToDraw forCoordinate:(ARCoordinate *)coordinate;
@end

#pragma mark -

@implementation AugmentedRealityController

@synthesize locationManager, accelerometerManager, displayView, centerCoordinate, scaleViewsBasedOnDistance, rotateViewsBasedOnPerspective, maximumScaleDistance, minimumScaleFactor, maximumRotationAngle, centerLocation, coordinates, currentOrientation, degreeRange, rootViewController;
@synthesize debugMode, debugView, latestHeading, viewAngle, coordinateViews;
@synthesize cameraController;

#pragma mark - Init & dealloc 

- (id)initWithViewController:(UIViewController *)vc {
	coordinates		= [[NSMutableArray alloc] init];
	coordinateViews	= [[NSMutableArray alloc] init];
	latestHeading	= -1.0f;
	debugView		= nil;
	
	self.rootViewController = vc; 

	self.debugMode = NO; 
	self.maximumScaleDistance = 0.0;
	self.minimumScaleFactor = 1.0;
	self.scaleViewsBasedOnDistance = NO;
	self.rotateViewsBasedOnPerspective = NO;
	self.maximumRotationAngle = M_PI / 6.0;
	
	CGRect screenRect = [[UIScreen mainScreen] bounds];
	
	self.displayView = [[UIView alloc] initWithFrame: screenRect]; 
	self.currentOrientation = UIDeviceOrientationPortrait; 
	self.degreeRange = self.displayView.bounds.size.width / 12; 

	vc.view = self.displayView; 
	
	self.cameraController = [[[UIImagePickerController alloc] init] autorelease];
	self.cameraController.sourceType = UIImagePickerControllerSourceTypeCamera;
	self.cameraController.cameraViewTransform = CGAffineTransformScale(self.cameraController.cameraViewTransform, 1.13f,  1.13f);
	self.cameraController.showsCameraControls = NO;
	self.cameraController.navigationBarHidden =YES;
	self.cameraController.cameraOverlayView = self.displayView;
	
	CLLocation *newCenter = [[CLLocation alloc] initWithLatitude:0.0 longitude:0.0];
	self.centerLocation = newCenter;
	[newCenter release];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name: UIDeviceOrientationDidChangeNotification object:nil];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];	
	
	[self startListening];
	
	return self;
}

- (void)dealloc {
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];

	self.locationManager = nil;
	self.coordinateViews = nil;
	self.debugView = nil;

	[coordinates release];
    [super dealloc];
}

// This is needed to start showing the Camera of the Augemented Reality Toolkit.
- (void)displayAR {
	[rootViewController presentModalViewController:self.cameraController animated:NO];
	displayView.frame = self.cameraController.view.bounds; 
}

- (void)startListening {
	
	// start our heading readings and our accelerometer readings.
	if (!self.locationManager) {
		self.locationManager = [[CLLocationManager alloc] init];
		self.locationManager.headingFilter = kCLHeadingFilterNone;
		self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
		[self.locationManager startUpdatingHeading];
		[self.locationManager startUpdatingLocation];
		self.locationManager.delegate = self;
	}
			
	if (!self.accelerometerManager) {
		self.accelerometerManager = [UIAccelerometer sharedAccelerometer];
		self.accelerometerManager.updateInterval = 0.25;
		self.accelerometerManager.delegate = self;
	}
	
	if (!self.centerCoordinate) 
		self.centerCoordinate = [ARCoordinate coordinateWithRadialDistance:1.0 inclination:0 azimuth:0];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
	latestHeading = degreesToRadian(newHeading.magneticHeading);
	[self updateCenterCoordinate];
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
	return YES;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	if (oldLocation == nil)
		self.centerLocation = newLocation;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	
}

#pragma mark - UIAccelerometerDelegate 

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
	
	switch (currentOrientation) {
		case UIDeviceOrientationLandscapeLeft:
			viewAngle = atan2(acceleration.x, acceleration.z);
			break;
		case UIDeviceOrientationLandscapeRight:
			viewAngle = atan2(-acceleration.x, acceleration.z);
			break;
		case UIDeviceOrientationPortrait:
			viewAngle = atan2(acceleration.y, acceleration.z);
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			viewAngle = atan2(-acceleration.y, acceleration.z);
			break;	
		default:
			break;
	}
	
	[self updateCenterCoordinate];
}

#pragma mark - NSNotificationCenter

- (void)deviceOrientationDidChange:(NSNotification *)notification {
	
	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
	
	// Later we may handle the Orientation of Faceup to show a Map.  For now let's ignore it.
	if (orientation != UIDeviceOrientationUnknown && orientation != UIDeviceOrientationFaceUp && orientation != UIDeviceOrientationFaceDown) {
		
		CGAffineTransform transform = CGAffineTransformMakeRotation(degreesToRadian(0));
		CGRect bounds = [[UIScreen mainScreen] bounds];
		
		if (orientation == UIDeviceOrientationLandscapeLeft) {
			transform		   = CGAffineTransformMakeRotation(degreesToRadian(90));
			bounds.size.width  = [[UIScreen mainScreen] bounds].size.height;
			bounds.size.height = [[UIScreen mainScreen] bounds].size.width;
		}
		else if (orientation == UIDeviceOrientationLandscapeRight) {
			transform		   = CGAffineTransformMakeRotation(degreesToRadian(-90));
			bounds.size.width  = [[UIScreen mainScreen] bounds].size.height;
			bounds.size.height = [[UIScreen mainScreen] bounds].size.width;
		}
		else if (orientation == UIDeviceOrientationPortraitUpsideDown)
			transform = CGAffineTransformMakeRotation(degreesToRadian(180));
		
		displayView.transform = CGAffineTransformIdentity;
		displayView.transform = transform;
		displayView.bounds = bounds;
		
		self.degreeRange = self.displayView.bounds.size.width / 12;
		self.debugMode = YES;
	}
}

#pragma mark - Private methods 

// called when updating acceleration or locationHeading 
- (void)updateCenterCoordinate {
	double adjustment = 0;
	
	if (currentOrientation == UIDeviceOrientationLandscapeLeft)
		adjustment = degreesToRadian(270); 
	else if (currentOrientation == UIDeviceOrientationLandscapeRight)
		adjustment = degreesToRadian(90);
	else if (currentOrientation == UIDeviceOrientationPortraitUpsideDown)
		adjustment = degreesToRadian(180);
    
	self.centerCoordinate.azimuth = latestHeading - adjustment;
	[self updateLocations];
}

// called by the two next methods 
- (double)findDeltaOfRadianCenter:(double*)centerAzimuth coordinateAzimuth:(double)pointAzimuth betweenNorth:(BOOL*)isBetweenNorth {
    
	if (*centerAzimuth < 0.0) 
		*centerAzimuth = (M_PI * 2.0) + *centerAzimuth;
	
	if (*centerAzimuth > (M_PI * 2.0)) 
		*centerAzimuth = *centerAzimuth - (M_PI * 2.0);
	
	double deltaAzimuth = ABS(pointAzimuth - *centerAzimuth);
	*isBetweenNorth		= NO;
    
	// If values are on either side of the Azimuth of North we need to adjust it.  Only check the degree range
	if (*centerAzimuth < degreesToRadian(self.degreeRange) && pointAzimuth > degreesToRadian(360-self.degreeRange)) {
		deltaAzimuth	= (*centerAzimuth + ((M_PI * 2.0) - pointAzimuth));
		*isBetweenNorth = YES;
	}
	else if (pointAzimuth < degreesToRadian(self.degreeRange) && *centerAzimuth > degreesToRadian(360-self.degreeRange)) {
		deltaAzimuth	= (pointAzimuth + ((M_PI * 2.0) - *centerAzimuth));
		*isBetweenNorth = YES;
	}
    
	return deltaAzimuth;
}

// called by updateLocations 
- (CGPoint)pointInView:(UIView *)realityView withView:(UIView *)viewToDraw forCoordinate:(ARCoordinate *)coordinate {	
	
	CGPoint point;
	CGRect realityBounds	= realityView.bounds;
	double currentAzimuth	= self.centerCoordinate.azimuth;
	double pointAzimuth		= coordinate.azimuth;
	BOOL isBetweenNorth		= NO;
	double deltaAzimuth		= [self findDeltaOfRadianCenter: &currentAzimuth coordinateAzimuth:pointAzimuth betweenNorth:&isBetweenNorth];
	
	if ((pointAzimuth > currentAzimuth && !isBetweenNorth) || (currentAzimuth > degreesToRadian(360-self.degreeRange) && pointAzimuth < degreesToRadian(self.degreeRange)))
		point.x = (realityBounds.size.width / 2) + ((deltaAzimuth / degreesToRadian(1)) * 12);  // Right side of Azimuth
	else
		point.x = (realityBounds.size.width / 2) - ((deltaAzimuth / degreesToRadian(1)) * 12);	// Left side of Azimuth
	
	point.y = (realityBounds.size.height / 2) + (radianToDegrees(M_PI_2 + viewAngle)  * 2.0);
	
	return point;
}

// called by updateLocations 
- (BOOL)viewportContainsView:(UIView *)viewToDraw  forCoordinate:(ARCoordinate *)coordinate {
	
	double currentAzimuth = self.centerCoordinate.azimuth;
	double pointAzimuth	  = coordinate.azimuth;
	BOOL isBetweenNorth	  = NO;
	double deltaAzimuth	  = [self findDeltaOfRadianCenter: &currentAzimuth coordinateAzimuth:pointAzimuth betweenNorth:&isBetweenNorth];
	BOOL result			  = NO;
	
	if (deltaAzimuth <= degreesToRadian(self.degreeRange))
		result = YES;
    
	return result;
}

#pragma - Properties

- (void)setCenterLocation:(CLLocation *)newLocation {
	[centerLocation release];
	centerLocation = [newLocation retain];
	
	for (ARGeoCoordinate *geoLocation in self.coordinates) {
		
		if ([geoLocation isKindOfClass:[ARGeoCoordinate class]]) {
			[geoLocation calibrateUsingOrigin:centerLocation];
			
			if (geoLocation.radialDistance > self.maximumScaleDistance) {
				self.maximumScaleDistance = geoLocation.radialDistance;
            }
		}
	}
}

#pragma mark - Public methods 

- (void)addCoordinate:(ARCoordinate *)coordinate augmentedView:(UIView *)agView animated:(BOOL)animated {
	
	[coordinates addObject:coordinate];
	
	if (coordinate.radialDistance > self.maximumScaleDistance) 
		self.maximumScaleDistance = coordinate.radialDistance;
	
	[coordinateViews addObject:agView];
}

- (void)removeCoordinate:(ARCoordinate *)coordinate {
	[self removeCoordinate:coordinate animated:YES];
}

- (void)removeCoordinate:(ARCoordinate *)coordinate animated:(BOOL)animated {
	[coordinates removeObject:coordinate];
}

- (void)removeCoordinates:(NSArray *)coordinateArray {	
	
	for (ARCoordinate *coordinateToRemove in coordinateArray) {
		NSUInteger indexToRemove = [coordinates indexOfObject:coordinateToRemove];
		
		//TODO: Error checking in here.
		[coordinates	 removeObjectAtIndex:indexToRemove];
		[coordinateViews removeObjectAtIndex:indexToRemove];
	}
}


- (void)updateLocations {
	
	if (!coordinateViews || [coordinateViews count] == 0) 
		return;
	
	debugView.text = [NSString stringWithFormat:@"%.3f %.3f ", -radianToDegrees(viewAngle), self.centerCoordinate.azimuth];
	
	int index			= 0;
	int totalDisplayed	= 0;
	
	for (ARCoordinate *item in coordinates) {
		
		UIView *viewToDraw = [coordinateViews objectAtIndex:index];
		
		if ([self viewportContainsView:viewToDraw forCoordinate:item]) {
			
			CGPoint loc = [self pointInView:self.displayView withView:viewToDraw forCoordinate:item];
			CGFloat scaleFactor = 1.0;
	
			if ([self scaleViewsBasedOnDistance]) 
				scaleFactor = 1.0 - self.minimumScaleFactor * (item.radialDistance / self.maximumScaleDistance);
			
			float width	 = viewToDraw.bounds.size.width  * scaleFactor;
			float height = viewToDraw.bounds.size.height * scaleFactor;
			
			viewToDraw.frame = CGRectMake(loc.x - width / 2.0, loc.y - (height / 2.0), width, height);

			totalDisplayed++;
			
			CATransform3D transform = CATransform3DIdentity;
			
			// Set the scale if it needs it. Scale the perspective transform if we have one.
			if ([self scaleViewsBasedOnDistance]) 
				transform = CATransform3DScale(transform, scaleFactor, scaleFactor, scaleFactor);
			
			if ([self rotateViewsBasedOnPerspective]) {
				transform.m34 = 1.0 / 300.0;
				
				double itemAzimuth		= item.azimuth;
				double centerAzimuth	= self.centerCoordinate.azimuth;
				
				if (itemAzimuth - centerAzimuth > M_PI) 
					centerAzimuth += 2 * M_PI;
				
				if (itemAzimuth - centerAzimuth < -M_PI) 
					itemAzimuth  += 2 * M_PI;
				
				double angleDifference	= itemAzimuth - centerAzimuth;
				transform				= CATransform3DRotate(transform, self.maximumRotationAngle * angleDifference / 0.3696f , 0, 1, 0);
			}
			
			viewToDraw.layer.transform = transform;
			
			//if we don't have a superview, set it up.
			if (!([viewToDraw superview])) {
				[self.displayView addSubview:viewToDraw];
				[self.displayView sendSubviewToBack:viewToDraw];
			}
		} 
		else 
			[viewToDraw removeFromSuperview];
		
		index++;
	}
}

#pragma mark - Unused? method

- (NSComparisonResult)locationSortClosestFirst:(ARCoordinate *) s1 secondCoord:(ARCoordinate*) s2 {
    
	if (s1.radialDistance < s2.radialDistance) 
		return NSOrderedAscending;
	else if (s1.radialDistance > s2.radialDistance) 
		return NSOrderedDescending;
	else 
		return NSOrderedSame;
}


#pragma mark - Debug

- (void)setupDebugPostion {
	if (self.debugMode) {
		[debugView sizeToFit];
		CGRect displayRect = self.displayView.bounds;
		
		debugView.frame = CGRectMake(0, displayRect.size.height - debugView.bounds.size.height,  displayRect.size.width, debugView.bounds.size.height);
	}
}

- (void)setDebugMode:(BOOL)flag {
	if (debugMode == flag) {
		currentOrientation = [[UIDevice currentDevice] orientation];

		CGRect debugRect  = CGRectMake(0, self.displayView.bounds.size.height -20, self.displayView.bounds.size.width, 20);	
		debugView.frame = debugRect;
		return;
	}
	
	debugMode = flag;
	
	if ([self debugMode]) {
		debugView = [[UILabel alloc] initWithFrame:CGRectZero];
		debugView.textAlignment = UITextAlignmentCenter;
		debugView.text = @"Waiting...";
		[displayView addSubview:debugView];
		[self setupDebugPostion];
	} else {
		[debugView removeFromSuperview];
    }
}

@end
