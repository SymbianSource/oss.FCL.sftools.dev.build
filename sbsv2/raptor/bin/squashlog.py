#
# Copyright (c) 2008-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# squash a raptor log file by removing commands from successful recipes
#

import sys

inRecipe = False

for line in sys.stdin.readlines():
	# escape % characters otherwise print will fail
	line = line.replace("%", "%%")
		
	# detect the start of a recipe
	if line.startswith("<recipe "):
		inRecipe = True
		recipeLines = [line]
		squashRecipe = True
		continue
		
	# detect the status report from a recipe
	if line.startswith("<status "):
		if not "exit='ok'" in line:
			# only squash ok recipes
			squashRecipe = False
		recipeLines.append(line)
		continue
				
	# detect the end of a recipe
	if line.startswith("</recipe>"):
		# print the recipe
		if squashRecipe:
			for text in recipeLines:
				if not text.startswith("+"):
					print text,
		else:
			for text in recipeLines:
				print text,
		print line,
		continue
		
	# remember the lines during a recipe
	if inRecipe:
		recipeLines.append(line)	
	else:
	# print all lines outside a recipe 
		print line,
	
# end

