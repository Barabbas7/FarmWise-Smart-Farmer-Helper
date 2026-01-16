import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlanEvent {
  final String id;
  final String title;
  final DateTime date;
  final String type; // 'planting', 'fertilizer', 'harvest', 'care', 'custom'
  final bool completed;

  PlanEvent({
    String? id,
    required this.title,
    required this.date,
    required this.type,
    this.completed = false,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': Timestamp.fromDate(date),
      'type': type,
      'completed': completed,
    };
  }

  factory PlanEvent.fromMap(Map<String, dynamic> map) {
    return PlanEvent(
      id: map['id'],
      title: map['title'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      type: map['type'] ?? 'care',
      completed: map['completed'] ?? false,
    );
  }
}

class FarmingPlan {
  final String id;
  final String userId;
  final String crop;
  final DateTime startDate;
  final List<PlanEvent> events;
  final bool isActive;

  FarmingPlan({
    required this.id,
    required this.userId,
    required this.crop,
    required this.startDate,
    required this.events,
    this.isActive = true,
  });

  factory FarmingPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FarmingPlan(
      id: doc.id,
      userId: data['userId'] ?? '',
      crop: data['crop'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      events: (data['events'] as List<dynamic>?)
              ?.map((e) => PlanEvent.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PlannerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Pre-defined templates for logic
  static final Map<String, List<Map<String, dynamic>>> _cropTemplates = {
    'Maize': [
      {'day': 0, 'title': 'Sowing Seeds', 'type': 'planting'},
      {'day': 3, 'title': 'Apply Pre-emergence Herbicide', 'type': 'care'},
      {
        'day': 14,
        'title': 'Apply First Fertilizer (NPK)',
        'type': 'fertilizer'
      },
      {'day': 21, 'title': 'First Weeding', 'type': 'care'},
      {'day': 45, 'title': 'Top Dressing (Urea)', 'type': 'fertilizer'},
      {'day': 60, 'title': 'Scout for Fall Armyworm', 'type': 'care'},
      {'day': 90, 'title': 'Harvest', 'type': 'harvest'},
    ],
    'Tomato': [
      {'day': 0, 'title': 'Transplanting Seedlings', 'type': 'planting'},
      {'day': 7, 'title': 'Gap Filling', 'type': 'care'},
      {'day': 14, 'title': 'Staking & Trellising', 'type': 'care'},
      {'day': 21, 'title': 'Apply Fungicide', 'type': 'care'},
      {'day': 30, 'title': 'Top Dressing', 'type': 'fertilizer'},
      {'day': 60, 'title': 'First Harvest', 'type': 'harvest'},
    ],
    'Wheat': [
      {'day': 0, 'title': 'Sowing', 'type': 'planting'},
      {'day': 21, 'title': 'Crown Root Initiation (Irrigate)', 'type': 'care'},
      {'day': 45, 'title': 'Tillering Stage (Weeding)', 'type': 'care'},
      {'day': 85, 'title': 'Flowering Stage check', 'type': 'care'},
      {'day': 120, 'title': 'Harvest', 'type': 'harvest'},
    ],
    'Cassava': [
      {'day': 0, 'title': 'Planting Cuttings', 'type': 'planting'},
      {'day': 30, 'title': 'Weeding', 'type': 'care'},
      {'day': 90, 'title': 'Second Weeding', 'type': 'care'},
      {'day': 270, 'title': 'Harvest Check', 'type': 'harvest'},
    ]
  };

  List<String> getAvailableCrops() => _cropTemplates.keys.toList();

  List<PlanEvent> generatePreview(String crop, DateTime startDate) {
    if (!_cropTemplates.containsKey(crop)) return [];

    return _cropTemplates[crop]!.map((t) {
      return PlanEvent(
        title: t['title'],
        date: startDate.add(Duration(days: t['day'] as int)),
        type: t['type'],
      );
    }).toList();
  }

  // Get active plan for current user
  Stream<FarmingPlan?> getActivePlan() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _db
        .collection('plans')
        .where('userId', isEqualTo: user.uid)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return FarmingPlan.fromFirestore(snapshot.docs.first);
    });
  }

  Future<void> createPlan(String crop, DateTime startDate) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    // Deactivate old plans
    final oldPlans = await _db
        .collection('plans')
        .where('userId', isEqualTo: user.uid)
        .where('isActive', isEqualTo: true)
        .get();

    for (var doc in oldPlans.docs) {
      await doc.reference.update({'isActive': false});
    }

    // Generate events
    final events = generatePreview(crop, startDate);

    // Save new plan
    await _db.collection('plans').add({
      'userId': user.uid,
      'crop': crop,
      'startDate': Timestamp.fromDate(startDate),
      'isActive': true,
      'events': events.map((e) => e.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addTask(String planId, PlanEvent task) async {
    final docRef = _db.collection('plans').doc(planId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    List<dynamic> events = doc.data()?['events'] ?? [];
    events.add(task.toMap());

    await docRef.update({'events': events});
  }

  Future<void> toggleTaskCompletion(
      String planId, String eventId, bool completed) async {
    final docRef = _db.collection('plans').doc(planId);

    // We transactionally update to ensure consistency
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      List<dynamic> eventsData = snapshot.data()?['events'] ?? [];

      // Map to list of objects to find and modify
      final updatedEvents = eventsData.map((e) {
        if (e['id'] == eventId) {
          return {...e, 'completed': completed};
        }
        return e;
      }).toList();

      transaction.update(docRef, {'events': updatedEvents});
    });
  }
}
