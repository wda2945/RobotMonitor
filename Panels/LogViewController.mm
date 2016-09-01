//
//  DetailViewController.m
//  Monitor
//
//  Created by Martin Lane-Smith on 4/12/14.
//  Copyright (c) 2014 Martin Lane-Smith. All rights reserved.
//

#import "syslog/ios/ps_syslog_ios.hpp"
#import "LogViewController.h"


LogViewController *thisLogViewController;

@interface LogViewController () {
    bool viewLoaded;
    UITableView *tableView;

}
- (void) logRobotMessage: (ps_syslog_message_t) message;

@property (strong, nonatomic) NSMutableArray *logMessages;
@end

@implementation LogViewController

void syslog_callback(ps_syslog_message_t *_logMsg)
{
    ps_syslog_message_t logMsg;
    
    memcpy(&logMsg, _logMsg, sizeof(ps_syslog_message_t));
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[LogViewController getLogViewController] logRobotMessage: logMsg];
    });
}

static ps_syslog_ios log_object(syslog_callback);

- (LogViewController*) init
{
    if (self = [super init])
    {
        self.view = tableView = [[UITableView alloc] init];
        tableView.dataSource = self;
        tableView.delegate = self;
        
        viewLoaded = YES;
        self.logMessages = [[NSMutableArray alloc] initWithCapacity:50];
        [self logMessage:@"Log Started"];
        thisLogViewController = self;
        
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    viewLoaded = YES;
}

+ (LogViewController*) getLogViewController
{
    return thisLogViewController;
}
+ (void) logAppMessage: (NSString*) message
{
    NSString *log = [NSString stringWithFormat:@"---@APP: %@", message];
    [[LogViewController getLogViewController] logMessage:log];
}
+ (void) ClearLog
{
    [LogViewController getLogViewController].logMessages = [[NSMutableArray alloc] initWithCapacity:50];
    [(UITableView*)[LogViewController getLogViewController].view reloadData];
}
- (void)viewWillAppear:(BOOL)animated {
    if (!_logMessages)
    {
        self.logMessages = [[NSMutableArray alloc] initWithCapacity:50];
        [self logMessage:@"Log Started"];
    }
    [(UITableView*)self.view reloadData];
    NSIndexPath *path = [NSIndexPath indexPathForRow:_logMessages.count-1 inSection:0];
    [(UITableView*)self.view scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void) logRobotMessage: (ps_syslog_message_t) message
{
    NSString *severity;
    NSString *source = @"???";
    
    char logString[PS_MAX_LOG_TEXT+1];
    strncpy(logString, message.text, PS_MAX_LOG_TEXT);
    logString[PS_MAX_LOG_TEXT] = '\0';
    
    char logFile[PS_SOURCE_LENGTH+1];
    strncpy(logFile, message.source, PS_SOURCE_LENGTH);
    logFile[PS_SOURCE_LENGTH] = '\0';
    
    if (strlen(logFile) > 0) source = [NSString stringWithFormat:@"%s", logFile];
    
    switch (message.severity){
        case SYSLOG_ROUTINE:
            severity = @"RRR";
            break;
        case SYSLOG_INFO:
            severity = @"INF";
            break;
        case SYSLOG_WARNING:
            severity = @"WRN";
            break;
        case SYSLOG_ERROR:
            severity = @"ERR";
            break;
        case SYSLOG_FAILURE:
            severity = @"FAI";
            break;
        default:
            severity = @"???";
            break;
    }
    
    NSString *log = [NSString stringWithFormat:@"%@@%@: %s", severity, source,
                     logString];
    [self logMessage: log];
}
- (void) logMessage: (NSString*) log
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    NSString *logmess = [NSString stringWithFormat:@"%@: %@",
                         [dateFormatter stringFromDate:[NSDate date]], log];
    [_logMessages addObject:logmess];
    
    if (viewLoaded)
    {
        NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:0];
        [(UITableView*)self.view insertRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationTop];
        path = [NSIndexPath indexPathForRow:0 inSection:0];
        [(UITableView*)self.view scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:YES];
        
        [(UITableView*)self.view reloadData];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _logMessages.count;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LogViewCell"];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LogViewCell"];
    }
    cell.textLabel.text = [_logMessages objectAtIndex: (_logMessages.count - indexPath.row - 1)];
    return cell;
}
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
