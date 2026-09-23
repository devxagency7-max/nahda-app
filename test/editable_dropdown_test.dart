import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nahda/features/case_details/presentation/widgets/editable_dropdown.dart';

void main() {
  testWidgets('EditableDropdown behaves as normal dropdown when standard item is selected',
      (tester) async {
    String? selectedValue = 'ابتدائي';
    final options = ['حضانة', 'ابتدائي', 'إعدادي', 'أخرى'];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return EditableDropdown(
                label: 'المرحلة التعليمية',
                value: selectedValue,
                options: options,
                onChanged: (val) {
                  setState(() => selectedValue = val);
                },
              );
            },
          ),
        ),
      ),
    );

    // Should find DropdownButtonFormField and not find custom TextField
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets(
      'EditableDropdown switches to in-field TextField when "أخرى" is selected and allows typing',
      (tester) async {
    String? selectedValue;
    final options = ['حضانة', 'ابتدائي', 'إعدادي', 'أخرى'];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return EditableDropdown(
                label: 'المرحلة التعليمية',
                value: selectedValue,
                options: options,
                onChanged: (val) {
                  setState(() => selectedValue = val);
                },
              );
            },
          ),
        ),
      ),
    );

    // Tap dropdown to open menu
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    // Select 'أخرى'
    await tester.tap(find.text('أخرى').last);
    await tester.pumpAndSettle();

    // Dropdown should now be replaced by in-field TextField
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.byType(TextField), findsOneWidget);

    // Type custom value
    await tester.enterText(find.byType(TextField), 'تعليم أزهري نوعي');
    await tester.pumpAndSettle();

    expect(selectedValue, 'تعليم أزهري نوعي');

    // Tap undo button to return to dropdown
    final undoBtn = find.byTooltip('الرجوع للقائمة المنسدلة');
    expect(undoBtn, findsOneWidget);
    await tester.tap(undoBtn);
    await tester.pumpAndSettle();

    // Should be back to dropdown
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(selectedValue, isNull);
  });

  testWidgets('EditableDropdown opens directly in custom mode when given a custom value',
      (tester) async {
    String? selectedValue = 'معهد خاص معتمد';
    final options = ['حضانة', 'ابتدائي', 'إعدادي', 'أخرى'];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditableDropdown(
            label: 'المرحلة التعليمية',
            value: selectedValue,
            options: options,
            onChanged: (val) => selectedValue = val,
          ),
        ),
      ),
    );

    // Should immediately show TextField with that custom text
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('معهد خاص معتمد'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
  });
}
