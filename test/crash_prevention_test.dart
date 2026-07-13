import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hyperscreener/utils/app_config.dart';
import 'package:hyperscreener/viewmodels/wallet_viewmodel.dart';
import 'package:hyperscreener/viewmodels/hl_tvl_viewmodel.dart';
import 'package:hyperscreener/widgets/error_state_widget.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Crash Prevention - AppConfig Fallback Tests', () {
    test('AppConfig returns default production fallback values when dotenv is uninitialized', () {
      dotenv.clean();
      expect(AppConfig.baseUrl, isNotEmpty);
      expect(AppConfig.wsUrl, isNotEmpty);
      expect(AppConfig.hipBaseUrl, isNotEmpty);
      expect(AppConfig.hipWsUrl, isNotEmpty);
      expect(AppConfig.defillamaUrl, isNotEmpty);
      expect(AppConfig.dexVolumeUrl, isNotEmpty);
      expect(AppConfig.hip4DetailBaseUrl, isNotEmpty);
      expect(AppConfig.hip4DetailsTabBaseUrl, isNotEmpty);
    });
  });

  group('Crash Prevention - WalletViewModel Null/Empty Safety', () {
    test('WalletViewModel initializes cleanly with default mock SharedPreferences', () {
      final viewModel = WalletViewModel();
      expect(viewModel.isInitialized, isFalse);
      expect(viewModel.accounts, isEmpty);
      expect(viewModel.address, isNull);
      expect(viewModel.isConnected, isFalse);
      expect(viewModel.selectedAccount, isNull);
      expect(viewModel.shortAddress, isEmpty);
    });

    test('WalletViewModel gracefully handles corrupted accounts list in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'saved_accounts': 'invalid corrupt json text',
      });
      final prefs = await SharedPreferences.getInstance();
      
      expect(() => WalletViewModel(prefs: prefs), returnsNormally);
      
      final viewModel = WalletViewModel(prefs: prefs);
      expect(viewModel.isInitialized, isTrue);
      expect(viewModel.accounts, isEmpty); // fallback to empty
    });
  });

  group('Crash Prevention - HlTvlViewModel Error Robustness', () {
    test('HlTvlViewModel.fetchAll handles API communication errors gracefully without throwing', () async {
      final viewModel = HlTvlViewModel();
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.error, isEmpty);

      // fetchAll should complete gracefully without throwing, even if API is unreachable
      await expectLater(viewModel.fetchAll(), completes);
      
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.error, isNotEmpty);
    });
  });

  group('Crash Prevention - ErrorStateWidget Rendering Tests', () {
    testWidgets('ErrorStateWidget renders correctly with default and custom message values', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              errorMessage: 'Test Error Message',
            ),
          ),
        ),
      );

      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.text('SHOW DETAILS'), findsOneWidget);
      await tester.tap(find.text('SHOW DETAILS'));
      await tester.pump();
      expect(find.text('Test Error Message'), findsOneWidget);
      expect(find.text('LOAD ERROR'), findsOneWidget);
      expect(find.text('RETRY CONNECTION'), findsNothing);
    });

    testWidgets('ErrorStateWidget displays retry button when onRetry is provided', (WidgetTester tester) async {
      bool isClicked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              errorMessage: '',
              onRetry: () {
                isClicked = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('RETRY CONNECTION'), findsOneWidget);
      await tester.tap(find.text('RETRY CONNECTION'));
      await tester.pump();
      expect(isClicked, isTrue);
    });
  });
}
