import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/name_record.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Fetch all records from the 'names' table ordered by 'created_at' descending.
  Future<List<NameRecord>> fetchRecords() async {
    final response = await _client
        .from('names')
        .select()
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((record) => NameRecord.fromJson(record as Map<String, dynamic>))
        .toList();
  }

  /// Insert a new record into the 'names' table.
  Future<void> addRecord(String name) async {
    await _client.from('names').insert({'name': name});
  }

  /// Delete list of records from the 'names' table by their IDs.
  Future<void> deleteRecords(List<int> ids) async {
    await _client.from('names').delete().inFilter('id', ids);
  }
}
