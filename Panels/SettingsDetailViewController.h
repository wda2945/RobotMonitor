//
//  SettingsDetailViewController.h
//  Monitor
//
//  Created by Martin Lane-Smith on 4/12/14.
//  Copyright (c) 2014 Martin Lane-Smith. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MessageDelegateProtocol.h"

@interface SettingsDetailViewController : UIViewController <MessageDelegate>

- (void) settingsDict: (NSMutableDictionary *) dict;

//@property (strong, nonatomic) UIPopoverController *popover;

@end
