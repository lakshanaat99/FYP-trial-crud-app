import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase using the provided URL and Anon Key
  await Supabase.initialize(
    url: 'https://qmxudhipjjijesjtcfzx.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFteHVkaGlwamppamVzanRjZnp4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE0MzEwODIsImV4cCI6MjA5NzAwNzA4Mn0.Dt3uHUkydmltOLiZbYBxnkmGeYUfryu-5IINKfYct80',
  );

  runApp(const SupabaseCrudApp());
}

class SupabaseCrudApp extends StatelessWidget {
  const SupabaseCrudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase CRUD Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF7C3AED), // Premium Violet
        scaffoldBackgroundColor: const Color(0xFF0F111A), // Midnight background
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7C3AED),
          secondary: Color(0xFF06B6D4), // Neon Cyan
          surface: Color(0xFF1E2235), // Dark Card/Surface
          error: Color(0xFFF43F5E), // Neon Red
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E2235),
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // State variables
  List<Map<String, dynamic>> _records = [];
  final Set<int> _selectedIds = {};
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Fetch all records from Supabase
  Future<void> _fetchRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _supabase
          .from('names')
          .select()
          .order('created_at', ascending: false);
      
      setState(() {
        _records = List<Map<String, dynamic>>.from(response);
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

  // Insert a new record
  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();

    try {
      await _supabase.from('names').insert({'name': name});
      _nameController.clear();
      _showSnackBar('Name successfully added!');
      await _fetchRecords();
    } catch (e) {
      _showSnackBar('Failed to add name. Ensure table exists & RLS policies permit inserts.', isError: true);
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Delete all selected records
  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected'),
        content: Text('Are you sure you want to delete ${_selectedIds.length} item(s)?'),
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
      final listToDelete = _selectedIds.toList();
      await _supabase.from('names').delete().inFilter('id', listToDelete);
      _showSnackBar('Successfully deleted ${_selectedIds.length} item(s).');
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

  // Copy SQL script to clipboard
  void _copySqlToClipboard() {
    const sql = '''
create table public.names (
  id bigint generated always as identity primary key,
  name text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable Row Level Security (RLS)
alter table public.names enable row level security;

-- Setup permissive CRUD policies for anonymous access
create policy "Allow public read" on public.names for select using (true);
create policy "Allow public insert" on public.names for insert with check (true);
create policy "Allow public delete" on public.names for delete using (true);
''';
    Clipboard.setData(const ClipboardData(text: sql)).then((_) {
      _showSnackBar('SQL schema script copied to clipboard!');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              // Header Section
              _buildHeader(theme),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Input Card
                          _buildInputCard(theme),
                          const SizedBox(height: 24),

                          // Action Control Bar for list
                          _buildListControls(theme),
                          const SizedBox(height: 16),

                          // Database List
                          _buildDataSection(theme),
                          const SizedBox(height: 32),

                          // Database Setup / SQL Panel Helper
                          _buildSetupHelper(theme),
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
                    theme.colorScheme.error.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.error.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _deleteSelected,
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

  // Build top dashboard header
  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.cloud_sync,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Supabase CRUD',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Status: Active Gateway',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: _fetchRecords,
            tooltip: 'Refresh Database',
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  // Build the text field & submit button card
  Widget _buildInputCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter User Name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Bilbo Baggins',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submitData(),
                  ),
                ),
                const SizedBox(width: 16),
                _isSubmitting
                    ? Container(
                        height: 52,
                        width: 100,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      )
                    : Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _submitData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.send_rounded, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'SUBMIT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build the list controls (Select all/Deselect all toggles)
  Widget _buildListControls(ThemeData theme) {
    if (_records.isEmpty) return const SizedBox.shrink();

    final isAllSelected = _selectedIds.length == _records.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: () {
            setState(() {
              if (isAllSelected) {
                _selectedIds.clear();
              } else {
                _selectedIds.addAll(_records.map((r) => r['id'] as int));
              }
            });
          },
          icon: Icon(
            isAllSelected ? Icons.check_box : Icons.check_box_outline_blank,
            color: theme.colorScheme.secondary,
          ),
          label: Text(
            isAllSelected ? 'Deselect All' : 'Select All',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          'Total: ${_records.length} records',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // Build database section (List of items, Empty state, Error state)
  Widget _buildDataSection(ThemeData theme) {
    if (_isLoading && _records.isEmpty) {
      return _buildShimmerLoading();
    }

    if (_errorMessage != null && _records.isEmpty) {
      return _buildErrorState(theme);
    }

    if (_records.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _records.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = _records[index];
        final id = record['id'] as int;
        final name = record['name'] as String;
        final createdAtStr = record['created_at'] != null
            ? DateTime.parse(record['created_at'] as String).toLocal().toString().split('.')[0]
            : 'Unknown';

        final isSelected = _selectedIds.contains(id);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.15)
                : theme.colorScheme.surface.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.white.withOpacity(0.05),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.1),
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
                setState(() {
                  if (checked == true) {
                    _selectedIds.add(id);
                  } else {
                    _selectedIds.remove(id);
                  }
                });
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
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error.withOpacity(0.8)),
              tooltip: 'Delete Item',
              onPressed: () async {
                setState(() {
                  _selectedIds.clear();
                  _selectedIds.add(id);
                });
                await _deleteSelected();
              },
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
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
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
                      color: Colors.white.withOpacity(0.05),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 10,
                      color: Colors.white.withOpacity(0.03),
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
        color: theme.colorScheme.surface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Colors.white.withOpacity(0.2),
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
              color: Colors.white.withOpacity(0.4),
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
        color: theme.colorScheme.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.2)),
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
            'Error Detail: $_errorMessage',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchRecords,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error.withOpacity(0.2),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // Collapsible SQL schema panel helper
  Widget _buildSetupHelper(ThemeData theme) {
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        child: ExpansionTile(
          iconColor: theme.colorScheme.secondary,
          collapsedIconColor: Colors.white.withOpacity(0.5),
          title: Row(
            children: [
              Icon(
                Icons.settings_ethernet,
                size: 20,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 12),
              const Text(
                'Supabase Setup Instructions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'To enable this app to insert, read, and delete records, execute the following SQL script inside your Supabase project\'s SQL Editor:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: const Text(
                      '-- Create public table "names"\n'
                      'create table public.names (\n'
                      '  id bigint generated always as identity primary key,\n'
                      '  name text not null,\n'
                      '  created_at timestamp with time zone default timezone(\'utc\'::text, now()) not null\n'
                      ');\n\n'
                      '-- Enable Row Level Security (RLS)\n'
                      'alter table public.names enable row level security;\n\n'
                      '-- Allow anonymous access policies\n'
                      'create policy "Allow public read" on public.names for select using (true);\n'
                      'create policy "Allow public insert" on public.names for insert with check (true);\n'
                      'create policy "Allow public delete" on public.names for delete using (true);',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFFA5B4FC), // light indigo
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _copySqlToClipboard,
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy SQL Script'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
