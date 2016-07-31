//
//  AppDelegate.h
//  Monitor
//
//  Created by Martin Lane-Smith on 4/12/14.
//  Copyright (c) 2014 Martin Lane-Smith. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PubSubMsg.h"
#import "MessageDelegateProtocol.h"
#import "MasterViewController.h"
#import <CoreFoundation/CoreFoundation.h>

#define DISCONNECTED [UIImage imageNamed:@"offline.png"]
#define CONNECTED [UIImage imageNamed:@"online.png"]

#define PORT_NUMBER 4000

@interface AppDelegate : UIResponder <UIApplicationDelegate, NSNetServiceDelegate, NSNetServiceBrowserDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UISplitViewController *splitViewController;
@property (strong, nonatomic) CollectionViewController *collectionController;

@property (strong, nonatomic) NSString *robotName;
@property (strong, nonatomic) NSString *hostName;
@property (strong, nonatomic) NSString *ipAddress;
@property                       int     robotSource;

@property  (readonly) bool connected;

- (void) connectTo: (NSString*) robot atIP: (NSString*) ip_address;

@end
