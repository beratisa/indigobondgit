import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For using json.decode
import 'package:intl/intl.dart'; // For formatting dates

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _selectedOption = '';
  String _dataDisplay = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Securities Dashboard',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
        backgroundColor: Colors.indigo, // Indigo blue background
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child:
                _buildMenu(), // Calls _buildMenu, which now correctly returns a widget
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Enables horizontal scrolling
        child:
            _buildBody(), // Calls _buildBody, ensures it always returns a widget
      ),
    );
  }

  // Ensures _buildBody always returns a Widget
  Widget _buildBody() {
    return Container(
      color: Colors.indigo[50],
      child: Center(
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              _selectedOption.isNotEmpty
                  ? 'Selected Option: $_selectedOption\n\n${_formatDisplayData()}'
                  : 'Please select a menu option',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }

  // Ensure _buildMenu returns a PopupMenuButton as expected
  Widget _buildMenu() {
    return PopupMenuButton<String>(
      color: Colors.indigo[100],
      onSelected: (value) {
        setState(() {
          _selectedOption = value; // Updates _selectedOption on selection
        });
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'Create Security',
          enabled: false,
          child: Text(
            'Create Security',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
        ),
        const PopupMenuDivider(),
        _buildSubMenu(
          'Bonds',
          {
            'Bills': 'Bills',
            'Zero Coupon Bonds': 'Zero Coupon Bonds',
            'Bonds/Notes': 'Bonds/Notes',
            'TIPS': 'TIPS',
          },
        ),
        _buildSubMenu(
          'Stocks',
          {
            'Shares': 'Shares',
            'Preferred Shares': 'Preferred Shares',
          },
        ),
        _buildSubMenu(
          'Funds',
          {
            'ETFs': 'ETFs',
            'Active Funds': 'Active Funds',
            'Passive Funds': 'Passive Funds',
          },
        ),
      ],
      child: const Row(
        children: [
          Icon(Icons.menu, color: Colors.white),
          SizedBox(width: 5),
          Text("Menu", style: TextStyle(fontSize: 18, color: Colors.white)),
        ],
      ),
    );
  }

  // Correctly returns a PopupMenuItem with its submenu
  PopupMenuItem<String> _buildSubMenu(
      String title, Map<String, String> subOptions) {
    return PopupMenuItem<String>(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.arrow_right, color: Colors.indigo),
            onSelected: (value) async {
              await fetchData(
                  value); // Calls fetchData when submenu item is selected
              setState(() {
                _selectedOption = value;
              });
            },
            itemBuilder: (BuildContext context) => subOptions.entries
                .map((entry) => PopupMenuItem<String>(
                      value: entry.value,
                      child: Text(entry.key),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // Fetches data based on the selected option and updates the UI
  Future<void> fetchData(String bondType) async {
    var url = Uri.parse('http://your-api-url.com/bonds?type=$bondType');
    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          _dataDisplay = data.toString(); // Update the UI with fetched data
        });
      } else {
        setState(() {
          _dataDisplay = 'Failed to load data';
        });
      }
    } catch (e) {
      setState(() {
        _dataDisplay = 'Failed to connect to the API';
      });
    }
  }

  // Formats the fetched data to include dates for issue and maturity
  String _formatDisplayData() {
    try {
      var data = json.decode(_dataDisplay);

      // Assuming your data contains `issue_date` and `maturity_date`
      var issueDate = DateTime.parse(data['issue_date']);
      var maturityDate = DateTime.parse(data['maturity_date']);

      var formatter = DateFormat('yyyy-MM-dd');
      String formattedIssueDate = formatter.format(issueDate);
      String formattedMaturityDate = formatter.format(maturityDate);

      return '''
        Security Name: ${data['sec_name']}
        Issue Date: $formattedIssueDate
        Maturity Date: $formattedMaturityDate
        Other Data: ${data.toString()}
      ''';
    } catch (e) {
      return 'Failed to format data';
    }
  }
}
