import 'package:flutter_test/flutter_test.dart';
import 'package:notion_book_library/services/author_matcher.dart';

void main() {
  group('nameSimilarity / bandFor', () {
    test('initials vs spelled-out given name is ambiguous, not exact (F. C. Yee vs Fonda C. Yee)', () {
      final score = nameSimilarity('F. C. Yee', 'Fonda C. Yee');
      expect(bandFor(score), AuthorMatchBand.ambiguous);
      expect(score, closeTo(0.9625, 0.001));
    });

    test('surname-only match with no given name info is ambiguous (Smith vs John Smith)', () {
      final score = nameSimilarity('Smith', 'John Smith');
      expect(bandFor(score), AuthorMatchBand.ambiguous);
      expect(score, closeTo(0.75, 0.001));
    });

    test('different surname is treated as unrelated, not ambiguous (John Smith vs John Smithson)', () {
      final score = nameSimilarity('John Smith', 'John Smithson');
      expect(bandFor(score), AuthorMatchBand.none);
    });

    test('a plain typo is ambiguous (Harari vs Harai)', () {
      final score = nameSimilarity('Harari', 'Harai');
      expect(bandFor(score), AuthorMatchBand.ambiguous);
    });

    test('identical strings score 1.0 / exact', () {
      final score = nameSimilarity('Yuval Noah Harari', 'Yuval Noah Harari');
      expect(score, 1.0);
      expect(bandFor(score), AuthorMatchBand.exact);
    });
  });

  group('isExactMatch', () {
    test('formatting-only differences count as exact', () {
      expect(isExactMatch('F. C. Yee', 'F C Yee'), isTrue);
      expect(isExactMatch('Yee, F. C.', 'F. C. Yee'), isTrue);
      expect(isExactMatch('  Fonda   Lee ', 'fonda lee'), isTrue);
    });

    test('genuinely different names are not exact', () {
      expect(isExactMatch('Fonda Lee', 'F. C. Yee'), isFalse);
    });
  });

  group('resolveAuthorMatch', () {
    test('exact match resolves silently to AuthorMatchExact', () {
      final decision = resolveAuthorMatch('fonda lee', ['Fonda Lee', 'Someone Else']);
      expect(decision, isA<AuthorMatchExact>());
      expect((decision as AuthorMatchExact).existingName, 'Fonda Lee');
    });

    test('an ambiguous near-match resolves to AuthorMatchAmbiguous, ranked by confidence', () {
      final decision = resolveAuthorMatch('F. C. Yee', ['Fonda C. Yee', 'Unrelated Author']);
      expect(decision, isA<AuthorMatchAmbiguous>());
      final candidates = (decision as AuthorMatchAmbiguous).candidates;
      expect(candidates.single.existingName, 'Fonda C. Yee');
    });

    test('a clearly new name with no similar existing author resolves to AuthorMatchNew', () {
      final decision = resolveAuthorMatch('Brandon Sanderson', ['Fonda Lee', 'Frank Herbert']);
      expect(decision, isA<AuthorMatchNew>());
    });
  });
}
