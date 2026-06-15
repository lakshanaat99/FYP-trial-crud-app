import 'package:flutter/material.dart';
import '../../models/name_record.dart';
import '../../services/supabase_service.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/input_card.dart';
import 'widgets/record_list.dart';
import 'widgets/setup_helper.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final SupabaseService _supabaseService = SupabaseService();

  // State variables
  List<NameRecord> _records = [];
  final Set<int> _selectedIds = {};
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  // Fetch all records from Supabase
  Future<void> _fetchRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final records = await _supabaseService.fetchRecords();
      setState(() {
        _records = records;
        _selectedIds.clear();
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      _showSnackBar(
        'Failed to load data. Please check if your "names" table is created in Supabase.',
        isError: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add a new record
  Future<void> _addRecord(String name) async {
    setState(() {
      _errorMessage = null;
    });

    try {
      await _supabaseService.addRecord(name);
      _showSnackBar('Name successfully added!');
      await _fetchRecords();
    } catch (e) {
      _showSnackBar(
        'Failed to add name. Ensure table exists & RLS policies permit inserts.',
        isError: true,
      );
      setState(() {
        _errorMessage = e.toString();
      });
      rethrow;
    }
  }

  // Delete specific records by their IDs
  Future<void> _deleteRecords(List<int> ids) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected'),
        content: Text('Are you sure you want to delete ${ids.length} item(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _supabaseService.deleteRecords(ids);
      _showSnackBar('Successfully deleted ${ids.length} item(s).');
      await _fetchRecords();
    } catch (e) {
      _showSnackBar('Failed to delete records.', isError: true);
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Toggle selection for a specific record ID
  void _onSelectionChanged(int id, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  // Toggle selection for all records
  void _onToggleSelectAll(bool selectAll) {
    setState(() {
      if (selectAll) {
        _selectedIds.addAll(_records.map((r) => r.id));
      } else {
        _selectedIds.clear();
      }
    });
  }

  // Show customized modern SnackBar
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAllSelected = _records.isNotEmpty && _selectedIds.length == _records.length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0C14), // Dark base
              Color(0xFF161324), // Indigo hint
              Color(0xFF0E1A24), // Cyan hint
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              DashboardHeader(
                isLoading: _isLoading,
                onRefresh: _fetchRecords,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          InputCard(
                            onAddName: _addRecord,
                          ),
                          const SizedBox(height: 24),

                          // Action Control Bar for list
                          if (_records.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _onToggleSelectAll(!isAllSelected),
                                  icon: Icon(
                                    isAllSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                    color: theme.colorScheme.secondary,
                                  ),
                                  label: Text(
                                    isAllSelected ? 'Deselect All' : 'Select All',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Total: ${_records.length} records',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Database List
                          RecordList(
                            records: _records,
                            selectedIds: _selectedIds,
                            isLoading: _isLoading,
                            errorMessage: _errorMessage,
                            onSelectionChanged: _onSelectionChanged,
                            onDeleteRecord: (id) => _deleteRecords([id]),
                            onRefresh: _fetchRecords,
                          ),
                          const SizedBox(height: 32),

                          // Database Setup / SQL Panel Helper
                          const SetupHelper(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Floating Action Banner when items are selected
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _selectedIds.isEmpty
          ? null
          : AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.error,
                    theme.colorScheme.error.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.error.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _deleteRecords(_selectedIds.toList()),
                  borderRadius: BorderRadius.circular(30),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.delete_sweep, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'DELETE SELECTED (${_selectedIds.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
