import 'package:flutter/foundation.dart'; // Required for ChangeNotifier
import '../calculators/saturation_calculator.dart';
import '../calculators/shrimp_respiration_calculator.dart';

/// Manages the application's state, including calculators, results, and loading status.
/// Uses ChangeNotifier to notify listeners (like UI widgets via Provider) about state changes.
class AppState with ChangeNotifier {
  // Private instances of the calculators
  SaturationCalculator? _calculator;
  ShrimpRespirationCalculator? _respirationCalculator;

  // Private state variables
  String? _error; // Holds the latest error message, null if no error
  bool _isLoading = false; // Tracks if data is loading or calculation is running

  // Stores calculation results, keyed by calculator type (e.g., 'Aerator Performance')
  final Map<String, Map<String, dynamic>> _results = {};
  // Stores input values used for calculations, keyed by calculator type
  final Map<String, Map<String, dynamic>> _inputs = {};

  /// Constructor: Initializes the calculator instances.
  AppState() {
    // Initialize calculators with specific implementations and data paths.
    // Consider making paths configurable if needed.
    _calculator = ShrimpPondCalculator('assets/data/o2_temp_sal_100_sat.json');
    _respirationCalculator = ShrimpRespirationCalculator('assets/data/shrimp_respiration_salinity_temperature_weight.json');
    // Note: Data loading happens in the initialize() method.
  }

  /// Asynchronously initializes the calculators by loading their required data.
  /// Should be called once when the app starts (e.g., in main.dart).
  Future<void> initialize() async {
    if (_calculator == null || _respirationCalculator == null) {
       setError('Calculators not instantiated.');
       return;
    }
    setLoading(true); // Indicate loading started
    clearError(); // Clear any previous errors
    try {
      // Load data for both calculators concurrently
      await Future.wait([
        _calculator!.loadData(), // Use ! assuming constructor initialized them
        _respirationCalculator!.loadData(), // Use ! assuming constructor initialized them
      ]);
      print("AppState initialized successfully."); // Log success
    } catch (e) {
      // Set an error state if loading fails
      print("Error during AppState initialization: $e"); // Log the error
      setError('Failed to load initial calculator data: ${e.toString()}');
    } finally {
      // Always ensure loading state is turned off
      setLoading(false);
    }
  }

  // --- Public Getters ---
  SaturationCalculator? get calculator => _calculator;
  ShrimpRespirationCalculator? get respirationCalculator => _respirationCalculator;
  String? get error => _error;
  bool get isLoading => _isLoading;

  /// Retrieves the results for a specific calculator type/tab.
  Map<String, dynamic>? getResults(String calculatorType) => _results[calculatorType];

  /// Retrieves the inputs used for a specific calculator type/tab.
  Map<String, dynamic>? getInputs(String calculatorType) => _inputs[calculatorType];

  // --- State Modification Methods ---

  /// Sets an error message and updates loading state. Notifies listeners.
  void setError(String error) {
    _error = error;
    _isLoading = false; // Typically, an error stops loading
    notifyListeners(); // Notify UI of the error
  }

  /// Clears the current error message. Notifies listeners.
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners(); // Notify UI that error is cleared
    }
  }

  /// Sets the loading state. Notifies listeners.
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      if (_isLoading) {
         _error = null; // Clear error when starting to load/calculate
      }
      notifyListeners(); // Notify UI of loading state change
    }
  }

  /// Stores the results and inputs for a specific calculation.
  /// Clears any existing error and sets loading to false. Notifies listeners.
  void setResults(String calculatorType, Map<String, dynamic> results, Map<String, dynamic> inputs) {
    // Consider making deep copies if maps might be mutated elsewhere
    _results[calculatorType] = Map<String, dynamic>.from(results);
    _inputs[calculatorType] = Map<String, dynamic>.from(inputs);
    _error = null; // Clear error on successful result
    _isLoading = false; // Calculation/loading finished
    notifyListeners(); // Notify UI of new results
  }

  /// Cleans up resources when AppState is no longer needed.
  @override
  void dispose() {
    print("AppState disposing."); // Log disposal
    // Nullify references to allow garbage collection
    _calculator = null;
    _respirationCalculator = null;
    // Clear stored data
    _results.clear();
    _inputs.clear();
    // Call super.dispose() for ChangeNotifier cleanup
    super.dispose();
  }
}
