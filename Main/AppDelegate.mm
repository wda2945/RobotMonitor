//
//  AppDelegate.m
//  BugMonitor
//
//  Created by Martin Lane-Smith on 4/12/14.
//  Copyright (c) 2014 Martin Lane-Smith. All rights reserved.
//

#include "ps.h"
#import "AppDelegate.h"
#import "CollectionViewController.h"
#import "MasterViewController.h"
#import "RobotListTableViewController.h"
#import "LogViewController.h"

#import "serial/socket/ps_socket_client.hpp"
#include "packet/serial_packet/linux/ps_packet_serial_linux.hpp"
#include "transport/linux/ps_transport_linux.hpp"
#include "network/ps_network.hpp"
#include "pubsub/ps_pubsub_class.hpp"


class Connection_Observer : public ps_root_class
{
public:
    Connection_Observer(ps_socket_client *conn) {conn->add_event_observer(this);}
    
    void process_observed_event(ps_root_class *_src, int event)
    {
        ps_socket_client *src = dynamic_cast<ps_socket_client*>(_src);
        
        char caption[100];
        
        src->get_client_status_caption(caption, 100);
        NSString *nsCaption = [NSString stringWithFormat:@"%s", caption];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [MasterViewController getMasterViewController].connectionCaption = nsCaption;
            AppDelegate *appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
            [appDelegate sendPing];
            [LogViewController logAppMessage: nsCaption];
        });
    }

    //not used
    void process_observed_data(ps_root_class *src, const void *msg, int length) {}
};


@interface AppDelegate () {
    
    NSTimer *pingTimer;
    
    ps_socket_client *robotConnection;
    Connection_Observer *connectionObserver;

}

@end

@implementation AppDelegate

void SIGPIPEhandler(int sig);
extern const char *topicNames[PS_TOPIC_COUNT];

message_handler_t appMessageHandler;
PingCallback_t  pingCallback;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.splitViewController = (UISplitViewController *)self.window.rootViewController;
        self.collectionController  = [_splitViewController.viewControllers lastObject];
        _splitViewController.delegate = _collectionController;
    }

    //preload registry
    NSString *path = [[NSBundle mainBundle] pathForResource: @"rm_registry_preload" ofType: @"txt"];
    
    load_registry([path UTF8String]);
    
    ps_register_topic_names(topicNames, PS_TOPIC_COUNT);
    
    //subscribe to topics
    ps_subscribe(RESPONSE_TOPIC, appMessageHandler);
    ps_subscribe(NAV_TOPIC, appMessageHandler);
    ps_subscribe(SYS_REPORT_TOPIC, appMessageHandler);
    
    //initialize plumbing connection
    robotConnection = new ps_socket_client(nullptr, PORT_NUMBER);
    connectionObserver = new Connection_Observer(robotConnection);
    
    ps_packet_serial_linux *pkt = new ps_packet_serial_linux(robotConnection);
    ps_transport_linux *trns = new ps_transport_linux(pkt);
    
    trns->transport_source = static_cast<Source_t>( _robotSource);
    the_network().add_transport_to_network(trns);
    
    the_broker().subscribe(ANNOUNCEMENTS_TOPIC, trns);
    the_broker().subscribe(SYS_ACTION_TOPIC, trns);
    
    pingTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(sendPing) userInfo:NULL repeats:YES];
    
    robotConnection->add_ping_observer(pingCallback, nullptr);
    
    return YES;
}

void pingCallback(char *_robot, char *_ip_address, void *args)
{
    NSString *robot = [NSString stringWithFormat:@"%s", _robot];
    NSString *ip = [NSString stringWithFormat:@"%s", _ip_address];

    dispatch_async(dispatch_get_main_queue(), ^{
        RobotListTableViewController *rlt = [RobotListTableViewController sharedRobotListTableViewController];
        [rlt addRobot: robot atIP: ip];
    });
}

- (bool) connectTo: (NSString*) robot atIP: (NSString*) ip_address port: (int) port
{
    [LogViewController logAppMessage: [NSString stringWithFormat:@"Selected %@ at %@:%i", robot, ip_address, port]];
    
    NSString *documents = [NSHomeDirectory() stringByAppendingPathComponent:@"/Documents/Config.plist"];
    
    NSDictionary *fileDict = nil;//[NSDictionary dictionaryWithContentsOfFile: documents];
    
    if (fileDict == nil)
    {
        fileDict = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"BaseConfig" ofType: @"plist"]];
        [fileDict writeToFile:documents atomically:NO];
    }
    
    NSDictionary *configDict = [fileDict objectForKey: robot];
    
    if (!configDict)
    {
        //robot not found
        NSLog(@"%@ not found.", robot);
        return NO;
    }
    else
    {
        self.robotName  = robot;
        self.ipAddress  = ip_address;
    }
    self.robotSource= [[configDict objectForKey:@"Source"] intValue];
    
    ps_registry_add_new([_robotName UTF8String], "Name", PS_REGISTRY_TEXT_TYPE, PS_REGISTRY_LOCAL);
    ps_registry_set_text([_robotName UTF8String], "Name", [_robotName UTF8String]);
    ps_registry_add_new([_robotName UTF8String], "IP", PS_REGISTRY_TEXT_TYPE, PS_REGISTRY_LOCAL);
    ps_registry_set_text([_robotName UTF8String], "IP", [_ipAddress UTF8String]);

    NSArray *panels = [configDict objectForKey:@"Panels"];
    
    for (NSDictionary *dict in panels)
    {
        [[MasterViewController getMasterViewController] addPanel: dict];
    }

    robotConnection->set_ip_address([_ipAddress UTF8String]);
    
    return YES;
}

void appMessageHandler(const void *msg, int len)
{
    PubSubMsg *message = [[PubSubMsg alloc] initWithMsg:(psMessage_t*) msg];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [message publish];
    });
}

- (bool) connected
{
    return robotConnection->isConnected();
}

- (void) sendPing
{
    [PubSubMsg sendSimpleMessage:PING_MSG];
    send_registry_sync();
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


#define topicmacro(e, name) name,
const char *topicNames[] = {
#include "rm_topics_list.h"
};
#undef topicmacro

@end
