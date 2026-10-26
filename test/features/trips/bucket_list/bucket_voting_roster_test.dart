import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/features/trips/bucket_list/models/bucket_priority.dart';
import 'package:amaterasutrip/features/trips/bucket_list/services/bucket_voting_roster.dart';

void main() {
  test('Owner is included even when not in member list', () {
    final roster = BucketVotingRoster(
      ownerUid: 'owner',
      memberUids: ['traveler-a', 'traveler-b'],
    );

    expect(roster.participantCount, 3);
    expect(roster.contains('owner'), isTrue);
  });

  test('Repeated members are counted only once', () {
    final roster = BucketVotingRoster(
      ownerUid: 'owner',
      memberUids: ['owner', 'a', 'a', ''],
    );

    expect(roster.participantCount, 2);
  });

  test('Every actual member must vote', () {
    final roster = BucketVotingRoster(
      ownerUid: 'owner',
      memberUids: ['a', 'b'],
    );

    final votes = {'owner': BucketPriority.ss, 'a': BucketPriority.s};

    expect(roster.everyoneHasVoted(votes), isFalse);

    votes['b'] = BucketPriority.b;

    expect(roster.everyoneHasVoted(votes), isTrue);
  });

  test('New member makes an earlier vote set incomplete', () {
    final votes = {'owner': BucketPriority.ss, 'a': BucketPriority.s};

    final before = BucketVotingRoster(ownerUid: 'owner', memberUids: ['a']);

    final after = BucketVotingRoster(ownerUid: 'owner', memberUids: ['a', 'b']);

    expect(before.everyoneHasVoted(votes), isTrue);
    expect(after.everyoneHasVoted(votes), isFalse);
  });

  test('Departed member no longer affects the average', () {
    final roster = BucketVotingRoster(ownerUid: 'owner', memberUids: ['a']);

    final summary = roster.summarize({
      'owner': BucketPriority.ss,
      'a': BucketPriority.s,
      'departed': BucketPriority.b,
    });

    expect(summary.totalPoints, 17);
    expect(summary.average, 8.5);
    expect(summary.respondedCount, 2);
    expect(summary.groupPriority, BucketPriority.ss);
  });

  test('Empty voter list is not considered complete', () {
    final roster = BucketVotingRoster(ownerUid: '', memberUids: []);

    expect(roster.everyoneHasVoted({}), isFalse);
  });

  test('Itinerary remains disabled with all votes present', () {
    final roster = BucketVotingRoster(ownerUid: 'owner', memberUids: ['a']);

    expect(
      roster.canAddToItinerary({
        'owner': BucketPriority.ss,
        'a': BucketPriority.s,
      }),
      isFalse,
    );
  });

  test('Unknown user is not an eligible voter', () {
    final roster = BucketVotingRoster(ownerUid: 'owner', memberUids: ['a']);

    expect(roster.contains('outsider'), isFalse);
  });
}
