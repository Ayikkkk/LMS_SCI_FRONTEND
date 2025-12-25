// lib/features/online_class/presentation/screens/jitsi_helper.dart

import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

class JitsiHelper {
  static Future<void> joinMeeting({
    required String room,
    required String displayName,
  }) async {
    final jitsiMeet = JitsiMeet();

    final options = JitsiMeetConferenceOptions(
      room: room,
      userInfo: JitsiMeetUserInfo(
        displayName: displayName,
      ),
    );

    await jitsiMeet.join(options);
  }
}
