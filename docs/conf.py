# Configuration file for the Sphinx documentation builder.
import os
import sys
sys.path.insert(0, os.path.abspath('../backend'))

# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- PROJECT information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#PROJECT-information

PROJECT = 'AeraSync'
COPYRIGHT = '2025, Luis Vinatea'
AUTHOR = 'Luis Vinatea'
RELEASE = '2025'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

EXTENSIONS = []

TEMPLATES_PATH = ['_templates']
EXCLUDE_PATTERNS = ['_build', 'Thumbs.db', '.DS_Store']

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

HTML_THEME = 'alabaster'
HTML_STATIC_PATH = ['_static']
