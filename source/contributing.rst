Contributing
============

This guide explains how to contribute to AeraSync.

Setup Development Environment
---------------------------

1. Clone the repository:

   .. code-block:: bash

      git clone https://github.com/luisvinatea/aerasync.git
      cd aerasync

2. Install backend dependencies:

   .. code-block:: bash

      cd backend
      pip install -r requirements.txt

3. Install frontend dependencies:

   .. code-block:: bash

      cd frontend
      flutter pub get

Development Workflow
------------------

1. Create a feature branch:

   .. code-block:: bash

      git checkout -b feature/your-feature-name

2. Make your changes
3. Run tests:

   .. code-block:: bash

      # Backend tests
      cd backend
      python -m pytest

      # Frontend tests
      cd frontend
      flutter test

4. Submit a pull request

Code Style
---------

- Backend: Follow PEP 8 Python style guide
- Frontend: Follow Dart and Flutter style guidelines

Documentation
------------

Update documentation when changing functionality:

1. Update code docstrings
2. Modify RST files under /source directory
3. Rebuild documentation:

   .. code-block:: bash

      make html