import 'package:isar/isar.dart';

part 'local_issue_model.g.dart';

@collection
class LocalIssue {
  Id id = Isar.autoIncrement; // Isar ID
  String? issueId; // Server-side ID, if synced
  late String description;
  late String category;
  late String urgency;
  List<String> tags = [];
  String? imageUrl;
  String? localImagePath;
  late DateTime timestamp;
  bool isSynced = false;
  bool isAiAnalysisDone = false;
}