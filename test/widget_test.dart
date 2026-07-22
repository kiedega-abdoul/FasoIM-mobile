import 'package:flutter_test/flutter_test.dart';
import 'package:fasoim_mobile/app/fasoim_app.dart';

void main() {
  testWidgets('FasoIM démarre sur le splash screen', (tester) async {
    await tester.pumpWidget(const FasoImApp());
    expect(find.text('FasoIM'), findsOneWidget);
    expect(find.text('Chargement…'), findsOneWidget);
  });
}
