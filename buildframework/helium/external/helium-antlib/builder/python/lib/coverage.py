#!/usr/bin/env python
"A script for invoking coverage from the command line."

import sys
del sys.path[0] # Otherwise "import coverage" finds this file!
import coverage

coverage.the_coverage.command_line(sys.argv[1:])
