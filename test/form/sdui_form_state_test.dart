import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sdui_renderer/sdui_renderer.dart';
import 'package:sdui_renderer/src/cache/sdui_cache_service.dart';
import 'package:sdui_renderer/src/form/sdui_form_state.dart';
import 'package:sdui_renderer/src/sdui.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SduiCacheService.resetForTest();
    Sdui.resetForTest();
    await Sdui.initialize(apiKey: 'k');
  });

  group('SduiFormState', () {
    test('validateAll passes when all validators return null', () {
      final s = SduiFormState();
      s.registerField('email', buildValidators([
        {'type': 'required'},
        {'type': 'pattern', 'pattern': r'^[^@]+@[^@]+\.[^@]+$'},
      ]));
      s.setValue('email', 'a@b.com');
      expect(s.validateAll(), isTrue);
      expect(s.errors['email'], isNull);
    });

    test('validateAll fails on required empty', () {
      final s = SduiFormState();
      s.registerField('email', buildValidators([{'type': 'required'}]));
      expect(s.validateAll(), isFalse);
      expect(s.errors['email'], isNotNull);
    });

    test('validateAll uses custom errorMessage', () {
      final s = SduiFormState();
      s.registerField('email', buildValidators([
        {'type': 'required', 'errorMessage': 'Email is required'},
      ]));
      s.validateAll();
      expect(s.errors['email'], 'Email is required');
    });

    test('minLength rule', () {
      final s = SduiFormState();
      s.registerField('pw', buildValidators([{'type': 'minLength', 'value': 6}]));
      s.setValue('pw', '12345');
      expect(s.validateAll(), isFalse);
      s.setValue('pw', '123456');
      expect(s.validateAll(), isTrue);
    });
  });

  testWidgets('getFormValue + validateForm + branch', (tester) async {
    String? branchHit;
    Sdui.registerAction('didValid', (ctx, a) async { branchHit = 'valid'; return null; },
        override: true);
    Sdui.registerAction('didNotValid', (ctx, a) async { branchHit = 'invalid'; return null; },
        override: true);

    final formKey = GlobalKey<_TestFormState>();
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: _TestForm(key: formKey),
    )));

    // Pre-populate value programmatically.
    formKey.currentState!.setFieldValue('email', 'a@b.com');

    // Dispatch validateForm.
    await tester.runAsync(() async {
      final ctx = formKey.currentContext!;
      await Sdui.dispatch(ctx, SduiAction(actionType: 'validateForm', props: {
        'isValid': {'actionType': 'didValid'},
        'isNotValid': {'actionType': 'didNotValid'},
      }));
    });

    expect(branchHit, 'valid');
  });
}

// ─── Test form helper ────────────────────────────────────────────────────────

class _TestForm extends StatefulWidget {
  const _TestForm({super.key});

  @override
  State<_TestForm> createState() => _TestFormState();
}

class _TestFormState extends State<_TestForm> {
  final state = SduiFormState();

  @override
  void initState() {
    super.initState();
    state.registerField('email', buildValidators([
      {'type': 'required'},
      {'type': 'email'},
    ]));
  }

  void setFieldValue(String id, dynamic v) {
    state.setValue(id, v);
  }

  @override
  Widget build(BuildContext context) {
    return SduiFormScope(state: state, child: const SizedBox.shrink());
  }
}
