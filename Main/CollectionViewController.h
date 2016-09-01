//
//  CollectionViewController.h
//  Monitor
//
//  Created by Martin Lane-Smith on 4/13/14.
//  Copyright (c) 2014 Martin Lane-Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CollectionProtocol.h"

@class SubsystemStatus;

@interface CollectionViewController : UIViewController <UISplitViewControllerDelegate, CollectionController>

- (bool) presentView: (NSString*) name;
- (void) firstView: (NSString*) name;

//- (void) addSubsystem: (SubsystemStatus*) sub;

@end
