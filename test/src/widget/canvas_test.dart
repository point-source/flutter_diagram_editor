import 'package:diagram_editor/diagram_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ComponentData extends BaseComponentData {
  ComponentData({
    super.id,
    super.position,
    super.size,
    super.minSize,
  });
}

void main() {
  // Tests can be run only all at once, not individually !!!
  group('Canvas tests', () {
    PolicySet policySet = PolicySet();

    var editor = MaterialApp(
      home: DiagramEditor(
        diagramEditorContext: DiagramEditorContext(
          policySet: policySet,
        ),
      ),
    );

    final componentData = ComponentData();

    testWidgets(
      'Given new canvas When no action Then canvas contains no components',
      (WidgetTester tester) async {
        await tester.pumpWidget(editor);
        expect(find.byType(ComponentData), findsNothing);
      },
    );

    testWidgets(
      'Given canvas with no components When component is added Then canvas contains that one component',
      (WidgetTester tester) async {
        await tester.pumpWidget(editor);

        policySet.canvasWriter.model.addComponent(componentData);

        await tester.pump();
        expect(find.byType(ComponentData), findsOneWidget);
      },
    );

    testWidgets(
      'Given canvas with one component When component is removed Then canvas contains no components',
      (WidgetTester tester) async {
        await tester.pumpWidget(editor);

        expect(find.byType(ComponentData), findsOneWidget);

        policySet.canvasWriter.model.removeComponent(componentData.id);

        await tester.pump();
        expect(find.byType(ComponentData), findsNothing);
      },
    );

    testWidgets(
      'Given canvas with one component When position is set to canvas Then canvas still contains one component',
      (WidgetTester tester) async {
        await tester.pumpWidget(editor);

        policySet.canvasWriter.model.addComponent(componentData);
        await tester.pump();

        policySet.canvasWriter.state.setPosition(const Offset(10, 0));

        await tester.pump();

        expect(find.byType(ComponentData), findsOneWidget);
      },
    );

    testWidgets(
      'Given canvas with one component When canvas position is updated Then canvas still contains one component',
      (WidgetTester tester) async {
        await tester.pumpWidget(editor);

        policySet.canvasWriter.state.setPosition(const Offset(10, 0));

        await tester.pump();

        expect(find.byType(ComponentData), findsOneWidget);
      },
    );

    testWidgets(
      'Given canvas with one component When scale is set to canvas Then canvas still contains one component',
      (WidgetTester tester) async {
        await tester.pumpWidget(editor);

        policySet.canvasWriter.state.setScale(1.5);

        await tester.pump();

        expect(find.byType(ComponentData), findsOneWidget);
      },
    );

    testWidgets(
      'Given canvas with one component When canvas scale is updated Then canvas still contains one component',
      (WidgetTester tester) async {
        await tester.pumpWidget(editor);

        policySet.canvasWriter.state.updateScale(1.5);

        await tester.pump();

        expect(find.byType(ComponentData), findsOneWidget);
      },
    );
  });
}
