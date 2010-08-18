#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of the License "Eclipse Public License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
#
# Contributors:
#
# Description: 
#
# Runs the specified suite of raptor tests

import os
import sys
import re
import imp
import datetime
import traceback
raptor_tests = imp.load_source("raptor_tests", "common/raptor_tests.py")

# Command line options ########################################################
from optparse import OptionParser

parser = OptionParser(
		prog = "run",
		usage = "%prog [Options]")

parser.add_option("-u", "--upload", action = "store", type = "string",
		dest = "upload", default = None,
		help = "Path for uploading results (Can be UNC path)")
parser.add_option("-b", "--branch", action = "store", type = "choice",
		dest = "branch", choices = ["master", "m", "fix", "f", "wip", "w"],
		help = "string indicating which branch is being tested:\n" + \
		"master, fix or wip. Default is 'fix'")
parser.add_option("-s", "--suite", action = "store", type = "string",
		dest = "suite", help = "regex to use for selecting test suites")
parser.add_option("-t", "--tests", action = "store", type = "string",
		dest = "tests", help = "regex to use for selecting tests")
parser.add_option("-d", "--debug", action = "store_true", dest = "debug_mode",
		default = False, help = "Turns on debug-mode")
parser.add_option("--test-home", action = "store", type = "string",
		dest = "test_home", default="default",
		help = "Location of custom .sbs_init.xml (name of directory in " +
		"'custom_options'): test/custom_options/<test_home>/.sbs_init.xml")
parser.add_option("--what-failed", action = "store_true", dest = "what_failed",
		help = "Re-run all the tests that failed in the previous test run")
parser.add_option("--clean", action = "store_true", dest = "clean",
		help = "Clean EPOCROOT after each test is run")


(options, args) = parser.parse_args()

# Check for --what-failed and override '-s' and '-t' (including flagless regex)
if options.what_failed:
	try:
		what_failed_file = open("what_failed", "r")
		what_failed = what_failed_file.readline()
		what_failed_file.close()
		print "Running: run " + what_failed
		
		first = what_failed.find('"')
		second = what_failed.find('"', (first + 1))
		options.suite = what_failed[(first + 1):second]
		
		first = what_failed.find('"', (second + 1))
		second = what_failed.find('"', (first + 1))
		options.tests = what_failed[(first + 1):second]
	except:
		# If no file exists, nothing failed, so run as usual
		pass

# Allow flagless test regex
if (options.tests == None) and (len(args) > 0):
	options.tests = args[len(args) - 1]
	
if options.upload != None:
	if options.branch != None:
		if options.branch == "m":
			branch = "master"
		elif options.branch == "f":
			branch = "fix"
		elif options.branch == "w":
			branch = "wip"
		else:
			branch = options.branch
	else:
		print "Warning: Test branch not set - Use " + \
				"'-b [master|fix|wip]'\n Using default of 'Fix'..."
		branch = "fix"

if options.debug_mode:
	raptor_tests.activate_debug()


# Set $HOME environment variable for finding a custom .sbs_init.xml 
if options.test_home != None:
	home_dir = options.test_home
	if home_dir in os.listdir("./custom_options"):
		os.environ["HOME"] = os.environ["SBS_HOME"] + "/test/custom_options/" \
				+ home_dir + "/"
	else:
		print "Warning: Path to custom .sbs_init.xml file not found (" + \
				home_dir + ")\nUsing defaults..."
		options.test_home = None


def format_milliseconds(microseconds):
	""" format a microsecond time in milliseconds """
	milliseconds = (microseconds / 1000)
	if milliseconds == 0:
		return "000"
	elif milliseconds < 10:
		return "00" + str(milliseconds)
	elif milliseconds < 100:
		return "0" + str(milliseconds)
	return milliseconds



class TestRun(object):
	"""Represents any series of tests"""
	def __init__(self):
		self.test_set = []
		self.failed_tests = []
		self.error_tests = []
		self.pass_total = 0
		self.fail_total = 0
		self.skip_total = 0
		self.exception_total = 0
		self.test_total = 0
		# For --what-failed:
		self.suites_failed = []
		self.tests_failed = []

	def aggregate(self, atestrun):
		""" Aggregate other test results into this one """
		self.test_set.append(atestrun)
		self.test_total += len(atestrun.test_set)

	def show(self):
		for test_set in self.test_set:
			print "\n\n" + str(test_set.suite_dir) + ":\n"
			
			# If a suite has failed/erroneous tests, add it to what_failed
			if (test_set.fail_total + test_set.exception_total) > 0:
				self.suites_failed.append(test_set.suite_dir)
				
			if len(test_set.test_set) < 1:
				print "No tests run"
			else:
				print "PASSED: " + str(test_set.pass_total)
				print "FAILED: " + str(test_set.fail_total)
				if test_set.skip_total > 0:
					print "SKIPPED: " + str(test_set.skip_total)
				if test_set.exception_total > 0:
					print "EXCEPTIONS: " + str(test_set.exception_total)
		
				if test_set.fail_total > 0:
					print "\nFAILED TESTS:"
					
					# Add each failed test to what_failed and print it
					for test in test_set.failed_tests:
						self.tests_failed.append("^" + test + ".py")
						print "\t", test
		
				if test_set.exception_total > 0:
					print "\nERRONEOUS TESTS:"
					
					# Add each erroneous test to what_failed and print it
					for test in test_set.error_tests:
						first = test.find("'")
						second = test.find("'", (first + 1))
						self.tests_failed.append("^" +
								test[(first + 1):second] + ".py")
						print "\t", test
						
	def what_failed(self):
		"Create the file for --what-failed if there were failing tests"
		if len(self.suites_failed) > 0:
			self.what_failed = open("what_failed", "w")
			# Add the suites and tests to the file as command-line options
			self.what_failed.write('-s "')
			loop_number = 0
			for suite in self.suites_failed:
				loop_number += 1
				self.what_failed.write(suite)
				
				# If this is not the last suite, prepare to add another
				if loop_number < len(self.suites_failed):
					self.what_failed.write("|")
					
			self.what_failed.write('" -t "')
			loop_number = 0
			for test in self.tests_failed:
				loop_number += 1
				self.what_failed.write(test)
				
				# If this is not the last test, prepare to add another
				if loop_number < len(self.tests_failed):
					self.what_failed.write("|")
			self.what_failed.write('"')
			self.what_failed.close()
			
		else:
			# If there were no failing tests this time, remove any previous file
			try:
				os.remove("what_failed")
			except:
				try:
					os.chmod("what_failed", stat.S_IRWXU)
					os.remove("what_failed")
				except:
					pass
					

class Suite(TestRun):
	"""A test suite"""

	python_file_regex = re.compile("(.*)\.py$", re.I)

	def __init__(self, dir, parent):
		TestRun.__init__(self)
		self.suite_dir = dir

		# Upload directory (if set)
		self.upload_location = parent.upload_location

		# Regex for searching for tests

		self.test_file_regex = parent.test_file_regex
		self.test_pattern = parent.testpattern
		

	def run(self):
		"""run the suite"""

		self.time_stamp = datetime.datetime.now()
		self.results = {}
		self.start_times = {}
		self.end_times = {}
		
		print "\n\nRunning " + str(self.suite_dir) + "..."

		# Iterate through all files in specified directory
		for test in os.listdir(self.suite_dir):
			# Only check '*.py' files
			name_match = self.python_file_regex.match(test)
			if name_match is not None:
				if self.test_file_regex is not None:
					# Each file that matches -t input is imported if any
					name_match = self.test_file_regex.match(test)
				else:
					name_match = 1
				if name_match is not None:
					import_name = test[:-3]
					try:
						self.test_set.append(imp.load_source(import_name,
								(raptor_tests.ReplaceEnvs(self.suite_dir
								+ "/" + test))))
					except:
						print "\n", (sys.exc_type.__name__ + ":"), \
								sys.exc_value, "\n", \
								traceback.print_tb(sys.exc_traceback)
	
		test_number = 0
		test_total = len(self.test_set)
		if test_total < 1:
			print "No tests in suite "+self.suite_dir+" matched by specification '"+self.test_pattern+"' (regex: /.*"+self.test_pattern+".*/)\n";
		# Run each test, capturing all its details and its results
		for test in self.test_set:
			test_number += 1
			# Save start/end times and save in dictionary for TMS
			start_time = datetime.datetime.now()
			try:
				test_number_text = "\n\nTEST " + str(test_number) + "/" + \
						str(test_total) + ":"
				
				if self.fail_total > 0:
					test_number_text += "    So far " + str(self.fail_total) + \
							" FAILED"
				if self.exception_total > 0:
					test_number_text += "    So far " + str(self.exception_total) + \
							" ERRONEOUS"
				
				print test_number_text
				
				test_object = test.run()
				
				end_time = datetime.datetime.now()
				
				# Add leading 0s
				test_object.id = raptor_tests.fix_id(test_object.id)

				# No millisecond function, so need to use microseconds/1000
				start_milliseconds = start_time.microsecond
				end_milliseconds = end_time.microsecond
		
				# Add trailing 0's if required
				start_milliseconds = \
						format_milliseconds(start_milliseconds)
				end_milliseconds = \
						format_milliseconds(end_milliseconds)
		
				self.start_times[test_object.id] = \
						start_time.strftime("%H:%M:%S:" +
						str(start_milliseconds))
				self.end_times[test_object.id] = \
						end_time.strftime("%H:%M:%S:" + \
						str(end_milliseconds))
				
				run_time = (end_time - start_time)
				
				run_time_seconds = (str(run_time.seconds) + "." + \
						str(format_milliseconds(run_time.microseconds)))
				print ("RunTime: " + run_time_seconds + "s")
				# Add to pass/fail count and save result to dictionary
				if test_object.result == raptor_tests.SmokeTest.PASS:
					self.pass_total += 1
					self.results[test_object.id] = "Passed"
				elif test_object.result == raptor_tests.SmokeTest.FAIL:
					self.fail_total += 1
					self.results[test_object.id] = "Failed"
					self.failed_tests.append(test_object.name)
				elif test_object.result == raptor_tests.SmokeTest.SKIP:
					self.skip_total += 1
				# Clean epocroot after running each test if --clean option is specified
				if options.clean:
					print "\nCLEANING TEST RESULTS..."
					raptor_tests.clean_epocroot()
					
			except:
				print "\nTEST ERROR:"
				print (sys.exc_type.__name__ + ":"), \
						sys.exc_value, "\n", \
						traceback.print_tb(sys.exc_traceback)
				self.exception_total += 1
				self.error_tests.append(str(self.test_set[test_number - 1]))
								
				
		if self.upload_location != None:
			self.create_csv()

		end_time_stamp = datetime.datetime.now()
			
		runtime = end_time_stamp - self.time_stamp
		seconds = (str(runtime.seconds) + "." + \
				str(format_milliseconds(runtime.microseconds)))
		if options.upload:
			self.create_tri(seconds)

		print ("\n" + str(self.suite_dir) + " RunTime: " + seconds + "s")

	def create_csv(self):
		"""
		This method will create a CSV file with the smoke test's output
				in order to successfully upload results to TMS QC
		"""
		
		# This sorts the dictionaries by their key values (Test IDs)
		id_list = run_tests.sort_dict(self.results)
		
		self.test_file_name = (self.suite_dir + "_" + \
				self.time_stamp.strftime("%Y-%m-%d_%H-%M-%S") + "_" +
				branch + "_results.csv")
		# This is the path for file-creation on the server. Includes
		self.test_path = (self.upload_location + "/csv/" + self.suite_dir + "/"
				+ self.test_file_name)
		
		try:
		
			if not os.path.isdir(self.upload_location + "/csv/" +
					self.suite_dir):
				os.makedirs(self.upload_location + "/csv/" + self.suite_dir)

			csv_file = \
					open(raptor_tests.ReplaceEnvs(os.path.normpath(self.test_path)),
					"w")
			csv_file.write("TestCaseID,StartTime,EndTime,Result\n")
			
			for test_id in id_list:
				csv_file.write("PCT-SBSV2-" + self.suite_dir + "-" + test_id + \
						"," + str(self.start_times[test_id]) + "," + \
						str(self.end_times[test_id]) + "," + \
						self.results[test_id] + "\n")
			csv_file.close()
			
		except OSError, e:
			print "SBS_TESTS: Error:", e
			
			
	def create_tri(self, overall_seconds):
		"""
		This method will create a TRI (xml) file containing the location of the
				CSV file in order to successfully upload results to TMS QC
		"""
		# Path for the tri file
		tri_path = (self.upload_location + "/new/" + self.suite_dir + \
				"_" + self.time_stamp.strftime("%Y-%m-%d_%H-%M-%S") + ".xml")
		run_name_timestamp = self.time_stamp.strftime(self.suite_dir + \
				"%Y-%m-%d_%H-%M-%S")
		date_time_timestamp = self.time_stamp.strftime("%d.%m.%Y %H:%M:%S")
		test_set_name = "Root\\Product Creation Tools\\Regression\\" + \
				"SBS v2 (Raptor)\\" + self.suite_dir + "_"
		if sys.platform.startswith("win"):
			test_set_name += ("WinXP_" + branch)
		else:
			test_set_name += ("Linux_" + branch)
		
		# /mnt/ -> // Fixes the difference in paths for lon-rhdev mounts vs. win
		if not sys.platform.startswith("win"):
			if self.test_path.startswith("/mnt/"):
				self.test_path = self.test_path.replace("mnt", "", 1)
		
		try:
			tri_file = \
					open(raptor_tests.ReplaceEnvs(os.path.normpath(tri_path)), \
					"w")
			tri_file.write(
					"<TestRunInfo>\n" + \
						"\t<RunName>\n\t\t" + \
							run_name_timestamp + \
						"\n\t</RunName>\n" + \
						"\t<TestGroup>\n" + \
							"\t\tSBSv2 (Non-SITK)\n" + \
						"\t</TestGroup>\n" + \
						"\t<DateTime>\n\t\t" + \
							date_time_timestamp + \
						"\n\t</DateTime>\n" + \
						"\t<RunDuration>\n\t\t" + \
							overall_seconds + \
						"\n\t</RunDuration>\n" + \
						'\t<TestSet name="' + test_set_name + '">\n' + \
							"\t\t<TestResults>\n\t\t\t" + \
								self.test_path + \
							"\n\t\t</TestResults>\n" + \
						"\t</TestSet>\n" + \
					"</TestRunInfo>")
			tri_file.close()
			print "Tests uploaded to '" + self.upload_location + "' (" + \
					branch + ")"
		except OSError, e:
			print "SBS_TESTS: Error:", e

class SuiteRun(TestRun):
	""" Represents a 'run' of a number of test suites """

	def __init__(self, suitepattern = None, testpattern = None,
			upload_location = None):
		TestRun.__init__(self)
		
		# Add common directory to list of paths to search for modules
		sys.path.append(raptor_tests.ReplaceEnvs("$(SBS_HOME)/test/common"))
		
		
		if suitepattern:
			self.suite_regex = re.compile(".*" + suitepattern + ".*", re.I)
		else:
			self.suite_regex = re.compile(".*\_suite$", re.I)

		if testpattern:
			self.test_file_regex = re.compile(".*" + testpattern + ".*",
					re.I)
		else:
			self.test_file_regex = None

		self.suitepattern = suitepattern
		self.testpattern = testpattern
		self.upload_location = upload_location
		


	def run_tests(self):
		"""
		Run all the tests in the specified suite (directory)
		"""
	
		suites = []
		for dir in os.listdir("."):
			name_match = self.suite_regex.match(dir)
			# Each folder that matches the suite pattern will be looked into
			# Also checks to make sure the found entry is actually a directory
			if name_match is not None and os.path.isdir(dir):
				s = Suite(dir, self)
				s.run()
				self.aggregate(s)
				suites.append(dir)
		
		# Print which options were used
		if options.test_home == None:
			options_dir = "defaults)"
		else:
			options_dir = "'" + options.test_home + "' options file)"
		print "\n(Tests run using %s" %options_dir

		# Summarise the entire test run
		if self.suitepattern and (len(suites) < 1):
			print "\nNo suites matched specification '" + self.suitepattern + \
					"'\n"
		else:
			print "Overall summary (%d suites, %d tests):" \
					%(len(suites), self.test_total)
			self.show()
			self.what_failed()
	        

	def sort_dict(self, input_dict):
		"""
		This method sorts values in a dictionary
		"""
		keys = input_dict.keys()
		keys.sort()
		return keys


# Make SBS_HOME, EPOCROOT have uppercase drive letters to match os.getcwd() and
# thus stop all those insane test problems which result from one being uppercase
# and the other lowercase

if sys.platform.startswith("win"):
	sh = os.environ['SBS_HOME']
	if sh[1] == ':':
		os.environ['SBS_HOME'] = sh[0].upper() + sh[1:]
	er = os.environ['EPOCROOT']
	if er[1] == ':':
		os.environ['EPOCROOT'] = er[0].upper() + er[1:]

# Clean epocroot before running tests
raptor_tests.clean_epocroot()
run_tests = SuiteRun(suitepattern = options.suite, testpattern = options.tests,
		upload_location = options.upload)
run_tests.run_tests()

if run_tests.suites_failed:
	sys.exit(1)
	
