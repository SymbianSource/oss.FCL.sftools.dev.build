# Copyright (c) 2009-2010 Nokia Corporation and/or its subsidiary(-ies).
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
# Raptor installer/uninstaller script

# Set compression type - the advice in the NSIS user manual 
# is to have this at the top of the main .nsi file.
SetCompressor /SOLID lzma

# Standard NSIS Library includes 
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "WinMessages.nsh"

# Extra plugin includes
!include "nsDialogs.nsh"
!include "Registry.nsh"
!include "NSISpcre.nsh"
!include "Time.nsh"

# Define functions from NSISpcre.nsh 
!insertmacro REMatches
!insertmacro un.REMatches
!insertmacro REQuoteMeta

# Variables
Var DIALOG
Var RESULT # Generic variable to obtain results, and immediately thrown away after
Var RESULT2 # Generic variable to obtain results, and immediately thrown away after
Var SBS_HOME
Var USERONLYINSTALL_HWND # HWND of radio button control for user-only installation
Var ALLUSERSINSTALL_HWND # HWND of radio button control for system installation
Var NOENVCHANGES_HWND    # HWND of radio button control for file-only installation
Var USERONLYINSTALL_STATE # State of user-only radio button
Var ALLUSERSINSTALL_STATE # State of system radio button
Var NOENVCHANGES_STATE # State of file-only installation radio button
Var INSTALL_TYPE # Type of installer ("USR" or "SYS")

# Custom includes (depend on above variables so much be here)
!include "raptorinstallerutils.nsh" # Functions and macros for handling environment variables
# !include "raptorversion.nsh" # Define the RAPTOR_VERSION variable

# Defines
!define INSTALLER_NAME "Raptor v${RAPTOR_VERSION}"
!define RAPTOR "sbs"
!define INSTALLER_FILENAME "${RAPTOR}-${RAPTOR_VERSION}.exe"
!define UNINSTALLER_FILENAME "${RAPTOR}-${RAPTOR_VERSION}-uninstaller.exe"

########################## Attributes ###########################
# Name of installer executable to create!
OutFile ${INSTALLER_FILENAME}
# Name for the installer caption
Name "Raptor v${RAPTOR_VERSION}"

####################### Generic Behaviour #######################
# Vista support; use admin in case user decides to install Raptor for all users
RequestExecutionLevel admin
# Set XPStyle on
XPStyle on

###################### Installer Behaviour ######################
# Warn on Cancel
!define MUI_ABORTWARNING
# Abort warning text
!define MUI_ABORTWARNING_TEXT "Are you sure you want to quit the ${INSTALLER_NAME} installer?"
# Cancel is default button on cancel dialogue boxes.
!define MUI_ABORTWARNING_CANCEL_DEFAULT
# Don't just to final page
!define MUI_FINISHPAGE_NOAUTOCLOSE
# Show installer details
ShowInstDetails show

##################### Pages in the installer #####################
!define MUI_WELCOMEPAGE_TITLE_3LINES
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE ${RAPTOR_LOCATION}\license.txt
!define MUI_PAGE_HEADER_TEXT "Installation type"
Page custom UserOrSysInstall UserOrSysInstallLeave
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE DirLeave # Directory page exit function - disallow spaces in $INSTDIR
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_TITLE_3LINES
!insertmacro MUI_PAGE_FINISH

######################## .onInit function ########################
Function .onInit
    StrCpy $INSTDIR "C:\Apps\Raptor"
FunctionEnd

#################### Sections in the installer ####################
# "Sections" - i.e. components to install. This installer
# only has Raptor, so there is no point giving options 
# to the user.
Section "Install Raptor" INSTALLRAPTOR
	
    StrCpy $SBS_HOME "SBS_HOME"
	
    # Install Raptor
    SetOutPath "$INSTDIR\bin"
    File /r /x distribution.policy.s60 ${RAPTOR_LOCATION}\bin\*.* 
    SetOutPath "$INSTDIR\examples"
    File /r /x distribution.policy.s60 ${RAPTOR_LOCATION}\examples\*.*
    SetOutPath "$INSTDIR\lib"
    File /r /x distribution.policy.s60 ${RAPTOR_LOCATION}\lib\*.*
    SetOutPath "$INSTDIR\python"
    File /r /x distribution.policy.s60 /x *.pyc /x *.pydevproject /x *.project ${RAPTOR_LOCATION}\python\*.*
    SetOutPath "$INSTDIR\schema"
    File /r /x distribution.policy.s60 ${RAPTOR_LOCATION}\schema\*.*
    SetOutPath "$INSTDIR\style"
    File /r /x distribution.policy.s60 ${RAPTOR_LOCATION}\style\*.*
    SetOutPath "$INSTDIR\win32\bin"
    File /r /x distribution.policy.s60 ${RAPTOR_LOCATION}\win32\bin\*.*
    SetOutPath "$INSTDIR\win32\bv"
    File /r /x distribution.policy.s60 /x .hg ${BV_LOCATION}\*.*
    SetOutPath "$INSTDIR\win32\cygwin"
    File /r /x distribution.policy.s60 /x .hg ${CYGWIN_LOCATION}\*.*
    SetOutPath "$INSTDIR\win32\mingw"
    File /r /x distribution.policy.s60 /x .hg ${MINGW_LOCATION}\*.*
    SetOutPath "$INSTDIR\win32\python264"
    File /r /x distribution.policy.s60 /x .hg ${PYTHON_LOCATION}\*.*
    
    SetOutPath "$INSTDIR"
    File ${RAPTOR_LOCATION}\RELEASE-NOTES.html
    SetOutPath "$INSTDIR\notes"
    File /r /x distribution.policy.s60 ${RAPTOR_LOCATION}\notes\*.*
    
    
    ${Unless} $INSTALL_TYPE == "NO_ENV"
        # Back up system and user environments before changing them.
        !insertmacro DefineDateStamp
        !define SYS_REG_BACKUP_FILE "$INSTDIR\SysEnvBackUpPreInstall-${DATE_STAMP}.reg"
        !define USR_REG_BACKUP_FILE "$INSTDIR\UsrEnvBackUpPreInstall-${DATE_STAMP}.reg"
        
        # Save System Environment just in case.
        ${registry::SaveKey} "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "${SYS_REG_BACKUP_FILE}" "" "$RESULT"
        
        ${If} $RESULT == 0
            DetailPrint "Successfully backed up system environment in ${SYS_REG_BACKUP_FILE}."
        ${Else}
            DetailPrint "Failed to back up system environment due to an unknown error."
        ${EndIf}
        
        # Save user Environment just in case.
        ${registry::SaveKey} "HKCU\Environment" "${USR_REG_BACKUP_FILE}" "" "$RESULT"
        
        ${If} $RESULT == 0
            DetailPrint "Successfully backed up user environment in ${USR_REG_BACKUP_FILE}."
        ${Else}
            DetailPrint "Failed to back up user environment due to an unknown error."
        ${EndIf}
    	
    	# Reset error flag
    	ClearErrors
    	
    	# Write SBS_HOME variable; if it exists, the user will be asked if they want it to be overwritten.
    	# Read the env var from the appropriate place
    	!insertmacro ReadEnvVar $SBS_HOME $RESULT
    	
    	${Unless} ${Errors} # No errors, so $SBS_HOME exists
    		DetailPrint "Env Var $SBS_HOME exists with value $RESULT"
    		# Ask user if they want it replaced. If yes, write it, if no don't write it.
    		MessageBox MB_YESNO|MB_ICONQUESTION "The ${INSTALLER_NAME} installer has detected that you already have the SBS_HOME environment variable set with value $RESULT. Would you like the installer to overwrite it with the value $INSTDIR? Click yes to over write with value $INSTDIR, and no to leave it as $RESULT." IDYES write_env_var_yes IDNO write_env_var_no
    	${Else} # No env var named $SBS_HOME
    		DetailPrint "Env Var $SBS_HOME does not exist!"
    	${EndUnless}
    	
write_env_var_yes:
    	# Write SBS_HOME to registry
    	Push "SBS_HOME" # Third on stack
    	Push "$INSTDIR" # Second on stack
    	Push "" # First on stack
    	
    	# Needs env var name, env var value, then "" on the stack
    	call WriteEnvVar
    	
    	# Prepend PATH with %SBS_HOME%\bin
    	Push "%SBS_HOME%\bin" # First on stack
    	call PrependToPath
    	goto end
        
write_env_var_no:
    	DetailPrint "Not writing the environment variable $SBS_HOME."
        
end:
    ${EndUnless} 
	
	# Generate batch file to set environment variables for Raptor
	StrCpy $RESULT "@REM Environment variables for ${INSTALLER_NAME}$\r$\nset SBS_HOME=$INSTDIR$\r$\nset PATH=%SBS_HOME%\bin;%PATH%$\r$\n"
	SetOutPath "$INSTDIR"
	!insertmacro WriteFile "RaptorEnv.bat" "$RESULT"
SectionEnd

# Finishing up installation.
Section
    ${Unless} $INSTALL_TYPE == "NO_ENV"
    	# Refresh environment to get changes for SBS_HOME and PATH
        !insertmacro RefreshEnv
    ${EndUnless}
	
	# Write the uninstaller
	WriteUninstaller "$INSTDIR\${UNINSTALLER_FILENAME}"
	# Unload registry plug in
	${registry::Unload}
SectionEnd

# Custom install page to select install type
Function UserOrSysInstall
    !insertmacro MUI_HEADER_TEXT "Choose Installation Type" "Choose the type of installation \
    you would like for your computer."
    
	nsDialogs::Create 1018
	Pop $DIALOG
	
	# Exit is unable to create dialog
	${If} $DIALOG == error
		Abort
	${EndIf}
	
	# Create second radio button for system install
	#${NSD_CreateRadioButton} 0 10u 100% 33% "Install Raptor for all users on this computer. \
    #(Recommended).$\nThis option modifies system wide environment variables."
	#Pop $ALLUSERSINSTALL_HWND
    
    # Create first radio button for user install
    #${NSD_CreateRadioButton} 0 45u 100% 67% "Install Raptor just for me on this computer.\
    #$\nThis option modifies only user environment variables."
    #Pop $USERONLYINSTALL_HWND
	
	# Create first radio button for system install
	${NSD_CreateRadioButton} 0 0% 100% 30% "Install Raptor for all users on this computer. \
    (Recommended).$\nThis option modifies system wide environment variables."
	Pop $ALLUSERSINSTALL_HWND
    
    # Create second radio button for user install
    ${NSD_CreateRadioButton} 0 25% 100% 30% "Install Raptor just for me on this computer.\
    $\nThis option modifies only user environment variables."
    Pop $USERONLYINSTALL_HWND
    
    # Create third radio button for file-only install
    ${NSD_CreateRadioButton} 0 50% 100% 40% "Install, but do not modify the environment.\
    $\nThis option only unpacks Raptor's files. A batch file in the installation \ 
    folder (RaptorEnv.bat) can be used to set Raptor's environment variables in a command prompt."
    Pop $NOENVCHANGES_HWND
	
	# Update page control with previous state, if set.
	# Initially these will be blank, so set system install to be on by default.
	${If} $USERONLYINSTALL_STATE == ""
	${AndIf} $ALLUSERSINSTALL_STATE == ""
    ${AndIf} $NOENVCHANGES_STATE == ""
		${NSD_SetState} $ALLUSERSINSTALL_HWND ${BST_CHECKED}
	${Else} # Previously set, user has returned to this page using "Back" button
		${If} $USERONLYINSTALL_STATE == ${BST_CHECKED}
			${NSD_SetState} $USERONLYINSTALL_HWND ${BST_CHECKED}
		${ElseIf} $NOENVCHANGES_STATE == ${BST_CHECKED}
            ${NSD_SetState} $NOENVCHANGES_HWND ${BST_CHECKED}
        ${Else}
			${NSD_SetState} $ALLUSERSINSTALL_HWND ${BST_CHECKED}
		${EndIf}
	${EndIf}
	
	nsDialogs::Show
FunctionEnd

# Store the states of the radio buttons once the user has left the page.
Function UserOrSysInstallLeave
	${NSD_GetState} $USERONLYINSTALL_HWND $USERONLYINSTALL_STATE
	${NSD_GetState} $ALLUSERSINSTALL_HWND $ALLUSERSINSTALL_STATE
    ${NSD_GetState} $NOENVCHANGES_HWND $NOENVCHANGES_STATE
    
    # Set the ${INSTALL_TYPE} variable
    ${If} $USERONLYINSTALL_STATE == ${BST_CHECKED}
        StrCpy $INSTALL_TYPE "USR"
    ${EndIf}
    
    ${If} $ALLUSERSINSTALL_STATE == ${BST_CHECKED}
        StrCpy $INSTALL_TYPE "SYS"
    ${EndIf}
    
    ${If} $NOENVCHANGES_STATE == ${BST_CHECKED}
        StrCpy $INSTALL_TYPE "NO_ENV"
    ${EndIf}
    
    ${Unless} $INSTALL_TYPE == "USR"
    ${AndUnless} $INSTALL_TYPE == "SYS"
    ${AndUnless} $INSTALL_TYPE == "NO_ENV"
        Abort "Failed to determine installation type.\n\
        $$INSTALL_TYPE = $\"$INSTALL_TYPE$\"."
    ${EndUnless} 
FunctionEnd

Function DirLeave
	StrCpy $0 " "
	${REQuoteMeta} $9 $0 # $9 now contains the meta-quoted version of $0
	${If} $INSTDIR =~ $9
		MessageBox MB_OK|MB_ICONSTOP "Please choose a directory without a space in it."
		Abort
	${EndIf}
FunctionEnd

########################### Uninstaller #########################
######################## .onInit function ########################
Function un.onInit
	!undef DATE_STAMP
	!insertmacro DefineDateStamp
FunctionEnd
########################### Behaviour ###########################
# Warn on Cancel
!define MUI_UNABORTWARNING
# Abort warning text
!undef MUI_UNABORTWARNING_TEXT
!define MUI_UNABORTWARNING_TEXT "Are you sure you want to quit the ${INSTALLER_NAME} uninstaller?"
# Cancel is default button on cancel dialogue boxes.
!define MUI_UNABORTWARNING_CANCEL_DEFAULT
# Don't just to final page
!define MUI_UNFINISHPAGE_NOAUTOCLOSE
# Show uninstaller details
ShowUninstDetails show

#################### Pages in the uninstaller ####################
!define MUI_WELCOMEPAGE_TITLE_3LINES
!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!define MUI_FINISHPAGE_TITLE_3LINES
!insertmacro MUI_UNPAGE_FINISH

################## Sections in the uninstaller ##################
# There is only one section in the uninstaller.
Section "Uninstall"
    # Delete Raptor
    RmDir /r $INSTDIR\bin
    RmDir /r $INSTDIR\examples
    RmDir /r $INSTDIR\lib
    RmDir /r $INSTDIR\python
    RmDir /r $INSTDIR\schema
    RmDir /r $INSTDIR\style
    RmDir /r $INSTDIR\win32
    Delete $INSTDIR\RELEASE-NOTES.html
    RmDir /r $INSTDIR\notes
    Delete $INSTDIR\RaptorEnv.bat
    Delete $INSTDIR\${UNINSTALLER_FILENAME}
    
    !undef SYS_REG_BACKUP_FILE
    !undef USR_REG_BACKUP_FILE
    !define SYS_REG_BACKUP_FILE "$INSTDIR\SysEnvBackUpPreUninstall-${DATE_STAMP}.reg"
    !define USR_REG_BACKUP_FILE "$INSTDIR\UsrEnvBackUpPreUninstall-${DATE_STAMP}.reg"
    
    # Save System Environment just in case.
    ${registry::SaveKey} "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "${SYS_REG_BACKUP_FILE}" "" "$RESULT"
    
    ${If} $RESULT == 0
        DetailPrint "Successfully backed up system environment in ${SYS_REG_BACKUP_FILE}."
    ${Else}
        DetailPrint "Failed to back up system environment due to an unknown error."
    ${EndIf}
    
    # Save user Environment just in case.
    ${registry::SaveKey} "HKCU\Environment" "${USR_REG_BACKUP_FILE}" "" "$RESULT"
    
    ${If} $RESULT == 0
        DetailPrint "Successfully backed up user environment in ${USR_REG_BACKUP_FILE}."
    ${Else}
        DetailPrint "Failed to back up user environment due to an unknown error."
    ${EndIf}
	
	# Reset error flag
	ClearErrors
	
	# Read user SBS_HOME
	!insertmacro ReadUsrEnvVar "SBS_HOME" $RESULT
	
	${Unless} ${Errors} # No errors, so user %SBS_HOME% exists
		DetailPrint "Removing user environment variable SBS_HOME ($RESULT)"
		
		# Reset error flag
		ClearErrors
		!insertmacro RmUsrEnvVar "SBS_HOME"
		
		${If} ${Errors}
			DetailPrint "ERROR: The ${INSTALLER_NAME} uninstaller could not remove the user environment variable SBS_HOME."
			DetailPrint "Please remove it manually."
		${EndIf}
		
	${Else} # No env var named $SBS_HOME
		DetailPrint "Note: Unable to find user environment variable SBS_HOME."
		DetailPrint "If required, this variable may need to be removed manually."
	${EndUnless}
	
	# Reset error flag
	ClearErrors
	
	# Read system SBS_HOME
	!insertmacro ReadSysEnvVar "SBS_HOME" $RESULT
	
	${Unless} ${Errors} # No errors, so system $SBS_HOME exists
		DetailPrint "Removing system environment variable SBS_HOME ($RESULT)"
		
		# Reset error flag
		ClearErrors
		!insertmacro RmSysEnvVar "SBS_HOME"
		
		${If} ${Errors}
			DetailPrint "ERROR: The ${INSTALLER_NAME} uninstaller could not remove the \
            System environment variable SBS_HOME."
			DetailPrint "Please remove it manually."
		${EndIf}
		
	${Else} # No env var named $SBS_HOME
		DetailPrint "Note: Unable to find system environment variable SBS_HOME."
		DetailPrint "If required, this variable may need to be removed manually."
	${EndUnless}
	
	################################# Clean up the path env vars #################################
	# Reset error flag
	ClearErrors
	
	# Read user path
	!insertmacro ReadUsrPath $RESULT
    DetailPrint "Read user Path: $RESULT"
	
	${Unless} ${Errors} # No errors, so user $SBS_HOME exists
		${If} $RESULT == "" # If it came back empty.
			DetailPrint "No user Path available - nothing to do."
		${Else}
            ${If} $RESULT un.=~ "%SBS_HOME%\\bin;" # Only need to act if %SBS_HOME%\bin; is in the Path
    			DetailPrint "Removing %SBS_HOME%\bin; from user path"
    			
    			# Reset error flag and clean user Path
    			ClearErrors
    			!insertmacro RemoveFromPathString $RESULT "%SBS_HOME%\bin;"
    			
    			DetailPrint "DEBUG: User path $$RESULT = "
    	        DetailPrint "DEBUG: User path  $RESULT"
    			
    			${If} $RESULT == ""
    				!insertmacro RmUsrEnvVar "Path"
    			${Else}
    				# Write cleaned Path to registry
    	            !insertmacro WriteUsrEnvVarExp "Path" $RESULT
    			${EndIf}
    			
    			${If} ${Errors}
    				DetailPrint "ERROR: The ${INSTALLER_NAME} uninstaller could not clean the user Path. Please clean it manually."
    			${EndIf}
            ${Else}
                DetailPrint "Nothing to remove from user path."
            ${EndIf}
		${EndIf}
		
	${Else} # No user path
		DetailPrint "Note: Unable to find user Path environment variable."
		DetailPrint "Please check that the variable exists and remove %SBS_HOME\bin manually if required."
	${EndUnless}
    
    # Read system path
    !insertmacro ReadSysPath $RESULT
    DetailPrint "Read system Path: $RESULT"
    
    ${Unless} ${Errors} # No errors, so system path read OK.
        ${If} $RESULT un.=~ "%SBS_HOME%\\bin;" # Only need to act if %SBS_HOME%\bin; is in the Path 
        
            DetailPrint "Removing %SBS_HOME%\bin; from system path"
            
            # Reset error flag
            ClearErrors
            !insertmacro RemoveFromPathString $RESULT "%SBS_HOME%\bin;"
            DetailPrint "DEBUG: System Path $$RESULT = "
            DetailPrint "DEBUG: System Path $RESULT"
            ClearErrors
            # Write cleaned PATH to registry
            !insertmacro WriteSysEnvVarExp "Path" $RESULT
            
            ${If} ${Errors}
                DetailPrint "ERROR: The ${INSTALLER_NAME} uninstaller could not clean the PATH."
                DetailPrint "Please clean it manually."
            ${EndIf}
        ${Else}
            DetailPrint "Nothing to remove from system path."
        ${EndIf}
    ${Else} # Some error reading system path
        DetailPrint "Note: Unable to read the system Path environment variable."
        DetailPrint "Please check that the variable and remove %SBS_HOME\bin manually if required."
    ${EndUnless}
	
	##########################################################################
	# Refresh environment to get changes for SBS_HOME and PATH
    !insertmacro RefreshEnv
	
	# Unload registry plug in
	${registry::Unload}
SectionEnd

# Languages
!insertmacro MUI_LANGUAGE "English"

################################################ End ################################################
