import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StompClient? stomp;
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  RTCPeerConnection? pc;

  @override
  void initState() {
    setState(() {
      stomp = StompClient(
          config: StompConfig.SockJS(
              url: 'http://192.168.0.6:8080/ws', onConnect: onConnect));
    });

    _localRenderer.initialize();
    _remoteRenderer.initialize();
    init();
    super.initState();
  }

  Future init() async {
    stomp?.activate();
    await joinRoom();
  }

  void onConnect(StompFrame frame) {
    stomp!.subscribe(
        destination: '/topic/wagly/join',
        callback: (StompFrame frame) async {
          // ignore: avoid_print
          print(frame.body);
          _sendOffer();
        });

    stomp!.subscribe(
        destination: '/topic/wagly/offer',
        callback: (StompFrame frame) async {
          // ignore: avoid_print
          print(frame.body);
          var data = jsonDecode(frame.body!);
          await _gotOffer(RTCSessionDescription(data['sdp'], data['type']));
          await _sendAnswer();
        });

    stomp!.subscribe(
        destination: '/topic/wagly/answer',
        callback: (StompFrame frame) {
          // ignore: avoid_print
          print(frame.body);
          var data = jsonDecode(frame.body!);
          _gotAnswer(RTCSessionDescription(data['sdp'], data['type']));
        });

    stomp!.subscribe(
        destination: '/topic/wagly/ice',
        callback: (StompFrame frame) {
          // ignore: avoid_print
          print(frame.body);
          var data = jsonDecode(frame.body!);
          _gotIce(RTCIceCandidate(
              data['candidate'], data['sdpMid'], data['sdpMLineIndex']));
        });
  }

  Future joinRoom() async {
    final config = {
      'iceServers': [
        {"url": "stun:stun.l.google.com:19302"},
      ]
    };

    final sdpConstraints = {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': []
    };

    pc = await createPeerConnection(config, sdpConstraints);

    final mediaConstraints = {
      'audio': true,
      'video': {'facingMode': 'user'}
    };

    _localStream = await Helper.openCamera(mediaConstraints);

    _localStream!.getTracks().forEach((track) {
      pc!.addTrack(track, _localStream!);
    });

    _localRenderer.srcObject = _localStream;

    pc!.onIceCandidate = (ice) {
      _sendIce(ice);
    };

    pc!.onAddStream = (stream) {
      _remoteRenderer.srcObject = stream;
    };

    stomp?.send(
        destination: '/app/join',
        body: jsonEncode("asdasdasdasd"),
        headers: {});
  }

  Future _sendOffer() async {
    var offer = await pc!.createOffer();
    pc!.setLocalDescription(offer);
    stomp?.send(
        destination: '/app/offer',
        body: jsonEncode(offer.toMap()),
        headers: {});
  }

  Future _gotOffer(RTCSessionDescription offer) async {
    pc!.setRemoteDescription(offer);
  }

  Future _sendAnswer() async {
    var answer = await pc!.createAnswer();
    pc!.setLocalDescription(answer);
    stomp?.send(
        destination: '/app/answer',
        body: jsonEncode(answer.toMap()),
        headers: {});
  }

  Future _gotAnswer(RTCSessionDescription answer) async {
    pc!.setRemoteDescription(answer);
  }

  Future _sendIce(RTCIceCandidate ice) async {
    // ignore: avoid_print
    print("아이스임 아무튼 : ${jsonEncode(ice.toMap())}");
    stomp?.send(
        destination: '/app/ice', body: jsonEncode(ice.toMap()), headers: {});
  }

  Future _gotIce(RTCIceCandidate ice) async {
    pc!.addCandidate(ice);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Container(
            color: Colors.white,
            child: Column(
              children: [
                Expanded(child: RTCVideoView(_localRenderer)),
                Expanded(child: RTCVideoView(_remoteRenderer)),
                TextButton(
                  child: const Text("button"),
                  // ignore: avoid_print
                  onPressed: () => {},
                ),
              ],
            )));
  }
}
