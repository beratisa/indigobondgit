import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SecurityFormPage extends StatefulWidget {
  final Map<String, dynamic>? security; // For updating security

  const SecurityFormPage({this.security, super.key});

  @override
  _SecurityFormPageState createState() => _SecurityFormPageState();
}

class _SecurityFormPageState extends State<SecurityFormPage> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _formData = {};
  String? _selectedSecurityType;
  String? _selectedSecuritySubtype;
  String? _selectedBasisCode;
  String? _selectedCountry;
  String? _selectedRatingId; // Rating selected by combined_rating

  List<Map<String, dynamic>> countries = [];
  List<Map<String, dynamic>> ratings = []; // List to hold rating options
  List<String> basisOptions = [];
  bool isCountryLoading = true;
  bool isRatingLoading = true; // Added for ratings

  final TextEditingController _issueDateController = TextEditingController();
  final TextEditingController _maturityDateController = TextEditingController();
  final TextEditingController _accrualStartDateController =
      TextEditingController(); // Added Accrual Start Date

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
          widget.security!['accrual_st_date'] ?? '';
      _selectedCountry = widget.security!['country_id']?.toString();
      _selectedRatingId = widget.security!['rating_id']?.toString();
      _selectedBasisCode = widget.security!['basis_code'];
      _setBasisCodeOptions(); // Update basis options based on security type
    }
    fetchCountries(); // Fetch countries independently
    fetchRatings(); // Fetch ratings independently
  }

  // Fetch countries independently
  Future<void> fetchCountries() async {
    try {
      final url = Uri.parse('http://192.168.100.95:8080/api/countries');
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
      final url = Uri.parse('http://192.168.100.95:8080/api/ratings');
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

  void _setBasisCodeOptions() {
    if (_selectedSecurityType == 'GOVT' ||
        _selectedSecurityType == 'CORP' ||
        _selectedSecurityType == 'ETF') {
      basisOptions = ['ACT/ACT', 'ACT/360', 'ACT/365', '30/360', '30/365'];
    } else if (_selectedSecurityType == 'STOCK') {
      basisOptions = ['None'];
    } else {
      basisOptions = [];
    }
  }

  Future<void> saveSecurity() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        String url = widget.security == null
            ? 'http://192.168.100.95:8080/securities'
            : 'http://192.168.100.95:8080/securities/${widget.security!['security_id']}';

        var response = await http.post(
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
            const SnackBar(content: Text('Security saved successfully!')),
          );
        } else {
          throw Exception(
              'Failed to save security. Status: ${response.statusCode}');
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
        title: Text(
            widget.security == null ? 'Create Security' : 'Update Security'),
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
                    Flexible(
                      flex: 8, // 80% width
                      child: _buildTextFormField('ISIN Code', 'isin_code'),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      flex: 8, // 80% width
                      child: _buildTextFormField('Security Name', 'sec_name'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Flexible(
                      flex: 8, // 80% width
                      child: _buildSecurityTypeDropdown(),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      flex: 8, // 80% width
                      child: _buildSecuritySubtypeDropdown(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Flexible(
                      flex: 8, // 80% width
                      child: _buildBasisCodeDropdown(),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      flex: 8, // 80% width
                      child:
                          _buildTextFormField('Ticker Symbol', 'ticker_symbol'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Flexible(
                      flex: 8, // 80% width
                      child: _buildTextFormField('Minimum Quantity', 'min_qty'),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      flex: 8, // 80% width
                      child: _buildTextFormField('Price', 'price'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Flexible(
                      flex: 8, // 80% width
                      child: _buildTextFormField('Coupon Rate', 'cp_rate'),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      flex: 8, // 80% width
                      child: _buildCountryDropdown(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Flexible(
                      flex: 8, // 80% width
                      child: _buildDateFormField(
                          'Issue Date', 'issue_date', _issueDateController),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      flex: 8, // 80% width
                      child: _buildDateFormField('Accrual Start Date',
                          'accrual_st_date', _accrualStartDateController),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Flexible(
                      flex: 8, // 80% width
                      child: _buildDateFormField('Maturity Date',
                          'maturity_date', _maturityDateController),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      flex: 8, // 80% width
                      child: _buildRatingDropdown(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: saveSecurity,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.indigo, // Text color
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 20),
                  ),
                  child: Text(widget.security == null ? 'Create' : 'Update'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Independent widget for Country Dropdown
  Widget _buildCountryDropdown() {
    if (isCountryLoading) {
      return const CircularProgressIndicator(); // Show spinner until data is loaded
    }
    if (countries.isEmpty) {
      return const Text('No countries available'); // Check for empty list
    }

    return DropdownButtonFormField<String>(
      value: _selectedCountry,
      decoration: const InputDecoration(
        labelText: 'Country',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
      items: countries.map((country) {
        return DropdownMenuItem<String>(
          value: country['country_id'].toString(), // Ensure unique values
          child: Text(country['country_name']),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCountry = value;
          _formData['country_id'] = value;
        });
      },
      validator: (value) {
        // Country is required if Security Type is GOVT
        if (_selectedSecurityType == 'GOVT' &&
            (value == null || value.isEmpty)) {
          return 'Country is required for GOVT';
        }
        return null; // No validation needed for non-GOVT types
      },
    );
  }

  // Independent widget for Rating Dropdown
  Widget _buildRatingDropdown() {
    if (isRatingLoading) {
      return const CircularProgressIndicator(); // Show spinner until data is loaded
    }
    if (ratings.isEmpty) {
      return const Text('No ratings available'); // Check for empty list
    }

    return DropdownButtonFormField<String>(
      value: _selectedRatingId,
      decoration: const InputDecoration(
        labelText: 'Rating',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
      items: ratings.map((rating) {
        return DropdownMenuItem<String>(
          value: rating['rating_id']
              .toString(), // Ensure unique values for each item
          child: Text(rating['combined_rating']), // Display combined_rating
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedRatingId = value;
          _formData['rating_id'] = value; // Store rating_id for the form
        });
      },
      validator: (value) =>
          value == null || value.isEmpty ? 'Rating is required' : null,
    );
  }

  Widget _buildBasisCodeDropdown() {
    if (basisOptions.isEmpty) {
      return const Text('No Basis Code available for this type');
    }

    return DropdownButtonFormField<String>(
      value: _selectedBasisCode,
      decoration: const InputDecoration(
        labelText: 'Basis Code',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
      items: basisOptions.map((basis) {
        return DropdownMenuItem<String>(
          value: basis,
          child: Text(basis),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedBasisCode = value;
          _formData['basis_code'] = value;
        });
      },
      validator: (value) => value == null ? 'Basis Code is required' : null,
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
        _formData[field] = formattedDate;
      });
    }
  }

  Widget _buildSecurityTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSecurityType,
      decoration: const InputDecoration(
        labelText: 'Security Type',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
      items: ['GOVT', 'CORP', 'STOCK', 'ETF'].map((type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedSecurityType = value;
          _selectedSecuritySubtype = null;
          _formData['security_type'] = value;
          _setBasisCodeOptions(); // Update basis options when type changes
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
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
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
