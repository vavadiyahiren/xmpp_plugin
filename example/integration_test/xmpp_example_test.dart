import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter_xmpp_example/main.dart' as app;

import 'util.dart';

/// This integration test was made to work with GitHub actions.
/// Warning: Without a XMPP server or account the test will fail!
Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  String username = dotenv.env['TEST_USER'] as String;
  String password = dotenv.env['TEST_PASSWORD'] as String;
  String host = dotenv.env['TEST_HOST'] as String;

  group('connection test: ', () {
    testWidgets('entering credentials and connecting to server, '
        'verifying connection status',
            (tester) async {
          app.main();
          // Are the credentials loaded correctly from the .env?
          expect(true, username.isNotEmpty);
          expect(true, password.isNotEmpty);
          expect(true, host.isNotEmpty);

          // Trigger a frame
          await tester.pumpAndSettle();

          // Verify that the text fields exist
          expect(find.text('Username'), findsOneWidget);
          expect(find.text('Password'), findsOneWidget);
          expect(find.text('Host'), findsOneWidget);

          // Verify that the client is not connected to the XMPP-server
          expect(find.text('Disconnected'), findsOneWidget);

          // Enter credentials
          await tester.enterText(find.byKey(Key('Username')), username);
          await tester.enterText(find.byKey(Key('Password')), password);
          await tester.enterText(find.byKey(Key('Host')), host);

          // Trigger a frame
          await tester.pumpAndSettle();

          // Emulate a tap on the elevated button to connect to the server
          await tester.tap(find.byKey(Key('ConnectButton')));

          // Verify the connection status of the client
          final fab = find.text('authenticated');
          await pumpUntilFound(tester, fab);
          expect(fab, findsOneWidget);
          expect(find.text('Disconnected'), findsNothing);
        });
  });
}
