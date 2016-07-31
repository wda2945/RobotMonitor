//
//  CollectionProtocol.h
//  FidoMonitor
//
//  Created by Martin Lane-Smith on 2/2/16.
//  Copyright © 2016 Martin Lane-Smith. All rights reserved.
//

#ifndef CollectionProtocol_h
#define CollectionProtocol_h

@protocol CollectionController
@required
- (void) addViewController: (UIViewController*) controller;
- (bool) presentView: (NSString*) name;
- (void) firstView: (NSString*) name;
@end

#endif /* CollectionProtocol_h */
