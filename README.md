# AeraSync

AeraSync is a mobile and web application designed to streamline the calculation and tracking of the Standard Oxygen Transfer Rate (SOTR) and Standard Aeration Efficiency (SAE) for aerators in aquaculture ponds. The app provides a seamless interface for technicians to perform daily checkpointing, ensuring accurate and efficient monitoring of aeration performance. Future versions will incorporate AI-driven predictions to optimize aeration efficiency.

AeraSync is built using Dart and Flutter for the frontend, with a Python backend API, enabling cross-platform support for mobile (Android, iOS) and web. The web application is deployed at [https://aerasync-web.vercel.app](https://aerasync-web.vercel.app) and the documentation is hosted at [https://luisvinatea.github.io/AeraSync/](https://luisvinatea.github.io/AeraSync/).

## Features

- **SOTR & SAE Calculation** – Compute key aerator efficiency metrics effortlessly using a built-in calculator.
- **Aerator Comparison** – Compare two aerators based on SOTR, cost, and maintenance to determine the most cost-effective option.
- **Oxygen Demand and Estimation** – Calculate oxygen demand and estimate the number of aerators needed, with both farm-based and experimental methods.
- **Cross-Platform Support** – Available on Android, iOS, and web, with a consistent user experience.
- **User-Friendly Interface** – Designed for field technicians with a simple and intuitive UI.
- **Localization** – Supports multiple languages (English, Spanish, Portuguese, French, Italian, German, Norwegian, Russian, Chinese, Japanese, Thai, Indonesian, Arabic, Hebrew, Swedish) for broader accessibility.
- **Data Integration** – Includes preloaded datasets for accurate calculations.
- **Interactive Charts** – Visualize key metrics using interactive charts.
- **Python Backend API** – Reliable serverless API deployed on Vercel for processing complex calculations.
- **Predictive Analytics (Upcoming)** – AI-driven insights for aeration optimization (planned for future releases).

## Installation

AeraSync is a Flutter project with separate frontend and backend components. Follow these steps to set up and run the application locally:

1. **Clone the Repository**:

   ```sh
   git clone https://github.com/luisvinatea/AeraSync.git
   ```

2. **Navigate to the Project Directory**:

   ```sh
   cd AeraSync
   ```

### Frontend Setup

1. **Navigate to the Frontend Directory**:

   ```sh
   cd frontend
   ```

2. **Install Flutter Dependencies**:

   Ensure you have Flutter installed (see [Flutter installation guide](https://flutter.dev/docs/get-started/install)). Then, install the project dependencies:

   ```sh
   flutter pub get
   ```

3. **Run the Frontend Application**:

   - Using the Makefile:

     ```sh
     make run-flutter
     ```

   - Or directly:

     ```sh
     flutter run -d chrome
     ```

   - For mobile (Android/iOS emulator or device):

     ```sh
     flutter run
     ```

### Backend Setup

1. **Navigate to the Backend Directory**:

   ```sh
   cd ../backend
   ```

2. **Set Up Python Environment**:

   ```sh
   pip install -r requirements.txt
   ```

3. **Run the Backend API Locally** (optional):

   ```sh
   python -m api.main
   ```

## Development Tasks

### Frontend Development

- **Generate Localization Files**:

  After updating the `.arb` files in `frontend/lib/l10n/`, regenerate the localization classes:

  ```sh
  cd frontend
  make gen-l10n
  ```

  Or:

  ```sh
  flutter gen-l10n
  ```

- **Run Tests**:

  Run the unit and widget tests:

  ```sh
  cd frontend
  make test
  ```

  Or:

  ```sh
  flutter test
  ```

- **Build for Web**:

  Create a release build for web deployment:

  ```sh
  cd frontend
  make build-web
  ```

  Or:

  ```sh
  flutter build web --release
  ```

### Backend Development

- **Run Backend Tests**:

  ```sh
  cd backend
  python -m pytest
  ```

## Deployment

### Documentation Deployment

The project documentation is hosted on GitHub Pages. To update the documentation:

- Using the build script:

  ```sh
  cd source
  make html
  ```

The documentation is available at [https://luisvinatea.github.io/AeraSync/](https://luisvinatea.github.io/AeraSync/).

### Web Application Deployment

The web application is deployed on Vercel. The live version is available at [https://aerasync-web.vercel.app](https://aerasync-web.vercel.app).

### Backend API Deployment

The Python backend API is deployed as a serverless function on Vercel.

## Tech Stack

- **Frontend & Cross-Platform**: Dart / Flutter
- **Backend**: Python FastAPI for the REST API
- **Data Storage**: Local JSON files (e.g., `o2_temp_sal_100_sat.json`); future plans for cloud storage (Firestore/PostgreSQL)
- **Web Hosting**: Vercel (frontend application), GitHub Pages (documentation)
- **AI Engine (Future)**: TensorFlow.js or PyTorch for predictive analytics

## Project Structure

```text
AeraSync/
├── frontend/              # Flutter application
│   ├── lib/               # Flutter source code
│   │   ├── core/          # Business logic (calculators, models, services)
│   │   ├── l10n/          # Localization files (*.arb)
│   │   ├── presentation/  # UI components (screens, widgets)
│   │   └── main.dart      # App entry point
│   ├── web/               # Web-specific files
│   ├── test/              # Unit and widget tests
│   └── build/             # Built application
├── backend/               # Python FastAPI backend
│   ├── api/               # API definition and routes
│   │   ├── core/          # Core business logic
│   │   └── routes/        # API endpoints
│   └── test/              # Backend tests
├── docs/                  # Documentation files
├── source/                # Documentation source files
├── LICENSE
└── README.md
```

## Contribution

Contributions are welcome! Feel free to submit issues and pull requests. To contribute:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/your-feature`).
3. Make your changes and commit (`git commit -m "Add your feature"`).
4. Push to your branch (`git push origin feature/your-feature`).
5. Open a pull request.

## License

This project is licensed under the MIT License.

---

Made with ❤️ for the aquaculture industry.
