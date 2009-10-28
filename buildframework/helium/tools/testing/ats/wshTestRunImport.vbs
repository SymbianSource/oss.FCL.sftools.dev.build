'
' WScript that will invoke the test run execute functionality at ATS3 web server without installing any ATS3
' specific programs on the local PC.
'
' Copies the test run zip into ATS3 server over HTTP before starting the test run
'
' Usage cscript wshRunX.vbs <username> <password> <server hostname> <path to testDrop.zip>
'

' Get the command line arguments
set args = WScript.Arguments

' Check that all arguments have been specified
Set objShell = WScript.CreateObject("WScript.Shell")
Set env = objShell.Environment("Process")
checkEnvVars(env)

' Invoke the web application and write the result to stdOut
WScript.StdOut.Write doTestRunX(env("ats3.username"), env("ats3.password"), env("ats3.host"), env("ats3.pathToDrop"), URLEncode( env("ats3.schedule") ))

' Quit the script
Wscript.Quit

Function checkEnvVars(env)
	if env("ats3.username") = "" then
		WScript.Echo "Environment variable ats3.username not specified"
		WScript.Quit 1
	elseif env("ats3.password") = "" then
		WScript.Echo "Environment variable ats3.password not specified"
		WScript.Quit 1
	elseif env("ats3.host") = "" then
		WScript.Echo "Environment variable ats3.host not specified"
		WScript.Quit 1		
	elseif env("ats3.pathToDrop") = "" then
		WScript.Echo "Environment variable ats3.pathToDrop not specified"
		WScript.Quit 1	
	end if
End Function

' Invoke the ATS3 web application in given host with the specified username, password and file path
Function doTestRunX(uname, password, hostName, pathToDrop, schedule)
    On Error Resume Next
    
	'If the given hostname contain port, use it otherwise use the default 8080
        if(InStr(1, hostName, ":", VBTEXTCOMPARE) = 0) then
        	hostName = hostName & ":8080"
        end if        

	Set objxmlHTTP = CreateObject("MSXML2.ServerXMLHTTP.3.0")
	objxmlHTTP.setTimeouts 0,60000,3600000,3600000
	
	Call objxmlHTTP.open("POST", "http://" & hostName & "/ats3/XTestRunExecute.do?username=" & uname & "&password=" & password & "&schedule=" & schedule, False)
	objxmlHTTP.setRequestHeader "Content-Type", "multipart/form-data; boundary=AaB03x"
		
	Set BinaryStream = CreateObject("ADODB.Stream")
	BinaryStream.Type = 1
	BinaryStream.Open
	BinaryStream.LoadFromFile pathToDrop
	If Err.Number <> 0 Then
		WScript.Echo "Error loading file: " + pathToDrop
    	WScript.Quit 1
	End if
	
	objxmlHTTP.Send BuildFormData(BinaryStream.Read,"AaB03x","testDrop.zip","testDrop")
	If Err.Number <> 0 Then
		WScript.Echo "Error sending data to server: " + hostName
    	WScript.Quit 1
	End if	
	
    BinaryStream.Close

    if objxmlHTTP.status = 200 then
    	doTestRunX = objxmlHTTP.ResponseText
    else
        WScript.Echo "Error importing test run: " + objxmlHTTP.ResponseText
    	WScript.Quit 1
	end if
End Function

Function BuildFormData(FileContents, Boundary, FileName, FieldName)
  Dim FormData, Pre, Po
  Const ContentType = "application/upload"
  
  'The two parts around file contents In the multipart-form data.
  Pre = "--" + Boundary + vbCrLf + mpFields(FieldName, FileName, ContentType)
  Po = vbCrLf + "--" + Boundary + "--" + vbCrLf
  
  'Build form data using recordset binary field
  Const adLongVarBinary = 205
  Dim RS: Set RS = CreateObject("ADODB.Recordset")
  RS.Fields.Append "b", adLongVarBinary, Len(Pre) + LenB(FileContents) + Len(Po)
  RS.Open
  RS.AddNew
    Dim LenData
    'Convert Pre string value To a binary data
    LenData = Len(Pre)
    RS("b").AppendChunk (StringToMB(Pre) & ChrB(0))
    Pre = RS("b").GetChunk(LenData)
    RS("b") = ""
    
    'Convert Po string value To a binary data
    LenData = Len(Po)
    RS("b").AppendChunk (StringToMB(Po) & ChrB(0))
    Po = RS("b").GetChunk(LenData)
    RS("b") = ""
    
    'Join Pre + FileContents + Po binary data
    RS("b").AppendChunk (Pre)
    RS("b").AppendChunk (FileContents)
    RS("b").AppendChunk (Po)
  RS.Update
  FormData = RS("b")
  RS.Close
  BuildFormData = FormData
End Function

Function mpFields(FieldName, FileName, ContentType)
  Dim MPTemplate 'template For multipart header
  MPTemplate = "Content-Disposition: form-data; name=""{field}"";" + _
   " filename=""{file}""" + vbCrLf + _
   "Content-Type: {ct}" + vbCrLf + vbCrLf
  Dim Out
  Out = Replace(MPTemplate, "{field}", FieldName)
  Out = Replace(Out, "{file}", FileName)
  mpFields = Replace(Out, "{ct}", ContentType)
End Function

Function StringToMB(S)
  Dim I, B
  For I = 1 To Len(S)
    B = B & ChrB(Asc(Mid(S, I, 1)))
  Next
  StringToMB = B
End Function

Function URLEncode(data)
	data = replace(data,"\","/")
	data = replace(data,"$","%24")
	data = replace(data,"&","%26")
	data = replace(data,"+","%2B")
	data = replace(data,",","%2C")
	data = replace(data,"/","%2F")
	data = replace(data,":","%3A")
	data = replace(data,";","%3B")
	data = replace(data,"=","%3D")
	data = replace(data,"?","%3F")
	data = replace(data,"@","%40")
	URLEncode = data
End Function