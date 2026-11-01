import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:amaterasutrip/features/trips/bucket_list/data/bucket_deletion_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/models/trip_destination.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/services/destination_places_service.dart';

import 'package:amaterasutrip/features/trips/bucket_list/data/bucket_activity_repository.dart';
import 'package:amaterasutrip/features/trips/bucket_list/data/bucket_vote_repository.dart';
import 'package:amaterasutrip/features/trips/bucket_list/models/bucket_item_type.dart';
import 'package:amaterasutrip/features/trips/bucket_list/models/bucket_list_item.dart';
import 'package:amaterasutrip/features/trips/bucket_list/models/bucket_priority.dart';
import 'package:amaterasutrip/features/trips/bucket_list/presentation/widgets/bucket_place_photo.dart';

part 'bucket_activity_editor_part.dart';
part 'bucket_activity_delete_request_part.dart';
part 'bucket_activity_card_part.dart';
part 'bucket_category_labels_part.dart';

part 'bucket_method_locale.dart';
part 'bucket_method_translation.dart';
part 'bucket_method_refresh.dart';
part 'bucket_method_load_more.dart';
part 'bucket_method_load_categories.dart';
part 'bucket_method_category_key.dart';
part 'bucket_method_register_category.dart';
part 'bucket_method_priority.dart';
part 'bucket_method_average.dart';
part 'bucket_method_visible_items.dart';
part 'bucket_method_save_activity.dart';
part 'bucket_method_vote.dart';
part 'bucket_method_page_view.dart';
part 'bucket_total_count.dart';
part 'bucket_method_preferences.dart';

class TripBucketListPage extends StatefulWidget {
  const TripBucketListPage({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripBucketListPage> createState() => _TripBucketListPageState();
}

class _TripBucketListPageState extends State<TripBucketListPage> {
  late final BucketActivityRepository _activities;
  late final BucketVoteRepository _votes;
  final DestinationPlacesService _places = const DestinationPlacesService();

  final List<BucketListItem> _items = [];
  final Map<String, Map<String, BucketPriority>> _itemVotes = {};
  final Set<String> _pendingVoteIds = {};
  final List<String> _categories = [];
  String _viewMode = 'cards';
  String _sortMode = 'priority';
  bool _sortAscending = false;
  String _filterCity = '';
  String _filterCategory = '';
  String _filterPriority = '';
  String _filterVoting = '';
  String _filterMine = '';
  String _filterSearch = '';
  bool _searchLoading = false;

  DocumentSnapshot<Map<String, dynamic>>? _cursor;

  List<String> _members = [];
  late Future<int> _totalCountFuture;
  bool _loading = true;
  bool _busy = false;
  bool _hasMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    _activities = BucketActivityRepository(firestore, auth);
    _votes = BucketVoteRepository(firestore, auth);

    _loadBucketPreferences();
    _totalCountFuture = _readBucketTotal();
    _refresh();
  }

  @override
  Widget build(BuildContext context) => _renderBucketPage(context);
}
