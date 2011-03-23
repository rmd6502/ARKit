//
//  ARViewController.m
//  ARKitDemo
//
//  Created by Niels W Hansen on 1/23/10.
//  Copyright 2010 Agilite Software. All rights reserved.
//

#import "ARViewController.h"
#import "AugmentedRealityController.h"

@implementation ARViewController

@synthesize agController;
@synthesize dataSource;

-(id)initWithDataSource:(id<ARLocationDataSource>)aDataSource {
	if ((self = [super init])) {
        self.dataSource = aDataSource;
        self.wantsFullScreenLayout = YES;
    }	
	return self;
}

- (void)loadView {
	self.agController = [[AugmentedRealityController alloc] initWithViewController:self];
	
	self.agController.debugMode = NO;
	self.agController.scaleViewsBasedOnDistance = YES;
	self.agController.minimumScaleFactor = 0.5;
	self.agController.rotateViewsBasedOnPerspective = YES;
	
	if ([dataSource.locations count] > 0) {
		for (ARCoordinate *coordinate in dataSource.locations) {
            UIView *coordinateView = [dataSource viewForCoordinate:coordinate];
			[agController addCoordinate:coordinate augmentedView:coordinateView animated:NO];
		}
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[agController displayAR];
	[super viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

@end
