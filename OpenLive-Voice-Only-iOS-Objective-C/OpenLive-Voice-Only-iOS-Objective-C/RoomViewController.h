//
//  RoomViewController.h
//  OpenLiveVoice
//
//  Created by CavanSu on 2017/9/18.
//  Copyright © 2017 Agora. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Define.h"

@interface RoomViewController : UIViewController
@property (nonatomic, copy) NSString *channelName;
@property (nonatomic, assign) RoleType roleType;
@end
