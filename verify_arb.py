import json
import os

def check_arb_consistency(ref_file_path, localization_dir, ref_file_name):
    """
    Checks the consistency of localization keys between a reference ARB file and other ARB files
    in a specified directory. Reports missing or extra keys for each file compared to the reference.
    """
    mismatch = False

    try:
        print(f"Checking reference file: {ref_file_path}")
        with open(ref_file_path, 'r', encoding='utf-8') as ref_file:
            ref_keys = set(json.load(ref_file).keys())
        print(f"Found {len(ref_keys)} keys in reference file.")

        for filename in os.listdir(localization_dir):
            if filename.startswith('app_') and filename.endswith('.arb') and filename != os.path.basename(ref_file_name):
                file_path = os.path.join(localization_dir, filename)
                print(f"Checking file: {filename}")
                try:
                    with open(file_path, 'r', encoding='utf-8') as arb_file:
                        file_keys = set(json.load(arb_file).keys())
                    if ref_keys != file_keys:
                        mismatch = True
                        missing_keys = sorted(list(ref_keys - file_keys))
                        extra_keys = sorted(list(file_keys - ref_keys))
                        print(f"ERROR in {filename}:")
                        if missing_keys:
                            print(f"  Missing keys: {missing_keys}")
                        if extra_keys:
                            print(f"  Extra keys: {extra_keys}")
                except (json.JSONDecodeError, OSError) as e:
                    print(f"Error processing {filename}: {e}")
                    mismatch = True
        if mismatch:
            print("Localization key consistency check failed.")
            return 1
        else:
            print("Localization key consistency check passed.")
            return 0
    except (json.JSONDecodeError, OSError) as e:
        print(f"Error processing reference file {ref_file_path}: {e}")
        return 1

if __name__ == "__main__":
    reference_file = "/home/luisvinatea/Dev/Repos/AeraSync/AeraSync/lib/l10n/app_en.arb"
    l10n_dir = "/home/luisvinatea/Dev/Repos/AeraSync/AeraSync/lib/l10n"
    exit(check_arb_consistency(reference_file, l10n_dir, reference_file))
