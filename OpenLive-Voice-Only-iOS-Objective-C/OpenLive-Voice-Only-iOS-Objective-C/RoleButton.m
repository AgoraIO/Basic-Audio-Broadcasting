//
//  RoleButton.m
//  OpenLiveVoice
//
//  Created by CavanSu on 2017/9/30.
//  Copyright © 2017 Agora. All rights reserved.
//

#import "RoleButton.h"

@implementation RoleButton
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat imageViewWH = 44;
    CGFloat imageViewY = (self.frame.size.width - imageViewWH) * 0.5;
    CGFloat labelWH = 20;
    self.imageView.frame = CGRectMake(imageViewY, 0, imageViewWH, imageViewWH);
    self.titleLabel.frame = CGRectMake(0, imageViewWH, self.frame.size.width, labelWH);
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont systemFontOfSize:14];
}

- (void)sendAction:(SEL)action to:(nullable id)target forEvent:(nullable UIEvent *)event {
    self.selected = !self.selected;
    [super sendAction:action to:target forEvent:event];
}

- (void)drawRect:(CGRect)rect {
    if (!self.selected) {
        CGPoint point = self.imageView.center;
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:point radius:self.imageView.bounds.size.width * 0.5 - 1 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
        [[UIColor whiteColor] setFill];
        [path fill];
    }
}
@end
