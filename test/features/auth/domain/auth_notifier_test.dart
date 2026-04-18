import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lms_frontend/features/auth/data/repository/auth_repository.dart';
import 'package:lms_frontend/features/auth/domain/auth_notifier.dart';

import 'auth_notifier_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockAuthRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('AuthNotifier', () {
    test('initial state is unknown', () {
      final state = container.read(authNotifierProvider);
      expect(state, AuthStatus.unknown);
    });

    test('checkAuthStatus → authenticated when token exists', () async {
      when(mockRepo.getToken()).thenAnswer((_) async => 'valid_token');

      await container.read(authNotifierProvider.notifier).checkAuthStatus();

      expect(container.read(authNotifierProvider), AuthStatus.authenticated);
    });

    test('checkAuthStatus → unauthenticated when no token', () async {
      when(mockRepo.getToken()).thenAnswer((_) async => null);

      await container.read(authNotifierProvider.notifier).checkAuthStatus();

      expect(container.read(authNotifierProvider), AuthStatus.unauthenticated);
    });

    test('doLogin → authenticated on success', () async {
      when(mockRepo.login('reno', 'reno123')).thenAnswer((_) async => true);
      when(mockRepo.getToken()).thenAnswer((_) async => 'token_abc');

      final result = await container
          .read(authNotifierProvider.notifier)
          .doLogin('reno', 'reno123');

      expect(result, true);
      expect(container.read(authNotifierProvider), AuthStatus.authenticated);
    });

    test('doLogin → returns false on failure', () async {
      when(mockRepo.login('reno', 'wrong')).thenAnswer((_) async => false);

      final result = await container
          .read(authNotifierProvider.notifier)
          .doLogin('reno', 'wrong');

      expect(result, false);
    });

    test('doLogin → rethrows exception on error', () async {
      when(mockRepo.login(any, any)).thenThrow(Exception('Network error'));

      expect(
        () => container
            .read(authNotifierProvider.notifier)
            .doLogin('reno', 'reno123'),
        throwsException,
      );
    });

    test('doLogout → state becomes unauthenticated', () async {
      when(mockRepo.getToken()).thenAnswer((_) async => 'token');
      when(mockRepo.logout()).thenAnswer((_) async {});

      // Set authenticated first
      await container.read(authNotifierProvider.notifier).checkAuthStatus();
      expect(container.read(authNotifierProvider), AuthStatus.authenticated);

      await container.read(authNotifierProvider.notifier).doLogout();

      expect(container.read(authNotifierProvider), AuthStatus.unauthenticated);
    });
  });
}
