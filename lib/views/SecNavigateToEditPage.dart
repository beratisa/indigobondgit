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
      _accrualStartDateController.text = widget.security!['accrual_st_date'] ??
          ''; // Prefill accrual start date
      _selectedCountry = widget.security!['country_id']?.toString();
      _selectedRatingId = widget.security!['rating_id']?.toString();
      _selectedBasisCode = widget.security!['basis_code'];
    }
    fetchCountries(); // Fetch countries independently
    fetchRatings(); // Fetch ratings independently
  }

  // Fetch countries independently
  Future<void> fetchCountries() async {
    try {
      final url = Uri.parse('http://192.168.100.95:8080/countries');
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
      final url = Uri.parse('http://localhost:8080/ratings');
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

      // Add debug print to check form data before sending the request

      try {
        String url =
            'http://localhost:8080/securities/${widget.security!['security_id']}';

        var response = await http.put(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'PIN 252-755-032', // Add your auth token here
          },
          body: json.encode(_formData),
        );

        print('Response: ${response.body}'); // Log the response from the server

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
                        child: _buildTextFormField('ISIN Code', 'isin_code')),
                    const SizedBox(width: 16),
                    Expanded(
                        child:
                            _buildTextFormField('Security Name', 'sec_name')),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildSecurityTypeDropdown()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildSecuritySubtypeDropdown()),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                        child: _buildTextFormField('Basis Code', 'basis_code')),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildTextFormField(
                            'Ticker Symbol', 'ticker_symbol')),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                        child:
                            _buildTextFormField('Minimum Quantity', 'min_qty')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextFormField('Price', 'price')),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                        child: _buildTextFormField('Coupon Rate', 'cp_rate')),
                    const SizedBox(width: 16),
                    Expanded(
                        child:
                            _buildCountryDropdown()), // Added Country Dropdown
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                        child: _buildDateFormField(
                            'Issue Date', 'issue_date', _issueDateController)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildDateFormField(
                            'Accrual Start Date',
                            'accrual_st_date',
                            _accrualStartDateController)), // Added Accrual Start Date
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                        child: _buildDateFormField('Maturity Date',
                            'maturity_date', _maturityDateController)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildRatingDropdown()), // Added Rating Dropdown
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

  Widget _buildTextFormField(String label, String field) {
    return TextFormField(
      initialValue: _formData[field]?.toString() ?? '',
      decoration: InputDecoration(labelText: label),
      onSaved: (value) => _formData[field] = value,
      validator: (value) => value!.isEmpty ? '$label is required' : null,
    );
  }

  Widget _buildDateFormField(
      String label, String field, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      readOnly: true,
      onTap: () => _selectDate(context, controller, field),
      onSaved: (value) => _formData[field] = value,
      validator: (value) => value!.isEmpty ? '$label is required' : null,
    );
  }

  Future<void> _selectDate(BuildContext context,
      TextEditingController controller, String field) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        String formattedDate =
            "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
        controller.text = formattedDate;
        _formData[field] = formattedDate; // Save date in formData
      });
    }
  }

  Widget _buildSecurityTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSecurityType,
      decoration: const InputDecoration(
          labelText: 'Security Type',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.arrow_drop_down)),
      items: ['GOVT', 'CORP', 'STOCK', 'ETF'].map((type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedSecurityType = value;
          _selectedSecuritySubtype = null; // Reset subtype when type changes
          _formData['security_type'] = value;
        });
      },
      validator: (value) => value == null ? 'Security Type is required' : null,
    );
  }

  Widget _buildSecuritySubtypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSecuritySubtype,
      decoration: const InputDecoration(
          labelText: 'Security Subtype',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.arrow_drop_down)),
      items: (_selectedSecurityType != null
              ? securitySubtypes[_selectedSecurityType] ?? []
              : [])
          .map((subtype) {
        return DropdownMenuItem<String>(
          value: subtype,
          child: Text(subtype),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedSecuritySubtype = value;
          _formData['security_subtype'] = value;
        });
      },
      validator: (value) =>
          value == null ? 'Security Subtype is required' : null,
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
      items: ratings.map((rating) {
        String displayText =
            "${rating['rating_id']} - ${rating['rating_agency']} (${rating['long_term_rating']} / ${rating['short_term_rating']})";
        return DropdownMenuItem<String>(
          value: rating['rating_id'].toString(),
          child: Text(displayText),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedRatingId = value;
          _formData['rating_id'] = value;
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
      items: countries.map((country) {
        return DropdownMenuItem<String>(
          value: country['country_id'].toString(),
          child: Text(country['country_name']),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCountry = value;
          _formData['country_id'] = value;
        });
      },
      validator: (value) => value == null ? 'Country is required' : null,
    );
  }

  final Map<String, List<String>> securitySubtypes = {
    'GOVT': ['TBill', 'Tbond', 'ZTBond', 'Funds', 'Other'],
    'CORP': ['ABS', 'MBS', 'CBOND', 'DBOND', 'OTHER'],
    'STOCK': [
      'Ordinary Shares',
      'Preferred Shares',
      'Redeemable shares',
      'Non-voting Shares'
    ],
    'ETF': ['ETFUCITS', 'ETFLEV'],
  };
}
