//
//  MasterViewController.m
//  Monitor
//
//  Created by Martin Lane-Smith on 4/12/14.
//  Copyright (c) 2014 Martin Lane-Smith. All rights reserved.
//

#import "MasterViewController.h"
#import "AppDelegate.h"
#include <sys/time.h>

@interface MasterViewController () {
    bool connected;
    int currentPage;
    
    NSMutableArray *panelList;
}

@end

static MasterViewController *me;

@implementation MasterViewController

+ (MasterViewController*) getMasterViewController
{
    return me;
}
- (void)awakeFromNib
{
    me = self;
    
    self.subsystems = [NSMutableDictionary dictionary];
    self.viewControllers = [NSMutableDictionary dictionary];
    panelList = [NSMutableArray array];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
        self.storyBoard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
    } else {
        self.storyBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    }

    self.connectionCaption = @"Disconnected";
    
    RobotListTableViewController *ListViewController = [[RobotListTableViewController alloc] init];
    [_viewControllers setObject:ListViewController forKey: @"List"];
    
    [super awakeFromNib];
}

- (void) addPanel: (NSDictionary *) panelDict
{
    [panelList addObject:panelDict];
    UIViewController *viewController;
    NSString *name = [panelDict objectForKey:@"Name"];
    NSString *title = [panelDict objectForKey:@"Title"];
    NSArray *domains = [panelDict objectForKey:@"Domains"];
    
    if ([name isEqualToString:@"SysLog"])
    {
        viewController = self.logViewController    = [[LogViewController alloc] init];
        [_viewControllers setObject:_logViewController forKey: title];
    }
    else if ([name isEqualToString:@"Behaviors"])
    {
        BehaviorViewController *vc    = [[BehaviorViewController alloc] initForDomains: domains];
        viewController = vc;
        vc.panelTitle = title;
        [_viewControllers setObject:vc forKey: title];
    }
    else if ([name isEqualToString:@"Conditions"])
    {
        ConditionsViewController *vc    = [[ConditionsViewController alloc]
                                           initForSource: [[panelDict objectForKey:@"Source"] intValue]
                                           domain: [domains firstObject]];
        viewController = vc;
        vc.panelTitle = title;
        [_viewControllers setObject:vc forKey: title];
    }
    else if ([name isEqualToString:@"Registry"])
    {
        RegistryViewController *vc    = [[RegistryViewController alloc] initForDomains: domains];
        viewController = vc;
        vc.panelTitle = title;
        [_viewControllers setObject:vc forKey: title];
    }
    else if ([name isEqualToString:@"Remote"])
    {
        self.rcController    = [_storyBoard instantiateViewControllerWithIdentifier:@"RC"];
        viewController = _rcController;
        _rcController.title = title;
        _rcController.lateral = [[panelDict objectForKey:@"Lateral"] boolValue];
        [_viewControllers setObject:_rcController forKey: title];
    }
    
    if (self.collectionController == nil)
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            self.collectionController = delegate.collectionController;
        }
        else
        {
            self.collectionController = self;
        }
    }
    
    [self.collectionController addViewController: viewController];
    
    [(UITableView*) self.view reloadData];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.collectionController = [(AppDelegate*)[[UIApplication sharedApplication] delegate] collectionController];
    }
    else
    {
        self.collectionController = self;
    }
}

- (void) setConnectionCaption:(NSString *)caption
{
    _connectionCaption = caption;
    if (self.view) [(UITableView*) self.view reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section){
        case 0:
            return 1;
            break;
        case 1:
            return panelList.count;
            break;

        default:
            return 0;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 20.0f;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 20.0f;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 35.0f;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    switch(indexPath.section){
        case 0:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"MasterCell"];
            if (!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MasterCell"];
            }
            AppDelegate* delegate = (AppDelegate* )[[UIApplication sharedApplication] delegate];
            
            switch(indexPath.row){
                case 0:
                    if (delegate.connected){
                        cell.textLabel.text = self.connectionCaption;
                        cell.imageView.image = CONNECTED;
                    }
                    else {
                        cell.textLabel.text = self.connectionCaption;
                        cell.imageView.image = DISCONNECTED;
                    }
                    break;
                default:
                    return nil;
                    break;
            }

        }
            break;
            
      case 1:       //panels
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"DetailCell"];
            if (!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DetailCell"];
            }
            
            NSDictionary *panel = [panelList objectAtIndex:indexPath.row];
            cell.textLabel.text = [panel objectForKey: @"Title"];
            cell.imageView.image = [UIImage imageNamed:[panel objectForKey: @"Icon"]];
        }
            break;
            
        case 2:
            cell = [tableView dequeueReusableCellWithIdentifier:@"ExtraBtnCell"];
            if (!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ExtraBtnCell"];
            }
                cell.textLabel.text = @"Clear Log";
                cell.imageView.image = [UIImage imageNamed:@"log.png"];
            break;
        default:
            break;
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.collectionController == nil)
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            self.collectionController = delegate.collectionController;
        }
        else
        {
            self.collectionController = self;
        }
    }
    switch(indexPath.section){
        case 0:
            if ([_collectionController presentView: @"List"]) return indexPath;
            break;
        case 1:
        {
            currentPage = (int) indexPath.row;
            [(UITableView*) self.view reloadData];
            
            NSDictionary *panel = [panelList objectAtIndex:indexPath.row];
            if ([_collectionController presentView: [panel objectForKey: @"Title"]]) return indexPath;
            
        }
            break;
        case 2:
        {
            currentPage = -1;
            [(UITableView*) self.view reloadData];
            if ([_collectionController presentView:  @"OVM"]) return indexPath;
        }
            break;
        case 3:
//            [LogViewController ClearLog];
            break;
        default:
            break;
    }
    return nil;
}
- (void) addViewController: (UIViewController*) controller
{
}
- (void) firstView: (NSString*) name
{
    [self presentView:name];
}
- (bool) presentView: (NSString*) name{
    UIViewController *controller = [_viewControllers objectForKey:name];
    controller.title = name;
    if (controller) {
        [self.navigationController pushViewController:controller animated:YES];
        return YES;
    }
    return NO;
}
- (void) statusChange: (SubsystemStatus*) ss{
    [(UITableView*)self.view reloadData];
}
@end
