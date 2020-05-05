//
//  RoomViewController.m
//  OpenLiveVoice
//
//  Created by CavanSu on 2017/9/18.
//  Copyright © 2017 Agora. All rights reserved.
//

#import <AgoraRtcKit/AgoraRtcEngineKit.h>
#import "RoomViewController.h"
#import "KeyCenter.h"
#import "InfoCell.h"
#import "InfoModel.h"

@interface RoomViewController () <UITableViewDataSource, UITableViewDelegate, AgoraRtcEngineDelegate>
@property (weak, nonatomic) IBOutlet UILabel *roomNameLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *roleButton;
@property (weak, nonatomic) IBOutlet UIButton *speakerButton;
@property (nonatomic, strong) NSMutableArray *infoArray;
@property (nonatomic, strong) AgoraRtcEngineKit *agoraKit;  // RTC engine instance
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
    // Initial the engine kit instance with the AppID from the project
    self.agoraKit = [AgoraRtcEngineKit sharedEngineWithAppId:[KeyCenter AppId] delegate:self];
    
    // Set up Chat Channel profile.  In this app, it is Live Broadcasting; other may be Communication.
    [self.agoraKit setChannelProfile:AgoraChannelProfileLiveBroadcasting];
    
    // Role of the client; "host" usually means Broadcaster
    AgoraClientRole role;
    
    switch (self.roleType) {
        case RoleTypeBroadcaster:
            role = AgoraClientRoleBroadcaster;
            self.roleButton.selected = NO;
            [self appendInfoToTableViewWithInfo:@"Set Broadcaster"];
            break;
            
        case RoleTypeAudience:
            role = AgoraClientRoleAudience;
            self.roleButton.selected = YES;
            [self appendInfoToTableViewWithInfo:@"Set Audience"];
            break;
    }
    [self.agoraKit setClientRole:role];
    
    // Join the channel, if successful, callback didJoinChannel will be called
    [self.agoraKit joinChannelByToken:nil channelId:self.channelName info:nil uid:0 joinSuccess:nil];
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
    [self.agoraKit leaveChannel:^(AgoraChannelStats * _Nonnull stat) {
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
    // changing role involves reassiging the AgoraClientRole on the API
    AgoraClientRole role = sender.selected ? AgoraClientRoleAudience : AgoraClientRoleBroadcaster;
    if (role == AgoraClientRoleBroadcaster && self.speakerButton.selected) {
        self.speakerButton.selected = NO;
    }
    [self.agoraKit setClientRole:role];
}

#pragma mark- <AgoraRtcEngineDelegate>

/** Occurs when the local user joins a specified channel.

Same as `joinSuccessBlock` in the [joinChannelByToken]([AgoraRtcEngineKit joinChannelByToken:channelId:info:uid:joinSuccess:]) method.

@param engine  AgoraRtcEngineKit object.
@param channel Channel name.
@param uid  local user's ID. If the `uid` is specified in the joinChannelByToekn method; if not specified, this is the system assigned uid.
@param elapsed Time elapsed (ms) from the user calling the [joinChannelByToken]([AgoraRtcEngineKit joinChannelByToken:channelId:info:uid:joinSuccess:]) method until the SDK triggers this callback.
*/
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinChannel:(NSString*)channel withUid:(NSUInteger)uid elapsed:(NSInteger) elapsed {
    [self appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"Self join channel with uid:%zd", uid]];
}

/** Occurs when a remote user or host joins a channel. Same as [userJoinedBlock]([AgoraRtcEngineKit userJoinedBlock:]).

- Communication profile: This callback notifies the app that another user joins the channel. If other users are already in the channel, the SDK also reports to the app on the existing users.
- Live-broadcast profile: This callback notifies the app that a host joins the channel. If other hosts are already in the channel, the SDK also reports to the app on the existing hosts. Agora recommends limiting the number of hosts to 17.

The SDK triggers this callback under one of the following circumstances:
- A remote user/host joins the channel by calling the [joinChannelByToken]([AgoraRtcEngineKit joinChannelByToken:channelId:info:uid:joinSuccess:]) method.
- A remote user switches the user role to the host by calling the [setClientRole]([AgoraRtcEngineKit setClientRole:]) method after joining the channel.
- A remote user/host rejoins the channel after a network interruption.
- A host injects an online media stream into the channel by calling the [addInjectStreamUrl]([AgoraRtcEngineKit addInjectStreamUrl:config:]) method.

**Note:**

Live-broadcast profile:

* The host receives this callback when another host joins the channel.
* The audience in the channel receives this callback when a new host joins the channel.
* When a web application joins the channel, the SDK triggers this callback as long as the web application publishes streams.

@param engine  AgoraRtcEngineKit object.
@param uid     ID of the user or host who joins the channel. If the `uid` is specified in the [joinChannelByToken]([AgoraRtcEngineKit joinChannelByToken:channelId:info:uid:joinSuccess:]) method, the specified user ID is returned. If the `uid` is not specified in the joinChannelByToken method, the Agora server automatically assigns a `uid`.
@param elapsed Time elapsed (ms) from the local user calling the [joinChannelByToken]([AgoraRtcEngineKit joinChannelByToken:channelId:info:uid:joinSuccess:]) or [setClientRole]([AgoraRtcEngineKit setClientRole:]) method until the SDK triggers this callback.
*/
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed {
    [self appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"Uid:%zd joined channel with elapsed:%zd", uid, elapsed]];
}

/** Occurs when the connection between the SDK and the server is interrupted.

The SDK triggers this callback when it loses connection with the server for more than four seconds after a connection is established.

After triggering this callback, the SDK tries reconnecting to the server. You can use this callback to implement pop-up reminders.

- The SDK triggers the [rtcEngineConnectionDidInterrupted]([AgoraRtcEngineDelegate rtcEngineConnectionDidInterrupted:]) callback when it loses connection with the server for more than four seconds after it joins the channel.
- The SDK triggers the [rtcEngineConnectionDidLost]([AgoraRtcEngineDelegate rtcEngineConnectionDidLost:]) callback when it loses connection with the server for more than 10 seconds, regardless of whether it joins the channel or not.

If the SDK fails to rejoin the channel 20 minutes after being disconnected from Agora's edge server, the SDK stops rejoining the channel.

 @param engine AgoraRtcEngineKit object.
 */
- (void)rtcEngineConnectionDidInterrupted:(AgoraRtcEngineKit *)engine {
    [self appendInfoToTableViewWithInfo:@"ConnectionDidInterrupted"];
}

/** Occurs when the SDK cannot reconnect to Agora's edge server 10 seconds after its connection to the server is interrupted.

The SDK triggers this callback when it cannot connect to the server 10 seconds after calling the [joinChannelByToken]([AgoraRtcEngineKit joinChannelByToken:channelId:info:uid:joinSuccess:]) method, regardless of whether it is in the channel or not.

- The SDK triggers the [rtcEngineConnectionDidInterrupted]([AgoraRtcEngineDelegate rtcEngineConnectionDidInterrupted:]) callback when it loses connection with the server for more than four seconds after it successfully joins the channel.
- The SDK triggers the [rtcEngineConnectionDidLost]([AgoraRtcEngineDelegate rtcEngineConnectionDidLost:]) callback when it loses connection with the server for more than 10 seconds, regardless of whether it joins the channel or not.

If the SDK fails to rejoin the channel 20 minutes after being disconnected from Agora's edge server, the SDK stops rejoining the channel.

@param engine AgoraRtcEngineKit object.
 */
- (void)rtcEngineConnectionDidLost:(AgoraRtcEngineKit *)engine {
    [self appendInfoToTableViewWithInfo:@"ConnectionDidLost"];
}


/** Reports an error during SDK runtime.

In most cases, the SDK cannot fix the issue and resume running. The SDK requires the app to take action or informs the user about the issue.

For example, the SDK reports an AgoraErrorCodeStartCall = 1002 error when failing to initialize a call. The app informs the user that the call initialization failed and invokes the [leaveChannel]([AgoraRtcEngineKit leaveChannel:]) method to leave the channel.

See [AgoraErrorCode](AgoraErrorCode).

 @param engine    AgoraRtcEngineKit object
 @param errorCode Error code: AgoraErrorCode
 */
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurError:(AgoraErrorCode)errorCode {
    [self appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"Error Code:%zd", errorCode]];
}


/** Occurs when a remote user (Communication)/host (Live Broadcast) leaves a channel. Same as [userOfflineBlock]([AgoraRtcEngineKit userOfflineBlock:]).

There are two reasons for users to be offline:

- Leave a channel: When the user/host leaves a channel, the user/host sends a goodbye message. When the message is received, the SDK assumes that the user/host leaves a channel.
- Drop offline: When no data packet of the user or host is received for a certain period of time (20 seconds for the Communication profile, and more for the Live-broadcast profile), the SDK assumes that the user/host drops offline. Unreliable network connections may lead to false detections, so Agora recommends using a signaling system for more reliable offline detection.

 @param engine AgoraRtcEngineKit object.
 @param uid    ID of the user or host who leaves a channel or goes offline.
 @param reason Reason why the user goes offline, see AgoraUserOfflineReason.
 */
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraUserOfflineReason)reason {
    [self appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"Uid:%zd didOffline reason:%zd", uid, reason]];
}

/** Occurs when the local audio route changes.

The SDK triggers this callback when the local audio route switches to an earpiece, speakerphone, headset, or Bluetooth device.

 @param engine  AgoraRtcEngineKit object.
 @param routing Audio route: AgoraAudioOutputRouting.
 */
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didAudioRouteChanged:(AgoraAudioOutputRouting)routing {
    switch (routing) {
        case AgoraAudioOutputRoutingDefault:
            NSLog(@"AgoraRtc_AudioOutputRouting_Default");
            break;
        case AgoraAudioOutputRoutingHeadset:
            NSLog(@"AgoraRtc_AudioOutputRouting_Headset");
            break;
        case AgoraAudioOutputRoutingEarpiece:
            NSLog(@"AgoraRtc_AudioOutputRouting_Earpiece");
            break;
        case AgoraAudioOutputRoutingHeadsetNoMic:
            NSLog(@"AgoraRtc_AudioOutputRouting_HeadsetNoMic");
            break;
        case AgoraAudioOutputRoutingSpeakerphone:
            NSLog(@"AgoraRtc_AudioOutputRouting_Speakerphone");
            break;
        case AgoraAudioOutputRoutingLoudspeaker:
            NSLog(@"AgoraRtc_AudioOutputRouting_Loudspeaker");
            break;
        case AgoraAudioOutputRoutingHeadsetBluetooth:
            NSLog(@"AgoraRtc_AudioOutputRouting_HeadsetBluetooth");
            break;
        default:
            break;
    }
}

/** Occurs when the local user role switches in a live broadcast.

The SDK triggers this callback when the local user switches the user role by calling the [setClientRole]([AgoraRtcEngineKit setClientRole:]) method after joining the channel.

 @param engine  AgoraRtcEngineKit object.
 @param oldRole Role that the user switches from: AgoraClientRole.
 @param newRole Role that the user switches to: AgoraClientRole.
 */
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didClientRoleChanged:(AgoraClientRole)oldRole newRole:(AgoraClientRole)newRole {
    if (newRole == AgoraClientRoleBroadcaster) {
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
