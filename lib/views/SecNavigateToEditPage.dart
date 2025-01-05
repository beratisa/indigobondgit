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
  String? _selectedRatingId;
  String? _selectedCountry;

  List<Map<String, dynamic>> countries = [];
  List<Map<String, dynamic>> ratings = [];
  bool isCountryLoading = true;
  bool isRatingLoading = true;

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
      _selectedCountry =
          "${widget.security!['country_id']}-${countries.indexWhere((c) => c['country_id'] == widget.security!['country_id'])}";
      _selectedRatingId =
          "${widget.security!['rating_id']}-${ratings.indexWhere((r) => r['rating_id'] == widget.security!['rating_id'])}";
      _selectedBasisCode = widget.security!['basis_code'];
    }
    fetchCountries(); // Fetch countries independently
    fetchRatings(); // Fetch ratings independently
  }

  // Fetch countries independently
  Future<void> fetchCountries() async {
    try {
      final url = Uri.parse('http://127.0.0.1:5000/countries');
      final response = await http.get(url, headers: {
        'Authorization': 'PIN 252-755-032',
      });

      if (response.statusCode == 200) {
        setState(() {
          countries =
              List<Map<String, dynamic>>.from(json.decode(response.body));
          isCountryLoading = false;
        });
      } else {
        throw Exception('Failed to load countries');
      }
    } catch (e) {
      setState(() {
        isCountryLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load countries: $e')),
      );
    }
  }

  // Fetch ratings independently
  Future<void> fetchRatings() async {
    try {
      final url = Uri.parse('http://127.0.0.1:5000/ratings');
      final response = await http.get(url, headers: {
        'Authorization': 'PIN 252-755-032',
      });

      if (response.statusCode == 200) {
        setState(() {
          ratings = List<Map<String, dynamic>>.from(json.decode(response.body));
          isRatingLoading = false;
        });
      } else {
        throw Exception('Failed to load ratings');
      }
    } catch (e) {
      setState(() {
        isRatingLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load ratings: $e')),
      );
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
                Row(
                  children: [
                    Expanded(
                        child:
                            _buildCountryDropdown()), // Country Dropdown Updated
                    const SizedBox(width: 16),
                    Expanded(
                        child:
                            _buildRatingDropdown()), // Rating Dropdown Updated
                  ],
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

  // Independent widget for Rating Dropdown
  Widget _buildRatingDropdown() {
    if (isRatingLoading) {
      return const CircularProgressIndicator(); // Show spinner until data is loaded
    }
    return DropdownButtonFormField<String>(
      value: _selectedRatingId,
      decoration: const InputDecoration(
        labelText: 'Rating',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.arrow_drop_down)),
      items: ratings.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> rating = entry.value;
      int randomNumber = (1 + (5000 * 1000000 - 1) * (index + 1) % 5000).toInt(); // Generate a random number between 1 and 5000 Mio
      String displayText =
        "${rating['rating_id']} - ${rating['rating_agency']} (${rating['long_term_rating']} / ${rating['short_term_rating']}) - $randomNumber";
      return DropdownMenuItem<String>(
        value: "${rating['rating_id']}-${index}", // Append index to ensure uniqueness
        child: Text(displayText),
      );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedRatingId = value;
          _formData['rating_id'] = value?.split('-')[0]; // Extract actual rating ID
        });
      },
      validator: (value) => value == null ? 'Rating is required' : null,
    );
  }

  // Independent widget for Country Dropdown
  Widget _buildCountryDropdown() {
    if (isCountryLoading) {
      return const CircularProgressIndicator(); // Show spinner until data is loaded
    }
    return DropdownButtonFormField<String>(
      value: _selectedCountry,
      decoration: const InputDecoration(
          labelText: 'Country',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.arrow_drop_down)),
      items: countries.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> country = entry.value;
        return DropdownMenuItem<String>(
          value: "${country['country_id']}-${index}", // Append index to ensure uniqueness
          child: Text(country['country_name']),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCountry = value;
          _formData['country_id'] = value?.split('-')[0]; // Extract actual country ID
        });
      },
      validator: (value) => value == null ? 'Country is required' : null,
    );
  }
}
