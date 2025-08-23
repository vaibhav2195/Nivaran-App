import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/issue_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/issue_card.dart';
import 'package:modern_auth_app/l10n/app_localizations.dart';

class MyReportedIssuesScreen extends StatefulWidget {
  const MyReportedIssuesScreen({super.key});

  @override
  State<MyReportedIssuesScreen> createState() => _MyReportedIssuesScreenState();
}

class _MyReportedIssuesScreenState extends State<MyReportedIssuesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _userId = FirebaseAuth.instance.currentUser!.uid;
  late Future<List<Issue>> _issuesFuture;

  @override
  void initState() {
    super.initState();
    _issuesFuture = _firestoreService.getIssuesByUserId(_userId);
  }

  Future<void> _deleteIssue(String issueId) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteIssue),
        content: Text(AppLocalizations.of(context)!.deleteIssueConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteIssue(issueId);
        setState(() {
          _issuesFuture = _firestoreService.getIssuesByUserId(_userId);
        });
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Issue deleted successfully')),
        );
        }
      } catch (e) {
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete issue: $e')),
        );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myReportedIssues),
      ),
      body: FutureBuilder<List<Issue>>(
        future: _issuesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('You have not reported any issues.'));
          }

          final issues = snapshot.data!;
          return ListView.builder(
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final issue = issues[index];
              return IssueCard(
                issue: issue,
                onDelete: () => _deleteIssue(issue.id),
              );
            },
          );
        },
      ),
    );
  }
}