//
//  BehaviorViewController.h
//  RoboMonitor
//
//  Created by Martin Lane-Smith on 2/2/15.
//  Copyright (c) 2015 Martin Lane-Smith. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BehaviorViewController : UITableViewController 

- (BehaviorViewController*) initForDomains: (NSArray*) domains;

@property NSString *panelTitle;

@end
