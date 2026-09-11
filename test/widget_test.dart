import 'package:flutter_test/flutter_test.dart';

import 'package:copypasta/utils/text_styler.dart';

void main() {
  test('bold style maps letters to mathematical bold unicode', () {
    expect(TextStyler.apply('Hi', FancyStyle.bold), '𝐇𝐢');
  });

  test('fullwidth style widens ascii characters', () {
    expect(TextStyler.apply('Hi', FancyStyle.fullwidth), 'Ｈｉ');
  });
}
