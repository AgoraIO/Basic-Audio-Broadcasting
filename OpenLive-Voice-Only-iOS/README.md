# Open Live Voice Only iOS for Swift

*其他语言版本： [简体中文](README.zh.md)*

The Open Live Voice Only iOS for Swift Sample App is an open-source demo that will help you get live voice chat integrated directly into your iOS applications using the Agora Voice SDK.

With this sample app, you can:

- Join / leave channel
- Set role as broadcaster or audience
- Mute / unmute audio
- Switch speaker

A tutorial demo can be found here: [Agora-iOS-Voice-Tutorial-Swift-1to1](https://github.com/AgoraIO/Basic-Audio-Call/tree/master/One-to-One-Voice/Agora-iOS-Voice-Tutorial-Swift-1to1)

## Running the App
First, create a developer account at [Agora.io](https://dashboard.agora.io/signin/), and obtain an App ID. Update "KeyCenter.swift" with your App ID.

```
static let AppId: String = "Your App ID"
```

Next, download the **Agora Voice SDK** from [Agora.io SDK](https://www.agora.io/en/blog/download/). Unzip the downloaded SDK package and copy the **libs/AgoraAudioKit.framework** to the "OpenLiveVoice" folder in project.

Finally, Open OpenLiveVoice.xcodeproj, connect your iPhone／iPad device, setup your development signing and run.

## Developer Environment Requirements
* XCode 8.0 +
* Real devices (iPhone or iPad)
* iOS simulator is NOT supported

## Connect Us

- You can find full API document at [Document Center](https://docs.agora.io/en/)
- You can file bugs about this demo at [issue](https://github.com/AgoraIO/Basic-Audio-Broadcasting/issues)

## License

The MIT License (MIT).
