import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

class JitsiHelper {
  static final _jitsiMeet = JitsiMeet();

  static Future<void> joinMeeting({
    required String room,
    required String displayName,
    Function()? onLeft,
  }) async {

    final options = JitsiMeetConferenceOptions(
      room: room,
      userInfo: JitsiMeetUserInfo(displayName: displayName),

      configOverrides: {
        "disableModeratorIndicator": true,
        "startWithAudioMuted": true,
        "startWithVideoMuted": true,
        "disableModerator": true,
        "prejoinPageEnabled": false,
      },
      featureFlags: {
        "kick-out.enabled": false,
        "mute-everyone.enabled": false,
        "invite.enabled": false,
        "recording.enabled": false,
        "live-streaming.enabled": false,
      },
    );

    // ⬇️ ketika meeting UI ditutup → dianggap keluar meeting
    await _jitsiMeet.join(options);

    if (onLeft != null) onLeft();
  }
}
