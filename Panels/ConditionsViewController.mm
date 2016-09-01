//
//  ConditionsViewController.mm
//  RoboMonitor
//
//  Created by Martin Lane-Smith on 2/2/15.
//  Copyright (c) 2015 Martin Lane-Smith. All rights reserved.
//

#import "ConditionsViewController.h"
#include "ps.h"

@interface ConditionsViewController ()
{
    UITableView *tableView;
    
    Source_t my_source;
    NSString *my_section;
    NSMutableDictionary *conditions;
    NSArray *sortedConditionNames;

    bool condition_state[PS_CONDITIONS_COUNT];

}
- (void) registry_callback_for: (NSString*) domain name: (NSString*) name;
- (void) refresh_from_registry: (NSString*) domain;

- (void) condition_callback_from: (Source_t) src forCondition: (ps_condition_id_t) condition state: (bool) set_value;

@end

@implementation ConditionsViewController

//callback for registry (name) update
void conditions_registry_callback(const char *_domain, const char *_name, const void *arg)
{
    if (strcmp(_name, "any") == 0) return;
    
    NSString *domain = [NSString stringWithFormat:@"%s", _domain];
    NSString *name = [NSString stringWithFormat:@"%s", _name];
    
    ConditionsViewController *svc = (__bridge ConditionsViewController*) arg;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [svc registry_callback_for: domain name: name];
    });
}

//callback for change in condition
void condition_callback(void *arg, Source_t src, ps_condition_id_t condition, bool condition_set)
{
    ConditionsViewController *svc = (__bridge ConditionsViewController*) arg;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [svc condition_callback_from: src forCondition: condition state: condition_set];
    });
}

- (ConditionsViewController*) init
{
    return self;
}

- (ConditionsViewController*) initForSource: (Source_t) src domain: (NSString*) section
{
    if (self = [super init])
    {
        self.view = tableView = [[UITableView alloc] init];
        tableView.dataSource = self;
        tableView.delegate = self;
        
        my_source = src;
        my_section = section;
        conditions = [NSMutableDictionary dictionary];
        
        ps_registry_set_observer(section.UTF8String, "any", conditions_registry_callback, (__bridge void *)(self));
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refresh_from_registry: section];
        });
        
    }
    return self;
}

//method for change in condition callback
- (void) condition_callback_from: (Source_t) src forCondition: (ps_condition_id_t) condition state: (bool) set_value
{
    if ((src == my_source) && (condition > 0) && (condition < PS_CONDITIONS_COUNT))
    {
        condition_state[condition] = set_value;
        
        [tableView reloadData];
    }
}


//method for registry (name) callback
- (void) registry_callback_for: (NSString*) domain name: (NSString*) name
{
    NSLog(@"Conditions callback for %@/%@", domain, name);
    
    if ([domain isEqualToString:my_section])
    {
        //one of mine
        ps_registry_struct_t reg_entry;
        if (ps_registry_get(domain.UTF8String, name.UTF8String, &reg_entry) != PS_OK) return;

        if ((reg_entry.source == my_source)
                && (reg_entry.int_value > 0)
                && ![conditions objectForKey: name])
        {
            //new condition name
            [conditions setObject: [NSNumber numberWithInt:reg_entry.int_value] forKey: name];
            ps_add_condition_observer(reg_entry.source, reg_entry.int_value, condition_callback, (__bridge void *)(self));
            
            sortedConditionNames =
                [conditions.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
            
            [tableView reloadData];
        }
    }
}

- (void) refresh_from_registry: (NSString*) domain
{
    NSLog(@"ConditionsView refreshing: %@", domain);
    ps_registry_iterate_domain(domain.UTF8String, conditions_registry_callback, (__bridge void *)(self));
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return my_section;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return conditions.count;
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:@"conditionsCell"];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"conditionsCell"];
    }
    
    if (conditions.count > indexPath.row)
    {
        NSString *name = [sortedConditionNames objectAtIndex:indexPath.row];

        NSNumber *key = [conditions objectForKey:name];
        
        cell.textLabel.text = name;
        
        if (condition_state[[key intValue]])
        {
            cell.detailTextLabel.text = @"++++ set ++++";
            cell.detailTextLabel.textColor = [UIColor redColor];
            cell.textLabel.textColor = [UIColor redColor];
        }
        else
        {
            cell.detailTextLabel.text = @"---- clear ----";
            cell.detailTextLabel.textColor = [UIColor greenColor];
            cell.textLabel.textColor = [UIColor greenColor];
        }
        
        
        UIImage *iv = [UIImage imageNamed: @"condition.png"];
        cell.imageView.image = iv;
    }
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)_tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}


@end
