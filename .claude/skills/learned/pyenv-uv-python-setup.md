# Pyenv + UV Python Environment Setup

## Problem Pattern
When using `uv pip install` with pyenv, you may encounter:
```
error: Python executable does not support `-I` flag. Please use Python 3.8 or newer.
```

This occurs when pyenv's global version is set to Python 2.x.

## Diagnosis Steps
1. Check pyenv versions: `pyenv versions`
2. Check current Python: `python --version`

## Solution
1. Set a Python 3.8+ version for the project:
   ```bash
   pyenv local 3.10.13  # or another 3.8+ version you have installed
   ```

2. Create virtual environment:
   ```bash
   uv venv
   ```

3. Activate and install:
   ```bash
   source .venv/bin/activate
   uv pip install -e .  # or other packages
   ```

## Notes
- `pyenv local` creates a `.python-version` file in the project directory
- `uv venv` automatically uses the Python version from pyenv
- The project needs `pyproject.toml` or `setup.py` for editable installs (`-e .`)
