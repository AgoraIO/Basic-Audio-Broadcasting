//
//  RoomViewController.swift
//  OpenLiveVoice
//
//  Created by GongYuhua on 2017/4/7.
//  Copyright © 2017年 Agora. All rights reserved.
//

import UIKit
import AgoraRtcKit

protocol RoomVCDelegate: class {
    func roomVCNeedClose(_ roomVC: RoomViewController)
}

class RoomViewController: UIViewController {
    
    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var logTableView: UITableView!
    @IBOutlet weak var broadcastButton: UIButton!
    @IBOutlet weak var muteAudioButton: UIButton!
    @IBOutlet weak var speakerButton: UIButton!
    
    var roomName: String!
    var clientRole = AgoraClientRole.audience {
        didSet {
            updateBroadcastButton()
        }
    }
    weak var delegate: RoomVCDelegate?
    
    fileprivate var agoraKit: AgoraRtcEngineKit!
    fileprivate var logs = [String]()
    
    fileprivate var isBroadcaster: Bool {
        return clientRole == .broadcaster
    }
    fileprivate var audioMuted = false {
        didSet {
            muteAudioButton?.setImage(audioMuted ? #imageLiteral(resourceName: "btn_mute_blue") : #imageLiteral(resourceName: "btn_mute"), for: .normal)
        }
    }
    
    fileprivate var speakerEnabled = true {
        didSet {
            speakerButton?.setImage(speakerEnabled ? #imageLiteral(resourceName: "btn_speaker_blue") : #imageLiteral(resourceName: "btn_speaker"), for: .normal)
            speakerButton?.setImage(speakerEnabled ? #imageLiteral(resourceName: "btn_speaker") : #imageLiteral(resourceName: "btn_speaker_blue"), for: .highlighted)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        roomNameLabel.text = "\(roomName!)"
        logTableView.rowHeight = UITableView.automaticDimension
        logTableView.estimatedRowHeight = 25
        
        updateBroadcastButton()
        
        loadAgoraKit()
    }
    
    @IBAction func doBroadcastPressed(_ sender: UIButton) {
        audioMuted = false
        clientRole = isBroadcaster ? .audience : .broadcaster
        
        agoraKit.setClientRole(clientRole)
    }
    
    @IBAction func doMuteAudioPressed(_ sender: UIButton) {
        audioMuted = !audioMuted
        // mute local audio
        agoraKit.muteLocalAudioStream(audioMuted)
    }
    
    @IBAction func doSpeakerPressed(_ sender: UIButton) {
        speakerEnabled = !speakerEnabled
        agoraKit.setEnableSpeakerphone(speakerEnabled)
    }
    
    @IBAction func doClosePressed(_ sender: UIButton) {
        leaveChannel()
    }
}

private extension RoomViewController {
    func append(log string: String) {
        guard !string.isEmpty else {
            return
        }
        
        logs.append(string)
        
        var deleted: String?
        if logs.count > 200 {
            deleted = logs.removeFirst()
        }
        
        updateLogTable(withDeleted: deleted)
    }
    
    func updateLogTable(withDeleted deleted: String?) {
        guard let tableView = logTableView else {
            return
        }
        
        let insertIndexPath = IndexPath(row: logs.count - 1, section: 0)
        
        tableView.beginUpdates()
        if deleted != nil {
            tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        }
        tableView.insertRows(at: [insertIndexPath], with: .none)
        tableView.endUpdates()
        
        tableView.scrollToRow(at: insertIndexPath, at: .bottom, animated: false)
    }
    
    func updateBroadcastButton() {
        muteAudioButton?.isEnabled = isBroadcaster
        broadcastButton?.setImage(isBroadcaster ? #imageLiteral(resourceName: "btn_join_blue") : #imageLiteral(resourceName: "btn_join"), for: .normal)
    }
}

//MARK: - table view
extension RoomViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "logCell", for: indexPath) as! LogCell
        cell.set(log: logs[(indexPath as NSIndexPath).row])
        return cell
    }
}

//MARK: - engine
private extension RoomViewController {
    func loadAgoraKit() {
        // Initialize the Agora engine with your key. Set the delegate to recieve AgoraRtcEngineKit events
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: KeyCenter.AppId, delegate: self)
        // Set live broadcasting mode
        agoraKit.setChannelProfile(.liveBroadcasting)
        // set client role
        agoraKit.setClientRole(clientRole)
        
        // join channel and start group chat
        // If join  channel success, agoraKit triggers its delegate function
        // 'rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int)'
        let code = agoraKit.joinChannel(byToken: nil, channelId: roomName, info: nil, uid: 0, joinSuccess: nil)
        
        if code != 0 {
            DispatchQueue.main.async(execute: {
                self.append(log: "Join channel failed: \(code)")
            })
        }
    }
    
    func leaveChannel() {
        // Leave channel and end the chat
        agoraKit.leaveChannel(nil)
        delegate?.roomVCNeedClose(self)
    }
}

extension RoomViewController: AgoraRtcEngineDelegate {
    /// Occurs when the connection between the SDK and the server is interrupted.
    func rtcEngineConnectionDidInterrupted(_ engine: AgoraRtcEngineKit) {
        append(log: "Connection Interrupted")
    }
    
    /// Occurs when the SDK cannot reconnect to Agora’s edge server 10 seconds after its connection to the server is interrupted.
    func rtcEngineConnectionDidLost(_ engine: AgoraRtcEngineKit) {
        append(log: "Connection Lost")
    }
    
    /// Reports an error during SDK runtime.
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        append(log: "Occur error: \(errorCode.rawValue)")
    }
    
    /**
     Occurs when the local user joins a specified channel.
     
     Same as `joinSuccessBlock` in the joinChannelByToken method.
    
     - Parameters:
        - engine: AgoraRtcEngineKit object.
        - channel: Channel name.
        - uid: local user's ID. If the `uid` is specified in the joinChannelByToekn method; if not specified, this is the system assigned uid.
        - elapsed: Time elapsed (ms) from the local user calling the joinChannelByToken method until the SDK triggers this callback.
     */
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        append(log: "Did joined channel: \(channel), with uid: \(uid), elapsed: \(elapsed)")
    }
    
    /**
     Occurs when a remote user or host joins a channel. Same as `userJoinedBlock`.
     
     - Communication profile: This callback notifies the app that another user joins the channel. If other users are already in the channel, the SDK also reports to the app on the existing users.
     - Live-broadcast profile: This callback notifies the app that a host joins the channel. If other hosts are already in the channel, the SDK also reports to the app on the existing hosts. Agora recommends limiting the number of hosts to 17.
     
     The SDK triggers this callback under one of the following circumstances:
     - A remote user/host joins the channel by calling the `joinChannelByToken` method.
     - A remote user switches the user role to the host by calling the `setClientRole` method after joining the channel.
     - A remote user/host rejoins the channel after a network interruption.
     - A host injects an online media stream into the channel by calling the `addInjectStreamUrl` method.
     
     **Note:**
     
     Live-broadcast profile:
     
     * The host receives this callback when another host joins the channel.
     * The audience in the channel receives this callback when a new host joins the channel.
     * When a web application joins the channel, the SDK triggers this callback as long as the web application publishes streams.

     - Parameters:
        - engine: AgoraRtcEngineKit object.
        - uid: ID of the user or host who joins the channel. If the `uid` is specified in the `joinChannelByToken` method, the specified user ID is returned. If the `uid` is not specified in the joinChannelByToken method, the Agora server automatically assigns a `uid`.
        - elapsed: Time elapsed (ms) from the local user calling the `joinChannelByToken` or `setClientRole` method until the SDK triggers this callback.
     */
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        append(log: "Did joined of uid: \(uid)")
    }
    
    /// Occurs when a remote user (Communication)/host (Live Broadcast) leaves a channel. Same as `userOfflineBlock`.
    ///
    /// There are two reasons for users to be offline:
    ///
    /// - Leave a channel: When the user/host leaves a channel, the user/host sends a goodbye message. When the message is received, the SDK assumes that the user/host leaves a channel.
    /// - Drop offline: When no data packet of the user or host is received for a certain period of time (20 seconds for the Communication profile, and more for the Live-broadcast profile), the SDK assumes that the user/host drops offline. Unreliable network connections may lead to false detections, so Agora recommends using a signaling system for more reliable offline detection.
    /// - Parameters:
    ///   - engine: AgoraRtcEngineKit object.
    ///   - uid: ID of the user or host who leaves a channel or goes offline.
    ///   - reason: Reason why the user goes offline, see AgoraUserOfflineReason.
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        append(log: "Did offline of uid: \(uid), reason: \(reason.rawValue)")
    }
    
    /// Reports the audio quality of the remote user.
    ///
    /// Same as `audioQualityBlock`.

    /// DEPRECATED from v2.3.2. Use `remoteAudioStats` instead.

    /// The SDK triggers this callback once every two seconds. This callback reports the audio quality of each remote user/host sending an audio stream. If a channel has multiple users/hosts sending audio streams, then the SDK triggers this callback as many times.
    /// - Parameters:
    ///   - engine: AgoraRtcEngineKit object.
    ///   - uid: User ID of the speaker.
    ///   - quality: Audio quality of the user, see AgoraNetworkQuality.
    ///   - delay: Time delay (ms) of the audio packet sent from the sender to the receiver, including the time delay from audio sampling pre-processing, transmission, and the jitter buffer.
    ///   - lost: Packet loss rate (%) of the audio packet sent from the sender to the receiver.
    func rtcEngine(_ engine: AgoraRtcEngineKit, audioQualityOfUid uid: UInt, quality: AgoraNetworkQuality, delay: UInt, lost: UInt) {
        append(log: "Audio Quality of uid: \(uid), quality: \(quality.rawValue), delay: \(delay), lost: \(lost)")
    }
    
    /// Occurs when a method is executed by the SDK.
    /// - Parameters:
    ///   - engine: AgoraRtcEngineKit object.
    ///   - api: The method executed by the SDK.
    ///   - error: The error code (AgoraErrorCode) returned by the SDK when the method call fails. If the SDK returns 0, then the method call succeeds.
    func rtcEngine(_ engine: AgoraRtcEngineKit, didApiCallExecute api: String, error: Int) {
        append(log: "Did api call execute: \(api), error: \(error)")
    }
}
