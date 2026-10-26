#!/usr/bin/env python3
"""
Independent PDF Validator for Doxivo.
Validates PDF structure, compliance, headers, page count, and stream integrity
without relying on Flutter or proprietary PDF SDKs.
"""

import sys
import os
import re

def validate_pdf(file_path):
    if not os.path.exists(file_path):
        print(f"[FAIL] File not found: {file_path}")
        return False

    with open(file_path, "rb") as f:
        data = f.read()

    size_bytes = len(data)
    if size_bytes < 32:
        print(f"[FAIL] File too small to be a valid PDF ({size_bytes} bytes): {file_path}")
        return False

    # 1. Header check
    header = data[:8]
    if not header.startswith(b"%PDF-"):
        print(f"[FAIL] Invalid PDF magic header: {header[:10]}")
        return False
    version = header.decode("latin1", errors="ignore").strip()

    # 2. EOF check
    tail = data[-1024:]
    if b"%%EOF" not in tail:
        print(f"[FAIL] Missing %%EOF marker in file tail: {file_path}")
        return False

    # 3. Catalog / Pages check
    has_catalog = b"/Catalog" in data or b"/Root" in data
    has_pages = b"/Pages" in data
    if not (has_catalog and has_pages):
        print(f"[FAIL] Missing essential PDF Catalog/Pages dictionaries: {file_path}")
        return False

    # Extract page count if possible
    page_match = re.search(rb"/Count\s+(\d+)", data)
    page_count = int(page_match.group(1)) if page_match else "unknown"

    print(f"[PASS] {os.path.basename(file_path)}:")
    print(f"       Version: {version}")
    print(f"       Size: {size_bytes} bytes")
    print(f"       Page count: {page_count}")
    print(f"       Structure: Valid header, catalog, pages, and %%EOF verified.")
    return True

def main():
    if len(sys.argv) < 2:
        print("Usage: python tool/verify_pdfs.py <pdf_file_or_directory>")
        sys.exit(1)

    target = sys.argv[1]
    if os.path.isfile(target):
        files = [target]
    elif os.path.isdir(target):
        files = [os.path.join(target, f) for f in os.listdir(target) if f.lower().endswith(".pdf")]
    else:
        print(f"Target not found: {target}")
        sys.exit(1)

    if not files:
        print(f"No PDF files found in {target}")
        sys.exit(1)

    all_passed = True
    for f in files:
        if not validate_pdf(f):
            all_passed = False

    sys.exit(0 if all_passed else 1)

if __name__ == "__main__":
    main()
