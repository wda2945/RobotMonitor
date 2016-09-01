//
//  RobotListTableViewController.h
//  RobotMonitor
//
//  Created by Martin Lane-Smith on 8/6/16.
//  Copyright © 2016 Martin Lane-Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RobotListTableViewController : UITableViewController

@property (strong, nonatomic) NSMutableDictionary *knownRobots;
@property (strong, nonatomic) NSString *selectedRobot;

- (RobotListTableViewController*) init;

+ (RobotListTableViewController*) sharedRobotListTableViewController;

- (void) addRobot: (NSString*) robot atIP: (NSString*) ip_address;

@end
