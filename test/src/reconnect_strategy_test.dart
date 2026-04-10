import 'dart:math';

import 'package:eventflux/models/reconnect.dart';
import 'package:eventflux/src/reconnect_strategy.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

void main() {
  late ReconnectStrategy strategy;

  setUp(() {
    strategy = ReconnectStrategy();
    // Use a seeded Random for deterministic jitter in tests
    ReconnectStrategy.random = Random(42);
  });

  tearDown(() {
    ReconnectStrategy.random = Random();
  });

  group('ReconnectStrategy', () {
    test('hasConfig is false before initialize', () {
      expect(strategy.hasConfig, false);
      expect(strategy.config, isNull);
    });

    test('initialize sets config and state', () {
      strategy.initialize(ReconnectConfig(
        mode: ReconnectMode.linear,
        interval: const Duration(seconds: 3),
        maxAttempts: 5,
      ));
      expect(strategy.hasConfig, true);
      expect(strategy.config!.mode, ReconnectMode.linear);
    });

    test('clear removes config', () {
      strategy.initialize(ReconnectConfig(
        mode: ReconnectMode.linear,
      ));
      strategy.clear();
      expect(strategy.hasConfig, false);
    });

    test('returns false when autoReconnect is false', () {
      strategy.initialize(ReconnectConfig(mode: ReconnectMode.linear));

      fakeAsync((async) {
        bool result = false;
        strategy
            .attemptIfNeeded(
              autoReconnect: false,
              isExplicitDisconnect: () => false,
              tag: null,
              refreshHeaders: () async {},
              startConnection: () {},
              stopConnection: () async {},
            )
            .then((v) => result = v);
        async.flushMicrotasks();
        expect(result, false);
      });
    });

    test('returns false when explicitly disconnected', () {
      strategy.initialize(ReconnectConfig(mode: ReconnectMode.linear));

      fakeAsync((async) {
        bool result = false;
        strategy
            .attemptIfNeeded(
              autoReconnect: true,
              isExplicitDisconnect: () => true,
              tag: null,
              refreshHeaders: () async {},
              startConnection: () {},
              stopConnection: () async {},
            )
            .then((v) => result = v);
        async.flushMicrotasks();
        expect(result, false);
      });
    });

    test('calls stopConnection when max attempts exhausted', () {
      strategy.initialize(ReconnectConfig(
        mode: ReconnectMode.linear,
        maxAttempts: 0,
      ));

      fakeAsync((async) {
        bool stopped = false;
        strategy.attemptIfNeeded(
          autoReconnect: true,
          isExplicitDisconnect: () => false,
          tag: null,
          refreshHeaders: () async {},
          startConnection: () {},
          stopConnection: () async {
            stopped = true;
          },
        );
        async.flushMicrotasks();
        expect(stopped, true);
      });
    });

    test('linear mode reconnects after interval (with jitter)', () {
      strategy.initialize(ReconnectConfig(
        mode: ReconnectMode.linear,
        interval: const Duration(milliseconds: 100),
        maxAttempts: 2,
      ));

      fakeAsync((async) {
        int connectCalls = 0;
        strategy.attemptIfNeeded(
          autoReconnect: true,
          isExplicitDisconnect: () => false,
          tag: null,
          refreshHeaders: () async {},
          startConnection: () => connectCalls++,
          stopConnection: () async {},
        );
        expect(connectCalls, 0);
        // Jitter adds 0-25%, so wait a bit more than the base interval
        async.elapse(const Duration(milliseconds: 130));
        expect(connectCalls, 1);
      });
    });

    test('exponential mode doubles interval (with jitter)', () {
      strategy.initialize(ReconnectConfig(
        mode: ReconnectMode.exponential,
        interval: const Duration(seconds: 1),
        maxAttempts: 3,
      ));

      fakeAsync((async) {
        int connectCalls = 0;

        // First attempt: waits ~1s + jitter
        strategy.attemptIfNeeded(
          autoReconnect: true,
          isExplicitDisconnect: () => false,
          tag: null,
          refreshHeaders: () async {},
          startConnection: () => connectCalls++,
          stopConnection: () async {},
        );
        async.elapse(const Duration(milliseconds: 1300));
        expect(connectCalls, 1);

        // Second attempt: waits ~2s + jitter (doubled)
        strategy.attemptIfNeeded(
          autoReconnect: true,
          isExplicitDisconnect: () => false,
          tag: null,
          refreshHeaders: () async {},
          startConnection: () => connectCalls++,
          stopConnection: () async {},
        );
        async.elapse(const Duration(milliseconds: 2600));
        expect(connectCalls, 2);
      });
    });

    test('resetOnSuccess resets interval, attempts, and currentAttempt', () {
      strategy.initialize(ReconnectConfig(
        mode: ReconnectMode.exponential,
        interval: const Duration(seconds: 1),
        maxAttempts: 5,
      ));

      fakeAsync((async) {
        int connectCalls = 0;

        // First attempt
        strategy.attemptIfNeeded(
          autoReconnect: true,
          isExplicitDisconnect: () => false,
          tag: null,
          refreshHeaders: () async {},
          startConnection: () => connectCalls++,
          stopConnection: () async {},
        );
        async.elapse(const Duration(milliseconds: 1300));
        expect(connectCalls, 1);
        expect(strategy.currentAttempt, 1);

        // Reset on success
        strategy.resetOnSuccess();
        expect(strategy.currentAttempt, 0);

        // After reset: interval should be back to ~1s
        strategy.attemptIfNeeded(
          autoReconnect: true,
          isExplicitDisconnect: () => false,
          tag: null,
          refreshHeaders: () async {},
          startConnection: () => connectCalls++,
          stopConnection: () async {},
        );
        // Should reconnect at ~1s, not ~2s
        async.elapse(const Duration(milliseconds: 1300));
        expect(connectCalls, 2);
      });
    });

    test('backoff caps at maxBackoff', () {
      strategy.initialize(ReconnectConfig(
        mode: ReconnectMode.exponential,
        interval: const Duration(seconds: 4),
        maxAttempts: -1,
        maxBackoff: const Duration(seconds: 5),
      ));

      fakeAsync((async) {
        int connectCalls = 0;

        // First attempt: waits ~4s + jitter
        strategy.attemptIfNeeded(
          autoReconnect: true,
          isExplicitDisconnect: () => false,
          tag: null,
          refreshHeaders: () async {},
          startConnection: () => connectCalls++,
          stopConnection: () async {},
        );
        async.elapse(const Duration(seconds: 6));
        expect(connectCalls, 1);

        // Second attempt: would be 8s, but capped at ~5s + jitter
        strategy.attemptIfNeeded(
          autoReconnect: true,
          isExplicitDisconnect: () => false,
          tag: null,
          refreshHeaders: () async {},
          startConnection: () => connectCalls++,
          stopConnection: () async {},
        );
        // If not capped, would need 8+ seconds. With cap at 5s + jitter (max 25%), 7s should be enough
        async.elapse(const Duration(seconds: 7));
        expect(connectCalls, 2);
      });
    });

    test('jitter stays within 0-25% range', () {
      // Use many random samples to check range
      final testRandom = Random(123);
      ReconnectStrategy.random = testRandom;

      strategy.initialize(ReconnectConfig(
        mode: ReconnectMode.linear,
        interval: const Duration(seconds: 1),
        maxAttempts: -1,
      ));

      fakeAsync((async) {
        for (int i = 0; i < 10; i++) {
          int connectCalls = 0;
          strategy.attemptIfNeeded(
            autoReconnect: true,
            isExplicitDisconnect: () => false,
            tag: null,
            refreshHeaders: () async {},
            startConnection: () => connectCalls++,
            stopConnection: () async {},
          );
          // Base is 1000ms. Max with jitter is 1250ms.
          // Should not fire at 999ms
          async.elapse(const Duration(milliseconds: 999));
          // But should fire by 1250ms
          async.elapse(const Duration(milliseconds: 251));
          expect(connectCalls, 1, reason: 'iteration $i');
        }
      });
    });

    test('onReconnect receives (attempt, delay)', () {
      int? receivedAttempt;
      Duration? receivedDelay;

      strategy.initialize(ReconnectConfig(
        mode: ReconnectMode.linear,
        interval: const Duration(milliseconds: 100),
        maxAttempts: 2,
        onReconnect: (attempt, delay) {
          receivedAttempt = attempt;
          receivedDelay = delay;
        },
      ));

      fakeAsync((async) {
        strategy.attemptIfNeeded(
          autoReconnect: true,
          isExplicitDisconnect: () => false,
          tag: null,
          refreshHeaders: () async {},
          startConnection: () {},
          stopConnection: () async {},
        );
        async.elapse(const Duration(milliseconds: 200));

        expect(receivedAttempt, 1);
        expect(receivedDelay, isNotNull);
        expect(receivedDelay!.inMilliseconds, greaterThanOrEqualTo(100));
        expect(receivedDelay!.inMilliseconds, lessThanOrEqualTo(125));
      });
    });

    test('updateRetryInterval changes the interval', () {
      strategy.initialize(ReconnectConfig(
        mode: ReconnectMode.exponential,
        interval: const Duration(seconds: 1),
        maxAttempts: 2,
      ));

      strategy.updateRetryInterval(const Duration(seconds: 5));

      fakeAsync((async) {
        int connectCalls = 0;
        strategy.attemptIfNeeded(
          autoReconnect: true,
          isExplicitDisconnect: () => false,
          tag: null,
          refreshHeaders: () async {},
          startConnection: () => connectCalls++,
          stopConnection: () async {},
        );
        // Should wait ~5s (not 1s)
        async.elapse(const Duration(seconds: 2));
        expect(connectCalls, 0);
        async.elapse(const Duration(seconds: 5));
        expect(connectCalls, 1);
      });
    });

    test('currentAttempt resets on success', () {
      strategy.initialize(ReconnectConfig(
        mode: ReconnectMode.linear,
        interval: const Duration(milliseconds: 50),
        maxAttempts: -1,
      ));

      fakeAsync((async) {
        strategy.attemptIfNeeded(
          autoReconnect: true,
          isExplicitDisconnect: () => false,
          tag: null,
          refreshHeaders: () async {},
          startConnection: () {},
          stopConnection: () async {},
        );
        async.elapse(const Duration(milliseconds: 100));
        expect(strategy.currentAttempt, 1);

        strategy.attemptIfNeeded(
          autoReconnect: true,
          isExplicitDisconnect: () => false,
          tag: null,
          refreshHeaders: () async {},
          startConnection: () {},
          stopConnection: () async {},
        );
        async.elapse(const Duration(milliseconds: 100));
        expect(strategy.currentAttempt, 2);

        strategy.resetOnSuccess();
        expect(strategy.currentAttempt, 0);
      });
    });
  });
}
