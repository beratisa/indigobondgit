import 'package:postgres/postgres.dart';

void main() async {
  // Initialize the PostgreSQL connection
  var connection = PostgreSQLConnection(
    'localhost', // The host of your PostgreSQL server
    5432, // The port PostgreSQL is listening on
    'bond_port', // The name of the database you want to connect to
    username: 'postgres', // The PostgreSQL username
    password: '3107', // The PostgreSQL password
  );

  try {
    // Open the connection
    await connection.open();
    print(
        'Connected to PostgreSQL!'); // If connection is successful, print this
  } catch (e) {
    // If there is an error, print the error message
    print('Error: $e');
  } finally {
    // Close the connection after use
    await connection.close();
    print('Connection closed.');
  }
}
