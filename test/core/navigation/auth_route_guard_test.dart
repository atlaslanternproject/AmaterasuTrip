import 'package:amaterasutrip/core/navigation/auth_route_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const invite = '/trip-invite/trip-123?token=valid-token';

  String? redirect({
    required bool authenticated,
    required bool verified,
    required String location,
    String? uri,
  }) {
    return AuthRouteGuard.redirect(
      isAuthenticated: authenticated,
      isEmailVerified: verified,
      matchedLocation: location,
      uri: Uri.parse(uri ?? location),
    );
  }

  group('AuthRouteGuard - anonymous user', () {
    test('can access authentication root', () {
      expect(
        redirect(authenticated: false, verified: false, location: '/'),
        isNull,
      );
    });

    test('can access registration', () {
      expect(
        redirect(authenticated: false, verified: false, location: '/register'),
        isNull,
      );
    });

    test('can access Google authentication flow', () {
      expect(
        redirect(
          authenticated: false,
          verified: false,
          location: '/google-auth',
        ),
        isNull,
      );
    });

    test('can open a trip invitation before authentication', () {
      expect(
        redirect(
          authenticated: false,
          verified: false,
          location: '/trip-invite/trip-123',
          uri: invite,
        ),
        isNull,
      );
    });

    test('is redirected away from protected routes', () {
      expect(
        redirect(authenticated: false, verified: false, location: '/home'),
        '/',
      );

      expect(
        redirect(
          authenticated: false,
          verified: false,
          location: '/trips/trip-123',
        ),
        '/',
      );

      expect(
        redirect(authenticated: false, verified: false, location: '/settings'),
        '/',
      );
    });

    test('preserves invite returnTo when session is lost on verify-email', () {
      final result = redirect(
        authenticated: false,
        verified: false,
        location: '/verify-email',
        uri: Uri(
          path: '/verify-email',
          queryParameters: {'returnTo': invite},
        ).toString(),
      );

      final resultUri = Uri.parse(result!);

      expect(resultUri.path, '/');
      expect(resultUri.queryParameters['returnTo'], invite);
    });

    test(
      'preserves invite returnTo when session is lost on username creation',
      () {
        final result = redirect(
          authenticated: false,
          verified: false,
          location: '/create-username',
          uri: Uri(
            path: '/create-username',
            queryParameters: {'returnTo': invite},
          ).toString(),
        );

        final resultUri = Uri.parse(result!);

        expect(resultUri.path, '/');
        expect(resultUri.queryParameters['returnTo'], invite);
      },
    );
  });

  group('AuthRouteGuard - authenticated unverified user', () {
    test('root goes to email verification', () {
      expect(
        redirect(authenticated: true, verified: false, location: '/'),
        '/verify-email',
      );
    });

    test('protected route goes to email verification', () {
      expect(
        redirect(authenticated: true, verified: false, location: '/home'),
        '/verify-email',
      );
    });

    test('can remain on email verification page', () {
      expect(
        redirect(
          authenticated: true,
          verified: false,
          location: '/verify-email',
        ),
        isNull,
      );
    });

    test(
      'can remain on trip invitation so invite flow can request verification',
      () {
        expect(
          redirect(
            authenticated: true,
            verified: false,
            location: '/trip-invite/trip-123',
            uri: invite,
          ),
          isNull,
        );
      },
    );

    test(
      'preserves valid invite returnTo when redirecting to verification',
      () {
        final result = redirect(
          authenticated: true,
          verified: false,
          location: '/home',
          uri: Uri(
            path: '/home',
            queryParameters: {'returnTo': invite},
          ).toString(),
        );

        final resultUri = Uri.parse(result!);

        expect(resultUri.path, '/verify-email');
        expect(resultUri.queryParameters['returnTo'], invite);
      },
    );
  });

  group('AuthRouteGuard - authenticated verified user', () {
    test('root goes to home', () {
      expect(
        redirect(authenticated: true, verified: true, location: '/'),
        '/home',
      );
    });

    test('root with valid invite returnTo goes back to invitation', () {
      expect(
        redirect(
          authenticated: true,
          verified: true,
          location: '/',
          uri: Uri(path: '/', queryParameters: {'returnTo': invite}).toString(),
        ),
        invite,
      );
    });

    test('verify-email without returnTo goes to home', () {
      expect(
        redirect(
          authenticated: true,
          verified: true,
          location: '/verify-email',
        ),
        '/home',
      );
    });

    test('verify-email with invite returnTo goes back to invitation', () {
      expect(
        redirect(
          authenticated: true,
          verified: true,
          location: '/verify-email',
          uri: Uri(
            path: '/verify-email',
            queryParameters: {'returnTo': invite},
          ).toString(),
        ),
        invite,
      );
    });

    test('registration page goes to home', () {
      expect(
        redirect(authenticated: true, verified: true, location: '/register'),
        '/home',
      );
    });

    test('protected routes remain accessible', () {
      expect(
        redirect(authenticated: true, verified: true, location: '/home'),
        isNull,
      );

      expect(
        redirect(
          authenticated: true,
          verified: true,
          location: '/trips/trip-123',
        ),
        isNull,
      );
    });
  });

  group('AuthRouteGuard - returnTo validation', () {
    test('rejects absolute external returnTo', () {
      expect(
        redirect(
          authenticated: true,
          verified: true,
          location: '/',
          uri: Uri(
            path: '/',
            queryParameters: {'returnTo': 'https://evil.example/steal'},
          ).toString(),
        ),
        '/home',
      );
    });

    test('rejects unrelated internal returnTo', () {
      expect(
        redirect(
          authenticated: true,
          verified: true,
          location: '/',
          uri: Uri(
            path: '/',
            queryParameters: {'returnTo': '/settings/account'},
          ).toString(),
        ),
        '/home',
      );
    });

    test('rejects invite returnTo without token', () {
      expect(
        redirect(
          authenticated: true,
          verified: true,
          location: '/',
          uri: Uri(
            path: '/',
            queryParameters: {'returnTo': '/trip-invite/trip-123'},
          ).toString(),
        ),
        '/home',
      );
    });
  });
}
