"""Utility functions for the AeraSync backend."""
import json
from typing import Any, Dict


def load_json_data(file_path: str) -> Dict[str, Any]:
    """
    Load and validate JSON data from a file with consistent error handling.

    Args:
        file_path: Path to the JSON file.

    Returns:
        Parsed JSON data as a dictionary.

    Raises:
        FileNotFoundError: If the file does not exist.
        ValueError: If the JSON is invalid or malformed.
        RuntimeError: For unexpected errors.
    """
    print(f"Attempting to load data from: {file_path}")
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError as exc:
        print(f"Error: Data file not found at {file_path}")
        raise FileNotFoundError(f"Data file not found at {file_path}") from exc
    except json.JSONDecodeError as exc:
        print(f"Error: Invalid JSON format in data file: {file_path}")
        raise ValueError(
            f"Invalid JSON format in data file: {file_path}") from exc
    except Exception as exc:
        print(f"An unexpected error occurred during data loading: {exc}")
        raise RuntimeError(
            f"Unexpected error during data loading: {exc}") from exc
