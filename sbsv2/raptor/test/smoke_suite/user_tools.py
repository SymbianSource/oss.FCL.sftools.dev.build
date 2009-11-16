import os
import sys
from raptor_tests import SmokeTest

def run():
	
	t = SmokeTest()
	t.id = "86"
	t.name = "user_tools"
	
	if sys.platform.lower().startswith("win"):
		result = SmokeTest.PASS
		t.logfileOption = lambda :""
		t.makefileOption = lambda :""
		t.description = "Tests that Raptor picks up SBS_PYTHON, SBS_CYGWIN " \
				+ "and SBS_MINGW from the environment when present"
		
		
		t.id = "0086a"
		t.name = "user_python"
		t.environ['SBS_PYTHON'] = "C:/pyt*hon"
		
		t.command = "sbs -b smoke_suite/test_resources/simple/bld.inf -c armv5_urel" \
					+ " -n --toolcheck off -f " + t.logfile() + " -m " + t.makefile()
				
		t.mustmatch = [
				"'C:/pyt\*hon' is not recognized as an internal or external command,",
				"operable program or batch file."
				]
		t.returncode = 9009
		t.run()
		if t.result == SmokeTest.FAIL:
			result = SmokeTest.FAIL
	
	
		t.id = "0086b"
		t.name = "user_cygwin"
		t.environ = {}
		t.environ['SBS_CYGWIN'] = "C:/cygwin"
		
		t.command = "sbs -b smoke_suite/test_resources/simple/bld.inf -c armv5_urel" \
				+ " -n --toolcheck off -f " + t.logfile() + " -m " + t.makefile() \
				+ " && $(__CYGWIN__)/bin/grep.exe -ir 'TALON_SHELL:=C:/cygwin/bin/sh.exe' " + t.makefile() + ".default"
				
		t.mustmatch = [
				"TALON_SHELL:=C:/cygwin/bin/sh.exe"
				]
		t.returncode = 0
		t.run()
		if t.result == SmokeTest.FAIL:
			result = SmokeTest.FAIL
		
		
		t.id = "0086c"
		t.name = "user_mingw"
		t.environ = {}
		t.environ['SBS_MINGW'] = "C:/mingw"
		
		t.command = "sbs -b smoke_suite/test_resources/simple/bld.inf -c armv5_urel" \
				+ " -n --toolcheck off -f " + t.logfile() + " -m " + t.makefile()
				
		t.mustmatch = [
				"sbs: error: Preprocessor exception: \[Error 3\] The system cannot find the path specified"
				]
		
		t.errors = 1
		t.returncode = 1
		
		t.run()
		if t.result == SmokeTest.FAIL:
			result = SmokeTest.FAIL
		
		t.id = "86"
		t.name = "user_tools"
		t.result = result
		t.print_result()
		
	else:
		t.run("windows")
		
		
	return t
