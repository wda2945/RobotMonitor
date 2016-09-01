//
//  ConditionsViewController.h
//  RoboMonitor
//
//  Created by Martin Lane-Smith on 2/2/15.
//  Copyright (c) 2015 Martin Lane-Smith. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "ps.h"

@interface ConditionsViewController : UITableViewController 

- (ConditionsViewController*) initForSource: (Source_t) src domain: (NSString*) section;

@property NSString *panelTitle;

@end
