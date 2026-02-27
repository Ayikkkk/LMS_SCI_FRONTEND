import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

import '../../../../core/utils/logger.dart';

typedef OnMeetingLeft = Future<void> Function();

class JitsiHelper {
  static final JitsiMeet _jitsiMeet = JitsiMeet();

  static Future<void> joinMeeting({
    required String room,
    required String displayName,
    OnMeetingLeft? onMeetingLeft,
  }) async {
    final options = JitsiMeetConferenceOptions(
      room: room,
      userInfo: JitsiMeetUserInfo(
        displayName: displayName,
      ),
      configOverrides: {
        "startWithAudioMuted": true,
        "startWithVideoMuted": true,
        "prejoinPageEnabled": false,
      },
      featureFlags: {
        "invite.enabled": false,
        "kick-out.enabled": false,
        "recording.enabled": false,
        "live-streaming.enabled": false,
      },
    );

    final listener = JitsiMeetEventListener(
      conferenceJoined: (url) {
        AppLogger.info('Jitsi conference joined: $url', 'JitsiHelper');
      },
      conferenceTerminated: (url, error) async {
        AppLogger.info('Jitsi conference terminated', 'JitsiHelper');
        if (onMeetingLeft != null) {
          await onMeetingLeft();
        }
      },
    );

    // ✅ INI YANG BENAR DI SDK 10.3.0
    await _jitsiMeet.join(
      options,
      listener,
    );
  }

  static Future<void> leaveMeeting() async {
    await _jitsiMeet.hangUp();
  }
}
