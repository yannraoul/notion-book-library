import 'package:flutter_test/flutter_test.dart';
import 'package:notion_book_library/services/book_lookup_service.dart';

void main() {
  final service = BookLookupService();

  BookLookupResult book(String title, List<String> authors) => BookLookupResult(title: title, authors: authors);

  group('BookLookupService.confidence', () {
    test('title match beats a title that only contains the author name (NBLM-7)', () {
      const query = 'Sapiens Yuval Noah Harari';
      final correct = book('Sapiens', ['Yuval Noah Harari']);
      final unrelated = book('Yuval Noah Harari: Seti', ['Someone Else']);

      final correctScore = service.confidence(query, correct);
      final unrelatedScore = service.confidence(query, unrelated);

      expect(correctScore, greaterThan(unrelatedScore));
    });

    test('a plain title-only query still scores highly against the right title', () {
      final result = book('The Hobbit', ['J.R.R. Tolkien']);
      expect(service.confidence('The Hobbit', result), greaterThan(0.9));
    });

    test('no regression when the author field has no overlap with the query', () {
      final result = book('Dune', ['Frank Herbert']);
      expect(service.confidence('Dune', result), greaterThan(0.9));
      expect(service.confidence('Unrelated Query Text', result), lessThan(0.2));
    });
  });
}
