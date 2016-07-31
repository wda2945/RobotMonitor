//
//  RegistryViewController.m
//  RoboMonitor
//
//  Created by Martin Lane-Smith on 2/2/15.
//  Copyright (c) 2015 Martin Lane-Smith. All rights reserved.
//

#import "RegistryViewController.h"
#import "SettingsDetailViewController.h"

@interface RegistryViewController ()
{
    UITableView *tableView;
    SettingsDetailViewController *detailController;
    
    NSMutableDictionary *my_domains;
    NSMutableDictionary *switches;
    NSMutableArray      *switchList;
}
- (void) registry_update_method: (NSString *) domain name: (NSString *) name;
- (void) refreshFromRegistry: (NSString*) domain;

@end

@implementation RegistryViewController

ps_registry_callback_t registry_callback;

- (RegistryViewController*) init
{
    self = [super init];
    return self;
}

- (RegistryViewController*) initForDomains: (NSArray*) _domains
{
    if (self = [super init])
    {
        self.view = tableView = [[UITableView alloc] init];
        tableView.dataSource = self;
        tableView.delegate = self;
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            detailController = [[SettingsDetailViewController alloc] initWithNibName:@"SettingsDetail-iPad" bundle:nil];
        }
        else{
            detailController = [[SettingsDetailViewController alloc] initWithNibName:@"SettingsDetail-iPhone" bundle:nil];
        }
        
        my_domains  = [NSMutableDictionary dictionary];
        switches    = [NSMutableDictionary dictionary];
        switchList  = [NSMutableArray array];
        
        for (NSString *domain in _domains)
        {
            NSLog(@"RegistryView Domain %i = %@", (int)my_domains.count+1, domain);
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         domain, @"domain_name",
                                         [NSMutableDictionary dictionary], @"settings",
                                         nil];
            [my_domains setObject: dict forKey: domain];
            
            ps_registry_set_observer(domain.UTF8String, "any", registry_callback, (__bridge void *)(self));
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self refreshFromRegistry: domain];
            });
            
        }
        
    }
    return self;
}
void registry_callback(const char *_domain, const char *_name, const void *arg)
{
    if (strcmp(_name, "any") == 0) return;
    
    NSString *domain = [NSString stringWithFormat:@"%s", _domain];
    NSString *name = [NSString stringWithFormat:@"%s", _name];
    
    RegistryViewController *svc = (__bridge RegistryViewController*) arg;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [svc registry_update_method: domain name: name];
    });
}

- (void) registry_update_method: (NSString *) domain name: (NSString *) name
{
    NSLog(@"RegistryView callback for %@/%@", domain, name);
    
    NSMutableDictionary *domain_dict = [my_domains objectForKey: domain];
    NSMutableDictionary *settings;
    
    if (domain_dict)
    {
        //one of my domains
        settings = [domain_dict objectForKey: @"settings"];
        NSMutableDictionary *dict = [settings objectForKey: name];
        
        ps_registry_struct_t reg_entry;
        if (ps_registry_get(domain.UTF8String, name.UTF8String, &reg_entry) != PS_OK) return;
        
        ps_registry_datatype_t type = reg_entry.datatype;
        
        if (!dict)
        {
            //new registry name
            dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                    name, @"name",
                    [NSNumber numberWithInt:type], @"type",
                    [NSNumber numberWithInt:reg_entry.flags], @"flags",
                    [NSNumber numberWithInt:reg_entry.source], @"source",
                    domain, @"domain",
                    nil];
            [settings setObject:dict forKey:name];
        }
        //set (new) values
        switch(type)
        {
            case PS_REGISTRY_TEXT_TYPE:
            {
                [dict setObject:[NSString stringWithFormat:@"%s", reg_entry.string_value] forKey:@"value"];
            }
                break;
            case PS_REGISTRY_INT_TYPE:
            {
                [dict setObject:[NSNumber numberWithInt:reg_entry.int_min] forKey:@"min"];
                [dict setObject:[NSNumber numberWithInt:reg_entry.int_max] forKey:@"max"];
                [dict setObject:[NSNumber numberWithInt:reg_entry.int_value] forKey:@"value"];
            }
                break;
            case PS_REGISTRY_REAL_TYPE:
            {
                [dict setObject:[NSNumber numberWithFloat:reg_entry.real_min] forKey:@"min"];
                [dict setObject:[NSNumber numberWithFloat:reg_entry.real_max] forKey:@"max"];
                [dict setObject:[NSNumber numberWithFloat:reg_entry.real_value] forKey:@"value"];
            }
                break;
            case PS_REGISTRY_BOOL_TYPE:
            {
                [dict setObject:[NSNumber numberWithBool:reg_entry.bool_value] forKey:@"value"];
            }
                break;
            default:
                return;
                break;
        }
        NSArray *sortedNames = [settings.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        [domain_dict setObject: sortedNames forKey: @"sorted_names"];
    
        [tableView reloadData];
    }
}

- (void) refreshFromRegistry: (NSString*) domain
{
    NSLog(@"RegistryView refreshing: %@", domain);
    ps_registry_iterate_domain(domain.UTF8String, registry_callback, (__bridge void *)(self));
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return my_domains.count;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return [my_domains.allKeys objectAtIndex: section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *sectionName = [my_domains.allKeys objectAtIndex: section];
    NSMutableDictionary *dict = [my_domains objectForKey: sectionName];
    NSArray *sortedSettingNames = [dict objectForKey: @"sorted_names"];
    return sortedSettingNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:@"SettingsCell"];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"SettingsCell"];
    }
    
    NSString *sectionName = [my_domains.allKeys objectAtIndex: indexPath.section];
    NSMutableDictionary *domain_dict = [my_domains objectForKey: sectionName];
    NSMutableDictionary *settings = [domain_dict objectForKey: @"settings"];
    NSArray *sortedSettingNames = [domain_dict objectForKey: @"sorted_names"];
    
    if (sortedSettingNames.count > indexPath.row)
    {
        NSString *settingName = [sortedSettingNames objectAtIndex:indexPath.row];
        NSMutableDictionary *dict = [settings objectForKey:settingName];
        cell.textLabel.text = settingName;
        
        int type = [[dict objectForKey:@"type"] intValue];
        
        switch(type)
        {
            case PS_REGISTRY_TEXT_TYPE:
            {
                cell.detailTextLabel.text = [dict objectForKey:@"value"];
            }
                break;
            case PS_REGISTRY_INT_TYPE:
            {
                cell.detailTextLabel.text = [[dict objectForKey:@"value"] stringValue];
            }
                break;
            case PS_REGISTRY_REAL_TYPE:
            {
                cell.detailTextLabel.text = [[dict objectForKey:@"value"] stringValue];
            }
                break;
            case PS_REGISTRY_BOOL_TYPE:
            {
                cell.detailTextLabel.text = ([[dict objectForKey:@"value"] boolValue] ? @"+++ON+++" : @"---OFF---");
            }
            default:
                break;
        }
        
        int flags = [[dict objectForKey:@"flags"] intValue];
        int source = [[dict objectForKey:@"source"] intValue];
        
        if ((flags & PS_REGISTRY_ANY_WRITE) || ((flags & PS_REGISTRY_SRC_WRITE) && (SOURCE == source)))
        {
            if (type == PS_REGISTRY_BOOL_TYPE)
            {
                UISwitch *sw = [switches objectForKey:settingName];
                if (!sw) {
                    sw = [[UISwitch alloc] init];
                    [switches setObject:sw forKey:settingName];
                    
                    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:sectionName, @"domain",
                                          settingName, @"name", nil];
                    
                    sw.tag = switchList.count;
                    [switchList addObject:dict];
                    [sw addTarget:self action:@selector(swChanged:) forControlEvents:UIControlEventValueChanged];
                }
                sw.on = [(NSNumber*)[dict objectForKey:@"value"] boolValue];
                
                cell.accessoryView  = sw;
            }
            else
            {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
        }
        
        NSString *imageName = [NSString stringWithFormat:@"%@.png", sectionName];
        UIImage *iv = [UIImage imageNamed: imageName];
        cell.imageView.image = iv;
    }
    return cell;
}

- (void) swChanged: (UISwitch *) sw
{
    NSDictionary *dict = [switchList objectAtIndex:sw.tag];
    NSString *domain = [dict objectForKey:@"domain"];
    NSString *name = [dict objectForKey:@"name"];
    
    ps_registry_set_bool([domain UTF8String], [name UTF8String], sw.on);
}

- (NSIndexPath *)tableView:(UITableView *)_tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *sectionName = [my_domains.allKeys objectAtIndex: indexPath.section];
    NSMutableDictionary *domain_dict = [my_domains objectForKey: sectionName];
    NSMutableDictionary *settings = [domain_dict objectForKey: @"settings"];
    NSArray *sortedSettingNames = [domain_dict objectForKey: @"sorted_names"];
    
    NSString *settingName = [sortedSettingNames objectAtIndex:indexPath.row];
    NSMutableDictionary *dict = [settings objectForKey:settingName];
    
    int type = [[dict objectForKey:@"type"] intValue];
    int flags = [[dict objectForKey:@"flags"] intValue];
    int source = [[dict objectForKey:@"source"] intValue];
    
    if ((flags & PS_REGISTRY_ANY_WRITE) || ((flags & PS_REGISTRY_SRC_WRITE) && (SOURCE == source)))
    {
        switch(type)
        {
            case PS_REGISTRY_INT_TYPE:
            case PS_REGISTRY_REAL_TYPE:
                break;
            default:
                return nil;
                break;
        }
        
        [detailController settingsDict: dict];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            detailController.modalPresentationStyle = UIModalPresentationPopover;
            
            // Get the popover presentation controller and configure it.
            UIPopoverPresentationController *presentationController =
            [detailController popoverPresentationController];
            presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
            presentationController.sourceView = self.view;
            presentationController.sourceRect = [tableView rectForRowAtIndexPath:indexPath];
            
            //        [self showViewController:detailController sender:self];
            [self presentViewController:detailController animated: YES completion: nil];
            
        }
        else
        {
            [self.navigationController pushViewController:detailController animated:YES];
        }
        return indexPath;
    }
    else
    {
        return nil;
    }
}

-(void) didReceiveMsg: (PubSubMsg*) message{

}



@end
