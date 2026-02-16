# Pin Python to 3.12 until future library supports 3.13
# The future-1.0.0 library doesn't support Python 3.13 yet, causing many Python packages to fail
# This overlay ensures all Python packages use Python 3.12 instead
final: prev: {
  # Pin python3 to python312
  python3 = prev.python312;
  python3Packages = prev.python312Packages;
}
