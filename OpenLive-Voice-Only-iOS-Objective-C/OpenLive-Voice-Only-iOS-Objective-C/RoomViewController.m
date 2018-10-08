//
//  RoomViewController.m
//  OpenLiveVoice
//
//  Created by CavanSu on 2017/9/18.
//  Copyright © 2017 Agora. All rights reserved.
//

#import <AgoraAudioKit/AgoraRtcEngineKit.h>
#import "RoomViewController.h"
#import "AppID.h"
#import "InfoCell.h"
#import "InfoModel.h"

@interface RoomViewController () <UITableViewDataSource, UITableViewDelegate, AgoraRtcEngineDelegate>
@property (weak, nonatomic) IBOutlet UILabel *roomNameLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *roleButton;
@property (weak, nonatomic) IBOutlet UIButton *speakerButton;
@property (nonatomic, strong) NSMutableArray *infoArray;
@property (nonatomic, strong) AgoraRtcEngineKit *agoraKit;
@end

static NSString *cellID = @"infoID";

@implementation RoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateViews];
    [self loadAgoraKit];
}

#pragma mark- setupViews
- (void)updateViews {
    self.roomNameLabel.text = self.channelName;
    self.tableView.backgroundColor = [UIColor clearColor];
}

#pragma mark- initAgoraKit
- (void)loadAgoraKit {
    self.agoraKit = [AgoraRtcEngineKit sharedEngineWithAppId:[AppID appID] delegate:self];
    
    [self.agoraKit setChannelProfile:AgoraRtc_ChannelProfile_LiveBroadcasting];
    
    AgoraRtcClientRole role;
    
    switch (self.roleType) {
        case RoleTypeBroadcaster:
            role = AgoraRtc_ClientRole_Broadcaster;
            self.roleButton.selected = NO;
            [self appendInfoToTableViewWithInfo:@"Set Broadcaster"];
            break;
            
        case RoleTypeAudience:
            role = AgoraRtc_ClientRole_Audience;
            self.roleButton.selected = YES;
            [self appendInfoToTableViewWithInfo:@"Set Audience"];
            break;
    }
    [self.agoraKit setClientRole:role withKey:nil];
    [self.agoraKit joinChannelByKey:nil channelName:self.channelName info:nil uid:0 joinSuccess:nil];
}

#pragma mark- Append info to tableView to display
- (void)appendInfoToTableViewWithInfo:(NSString *)infoStr {
    InfoModel *model = [InfoModel modelWithInfoStr:infoStr];
    [self.infoArray insertObject:model atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
}

#pragma mark- Click buttons
- (IBAction)clickMuteButton:(UIButton *)sender {
    [self.agoraKit muteLocalAudioStream:sender.selected];
}

- (IBAction)clickHungUpButton:(UIButton *)sender {
    __weak typeof(RoomViewController) *weakself = self;
    [self.agoraKit leaveChannel:^(AgoraRtcStats * _Nonnull stat) {
        [weakself dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (IBAction)clickSpeakerButton:(UIButton *)sender {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        sender.selected = NO;
    }
    else {
        [self.agoraKit setEnableSpeakerphone:!sender.selected];
    }
}

- (IBAction)clickRoleButton:(UIButton *)sender {
    AgoraRtcClientRole role = sender.selected ? AgoraRtc_ClientRole_Audience : AgoraRtc_ClientRole_Broadcaster;
    if (role == AgoraRtc_ClientRole_Broadcaster && self.speakerButton.selected) {
        self.speakerButton.selected = NO;
    }
    [self.agoraKit setClientRole:role withKey:nil];
}

#pragma mark- <AgoraRtcEngineDelegate>
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinChannel:(NSString*)channel withUid:(NSUInteger)uid elapsed:(NSInteger) elapsed {
    [self appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"Self join channel with uid:%zd", uid]];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed {
    [self appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"Uid:%zd joined channel with elapsed:%zd", uid, elapsed]];
}

- (void)rtcEngineConnectionDidInterrupted:(AgoraRtcEngineKit *)engine {
    [self appendInfoToTableViewWithInfo:@"ConnectionDidInterrupted"];
}

- (void)rtcEngineConnectionDidLost:(AgoraRtcEngineKit *)engine {
    [self appendInfoToTableViewWithInfo:@"ConnectionDidLost"];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurError:(AgoraRtcErrorCode)errorCode {
    [self appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"Error Code:%zd", errorCode]];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraRtcUserOfflineReason)reason {
    [self appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"Uid:%zd didOffline reason:%zd", uid, reason]];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didAudioRouteChanged:(AgoraRtcAudioOutputRouting)routing {
    switch (routing) {
        case AgoraRtc_AudioOutputRouting_Default:
            NSLog(@"AgoraRtc_AudioOutputRouting_Default");
            break;
        case AgoraRtc_AudioOutputRouting_Headset:
            NSLog(@"AgoraRtc_AudioOutputRouting_Headset");
            break;
        case AgoraRtc_AudioOutputRouting_Earpiece:
            NSLog(@"AgoraRtc_AudioOutputRouting_Earpiece");
            break;
        case AgoraRtc_AudioOutputRouting_HeadsetNoMic:
            NSLog(@"AgoraRtc_AudioOutputRouting_HeadsetNoMic");
            break;
        case AgoraRtc_AudioOutputRouting_Speakerphone:
            NSLog(@"AgoraRtc_AudioOutputRouting_Speakerphone");
            break;
        case AgoraRtc_AudioOutputRouting_Loudspeaker:
            NSLog(@"AgoraRtc_AudioOutputRouting_Loudspeaker");
            break;
        case AgoraRtc_AudioOutputRouting_HeadsetBluetooth:
            NSLog(@"AgoraRtc_AudioOutputRouting_HeadsetBluetooth");
            break;
        default:
            break;
    }
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didClientRoleChanged:(AgoraRtcClientRole)oldRole newRole:(AgoraRtcClientRole)newRole {
    if (newRole == AgoraRtc_ClientRole_Broadcaster) {
        [self appendInfoToTableViewWithInfo:@"Self changed to Broadcaster"];
    }
    else {
        [self appendInfoToTableViewWithInfo:@"Self changed to Audience"];
    }
}

#pragma mark- <UITableViewDataSource>
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.infoArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    InfoCell *cell =  [tableView dequeueReusableCellWithIdentifier:cellID];
    InfoModel *model = self.infoArray[indexPath.row];
    cell.model = model;
    return cell;
}

#pragma mark- <UITableViewDelegate>
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    InfoModel *model = self.infoArray[indexPath.row];
    return model.height;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 20;
}

#pragma mark- others
- (NSMutableArray *)infoArray {
    if (!_infoArray) {
        _infoArray = [NSMutableArray array];
    }
    return _infoArray;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
