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
# Raptor installer header file

!include "WordFunc.nsh"

# Time macros
!macro DefineDateStamp
	${time::GetLocalTime} $RESULT
	${time::TimeString} "$RESULT" $0 $1 $2 $3 $4 $5
	!define DATE_STAMP "$2-$1-$0-$3-$4-$5"
!macroend

# Env var manipulation macros

# Macro to refresh the computer's environment by sending Windows the
# WM_WININICHANGE message so that it re-reads the environment changes
# the installer has made.
!macro RefreshEnv
	DetailPrint "Refreshing your computer's environment..."
	SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" $RESULT /TIMEOUT=5000
	DetailPrint "Done."
!macroend

# Sets ${RESULT} to value of user env var named ${VARNAME}
!macro ReadUsrEnvVar VARNAME RESULT
	ReadRegStr ${RESULT} HKCU "Environment" ${VARNAME}
!macroend

# Sets ${RESULT} to value of system env var named ${VARNAME}
!macro ReadSysEnvVar VARNAME RESULT
	ReadRegStr ${RESULT} HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" ${VARNAME}
!macroend

# Read the env var from the appropriate place
!macro ReadEnvVar VARNAME RESULT
	${If} $USERONLYINSTALL_STATE == ${BST_CHECKED}
		# User env var
		!insertmacro ReadUsrEnvVar ${VARNAME} ${RESULT}
	${ElseIf} $ALLUSERSINSTALL_STATE == ${BST_CHECKED}
		# System env var
		!insertmacro ReadSysEnvVar ${VARNAME} ${RESULT}
	${Else}
		# Something has gone wrong!
		MessageBox MB_OK|MB_ICONSTOP "Failed to determine installation type (Current User or All Users)."
	${EndIf}
!macroend

# Read the user Path
!macro ReadUsrPath OUTPUT
	# Reset error flag
	ClearErrors
    !insertmacro ReadUsrEnvVar "Path" ${OUTPUT}
    
	${If} ${Errors}
		DetailPrint "User has no Path variable."
		StrCpy "${OUTPUT}" ""
	${EndIf}
!macroend

# Read the user Path
!macro ReadSysPath OUTPUT
	# Reset error flag
	ClearErrors
	!insertmacro ReadSysEnvVar "Path" ${OUTPUT}
!macroend

# Read the Path (installer only).
!macro ReadPath OUTPUT
${If} $USERONLYINSTALL_STATE == ${BST_CHECKED}
	# User env var
	!insertmacro ReadUsrPath ${OUTPUT}
${ElseIf} $ALLUSERSINSTALL_STATE == ${BST_CHECKED}
	# System env var
	!insertmacro ReadSysPath ${OUTPUT}
${Else}
	# Something has gone wrong!
	MessageBox MB_OK|MB_ICONSTOP "Failed to determine installation type (Current User or All Users)."
${EndIf}
!macroend

# Writes a string user environment variable to the Registry
# DO NOT USE FOR WRITING THE PATH ENVIRONMENT VARIABLE. USE THE BELOW MARCOS!
!macro WriteUsrEnvVar VARNAME VALUE
	WriteRegStr HKCU "Environment" ${VARNAME} ${VALUE}
!macroend

# Writes a string system environment variable to the Registry
# DO NOT USE FOR WRITING THE PATH ENVIRONMENT VARIABLE. USE THE BELOW MARCOS!
!macro WriteSysEnvVar VARNAME VALUE
	WriteRegStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" ${VARNAME} ${VALUE}
!macroend

# Use the following for PATH env var that can expand variables it contains, e.g.
# Something like 
# %SBS_HOME%;C:\Windows...
# should be written to the registry
# SBS_HOME must NOT be an "expandable string"; in fact expandable strings don't work recursively

# Writes an expandable string user environment variable to the Registry; mostly used for PATH
!macro WriteUsrEnvVarExp VARNAME VALUE
	WriteRegExpandStr HKCU "Environment" ${VARNAME} ${VALUE}
!macroend

# Writes an expandable string system environment variable to the Registry; mostly used for PATH
!macro WriteSysEnvVarExp VARNAME VALUE
	WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" ${VARNAME} ${VALUE}
!macroend

# Deletes a user environment variable from the Registry
!macro RmUsrEnvVar VARNAME
	DeleteRegValue HKCU "Environment" ${VARNAME}
!macroend

# Deletes a system environment variable from the Registry
!macro RmSysEnvVar VARNAME
	DeleteRegValue HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" ${VARNAME}
!macroend

# Push env var name, value of env var, and either "" (for normal string env var) 
# or "exp" (for expandable env var) onto stack before calling this function
# in this order
Function WriteEnvVar
	pop $2 # Expandable string or not?
	pop $1 # Env var value
	pop $0 # Env var name
		
	DetailPrint "Going to write evn var $0, with value $1, expandable: $2."
	
	# Reset error flag
	ClearErrors
	
	${If} $2 == "exp" # Expandable string env var
		# Write the env var to the appropriate place
		${If} $USERONLYINSTALL_STATE == ${BST_CHECKED}
			DetailPrint "DEBUG $$0 $$1 = $0 $1"
			# User env var
			!insertmacro WriteUsrEnvVarExp $0 $1
		${ElseIf} $ALLUSERSINSTALL_STATE == ${BST_CHECKED}
			DetailPrint "DEBUG $$0 $$1 = $0 $1"
			# System env var
			!insertmacro WriteSysEnvVarExp $0 $1
		${Else}
			# Something has gone wrong!
			MessageBox MB_OK|MB_ICONSTOP "Failed to determine installation type (Current User or All Users)."
		${EndIf}
	${Else} # Normal string env var
		# Write the env var to the appropriate place
		${If} $USERONLYINSTALL_STATE == ${BST_CHECKED}
			DetailPrint "DEBUG $$0 $$1 = $0 $1"
			# User env var
			!insertmacro WriteUsrEnvVar $0 $1
		${ElseIf} $ALLUSERSINSTALL_STATE == ${BST_CHECKED}
			DetailPrint "DEBUG $$0 $$1 = $0 $1"
			# System env var
			!insertmacro WriteSysEnvVar $0 $1
		${Else}
			# Something has gone wrong!
			MessageBox MB_OK|MB_ICONSTOP "Failed to determine installation type (Current User or All Users)."
		${EndIf}
	${EndIf}
FunctionEnd

# Prepend the PATH env var with the given string. User/system path is determined using
# other function.
Function PrependToPath
	pop $0 # String to prepend to PATH
		
	DetailPrint "Going to prepend PATH with $0."
	
	# Reset error flag
	ClearErrors
	
	# Read Path
	!insertmacro ReadPath $RESULT
	
	${Unless} ${Errors} # If no errors
		${REQuoteMeta} $9 $0 # $9 now contains the meta-quoted version of $0
		${If} $RESULT !~ $9 # If Path doesn't contain string to add
			StrLen $RESULT2 "$0;$RESULT"
			# Warn is Path might be "too" long for the Windows registry.
			${If} $RESULT2 > 1023
				DetailPrint "Note: adding %SBS_HOME%\bin; to the start of your Path..."
				DetailPrint "... will result in a string longer than 1023 characters..."
				DetailPrint "... being written to your registry. Certain versions of Windows..."
				DetailPrint "... cannot handle a string that long in the registry. The installer..."
				DetailPrint "... will continue writing to the registry. However, a back up of..."
				DetailPrint "... your full environment has been created in your installation directory ..."
				DetailPrint "... should anything go wrong which can be used to restore your previous Path."
			${EndIf}
			
			Push "Path" # Third on stack
			Push "$0;$RESULT" # Second on stack
			Push "exp" # First on stack
			# Write expandable string to registry
			call WriteEnvVar
		${EndIf}
	${Else}
		DetailPrint "Error: failed to read Path environment variable."
	${EndUnless}
FunctionEnd

# Remove the string STR from the string PATH.
!macro RemoveFromPathString PATH STR
	DetailPrint "Going to remove ${STR} from ${PATH}."
	${WordReplace} "${PATH}" "${STR}" "" "+" $RESULT2
	DetailPrint "Debug: Replaced ${STR} in RESULT2 = [$RESULT2]"
	StrCpy ${PATH} "$RESULT2"
	
	${WordReplace} "${PATH}" ";;" ";" "+" $RESULT2
	DetailPrint "Debug: Replaced ;; in RESULT2 = [$RESULT2]"
	StrCpy ${PATH} $RESULT2
!macroend

################### Miscellaneous utilities
# WriteFile - writes a file with given contents
# FILENAME - full path to file (all directories in path must exist)
# CONTENTS - string to write to the file.
!macro WriteFile FILENAME CONTENTS
	DetailPrint "Creating batch file for setting Raptor's environment..."
	ClearErrors
	FileOpen $0 ${FILENAME} w
	${Unless} ${Errors}
		FileWrite $0 "${CONTENTS}"
		FileClose $0
		DetailPrint "Done."		
	${Else}
		DetailPrint "Error: failed to write RaptorEnv.bat."
	${EndUnless}
!macroend

################################################ End ################################################
