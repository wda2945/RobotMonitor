//
//  RobotListTableViewController.m
//  RobotMonitor
//
//  Created by Martin Lane-Smith on 8/6/16.
//  Copyright © 2016 Martin Lane-Smith. All rights reserved.
//

#import "RobotListTableViewController.h"
#import "AppDelegate.h"

@interface RobotListTableViewController ()
{
    UITableView *tableView;
}
@end

RobotListTableViewController* rltvController;

@implementation RobotListTableViewController

- (RobotListTableViewController*) init
{
    if (self = [super init])
    {
        self.knownRobots = [NSMutableDictionary dictionary];
        self.selectedRobot = @"";
        self.view = tableView = [[UITableView alloc] init];
        tableView.dataSource = self;
        tableView.delegate = self;
        
        rltvController = self;
    }
    return self;
}

- (void)viewDidLoad {

    [super viewDidLoad];
}

+ (RobotListTableViewController*) sharedRobotListTableViewController
{
    if (!rltvController)
    {
        rltvController = [[RobotListTableViewController alloc] init];
    }
    return rltvController;
}

- (void) addRobot: (NSString*) robot atIP: (NSString*) ip_address
{
    if (![_knownRobots objectForKey:robot])
    {
        [_knownRobots setObject:ip_address forKey:robot];
        [tableView reloadData];
        NSLog(@"Added %@ at %@", robot, ip_address);
        [LogViewController logAppMessage: [NSString stringWithFormat:@"Added %@ at %@", robot, ip_address]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return @"Robots Online";
}
- (NSInteger)tableView:(UITableView *)_tableView numberOfRowsInSection:(NSInteger)section {
    return self.knownRobots.allKeys.count;
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:@"RobotListCell"];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"RobotListCell"];
    }
    
    NSString *robot = [_knownRobots.allKeys objectAtIndex:indexPath.row];
    NSString *ip    = [_knownRobots objectForKey:robot];
    
    NSRange r = [robot rangeOfString:@"-"];
    NSString *robotName = [robot substringToIndex:r.location];
    NSString *portString = [robot substringFromIndex:r.location+1];
    
    // Configure the cell...
    cell.textLabel.text = robotName;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@:%@", ip, portString];
    
    if ([_selectedRobot isEqualToString:robot])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)_tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_selectedRobot.length == 0)
    {
        NSString *robot = [_knownRobots.allKeys objectAtIndex:indexPath.row];
        NSString *ip    = [_knownRobots objectForKey: robot];
    
        AppDelegate *appDelegate = (AppDelegate*) [UIApplication sharedApplication].delegate;
        
        NSRange r = [robot rangeOfString:@"-"];
        NSString *robotName = [robot substringToIndex:r.location];
        NSString *portString = [robot substringFromIndex:r.location+1];
        
        if ([appDelegate connectTo:robotName atIP:ip port: [portString intValue]])
        {
            self.selectedRobot = robot;
        }
        
        [_tableView reloadData];
    }
    return nil;
}


@end
