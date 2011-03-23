//
//  ARViewController.h
//  ARKitDemo
//
//  Created by Niels W Hansen on 1/23/10.
//  Copyright 2010 Agilite Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ARKit.h"

@class AugmentedRealityController;
@protocol ARLocationDataSource;

@interface ARViewController : UIViewController {
	AugmentedRealityController	*agController;
	id<ARLocationDataSource> dataSource;
}

@property (nonatomic, retain) AugmentedRealityController *agController;
@property (nonatomic, assign) id<ARLocationDataSource> dataSource;

-(id)initWithDataSource:(id<ARLocationDataSource>) aDataSource;

@end

