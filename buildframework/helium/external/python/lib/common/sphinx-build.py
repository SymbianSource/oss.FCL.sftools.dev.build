#!python.exe
# EASY-INSTALL-ENTRY-SCRIPT: 'Sphinx==0.5.1','console_scripts','sphinx-build'
__requires__ = 'Sphinx==0.5.1'
import sys
from pkg_resources import load_entry_point

sys.exit(
   load_entry_point('Sphinx==0.5.1', 'console_scripts', 'sphinx-build')()
)
