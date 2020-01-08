//
//  MainViewController.m
//  OpenLiveVoice
//
//  Created by CavanSu on 2017/9/16.
//  Copyright © 2017 Agora. All rights reserved.
//

#import "MainViewController.h"
#import "ChannelNameCheck.h"
#import "RoomViewController.h"

@interface MainViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIButton *joinButton;
@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;
@property (weak, nonatomic) IBOutlet UITextField *channelNameTextField;
@property (nonatomic, assign) RoleType roleType;
@end

@implementation MainViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateViews];
}

- (void)updateViews {
    [self.joinButton setTitleColor:ThemeColor forState:UIControlStateNormal];
    self.joinButton.backgroundColor = [UIColor whiteColor];
    self.welcomeLabel.adjustsFontSizeToFitWidth = YES;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.joinButton.layer.cornerRadius = self.joinButton.bounds.size.height * 0.5;
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(nullable id)sender {
    BOOL YesOrNo = self.channelNameTextField.text.length > 0 ? YES : NO;
    return YesOrNo;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(nullable id)sender {
    RoomViewController *roomVC = segue.destinationViewController;
    roomVC.channelName = self.channelNameTextField.text;
    roomVC.roleType = self.roleType;
}

- (IBAction)editingChannelName:(UITextField *)sender {
    NSString *legalChannelName = [ChannelNameCheck channelNameCheckLegal:sender.text];
    sender.text = legalChannelName;
}

- (IBAction)clickJoinButton:(UIButton *)sender {
    UIAlertController *alertController  = [UIAlertController alertControllerWithTitle:@"Choose Role" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *audienceAction = [UIAlertAction actionWithTitle:@"Audience" style:0 handler:^(UIAlertAction * _Nonnull action) {
        [self enterRoomWithRoleType:RoleTypeAudience];
    }];
    
    UIAlertAction *hostAction = [UIAlertAction actionWithTitle:@"Host" style:0 handler:^(UIAlertAction * _Nonnull action) {
        [self enterRoomWithRoleType:RoleTypeBroadcaster];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:0 handler:nil];
    
    [alertController addAction:audienceAction];
    [alertController addAction:hostAction];
    [alertController addAction:cancelAction];
    
    alertController.popoverPresentationController.sourceView = self.joinButton;
    alertController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// Enter Room After Click AlertAction
- (void)enterRoomWithRoleType:(RoleType)roleType {
    self.roleType = roleType;
    [self performSegueWithIdentifier:@"mainToLive" sender:nil];
}

#pragma mark- <UITextFieldDelegate>
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.channelNameTextField endEditing:YES];
    return YES;
}

// End Edit
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.channelNameTextField endEditing:YES];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}
@end
