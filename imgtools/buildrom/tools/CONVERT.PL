#
# Copyright (c) 2004-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# parameter %1 is the string which is to occur around (i.e. before and after) the language names in the rest of the parameters to convert to 2-digit language codes
# parameter %2 is the command to execute
# parameters %3 onwards are the parameters to %2
# example:
# perl -w CONVERT.PL # echo the language code for french is #french#

$conversionDelimiter=shift;
open(E32STD_H, "< \\epoc32\\include\\E32STD.H") or die "\\epoc32\\include\\E32STD.H could not be opened";
while ($line=<E32STD_H>)
	{
	if ($line=~/\benum\s+TLanguage\b(.*)$/)
		{
		$line=$1;
		while (1)
			{
			if ($line=~/\{(.*)$/)
				{
				$line=$1;
				last;
				}
			$line=<E32STD_H>;
			}
		$last=0;
		$languageCode=0;
		while (1)
			{
			if ($line=~/^(.*?)\}/)
				{
				$line=$1;
				$last=1;
				}
			while ($line=~/^.*?ELang(\w+)\b(.*)$/)
				{
				$languageNameInLowerCase=lc $1;
				$line=$2;
				if ($line=~/^=(\d+)(.*)$/)
					{
					$languageCode=$1;
					$line=$2;
					}
				$languageData{$languageNameInLowerCase}=$languageCode;
				++$languageCode;
				}
			if ($last)
				{
				last;
				}
			$line=<E32STD_H>;
			}
		last;
		}
	}
close(E32STD_H);
for ($i=$#ARGV; $i>=0; --$i)
	{
	if ($ARGV[$i]=~/^(.*?)$conversionDelimiter(.*?)$conversionDelimiter(.*)$/)
		{
		$bitBefore=$1;
		$languageNameInLowerCase=lc $2;
		$bitAfter=$3;
		defined $languageData{$languageNameInLowerCase} or die "The language \"$languageNameInLowerCase\" is not defined in \\epoc32\\include\\E32STD.H";
		$ARGV[$i]=sprintf("$bitBefore%02d$bitAfter", $languageData{$languageNameInLowerCase});
		}
	}
system("@ARGV");

