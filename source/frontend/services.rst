Frontend Services
================

This page documents the service layer in the AeraSync Flutter application.

API Service
----------

The API service manages communication between the frontend and backend:

- Makes HTTP requests to backend endpoints
- Serializes/deserializes JSON data
- Handles error conditions and timeouts
- Implements retry logic for network failures

Example:

.. code-block:: dart

   class ApiService {
     final String baseUrl;
     final http.Client client;
     
     ApiService(this.baseUrl, {http.Client? client})
         : this.client = client ?? http.Client();
     
     Future<ComparisonResult> compareAerators(ComparisonRequest request) async {
       final response = await client.post(
         Uri.parse('$baseUrl/compare'),
         headers: {'Content-Type': 'application/json'},
         body: jsonEncode(request.toJson()),
       );
       
       if (response.statusCode == 200) {
         return ComparisonResult.fromJson(jsonDecode(response.body));
       } else {
         throw ApiException('Failed to compare aerators: ${response.body}');
       }
     }
   }

State Management
--------------

The application state is managed through a dedicated service:

- Stores form data during user input
- Caches comparison results
- Provides reactivity through streams/notifiers
- Persists state between sessions