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

###########################################################################################
#  CBR Tools handling
# 
!define RELTOOLSKEY "SOFTWARE\Symbian\Release Tools"
!define CBRTOOLSKEY "SOFTWARE\Symbian\Symbian CBR Tools"
!define PRODUCT_UNINST_KEY "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"

VAR CBRUNINSTALL

!macro CBRToolsNSISManualUninstall inVersion inPath
           SetShellVarContext current
           RMDir /r "$SMPROGRAMS\Symbian CBR Tools\${inVersion}"
           RMDir "$SMPROGRAMS\Symbian CBR Tools" ; delete if empty
           RMDir /r "${inPath}"
           DeleteRegKey HKLM "${PRODUCT_UNINST_KEY}\Symbian CBR Tools ${inVersion}"
           DeleteRegKey HKLM "${CBRTOOLSKEY}\${inVersion}"
           DeleteRegKey /ifempty HKLM "${CBRTOOLSKEY}"
           Push "${inPath}"
           !insertmacro PathTypeRmvFromEnvVar "path" "${inPath}" ""
           !insertmacro SetShellVarCtxt
!macroend


!macro CBRToolsISManualUninstall inVersion inPath inUninstallKey
           RMDir /r "$SMPROGRAMS\Symbian OS Release Tools\"
           RMDir /r "${inPath}"
           ${If} "${inUninstallKey}" != ""
             DeleteRegKey HKLM "${PRODUCT_UNINST_KEY}\${inUninstallKey}"
           ${EndIf}
           DeleteRegKey HKLM "${RELTOOLSKEY}\${inVersion}"
           DeleteRegKey /ifempty HKLM "${RELTOOLSKEY}"
           DeleteRegKey /ifempty HKLM "SOFTWARE\Symbian"
           Push "${inPath}"
           !insertmacro PathTypeRmvFromEnvVar "path" "${inPath}" ""
!macroend


Function CBRToolsPreConfigureFunction
exch $0 
push $1 # counter
push $2 # version
push $3 # uninstall string
push $4
push $5

push $6

push $R0 # $ReplaceVer
push $R1 # $ReplaceKey

push $R2 # nsis installations found
push $R3 # install shield installations found
      StrCpy $CBRUNINSTALL "no"
StrCpy $5 1
SectionGetFlags $0  $R0 
IntOp $R0 $R0 & ${SF_SELECTED} 
${If} $R0 == ${SF_SELECTED} 

  StrCpy $R0 "Following CBR Tools version(s) are already installed: "
  StrCpy $R1 ""
  StrCpy $R2 "" 
  StrCpy $R3 ""
  StrCpy $6 ""
  StrCpy $1 0
  loop:           #check if there is install shield installation
    EnumRegKey $2 HKLM "${RELTOOLSKEY}" $1
    StrCmp $2 "" checkNsis
    IntOp $1 $1 + 1
    readregstr $3 HKLM "${RELTOOLSKEY}\$2" "Path"
    StrCpy $R3 "1"
    StrCpy $R0 "$R0$\r$\nVersion $2 is already installed in $3."
    GoTo loop
  
  checkNsis:    # check if there is NSIS installation
  StrCpy $4 $1  
  StrCpy $1 0
  loop1:
    EnumRegKey $2 HKLM "${CBRTOOLSKEY}" $1
    StrCmp $2 "" done
    IntOp $1 $1 + 1
    readregstr $3 HKLM "${CBRTOOLSKEY}\$2" "Path"
    StrCpy $R2 "$R2-$2-"  
    StrCpy $R0 "$R0$\r$\nVersion $2 is already installed in $3."
    GoTo loop1
  
  done:
    IntOp $1 $1 + $4
    ${If} $1 > 0
   
    ${If} $SILENT == "true"
    ${AndIf} $DIALOGS == "false"
      !insertmacro LogStopMessage "CBRTools (Release Tools) already installed. Stopping installation.\
      $\r$\nPlease uninstall CBRTools (Rlease Tools) before continuing " "${OTHER_ERROR}"
    ${Else}
      MessageBox MB_YESNOCANCEL "$R0$\r$\n\
        Do you want to uninstall previous installation(s) before continuing?" IDYES continue IDNO finish 
    ${EndIf} 

      cancel:
      StrCpy $5 0
      GoTo finish
      
      
      continue:
      StrCpy $CBRUNINSTALL "yes"
      
    ${EndIf}
  finish:  
${EndIf}
  StrCpy $0 "$5"
  pop $R3
  pop $R2
  pop $R1
  pop $R0
  pop $6
  pop $5
  pop $4
  pop $3
  pop $2
  pop $1
  exch $0
FunctionEnd

Function CBRToolsPreviousUninstall
exch $0 
push $1 # counter
push $2 # version
push $3 # uninstall string
push $4
push $5

push $6

push $R0 # $ReplaceVer
push $R1 # $ReplaceKey

push $R2 # nsis installations found
push $R3 # install shield installations found

${If} $CBRUNINSTALL == "yes"
  #uninstall
  #Uninstall first all NSIS installations
  StrCpy $1 0
  EnumRegKey $2 HKLM "${CBRTOOLSKEY}" $1
  ${While} $2 != ""
        ReadRegStr $3 HKLM "${PRODUCT_UNINST_KEY}\Symbian CBR Tools $2" "UninstallString"
        ReadRegStr $4 HKLM "${CBRTOOLSKEY}\$2" "Path"
        ${If} $3 == "" #no uninstaller found
          StrCpy $6 "error"
        ${Else}
          IfFileExists $3 +2 0
          StrCpy $6 "error"
        ${EndIf}
        
          ${If} $SILENT == "false" 
          ${OrIf} $DIALOGS == "true"
            Banner::show /NOUNLOAD /set 76 "Removing previous installation $2..." "Please wait."
          ${EndIf}
          IfFileExists "$4\reltools.ini" 0 +3
           CreateDirectory "$TEMP\sitk\$2\"
           CopyFiles /SILENT "$4\reltools.ini" "$TEMP\sitk\$2\"
          ${If} $6 == "error"
            !insertmacro CBRToolsNSISManualUninstall "$2" "$4"
          ${Else}
            ClearErrors
            ExecWait '"$3" /S _?=$4\' ;$3: Uninstaller $4:installation path
            IfErrors +2 0
            RMDir /r $4 ; delete installation folder
          ${EndIf}
          IfFileExists "$TEMP\sitk\$2\reltools.ini" 0 +4
           CreateDirectory "$4"        
           CopyFiles /SILENT "$TEMP\sitk\$2\reltools.ini" "$4" 
           RMDir /r "$TEMP\sitk\$2\"
          ${If} $SILENT == "false" 
          ${OrIf} $DIALOGS == "true"
            Banner::destroy
          ${EndIf}

     #IntOp $1 $1 + 1
     EnumRegKey $2 HKLM "${CBRTOOLSKEY}" $1
  ${EndWhile}

  loop:           #check if there is install shield installation


  StrCpy $1 0
  StrCpy $R3 0
  EnumRegKey $2 HKLM "${RELTOOLSKEY}" $1 
  ${While} $2 != ""
    ReadRegStr $3 HKLM "${RELTOOLSKEY}\$2" "Path"
    
           CreateDirectory "$TEMP\sitk\InstallShield\$2\"
           IfFileExists "$3\reltools.ini" 0 +2
           CopyFiles /SILENT "$3\reltools.ini" "$TEMP\sitk\InstallShield\$2\"
           FileOpen $4 "$TEMP\sitk\InstallShield\$2\dir.txt" "w"
           FileWrite $4 "$3"
           FileClose $4
    StrCpy $R3 "1"
    IntOp $1 $1 + 1
    EnumRegKey $2 HKLM "${RELTOOLSKEY}" $1
  ${EndWhile}    
  
  
      ${If} $R3 == "1" #Look for install shield installations to uninstall
        StrCpy $1 0
        StrCpy $6 ""
        EnumRegKey $2 HKLM "${PRODUCT_UNINST_KEY}" $1
        ${While} $2 != "" 
           ReadRegStr $3 HKLM "${PRODUCT_UNINST_KEY}\$2" "DisplayName"
           ${If} $3 == "Release Tools"
              ${ExitWhile}
           ${EndIf}
           IntOp $1 $1 + 1    
           EnumRegKey $2 HKLM "${PRODUCT_UNINST_KEY}" $1
        ${EndWhile}
        
        ${If} $2 == ""
          StrCpy $6 "error"
        ${ElseIf} $3 == "Release Tools"
          ReadRegStr $3 HKLM "${PRODUCT_UNINST_KEY}\$2" "UninstallString"
          ${If} $3 == ""
            StrCpy $6 "error"
          ${Else}
            MessageBox MB_OK "InstallShield will be launched, please select <remove> and follow the wizard" /SD IDOK
            ExecWait $3
          ${EndIf}
        ${EndIf}
        
        FindFirst $0 $4 "$TEMP\sitk\InstallShield\*"
        ${While} $4 != ""
            ${If} $4 != "."
            ${AndIf} $4 != ".."
              IfFileExists "$TEMP\sitk\InstallShield\$4\dir.txt" 0 notfound

              FileOpen $3 "$TEMP\sitk\InstallShield\$4\dir.txt" "r"
              FileRead $3 $1
              FileClose $3
              
              ${If} $6 == "error"
                !insertmacro CBRToolsISManualUninstall "$4" "$1" "$2"
              ${EndIf}
              
              IfFileExists "$TEMP\sitk\InstallShield\$4\reltools.ini" 0 notfound
              CreateDirectory "$1" 
              CopyFiles /SILENT "$TEMP\sitk\InstallShield\$4\reltools.ini" "$1" 
              notfound:
              
            ${EndIf}
            FindNext $0 $4
        ${EndWhile}
        FindClose $0   

      ${EndIf}
      #uninstal
${EndIF}

  pop $R3
  pop $R2
  pop $R1
  pop $R0
  pop $6
  pop $5
  pop $4
  pop $3
  pop $2
  pop $1
  pop $0
FunctionEnd

!macro CBRToolsPreconfigure inSectionName
  push "${inSectionName}"
  call CBRToolsPreConfigureFunction
!macroend
