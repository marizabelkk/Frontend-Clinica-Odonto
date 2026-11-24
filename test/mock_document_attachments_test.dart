import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondonto_uninassau/views/atendimentos/semiologia/widgets/anexos_documentos_demo.dart';

void main() {
  testWidgets('allows selecting a simulated file and labels it as local', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AnexosDocumentosDemo())),
    );

    await tester.tap(find.text('Simular seleção de arquivo ou foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Radiografia panorâmica · exemplo.jpg'));
    await tester.pumpAndSettle();

    expect(find.text('Radiografia panorâmica · exemplo.jpg'), findsOneWidget);
    expect(find.text('Exemplo local · não enviado'), findsOneWidget);
  });
}
