import 'dart:async';
import 'dart:developer';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:get/route_manager.dart';
import 'package:video_player/video_player.dart';

class HomeController extends GetxController {
  VideoPlayerController? videoController;
  ChewieController? chewieController;

  bool isVideoInitialized = false;
  bool _isDisposed = false;
  RxInt? currentlyPlayingIndex = (-1).obs;

  RxBool showButton = false.obs;
  Timer? _hideButtonTimer;
  int _playerInitToken = 0;
  String _currentVideoUrl = 'https://mercyott.com/hls_output/master.m3u8';
  RxBool isLiveStreamVar = true.obs;

  Rx<Orientation> currentOrientation = Orientation.portrait.obs;

  Future<void> initializePlayer(String videoUrl, bool isLiveStream) async {
    _disposeControllers();

    final int currentToken = ++_playerInitToken;

    try {
      videoController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: isLiveStream
            ? VideoPlayerOptions(
                mixWithOthers: true, allowBackgroundPlayback: true)
            : null,
      );

      await videoController!.initialize();

      if (!_isDisposed && currentToken == _playerInitToken) {
        isLiveStreamVar.value = isLiveStream;
        isVideoInitialized = true;
        _setupChewieController();
        if (isLiveStream) {
          videoController!.play();
        }
        if (!_isDisposed) {}
      }
    } catch (e) {
      if (currentToken == _playerInitToken) {
        isVideoInitialized = false;
        if (!_isDisposed) {}
      }
      print("Error initializing video: $e");
    }
  }

  void _setupChewieController() {
    chewieController = ChewieController(
      videoPlayerController: videoController!,
      aspectRatio: videoController!.value.aspectRatio,
      autoPlay: true,
      looping: false,
      showControls: true,
      allowFullScreen: true,
      allowPlaybackSpeedChanging: !isLiveStreamVar.value,
      isLive: false,
      fullScreenByDefault: false,
      additionalOptions: (context) {
        if (isLiveStreamVar.value &&
            !(chewieController?.isFullScreen ?? false)) {
          return <OptionItem>[
            OptionItem(
              iconData: Icons.video_settings,
              title: 'Quality',
              onTap: (context) => _showQualityOptions(context),
            )
          ];
        }
        return [];
      },
    );
  }

  void _showQualityOptions(BuildContext context) {
    if (_isDisposed) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      builder: (BuildContext context) {
        return Wrap(
          children: [
            _qualityOption(
                context, 'Auto', 'https://mercyott.com/hls_output/master.m3u8'),
            _qualityOption(
                context, '360p', 'https://mercyott.com/hls_output/360p.m3u8'),
            _qualityOption(
                context, '720p', 'https://mercyott.com/hls_output/720p.m3u8'),
            _qualityOption(
                context, '1080p', 'https://mercyott.com/hls_output/1080p.m3u8'),
          ],
        );
      },
    );
  }

  Widget _qualityOption(BuildContext context, String quality, String url) {
    return ListTile(
      leading: const Icon(Icons.hd, color: Colors.white),
      title: Text(quality, style: const TextStyle(color: Colors.white)),
      onTap: () => _changeVideoQuality(url),
    );
  }

  Future<void> _changeVideoQuality(String videoUrl) async {
    // Close quality bottom sheet if open
    Get.back();
    log('Changing quality to: $videoUrl');

    // Safely handle transition when changing quality
    if (chewieController != null && chewieController!.isFullScreen) {
      await Future.delayed(const Duration(milliseconds: 200));

      initializePlayer(videoUrl, true);
    } else {
      await Future.delayed(const Duration(milliseconds: 200));

      initializePlayer(videoUrl, true);
    }
  }

  void _disposeControllers() {
    chewieController?.dispose();
    videoController?.dispose();
    chewieController = null;
    videoController = null;
    isVideoInitialized = false;
  }

  void onScreenTapped() {
    showButton.value = true;

    _hideButtonTimer?.cancel();
    _hideButtonTimer = Timer(const Duration(seconds: 4), () {
      if (!_isDisposed) {
        showButton.value = false;
      }
    });
  }

  @override
  void onInit() {
    initializePlayer(_currentVideoUrl, isLiveStreamVar.value);
    super.onInit();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _disposeControllers();
    _hideButtonTimer?.cancel();
    super.dispose();
  }
}
