import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modern_auth_app/models/local_issue_model.dart';
import 'package:modern_auth_app/services/offline_sync_service.dart';
import 'package:provider/provider.dart';

class UnsyncedIssuesScreen extends StatefulWidget {
  const UnsyncedIssuesScreen({super.key});

  @override
  UnsyncedIssuesScreenState createState() => UnsyncedIssuesScreenState();
}

class UnsyncedIssuesScreenState extends State<UnsyncedIssuesScreen> {
  late Future<List<LocalIssue>> _unsyncedIssuesFuture;

  @override
  void initState() {
    super.initState();
    // Access OfflineSyncService from the context and load issues.
    // The listen: false is important because we are calling this from initState.
    _loadUnsyncedIssues();
  }

  void _loadUnsyncedIssues() {
    final offlineSyncService =
        Provider.of<OfflineSyncService>(context, listen: false);
    setState(() {
      _unsyncedIssuesFuture = offlineSyncService.getUnsyncedIssues();
    });
  }

  Future<void> _deleteIssue(int issueId) async {
    final offlineSyncService =
        Provider.of<OfflineSyncService>(context, listen: false);
    try {
      await offlineSyncService.deleteLocalIssue(issueId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Issue deleted successfully')),
      );
      _loadUnsyncedIssues();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete issue: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unsynced Issues'),
      ),
      body: FutureBuilder<List<LocalIssue>>(
        future: _unsyncedIssuesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No unsynced issues found.'));
          }

          final issues = snapshot.data!;
          return ListView.builder(
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final issue = issues[index];
              return ListTile(
                title: Text(issue.description),
                subtitle: Text(
                    '${issue.category} - ${DateFormat.yMd().add_jms().format(issue.timestamp)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteIssue(issue.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}