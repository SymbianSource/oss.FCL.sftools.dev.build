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
#! python

import optparse
import sys

def writeline(line, filehandle):
	"""Assumes filehandle has a write method and that line is a string; 
	Calls the filehandle's write method with line as an argument. Note:
	filehandle can be STDOUT or STDERR or a real file. The client code
	should take care of the creation of the filehandle object"""
	print >> filehandle, line,

def info(arg, filehandle):
	writeline("# INFO: " + str(arg), filehandle)

def warning(arg, filehandle):
	writeline("# WARNING: " + str(arg), filehandle)

def error(arg, filehandle):
	writeline("# ERROR: " + str(arg), filehandle)

# Get the command line options
parser = optparse.OptionParser()
parser.add_option("-t", "--targets", type="int", dest="targets",   
				  help="Number of main (or \"level1\") targets to generate - these are the targets " + \
				  "that actually perform some simulated actions.")
parser.add_option("-d", "--divisions", type="int", dest="divisions", 
				  help="The number of \"level2\" targets. Each level2 target will depend on " + \
				  "t/d level1 targets. This makes makefile generation more logical.")
parser.add_option("-m", "--makefile", dest="makefile", 
				  help="Name of makefile to generate. If blank, makefile is printed to STDOUT.")
parser.add_option("-c", "--case", dest="case", 
				  help="Type of commands to use in each rule. Default is \"all\"; other options are " + \
				  "\"env\", \"echo\", \"cp\" and \"sed\"")

(options, args) = parser.parse_args()

makefile = options.makefile
makefilefh = None
# Open the makefile if possible. Note, all info, warnings and errors 
# will appear in the makefile as comments.
if makefile != None:
	try:
		makefilefh = open(makefile, "w")
	except:
		makefile = None
		makefilefh = None
		error("Failed to open " + makefile + ". STDOUT will be used instead.", makefilefh)

info("Auto-generated makefile for stress-testing.\n\n", makefilefh)

if options.targets == None:
	error("Missing option \"targets\". Please ensure you have specified the number of targets required.\n\n", makefilefh)
	sys.exit(2)

if options.divisions == None:
	info("Missing option \"divisions\". Defaulting to 1.\n\n", makefilefh)
	options.divisions = 1

# Commands to use in the main "worker" rules
command_env = "echo Echoing PATH from $@ in a subshell; (echo PATH=$$PATH;)"
command_echo_1 = "echo This is rule $@; echo PATH=$$PATH && echo TMP=$$TMP;"
command_echo_2 = "echo Echoing PATH from $@ in a subshell; (echo PATH=$$PATH;)"
command_echo_3 = "echo Echoing PATH from $@ in a subshell; (echo Another subshell; (echo PATH=$$PATH;))"
command_cp_1 = "cp -f junk_file junk_file_copy_1_$@"
command_cp_2 = "cp -f junk_file junk_file_copy_2_$@"
command_cp_3 = "cp -f junk_file junk_file_copy_3_$@"
command_cp_4 = "cp -f junk_file junk_file_copy_4_$@"
command_sed_1 = "echo asdfsdf-----asdfasdfasdf-.txt | sed 's!.*-----!!g';"
command_sed_2 = "echo 'ssss:33 x' | sed 's!.*:[0-9][0-9] *!!g'"

# Default command list
command_list = []

if options.case == "env":
	command_list = [command_env]
elif options.case == "echo":
	command_list = [command_echo_1, command_echo_2, command_echo_3]
elif options.case == "cp":
	command_list = [command_cp_1, command_cp_2, command_cp_3, command_cp_4]
elif options.case == "sed":
	command_list = [command_sed_1, command_sed_2]
elif options.case in ["all", None]:
	command_list = [command_env, 
				    command_echo_1, command_echo_2, command_echo_3, 
				    command_cp_1, command_cp_2, command_cp_3, command_cp_4, 
				    command_sed_1, command_sed_2]
else:
	error("Unknown option for \"case\" option: %s. Reverting to defaults..." % (options.case), makefilefh)
	command_list = [command_env, 
				    command_echo_1, command_echo_2, command_echo_3, 
				    command_cp_1, command_cp_2, command_cp_3, command_cp_4, 
				    command_sed_1, command_sed_2]

# Clean command to delete all the junk copy files
clean = "rm -f junk_file_copy_*"

total_targets = options.targets
divisions = options.divisions
quotient = total_targets/divisions
remainder = total_targets - quotient*divisions

writeline("main:", makefilefh)
for i in range(divisions):
	writeline("level_2_rule_%09d " % (i), makefilefh)
writeline("\n\n", makefilefh)

for i in range(divisions):
	writeline("level_2_rule_%09d: " % (i), makefilefh)
	for j in range(quotient):
		writeline("level_1_rule_%09d " % (j + i*quotient), makefilefh)
	writeline("\n\n", makefilefh)

# Generate extra rule for the "remainder" targets
if remainder > 0:
	writeline("main:", makefilefh)
	writeline("level_2_rule_%09d " % (divisions), makefilefh)
	writeline("\n\n", makefilefh)
	writeline("level_2_rule_%09d: " % (divisions), makefilefh)	
	for j in range(total_targets - remainder,total_targets):
		writeline("level_1_rule_%09d " % (j), makefilefh)
	writeline("\n\n", makefilefh)

# Generate the level_1_rules - these are the ones that actually
# execute commands.
for i in range(total_targets):
	writeline("level_1_rule_%09d: \n" % (i), makefilefh)
	for command in command_list:
		writeline("\t" + command + "\n", makefilefh)
	writeline("\n\n", makefilefh)

writeline("clean:\n", makefilefh)
writeline("\t" + clean + "\n", makefilefh)
writeline("\n", makefilefh)

if makefile != None:
	makefilefh.close()