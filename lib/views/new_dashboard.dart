import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sec_pro_01/views/SecNavigateToEditPage.dart';
import 'package:sec_pro_01/views/security_form_page.dart';

class NewDashboardPage extends StatefulWidget {
  const NewDashboardPage({super.key});

  @override
  _NewDashboardPageState createState() => _NewDashboardPageState();
}

class _NewDashboardPageState extends State<NewDashboardPage> {
  List securities = [];
  List filteredSecurities = [];
  bool isLoading = true;
  int? _sortColumnIndex;
  bool _isAscending = true;
  bool _showDetails = false;
  bool _includeInactive = false;

  String _isinSearch = '';
  String _nameSearch = '';
  String _typeSearch = '';

  // Dropdown variables for navigation
  String tradeValue = 'Auction';
  String manageCustomerValue = 'Create a Customer';
  String portfoliosValue = 'Create a Portfolio';
  String entitlementsValue = 'Settlement Diary';
  String securitiesValue = 'Create a Security';
  String reportingValue = 'Export Data to Excel';

  @override
  void initState() {
    super.initState();
    fetchSecurities();
  }

  Future<void> fetchSecurities() async {
    setState(() {
      isLoading = true;
    });
    try {
      final url = Uri.parse('http://127.0.0.1:5000/securities');
      final response = await http.get(url, headers: {
        'Authorization': 'PIN 252-755-032',
      });

      if (response.statusCode == 200) {
        setState(() {
          securities = json.decode(response.body);
          filteredSecurities = securities;
        });
      } else {
        throw Exception(
            'Failed to load securities. Status: ${response.statusCode}');
      }
    } catch (e) {
      showError('An error occurred: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterSecurities() {
    setState(() {
      filteredSecurities = securities.where((security) {
        final isinMatch = security['isin_code']
                ?.toLowerCase()
                .contains(_isinSearch.toLowerCase()) ??
            true;
        final nameMatch = security['sec_name']
                ?.toLowerCase()
                .contains(_nameSearch.toLowerCase()) ??
            true;
        final typeMatch = security['security_type']
                ?.toLowerCase()
                .contains(_typeSearch.toLowerCase()) ??
            true;

        if (_includeInactive) {
          final maturityDate = security['maturity_date'] ?? '';
          final parsedDate = DateTime.tryParse(maturityDate);
          if (parsedDate != null && parsedDate.isBefore(DateTime.now())) {
            return isinMatch && nameMatch && typeMatch;
          } else {
            return false;
          }
        }

        return isinMatch && nameMatch && typeMatch;
      }).toList();
    });
  }

  void _sort<T>(Comparable<T> Function(Map<String, dynamic> security) getField,
      int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;

      filteredSecurities.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);
        return ascending
            ? Comparable.compare(aValue, bValue)
            : Comparable.compare(bValue, aValue);
      });
    });
  }

  Future<void> deleteSecurity(int securityId) async {
    try {
      final url = Uri.parse('http://127.0.0.1:5000/securities/$securityId');
      final response = await http.delete(url, headers: {
        'Authorization': 'PIN 252-755-032',
      });

      if (response.statusCode == 200) {
        fetchSecurities();
        showSuccess('Security deleted successfully.');
      } else {
        showError('Failed to delete security. Status: ${response.statusCode}');
      }
    } catch (e) {
      showError('An error occurred: $e');
      print(e);
    }
  }

  Future<void> _showDeleteConfirmationDialog(
      int securityId, String isin, String secName) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
              'Are you sure you want to delete this security?\n\nISIN: $isin\nName: $secName',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('NO'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                deleteSecurity(securityId);
              },
              child: const Text('YES'),
            ),
          ],
        );
      },
    );
  }

  // Navigate to Create Security Page
  void navigateToCreatePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SecurityFormPage()),
    ).then((shouldRefresh) {
      if (shouldRefresh == true) {
        fetchSecurities();
      }
    });
  }

  void navigateToEditPage(Map<String, dynamic> security) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SecNavigateToEditPage(security: security)),
    ).then((shouldRefresh) {
      if (shouldRefresh == true) {
        fetchSecurities();
      }
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

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return 'N/A';

    try {
      DateTime parsedDate = DateTime.parse(date.trim());
      return '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year.toString()}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  DataCell getMaturityDateCell(String? maturityDate) {
    if (maturityDate == null || maturityDate.isEmpty) {
      return const DataCell(Text('N/A'));
    }

    try {
      DateTime parsedMaturityDate = DateTime.parse(maturityDate.trim());
      DateTime today = DateTime.now();
      Duration difference = parsedMaturityDate.difference(today);

      Color? bgColor;
      TextStyle textStyle = const TextStyle(color: Colors.black);

      if (difference.inDays <= 3) {
        bgColor = Colors.red;
        textStyle = const TextStyle(color: Colors.white);
      } else if (difference.inDays <= 7) {
        bgColor = Colors.orange;
        textStyle = const TextStyle(color: Colors.white);
      }

      return DataCell(
        Container(
          color: bgColor,
          padding: const EdgeInsets.all(7.0),
          child: Text(
            formatDate(maturityDate),
            style: textStyle,
          ),
        ),
      );
    } catch (e) {
      return const DataCell(Text('Invalid date'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.system,
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(backgroundColor: Colors.indigo),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
        ),
      ),
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(backgroundColor: Colors.indigo),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          toolbarHeight: 80,
          title: const Text("Securities Dashboard"),
          actions: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      _buildHorizontalDropdown("Trade", tradeValue, [
                        'Auction',
                        'Trade Own Book',
                        'Repo with FI',
                        'Buy from Customer',
                        'Sell from Customer',
                        'Repo with NON FI',
                        'Book building Admin',
                        'Approve Trade',
                        'Delete Trade',
                        'Create a BO Ticket'
                      ], (newValue) {
                        setState(() {
                          tradeValue = newValue!;
                        });
                      }),
                      const SizedBox(width: 5),
                      _buildHorizontalDropdown(
                          "Manage Customer", manageCustomerValue, [
                        'Create a Customer',
                        'Approve a Customer',
                        'Block a Customer',
                        'Deactivate a Customer',
                        'Report Customer Position',
                        'Manage Fees',
                        'Manage Taxes',
                        'Customer report MTD',
                        'Customer Report YTD',
                        'Customer Reporting Custom'
                      ], (newValue) {
                        setState(() {
                          manageCustomerValue = newValue!;
                        });
                      }),
                      const SizedBox(width: 5),
                      _buildHorizontalDropdown("Portfolios", portfoliosValue, [
                        'Create a Portfolio',
                        'Block Portfolio',
                        'Delete Portfolio',
                        'Transfer between portfolios'
                      ], (newValue) {
                        setState(() {
                          portfoliosValue = newValue!;
                        });
                      }),
                      const SizedBox(width: 5),
                      _buildHorizontalDropdown(
                          "Entitlements and CA", entitlementsValue, [
                        'Settlement Diary',
                        'Coupon Diary',
                        'Dividend',
                        'Bonus',
                        'Spinoff',
                        'Split',
                        'Merger',
                        'Acquisition',
                        'Warrant'
                      ], (newValue) {
                        setState(() {
                          entitlementsValue = newValue!;
                        });
                      }),
                      const SizedBox(width: 5),
                      _buildHorizontalDropdown("Securities", securitiesValue, [
                        'Create a Security',
                        'Create a new ISIN for Security',
                        'Block Security',
                        'Manage Exchanges and currencies',
                        'Manage Holidays and Cutoffs',
                        'Valuation Curves'
                      ], (newValue) {
                        setState(() {
                          securitiesValue = newValue!;
                        });
                      }),
                      const SizedBox(width: 5),
                      _buildHorizontalDropdown("Reporting", reportingValue, [
                        'Export Data to Excel',
                        'Reporting',
                        'Current Position',
                        'User Admin'
                      ], (newValue) {
                        setState(() {
                          reportingValue = newValue!;
                        });
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'ISIN Search',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              _isinSearch = value;
                              _filterSecurities();
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Name Search',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              _nameSearch = value;
                              _filterSecurities();
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Type Search',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              _typeSearch = value;
                              _filterSecurities();
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _includeInactive = !_includeInactive;
                              _filterSecurities();
                            });
                          },
                          child: Text(_includeInactive
                              ? 'Hide Inactive Securities'
                              : 'Include Inactive Securities'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 1.1,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columnSpacing: 7.0,
                            sortColumnIndex: _sortColumnIndex,
                            sortAscending: _isAscending,
                            columns: _getDataColumns(),
                            rows: _getDataRows(),
                            dataRowHeight: 30,
                            headingRowHeight: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  List<DataColumn> _getDataColumns() {
    return [
      _buildDataColumn('ISIN', (security) => security['isin_code']),
      _buildDataColumn('Name', (security) => security['sec_name']),
      const DataColumn(label: Text('Actions')),
      _buildDataColumn('Type', (security) => security['security_type']),
      _buildDataColumn('Subtype', (security) => security['security_subtype']),
      if (_showDetails)
        _buildDataColumn('Basis Code', (security) => security['basis_code']),
      if (_showDetails)
        _buildDataColumn('Ticker', (security) => security['ticker_symbol']),
      if (_showDetails)
        _buildDataColumn('Min Qty', (security) => security['min_qty']),
      _buildDataColumn('Price', (security) => security['price']),
      _buildDataColumn('Cp Rate', (security) => security['cp_rate']),
      _buildDataColumn('Iss Date', (security) => security['issue_date']),
      _buildDataColumn('Accrual', (security) => security['accrual_st_date']),
      DataColumn(
        label: const Text('Mat Date'),
        onSort: (columnIndex, ascending) => _sort<String>(
            (security) => security['maturity_date'], columnIndex, !ascending),
      ),
      _buildDataColumn('Country ID', (security) => security['country_id']),
      _buildDataColumn('Rating ID', (security) => security['rating_id']),
    ];
  }

  DataColumn _buildDataColumn(
      String label, Comparable Function(Map<String, dynamic>) getField) {
    return DataColumn(
      label: Text(label, style: const TextStyle(fontSize: 8)),
      onSort: (columnIndex, ascending) =>
          _sort(getField, columnIndex, ascending),
    );
  }

  List<DataRow> _getDataRows() {
    return filteredSecurities.map((security) {
      return DataRow(cells: [
        DataCell(Text(security['isin_code'] ?? 'N/A',
            style: const TextStyle(fontSize: 10),
            overflow: TextOverflow.ellipsis)),
        DataCell(Text(security['sec_name'] ?? 'N/A',
            style: const TextStyle(fontSize: 10),
            overflow: TextOverflow.ellipsis)),
        DataCell(Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 12),
              onPressed: () => navigateToEditPage(security),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 16),
              onPressed: () => _showDeleteConfirmationDialog(
                  security['security_id'],
                  security['isin_code'] ?? 'N/A',
                  security['sec_name'] ?? 'N/A'),
            ),
          ],
        )),
        DataCell(Text(security['security_type'] ?? 'N/A',
            style: const TextStyle(fontSize: 10),
            overflow: TextOverflow.ellipsis)),
        DataCell(Text(security['security_subtype'] ?? 'N/A',
            style: const TextStyle(fontSize: 10),
            overflow: TextOverflow.ellipsis)),
        if (_showDetails)
          DataCell(Text(security['basis_code'] ?? 'N/A',
              style: const TextStyle(fontSize: 10),
              overflow: TextOverflow.ellipsis)),
        if (_showDetails)
          DataCell(Text(security['ticker_symbol'] ?? 'N/A',
              style: const TextStyle(fontSize: 10),
              overflow: TextOverflow.ellipsis)),
        if (_showDetails)
          DataCell(Text(security['min_qty']?.toString() ?? 'N/A',
              style: const TextStyle(fontSize: 10),
              overflow: TextOverflow.ellipsis)),
        DataCell(Text(security['price']?.toString() ?? 'N/A',
            style: const TextStyle(fontSize: 10),
            overflow: TextOverflow.ellipsis)),
        DataCell(Text(security['cp_rate']?.toString() ?? 'N/A',
            style: const TextStyle(fontSize: 7),
            overflow: TextOverflow.ellipsis)),
        DataCell(Text(formatDate(security['issue_date']),
            style: const TextStyle(fontSize: 8),
            overflow: TextOverflow.ellipsis)),
        DataCell(Text(formatDate(security['accrual_st_date']),
            style: const TextStyle(fontSize: 8),
            overflow: TextOverflow.ellipsis)),
        getMaturityDateCell(security['maturity_date']),
        DataCell(Text(security['country_id']?.toString() ?? 'N/A',
            style: const TextStyle(fontSize: 8),
            overflow: TextOverflow.ellipsis)),
        DataCell(Text(security['rating_id']?.toString() ?? 'N/A',
            style: const TextStyle(fontSize: 8),
            overflow: TextOverflow.ellipsis)),
      ]);
    }).toList();
  }

  Widget _buildHorizontalDropdown(String label, String currentValue,
      List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        DropdownButton<String>(
          value: currentValue,
          dropdownColor: Colors.indigoAccent,
          style: const TextStyle(color: Colors.white),
          underline: const SizedBox(),
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}