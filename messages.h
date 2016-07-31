/* 
 * File:   Messages.h
 * Author: martin
 *
 * Enums and structs of Messages
 *
 */

#ifndef _MESSAGES_H_
#define _MESSAGES_H_

#include "ps.h"

//---------------------Message Formats

#include "rm_message_formats.h"

//---------------------Message Topics

#define topicmacro(e, name) e,
typedef enum {
#include "rm_topics_list.h"
    PS_TOPIC_COUNT
} ps_topic_id_enum;
#undef topicmacro

//---------------------Message codes enum

#define messagemacro(m,q,t,f,l) m,
typedef enum {
#include "rm_message_list.h"
    PS_MSG_COUNT
} psMessageType_enum;
#undef messagemacro

//---------------------Message Formats enum

#define formatmacro(e,t,p,s) e,

typedef enum {
#include "rm_message_format_list.h"
    PS_FORMAT_COUNT
} psMsgFormat_enum;
#undef formatmacro

//----------------------Complete message struct

//Generic struct for all messages

#define formatmacro(e,t,p,s) t p;
#pragma pack(1)
typedef struct {
    ps_message_id_t messageType;
    //Union option for each payload type
    union {
#include "rm_message_format_list.h"
    };
} psMessage_t;
#pragma pack()
#undef formatmacro

#endif
