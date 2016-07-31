//
//  PubSubMsg.h
//  FIDO
//
//  Created by Martin Lane-Smith on 12/5/13.
//  Copyright (c) 2013 Martin Lane-Smith. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "messages.h"

@interface PubSubMsg : NSObject

@property psMessage_t           msg;

//outgoing
+ (bool) sendMessage:(psMessage_t *) _msg;
+ (bool) sendSimpleMessage: (int) msgType;  //no payload

- (bool) sendMessage;

//incoming
- (PubSubMsg*) initWithMsg: (psMessage_t *) msg;
- (void) publish;

@end
