import 'package:flutter_test/flutter_test.dart';
import 'package:minipj_68/config.dart';
import 'package:minipj_68/chat/chat_room_page.dart';
import 'package:minipj_68/widgets.dart';

void main() {
  test('authenticated headers carry only the session token', () {
    final session = attachToken({'mb_id': 'MB00000000001'}, 'signed-token');
    final headers = apiHeaders(session);

    expect(headers['Content-Type'], 'application/json');
    expect(headers['Authorization'], 'Bearer signed-token');
    expect(headers.values, isNot(contains('MB00000000001')));
  });

  test('time conversion supports schedule validation boundaries', () {
    expect(toMinutes('09:30'), 570);
    expect(toMinutes('00:00'), 0);
    expect(toMinutes('23:59'), 1439);
  });

  test('successful chat send does not clear a newer draft', () {
    expect(shouldClearSentMessage('ข้อความใหม่', 'ข้อความเดิม'), isFalse);
    expect(shouldClearSentMessage('ข้อความเดิม', 'ข้อความเดิม'), isTrue);
  });

  test('message polling cannot start overlapping requests', () {
    final guard = RequestInFlightGuard();

    expect(guard.tryStart(), isTrue);
    expect(guard.tryStart(), isFalse);
    final oldRevision = guard.revision;
    guard.invalidateResponses();
    expect(guard.isCurrent(oldRevision), isFalse);
    guard.finish();
    expect(guard.tryStart(), isTrue);
  });
}
