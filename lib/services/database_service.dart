import 'package:postgres/postgres.dart';
import '../models/security.dart';

class DatabaseService {
  final PostgreSQLConnection connection = PostgreSQLConnection(
    'localhost',
    5432,
    'bond_port',
    username: 'postgres',
    password: '3107',
  );

  Future<List<Security>> fetchSecurities() async {
    await connection.open();
    List<Map<String, Map<String, dynamic>>> result =
        await connection.mappedResultsQuery('SELECT * FROM public.securities;');
    await connection.close();

    return result
        .map((map) => Security.fromJson(map['public.securities']!))
        .toList();
  }
}
