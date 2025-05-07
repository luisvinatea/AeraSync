"""
Configuration file for the Sphinx documentation builder for AeraSync.

This module contains all the configuration settings for generating
the AeraSync documentation using Sphinx.
"""

# -- Path setup --------------------------------------------------------------
import os
import sys

sys.path.insert(0, os.path.abspath(".."))
sys.path.insert(0, os.path.abspath("../backend"))
sys.path.insert(0, os.path.abspath("../frontend/web"))

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

PROJECT = "AeraSync"
COPYRIGHT = "2025, Luis Vinatea"
AUTHOR = "Luis Vinatea"
RELEASE = "1.0.0"

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    "sphinx.ext.autodoc",
    "sphinx.ext.viewcode",
    "sphinx.ext.napoleon",
    "sphinx.ext.intersphinx",
    "sphinx_rtd_theme",
]

templates_path = ["_templates"]
exclude_patterns = ["_build", "Thumbs.db", ".DS_Store"]

# Napoleon settings
NAPOLEON_GOOGLE_DOCSTRING = True
NAPOLEON_INCLUDE_INIT_WITH_DOC = False
NAPOLEON_INCLUDE_PRIVATE_WITH_DOC = False
NAPOLEON_INCLUDE_SPECIAL_WITH_DOC = True
NAPOLEON_USE_ADMONITION_FOR_EXAMPLES = False
NAPOLEON_USE_ADMONITION_FOR_NOTES = False
NAPOLEON_USE_ADMONITION_FOR_REFERENCES = False
NAPOLEON_USE_IVAR = False
NAPOLEON_USE_PARAM = True
NAPOLEON_USE_RTYPE = True
NAPOLEON_PREPROCESS_TYPES = False
NAPOLEON_TYPE_ALIASES = None
NAPOLEON_ATTR_ANNOTATIONS = True

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

HTML_THEME = "sphinx_rtd_theme"
HTML_STATIC_PATH = ["_static"]
HTML_TITLE = "AeraSync Documentation"
HTML_PROJECT = "AeraSync"
HTML_LOGO = "icons/aerasync.webp"
HTML_FAVICON = "favicon.webp"

# -- Intersphinx configuration ----------------------------------------------
intersphinx_mapping = {
    "python": ("https://docs.python.org/3", None),
    "flask": ("https://flask.palletsprojects.com/en/2.0.x/", None),
}
