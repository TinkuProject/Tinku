import 'package:flutter_test/flutter_test.dart';
import 'package:tinkuapp/utils/text/person_name_formatter.dart';

void main() {
  test('capitaliza cada parte y normaliza espacios', () {
    expect(normalizePersonName('  juan   carlos '), 'Juan Carlos');
    expect(normalizePersonName('pérez'), 'Pérez');
  });

  test('conserva el resto de cada nombre', () {
    expect(normalizePersonName('McDonald'), 'McDonald');
    expect(normalizePersonName('DE LA CRUZ'), 'DE LA CRUZ');
  });
}
