Installation
============

This guide will help you set up AeraSync for development or usage.

Requirements
-----------

Backend Requirements:
* Python 3.10+
* pip

Frontend Requirements:
* Flutter 3.0+
* Dart SDK
* Node.js 16+

Backend Installation
-------------------

To install the backend dependencies:

.. code-block:: bash

   cd backend
   pip install -r requirements.txt

Frontend Installation
--------------------

To install the frontend dependencies:

.. code-block:: bash

   cd frontend
   flutter pub get

Running the Application
----------------------

Backend
~~~~~~~

Start the backend server:

.. code-block:: bash

   cd backend
   python -m api.main

Frontend
~~~~~~~

Start the frontend application:

.. code-block:: bash

   cd frontend
   flutter run -d chrome  # For web
   # Or
   flutter run  # For mobile emulator