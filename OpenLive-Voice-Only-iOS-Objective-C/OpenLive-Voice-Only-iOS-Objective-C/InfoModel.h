//
//  InfoModel.h
//  OpenLiveVoice
//
//  Created by CavanSu on 2017/9/18.
//  Copyright © 2017 Agora. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfoModel : NSObject
@property (nonatomic, copy) NSString *infoStr;
@property (nonatomic, assign) CGFloat height;
+ (instancetype)modelWithInfoStr:(NSString *)infoStr;
@end
