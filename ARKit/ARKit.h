//
//  ARKit.h
//  ARKitDemo
//
//  Created by Jared Crawford on 2/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARViewController.h"
#import "ARGeoCoordinate.h"

@protocol ARLocationDataSource
- (NSMutableArray *)locations; //returns an array of ARGeoCoordinates 
- (UIView *)viewForCoordinate:(ARCoordinate *)coordinate; 
@end


@interface ARKit : NSObject {

}

+(BOOL)deviceSupportsAR;

@end
