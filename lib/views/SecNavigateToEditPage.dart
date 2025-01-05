import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SecNavigateToEditPage extends StatefulWidget {
  final Map<String, dynamic>? security;

  const SecNavigateToEditPage({this.security, super.key});

  @override
  _SecNavigateToEditPageState createState() => _SecNavigateToEditPageState();
}

class _SecNavigateToEditPageState extends State<SecNavigateToEditPage> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _formData = {};
  String? _selectedSecurityType;
  String? _selectedSecuritySubtype;
  String? _selectedBasisCode;

  final TextEditingController _issueDateController = TextEditingController();
  final TextEditingController _maturityDateController = TextEditingController();
  final TextEditingController _accrualStartDateController =
      TextEditingController(); // Controller for accrual_st_date

  @override
  void initState() {
    super.initState();
    if (widget.security != null) {
      // Prefill form with security data if updating
      _formData = Map<String, dynamic>.from(widget.security!);
      _selectedSecurityType = widget.security!['security_type'];
      _selectedSecuritySubtype = widget.security!['security_subtype'];
      _issueDateController.text = widget.security!['issue_date'] ?? '';
      _maturityDateController.text = widget.security!['maturity_date'] ?? '';
      _accrualStartDateController.text =
          widget.security!['accrual_st_date'] ?? ''; // Prefill accrual start date
      _selectedBasisCode = widget.security!['basis_code'];
    }
  }

  Future<void> updateSecurity() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        String url =
            'http://127.0.0.1:5000/securities/${widget.security!['security_id']}';

        var response = await http.put(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'PIN 252-755-032',
          },
          body: json.encode(_formData),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          Navigator.pop(context, true); // Return to previous page after saving
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Security updated successfully!')),
          );
        } else {
          throw Exception(
              'Failed to update security. Status: ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Security'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Security Type'),
                  value: _selectedSecurityType,
                  items: ['BONDS', 'TBILLS', 'ETF', 'STOCK']
                    .map((type) => DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                      ))
                    .toList(),
                  onChanged: (value) {
                  setState(() {
                    _selectedSecurityType = value;
                  });
                  },
                  onSaved: (value) {
                  _formData['security_type'] = value;
                  },
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Security Subtype'),
                  value: _selectedSecuritySubtype,
                  items: _getSubtypeItems(),
                  onChanged: (value) {
                  setState(() {
                    _selectedSecuritySubtype = value;
                  });
                  },
                  onSaved: (value) {
                  _formData['security_subtype'] = value;
                  },
                ),
                TextFormField(
                  controller: _issueDateController,
                  decoration: const InputDecoration(labelText: 'Issue Date'),
                  onSaved: (value) {
                  _formData['issue_date'] = value;
                  },
                ),
                TextFormField(
                  controller: _maturityDateController,
                  decoration: const InputDecoration(labelText: 'Maturity Date'),
                  onSaved: (value) {
                    _formData['maturity_date'] = value;
                  },
                ),
                TextFormField(
                  controller: _accrualStartDateController,
                  decoration: const InputDecoration(labelText: 'Accrual Start Date'),
                  onSaved: (value) {
                    _formData['accrual_st_date'] = value;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Basis Code'),
                  initialValue: _selectedBasisCode,
                  onSaved: (value) {
                    _formData['basis_code'] = value;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: updateSecurity,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.indigo, // Text color
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50, vertical: 20),
                  ),
                  child: const Text('Update'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
