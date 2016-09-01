//
//  MasterViewController.h
//  Monitor
//
//  Created by Martin Lane-Smith on 4/12/14.
//  Copyright (c) 2014 Martin Lane-Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CollectionProtocol.h"
#import "CollectionViewController.h"

#import "BehaviorViewController.h"
#import "ConditionsViewController.h"
#import "LogViewController.h"
#import "RCViewController.h"
#import "RegistryViewController.h"
#import "RobotListTableViewController.h"

//#import "SubsystemViewController.h"

@interface MasterViewController : UITableViewController < CollectionController>

@property (strong, nonatomic) LogViewController         *logViewController;
@property (strong, nonatomic) RCViewController          *rcController;
//@property (strong, nonatomic) SubsystemViewController   *subsystemViewController;

@property (strong, nonatomic) NSMutableDictionary *viewControllers;

@property (strong, nonatomic) UIStoryboard *storyBoard;
@property (strong, nonatomic) UIViewController <CollectionController>  *collectionController;

@property (strong, nonatomic) NSMutableDictionary *subsystems;

@property (strong, nonatomic) NSString *connectionCaption;

@property (strong, nonatomic) NSString *robotName;
@property (strong, nonatomic) NSString *robotHostname;
@property (strong, nonatomic) NSString *robotIP;

+ (MasterViewController*) getMasterViewController;

- (void) addPanel: (NSDictionary *) panelDict;

@end
