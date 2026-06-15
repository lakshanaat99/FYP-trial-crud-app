import 'package:flutter/material.dart';
import '../../../models/name_record.dart';

class RecordList extends StatelessWidget {
  final List<NameRecord> records;
  final Set<int> selectedIds;
  final bool isLoading;
  final String? errorMessage;
  final void Function(int id, bool selected) onSelectionChanged;
  final void Function(int id) onDeleteRecord;
  final VoidCallback onRefresh;

  const RecordList({
    super.key,
    required this.records,
    required this.selectedIds,
    required this.isLoading,
    required this.errorMessage,
    required this.onSelectionChanged,
    required this.onDeleteRecord,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading && records.isEmpty) {
      return _buildShimmerLoading();
    }

    if (errorMessage != null && records.isEmpty) {
      return _buildErrorState(theme);
    }

    if (records.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = records[index];
        final id = record.id;
        final name = record.name;
        final createdAtStr = record.createdAt.toString().split('.')[0];
        final isSelected = selectedIds.contains(id);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                : theme.colorScheme.surface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.white.withValues(alpha: 0.05),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Checkbox(
              value: isSelected,
              activeColor: theme.colorScheme.primary,
              onChanged: (bool? checked) {
                if (checked != null) {
                  onSelectionChanged(id, checked);
                }
              },
            ),
            title: Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Added: $createdAtStr',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error.withValues(alpha: 0.8)),
              tooltip: 'Delete Item',
              onPressed: () => onDeleteRecord(id),
            ),
          ),
        );
      },
    );
  }

  // Shimmer loading UI helper
  Widget _buildShimmerLoading() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          height: 72,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 140,
                      height: 16,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 10,
                      color: Colors.white.withValues(alpha: 0.03),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Empty state UI helper
  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'No names stored yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a name above to save it into Supabase',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Error state UI helper
  Widget _buildErrorState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Text(
                'Database Table Connection Error',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'The app could not find the "names" table. Please check if you have executed the database schema setup in your Supabase SQL Editor.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            'Error Detail: $errorMessage',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
