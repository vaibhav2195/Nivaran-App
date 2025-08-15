import 'package:flutter/material.dart';

class DuplicateIssueBadge extends StatelessWidget {
  final String duplicateOfIssueId;
  final VoidCallback? onTap;
  
  const DuplicateIssueBadge({
    Key? key,
    required this.duplicateOfIssueId,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.amber.shade700),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.copy_all_rounded,
              size: 16.0,
              color: Colors.amber.shade800,
            ),
            const SizedBox(width: 4.0),
            Text(
              'Duplicate Issue',
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PotentialDuplicateDialog extends StatelessWidget {
  final String issueId;
  final String duplicateOfIssueId;
  final VoidCallback? onConfirm;
  final VoidCallback? onDismiss;
  
  const PotentialDuplicateDialog({
    Key? key,
    required this.issueId,
    required this.duplicateOfIssueId,
    this.onConfirm,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700),
          const SizedBox(width: 8.0),
          const Text('Potential Duplicate'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This issue appears to be a duplicate of an existing issue.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16.0),
          Text(
            'Would you like to:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8.0),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.merge_type_rounded),
            title: const Text('Mark as duplicate'),
            subtitle: const Text('This issue will be linked to the original'),
            dense: true,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.new_label_outlined),
            title: const Text('Submit as new issue'),
            subtitle: const Text('Create a separate issue record'),
            dense: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            if (onDismiss != null) onDismiss!();
          },
          child: const Text('SUBMIT AS NEW'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            if (onConfirm != null) onConfirm!();
          },
          child: const Text('MARK AS DUPLICATE'),
        ),
      ],
    );
  }
}