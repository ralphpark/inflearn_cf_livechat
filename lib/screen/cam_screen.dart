import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:inflearn_cf_live_chat/const/agora.dart';
import 'package:permission_handler/permission_handler.dart';

class CamScreen extends StatefulWidget {
  const CamScreen({super.key});

  @override
  State<CamScreen> createState() => _CamScreenState();
}

class _CamScreenState extends State<CamScreen> {
  RtcEngine? engine;

  //내 아이디, 0은 채널 접속전 임의의 숫자
  int? uid = 0;
  int? otherUid;

  @override
  void dispose() async {
    if (engine != null) {
      await engine!.leaveChannel(
        options: LeaveChannelOptions(),
      );
      engine!.release();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Chat'),
      ),
      body: FutureBuilder<bool>(
          future: init(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  snapshot.error.toString(),
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 24,
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      renderMainView(),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          color: Colors.black.withOpacity(0.5),
                          width: 120,
                          height: 160,
                          child: renderSubView(),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton(
                    onPressed: ()async{
                      if (engine != null)  {
                        await engine!.leaveChannel();
                        engine = null;
                      }
                      Navigator.of(context).pop();
                    },
                    child: Text('나가기'),
                  ),
                )
              ],
            );
          }),
    );
  }

  renderMainView() {
    if (uid == null) {
      return Center(
        child: Text(
          '채널에 참여해 주세요.',
          style: TextStyle(
            fontSize: 24,
          ),
        ),
      );
    } else {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: engine!,
          canvas: VideoCanvas(
            uid: 0,
          ),
        ),
      );
    }
  }

  renderSubView() {
    if (otherUid == null) {
      return Center(
        child: Text(
          '채널에 유저가 없습니다.',
          style: TextStyle(
            fontSize: 24,
          ),
        ),
      );
    } else {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: engine!,
          canvas: VideoCanvas(
            uid: otherUid!,),
            connection: RtcConnection(
              channelId: CHANNEL_NAME,
          ),
        ),
      );
    }
  }

  Future<bool> init() async {
    final resp = await [Permission.camera, Permission.microphone].request();
    final cameraPermission = resp[Permission.camera];
    final microphonePermission = resp[Permission.microphone];
    if (cameraPermission != PermissionStatus.granted ||
        microphonePermission != PermissionStatus.granted) {
      throw '카메라 또는 마이크 권한을 허용해야 합니다.';
    }
    if (engine == null) {
      engine = createAgoraRtcEngine();
      await engine!.initialize(RtcEngineContext(
        appId: APP_ID,
      ));
      engine!.registerEventHandler(RtcEngineEventHandler(
        //내가 채널에 입장했을때
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print('채널 입장 성공. uid: ${connection.localUid}');
          setState(() {
            uid = connection.localUid;
          });
        },
        //내가 채널에서 나갔을때
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          print('채널 퇴장');
          setState(() {
            uid = null;
          });
        },
        //다른 사용자가 채널에 입장했을때
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print('다른 사용자 입장. uid: $remoteUid');
          setState(() {
            otherUid = remoteUid;
          });
        },
        //다른 사용자가 채널에서 나갔을때
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          print('다른 사용자 퇴장. uid: $remoteUid');
          setState(() {
            otherUid = null;
          });
        },
      ));
      //engine 시작
      await engine!.enableVideo();
      await engine!.startPreview();
      ChannelMediaOptions options = ChannelMediaOptions();
      await engine!.joinChannel(
        token: TEMP_TOCKEN,
        channelId: CHANNEL_NAME,
        uid: 0,
        options: options,
      );
    }

    return true;
  }
}
