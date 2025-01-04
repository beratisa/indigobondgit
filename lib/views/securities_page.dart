import 'package:flutter/material.dart';
import '../models/security.dart';
import '../services/database_service.dart';

class SecuritiesPage extends StatefulWidget {
  const SecuritiesPage({super.key});

  @override
  _SecuritiesPageState createState() => _SecuritiesPageState();
}

class _SecuritiesPageState extends State<SecuritiesPage> {
  late Future<List<Security>> securities;

  @override
  void initState() {
    super.initState();
    securities = DatabaseService().fetchSecurities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Securities'),
      ),
      body: FutureBuilder<List<Security>>(
        future: securities,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text("No securities found."));
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              Security security = snapshot.data![index];
              return ListTile(
                title: Text(security.secName),
                subtitle: Text(
                    'ISIN: ${security.isinCode} - Price: ${security.price.toStringAsFixed(2)}'),
              );
            },
          );
        },
      ),
    );
  }
}
