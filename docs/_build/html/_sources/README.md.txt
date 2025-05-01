# AeraSync Documentation

This directory contains the documentation for the AeraSync project, built using [Sphinx](https://www.sphinx-doc.org/).

## Building the Documentation

### Prerequisites

Make sure you have the required packages installed:

```bash
pip install sphinx sphinx-rtd-theme recommonmark
```

### Build Instructions

To build the HTML documentation:

```bash
cd docs
sphinx-build -b html . _build/html
```

Or use the Makefile:

```bash
cd docs
make html
```

### View the Documentation

After building, you can open the documentation in your web browser:

```bash
xdg-open _build/html/index.html  # Linux
open _build/html/index.html      # macOS
start _build/html/index.html     # Windows
```

## Documentation Structure

- `conf.py`: Sphinx configuration file
- `index.rst`: Main documentation index
- `api/`: API documentation
- `frontend/`: Frontend documentation

## Updating the Documentation

When updating the documentation:

1. Edit the relevant `.rst` files
2. Rebuild the documentation using the commands above
3. Verify the changes by viewing the HTML output

For more information on writing reStructuredText, see the [Sphinx documentation](https://www.sphinx-doc.org/en/master/usage/restructuredtext/basics.html).