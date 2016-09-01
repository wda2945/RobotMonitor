//
//  RegistryViewController.m
//  RoboMonitor
//
//  Created by Martin Lane-Smith on 2/2/15.
//  Copyright (c) 2015 Martin Lane-Smith. All rights reserved.
//

#import "BehaviorViewController.h"
#import "PubSubMsg.h"
#import "LogViewController.h"
#include "ps.h"

@interface BehaviorViewController ()
{
    UITableView *tableView;
    
    NSMutableDictionary *my_domains;
    
}
- (void) behavior_registry_updateFor: (NSString*) domain name: (NSString*) name;
- (void) refresh_from_registry: (NSString*) domain;

@end

@implementation BehaviorViewController

ps_registry_callback_t behaviors_registry_callback;

- (BehaviorViewController*) initForDomains: (NSArray*) _domains
{
    if (self = [super init])
    {
        self.view = tableView = [[UITableView alloc] init];
        tableView.dataSource = self;
        tableView.delegate = self;
        
        my_domains  = [NSMutableDictionary dictionary];
        
        for (NSString *domain in _domains)
        {
            NSLog(@"Behaviors Domain %i = %@", (int)my_domains.count+1, domain);
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         domain, @"domain_name",
                                         [NSMutableDictionary dictionary], @"settings",
                                         nil];
            [my_domains setObject: dict forKey: domain];
            
            ps_registry_set_observer(domain.UTF8String, "any", behaviors_registry_callback, (__bridge void *)(self));
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self refresh_from_registry: domain];
            });
        }
    }
    return self;
}

//callback for registry updates
void behaviors_registry_callback(const char *_domain, const char *_name, const void *arg)
{
    if (strcmp(_name, "any") == 0) return;
    
    NSString *domain = [NSString stringWithFormat:@"%s", _domain];
    NSString *name = [NSString stringWithFormat:@"%s", _name];
    
    BehaviorViewController *svc = (__bridge BehaviorViewController*) arg;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [svc behavior_registry_updateFor: domain name: name];
    });
}

//registry callback method
- (void) behavior_registry_updateFor: (NSString*) domain name: (NSString*) name
{
    NSLog(@"Behaviors callback for %@/%@", domain, name);

    NSMutableDictionary *domain_dict = [my_domains objectForKey: domain];
    
    if (domain_dict)
    {
        NSMutableDictionary *settings = [domain_dict objectForKey: @"settings"];
        NSMutableDictionary *dict = [settings objectForKey: name];
        
        ps_registry_struct_t reg_entry;
        if (ps_registry_get(domain.UTF8String, name.UTF8String, &reg_entry) != PS_OK) return;
        
        ps_registry_datatype_t type = reg_entry.datatype;
        
        if (!dict)
        {
            dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                    name, @"name",
                    [NSNumber numberWithInt:type], @"type",
                    [NSNumber numberWithInt:reg_entry.flags], @"flags",
                    [NSNumber numberWithInt:reg_entry.source], @"source",
                    nil];
            [settings setObject:dict forKey:name];
            
            NSArray *sortedSettingsNames =
                [settings.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
            [domain_dict setObject: sortedSettingsNames forKey: @"sorted"];
        }
        
        switch(type)
        {
            case PS_REGISTRY_TEXT_TYPE:
            {
                [dict setObject:[NSString stringWithFormat:@"%s", reg_entry.string_value] forKey:@"value"];
            }
                break;
            case PS_REGISTRY_INT_TYPE:
            {
                [dict setObject:[NSNumber numberWithInt:reg_entry.int_value] forKey:@"value"];
            }
                break;
            case PS_REGISTRY_REAL_TYPE:
            {
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

        if ([domain isEqualToString:@"Behavior Status"])
        {
            if ([name isEqualToString:@"Status"])
            {
                if (strcmp(reg_entry.string_value, "running") != 0)
                {
                    NSLog(@"%@ = %s", name, reg_entry.string_value);
                    
                    [LogViewController logAppMessage:[NSString stringWithFormat:@"Behavior: %s", reg_entry.string_value]];
                }
            }
            else
            {
                NSLog(@"%@ = %s", name, reg_entry.string_value);
            }
        }
        
        [tableView reloadData];
    }
}

- (void) refresh_from_registry: (NSString*) domain
{
    NSLog(@"BehaviorView refreshing: %@", domain);
    ps_registry_iterate_domain(domain.UTF8String, behaviors_registry_callback, (__bridge void *)(self));
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
    NSMutableDictionary *domain_dict = [my_domains objectForKey: sectionName];
    NSMutableDictionary *settings = [domain_dict objectForKey: @"settings"];
    return settings.count;
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
    NSArray *sortedSettingNames = [domain_dict objectForKey:@"sorted"];
   
    if (settings.allKeys.count > indexPath.row)
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

        
        NSString *imageName = [NSString stringWithFormat:@"%@.png", sectionName];
        UIImage *iv = [UIImage imageNamed: imageName];
        cell.imageView.image = iv;
    }
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)_tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *sectionName = [my_domains.allKeys objectAtIndex: indexPath.section];
    
    if ([sectionName isEqualToString:@"Behaviors"])
    {
        NSMutableDictionary *domain_dict = [my_domains objectForKey: sectionName];
        NSArray *sortedSettingNames = [domain_dict objectForKey: @"sorted"];
        NSString *settingName = [sortedSettingNames objectAtIndex:indexPath.row];
        
        psMessage_t msg;
        msg.messageType = ACTIVATE;
        strncpy(msg.namePayload.name, settingName.UTF8String, PS_NAME_LENGTH);
        msg.namePayload.name[PS_NAME_LENGTH] = '\0';
        
        [PubSubMsg sendMessage:&msg];
        
        [LogViewController logAppMessage:[NSString stringWithFormat:@"Activating %@", settingName]];
        return indexPath;
    }
    
   return nil;
}

@end
