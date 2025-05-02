=====
Usage
=====

Using AeraSync
------------

This section describes how to use the AeraSync tool effectively.

Backend API Usage
^^^^^^^^^^^^^^^

The backend API provides several endpoints for data synchronization and comparison:

.. code-block:: python

   # Example Python code for using the AeraSync API
   import requests

   # Compare two aerators
   response = requests.post('https://your-deployment.com/api/aerator_comparer', 
                           json={'aerator1': 'data1', 'aerator2': 'data2'})
   result = response.json()

Frontend Application Usage
^^^^^^^^^^^^^^^^^^^^^^^^

The frontend application provides an intuitive interface for:

1. Uploading aerator data
2. Comparing different aerators
3. Visualizing the results
4. Exporting reports

To get started with the frontend application:

1. Navigate to the application URL
2. Use the "Upload" button to add your aerator data
3. Select two aerators to compare
4. View the detailed comparison results