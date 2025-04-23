"""
Script to check the consistency of localization keys between a reference ARB
file and other ARB files in a specified directory.
Reports missing or extra keys for each file compared to the reference.
"""

import json
import os


def check_arb_consistency(ref_file_path: str, l10n_directory: str) -> int:
    """
    Checks the consistency of localization keys between
    a reference ARB file and other ARB files
    in a specified directory.
    Reports missing or extra keys for each file compared to the reference.
    """
    print("Starting ARB consistency check...")
    print(f"Reference file: {ref_file_path}")
    print(f"Directory: {l10n_directory}")
    mismatch = False

    try:
        with open(ref_file_path, "r", encoding="utf-8") as ref_file:
            ref_keys = set(json.load(ref_file).keys())
        print(f"Found {len(ref_keys)} keys in reference file.")
    except (json.JSONDecodeError, OSError) as e:
        print(f"Error processing reference file {ref_file_path}: {e}")
        return 1

    for filename in os.listdir(l10n_directory):
        if not (
            filename.startswith("app_")
            and filename.endswith(".arb")
            and filename != os.path.basename(ref_file_path)
        ):
            continue
        file_path = os.path.join(l10n_directory, filename)
        print(f"Checking file: {filename}")
        try:
            with open(file_path, "r", encoding="utf-8") as arb_file:
                file_keys = set(json.load(arb_file).keys())
        except (json.JSONDecodeError, OSError) as e:
            print(f"Error processing {filename}: {e}")
            mismatch = True
            continue
        if ref_keys != file_keys:
            mismatch = True
            missing_keys = sorted(list(ref_keys - file_keys))
            extra_keys = sorted(list(file_keys - ref_keys))
            print(f"ERROR in {filename}:")
            if missing_keys:
                print(f"  Missing keys: {missing_keys}")
            if extra_keys:
                print(f"  Extra keys: {extra_keys}")
    if mismatch:
        print("Localization key consistency check failed.")
        return 1
    print("Localization key consistency check passed.")
    return 0


if __name__ == "__main__":
    # Get the directory of the script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    # Navigate to the repo root (assuming scripts/ is directly under AeraSync/)
    repo_root = os.path.dirname(script_dir)
    # Define paths relative to repo root
    reference_file = os.path.join(repo_root, "lib", "l10n", "app_en.arb")
    l10n_dir = os.path.join(repo_root, "lib", "l10n")
    exit(check_arb_consistency(reference_file, l10n_dir))
