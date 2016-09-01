//
//  PubSubMsg.m
//  FIDO
//
//  Created by Martin Lane-Smith on 12/5/13.
//  Copyright (c) 2013 Martin Lane-Smith. All rights reserved.
//

#import "PubSubMsg.h"
#import "MasterViewController.h"
#import "ps.h"

@implementation PubSubMsg

+ (bool) sendMessage:(psMessage_t *) msg {
    PubSubMsg *message = [[PubSubMsg alloc] initWithMsg: msg];
    if (message) {
        return [message sendMessage];
    }
    else{
        return NO;
    }
}

+ (bool) sendSimpleMessage: (int) msgType {
    psMessage_t message;
    NSAssert1(msgType < PS_MSG_COUNT,@"Bad Message # %i", msgType);
    NSAssert1(psMsgFormats[msgType] == PS_NO_PAYLOAD, @"%s needs payload", psLongMsgNames[msgType]);
    
    message.messageType = msgType;
    
    return [PubSubMsg sendMessage: &message];
}

- (bool) sendMessage
{
    ps_publish(psDefaultTopics[_msg.messageType], (void*) &_msg,
              (int) psMessageFormatLengths[psMsgFormats[_msg.messageType]]);
    
    return true;
}

- (PubSubMsg*) initWithMsg: (psMessage_t *) msg {
    self = [super init];
    
    memcpy(&_msg, msg, sizeof(psMessage_t));
  
    return self;
}

- (void) publish
{
}

#define messagemacro(m,q,t,f,l) f,
int psMsgFormats[PS_MSG_COUNT] = {
#include "rm_message_list.h"
};
#undef messagemacro

#define messagemacro(m,q,t,f,l) l,
char *psLongMsgNames[PS_MSG_COUNT] = {
#include "rm_message_list.h"
};
#undef messagemacro

#define messagemacro(m,q,t,f,l) t,
int psDefaultTopics[PS_MSG_COUNT] = {
#include "rm_message_list.h"
};
#undef messagemacro

#define formatmacro(e,t,v,s) s,
int psMessageFormatLengths[PS_FORMAT_COUNT] = {
#include "rm_message_format_list.h"
};
#undef formatmacro

@end
