import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/features/trips/bucket_list/models/bucket_priority.dart';
import 'package:amaterasutrip/features/trips/bucket_list/services/bucket_priority_calculator.dart';
import 'package:amaterasutrip/features/trips/bucket_list/services/bucket_itinerary_eligibility.dart';

void main() {
  test('Priority values match the Excel system', () {
    expect(BucketPriority.ss.points, 10);
    expect(BucketPriority.s.points, 7);
    expect(BucketPriority.a.points, 4);
    expect(BucketPriority.b.points, 1);
  });

  test('Four SS votes produce total 40 and average 10', () {
    final result = BucketPriorityCalculator.calculate(
      participantUids: ['a', 'b', 'c', 'd'],
      votesByUid: {
        'a': BucketPriority.ss,
        'b': BucketPriority.ss,
        'c': BucketPriority.ss,
        'd': BucketPriority.ss,
      },
    );

    expect(result.totalPoints, 40);
    expect(result.average, 10);
    expect(result.groupPriority, BucketPriority.ss);
    expect(result.allVoted, isTrue);
  });

  test('Missing votes do not lower the average', () {
    final result = BucketPriorityCalculator.calculate(
      participantUids: ['a', 'b', 'c', 'd'],
      votesByUid: {
        'a': BucketPriority.s,
        'c': BucketPriority.s,
        'd': BucketPriority.s,
      },
    );

    expect(result.totalPoints, 21);
    expect(result.average, 7);
    expect(result.respondedCount, 3);
    expect(result.pendingCount, 1);
    expect(result.groupPriority, BucketPriority.s);
    expect(result.allVoted, isFalse);
  });

  test('B is a valid expressed vote', () {
    final result = BucketPriorityCalculator.calculate(
      participantUids: ['a', 'b'],
      votesByUid: {'a': BucketPriority.b, 'b': BucketPriority.b},
    );

    expect(result.average, 1);
    expect(result.groupPriority, BucketPriority.b);
    expect(result.allVoted, isTrue);
  });

  test('Votes from nonparticipants are ignored', () {
    final result = BucketPriorityCalculator.calculate(
      participantUids: ['a', 'b'],
      votesByUid: {'a': BucketPriority.s, 'outsider': BucketPriority.ss},
    );

    expect(result.totalPoints, 7);
    expect(result.respondedCount, 1);
    expect(result.allVoted, isFalse);
  });

  test('Adding a member requires another vote', () {
    final votes = {'a': BucketPriority.ss, 'b': BucketPriority.a};

    expect(
      BucketItineraryEligibility.everyoneHasVoted(
        participantUids: ['a', 'b'],
        votesByUid: votes,
      ),
      isTrue,
    );

    expect(
      BucketItineraryEligibility.everyoneHasVoted(
        participantUids: ['a', 'b', 'c'],
        votesByUid: votes,
      ),
      isFalse,
    );
  });

  test('An empty participant list is never complete', () {
    final result = BucketPriorityCalculator.calculate(
      participantUids: [],
      votesByUid: {},
    );

    expect(result.average, isNull);
    expect(result.groupPriority, isNull);
    expect(result.allVoted, isFalse);
  });

  test('Itinerary action remains disabled', () {
    expect(
      BucketItineraryEligibility.canAddToItinerary(
        participantUids: ['a'],
        votesByUid: {'a': BucketPriority.ss},
      ),
      isFalse,
    );
  });

  test('Duplicate participant IDs count only once', () {
    final result = BucketPriorityCalculator.calculate(
      participantUids: ['a', 'a', 'b'],
      votesByUid: {'a': BucketPriority.ss, 'b': BucketPriority.s},
    );

    expect(result.participantCount, 2);
    expect(result.respondedCount, 2);
    expect(result.average, 8.5);
    expect(result.groupPriority, BucketPriority.ss);
  });
}
