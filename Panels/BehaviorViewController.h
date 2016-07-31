//
//  BehaviorViewController.h
//  RoboMonitor
//
//  Created by Martin Lane-Smith on 2/2/15.
//  Copyright (c) 2015 Martin Lane-Smith. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MessageDelegateProtocol.h"

@interface BehaviorViewController : UITableViewController <MessageDelegate>

- (BehaviorViewController*) initForDomains: (NSArray*) domains;

@property NSString *panelTitle;

@end
