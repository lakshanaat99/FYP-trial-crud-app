import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SetupHelper extends StatelessWidget {
  const SetupHelper({super.key});

  static const String _sqlSchema = '''
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

  void _copySqlToClipboard(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: _sqlSchema)).then((_) {
      if (context.mounted) {
        _showSnackBar(context, 'SQL schema script copied to clipboard!');
      }
    });
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    final theme = Theme.of(context);
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
            ? theme.colorScheme.error
            : theme.colorScheme.primary,
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

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: ExpansionTile(
          iconColor: theme.colorScheme.secondary,
          collapsedIconColor: Colors.white.withValues(alpha: 0.5),
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
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
                    onPressed: () => _copySqlToClipboard(context),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy SQL Script'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.2),
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
