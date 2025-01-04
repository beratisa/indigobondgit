import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For parsing JSON responses

class NewDashboardPage extends StatefulWidget {
  const NewDashboardPage({super.key});

  @override
  _NewDashboardPageState createState() => _NewDashboardPageState();
}

class _NewDashboardPageState extends State<NewDashboardPage> {
  List securities = [];
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _formData = {};

  @override
  void initState() {
    super.initState();
    fetchSecurities(); // Fetch all securities on page load
  }

  Future<void> fetchSecurities() async {
    try {
      var url = Uri.parse(
          'http://192.168.100.95:8080/securities'); // Flask API endpoint
      var response = await http.get(
        url,
        headers: {
          'Authorization': 'PIN 252-755-032', // Add PIN in the headers
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          securities = json.decode(response.body);
        });
      } else {
        showError('Failed to load securities. Status: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network errors
      showError('An error occurred: $e');
    }
  }

  Future<void> createOrUpdateSecurity({int? securityId}) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        String url = securityId == null
            ? 'http://192.168.100.95:8080/securities'
            : 'http://192.168.100.95:8080/securities/$securityId';

        var response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'PIN 252-755-032', // Add PIN in the headers
          },
          body: json.encode(_formData),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          fetchSecurities(); // Refresh the list after adding/updating
          clearForm();
          showSuccess('Security saved successfully.');
        } else {
          showError('Failed to save security. Status: ${response.statusCode}');
        }
      } catch (e) {
        showError('An error occurred: $e');
      }
    }
  }

  Future<void> deleteSecurity(int securityId) async {
    try {
      var url = Uri.parse('http://192.168.100.25:5000/securities/$securityId');
      var response = await http.delete(
        url,
        headers: {
          'Authorization': 'PIN 252-755-032', // Add PIN in the headers
        },
      );
      if (response.statusCode == 200) {
        fetchSecurities(); // Refresh the list after deletion
        showSuccess('Security deleted successfully.');
      } else {
        showError('Failed to delete security. Status: ${response.statusCode}');
      }
    } catch (e) {
      showError('An error occurred: $e');
    }
  }

  void clearForm() {
    setState(() {
      _formData = {};
      _formKey.currentState?.reset();
    });
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.green)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Securities Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _formData = {}; // Reset form for creating new security
              showModalBottomSheet(
                context: context,
                builder: (context) => buildForm(),
              );
            },
          ),
        ],
      ),
      body: securities.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: securities.length,
              itemBuilder: (context, index) {
                var security = securities[index];

                // Check for null values in the security data
                return ListTile(
                  title: Text(security['sec_name'] ?? 'Unknown Security'),
                  subtitle:
                      Text('Ticker: ${security['ticker_symbol'] ?? 'N/A'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _formData = security ?? {};
                          showModalBottomSheet(
                            context: context,
                            builder: (context) =>
                                buildForm(securityId: security['security_id']),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            deleteSecurity(security['security_id'] ?? 0),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // Form for adding/updating securities
  Widget buildForm({int? securityId}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _formData['isin_code'] ?? '',
              decoration: const InputDecoration(labelText: 'ISIN Code'),
              onSaved: (value) => _formData['isin_code'] = value,
              validator: (value) =>
                  value!.isEmpty ? 'ISIN Code is required' : null,
            ),
            TextFormField(
              initialValue: _formData['sec_name'] ?? '',
              decoration: const InputDecoration(labelText: 'Security Name'),
              onSaved: (value) => _formData['sec_name'] = value,
              validator: (value) =>
                  value!.isEmpty ? 'Security Name is required' : null,
            ),
            TextFormField(
              initialValue: _formData['ticker_symbol'] ?? '',
              decoration: const InputDecoration(labelText: 'Ticker Symbol'),
              onSaved: (value) => _formData['ticker_symbol'] = value,
              validator: (value) =>
                  value!.isEmpty ? 'Ticker Symbol is required' : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => createOrUpdateSecurity(securityId: securityId),
              child: Text(securityId == null ? 'Create' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }
}
