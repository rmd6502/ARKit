//
//  ARKitDemoAppDelegate.h
//  ARKitDemo using the iPhoneAugmentedRealityLib
//
//  Created by Niels Hansen on 1/21/2010.
//  Copyright Niels Hansen 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ARKit.h"


@interface ARKitDemoAppDelegate : NSObject <UIApplicationDelegate, ARLocationDataSource> {
    UIWindow *window;
}


@property (nonatomic, retain) IBOutlet UIWindow *window;

@end

