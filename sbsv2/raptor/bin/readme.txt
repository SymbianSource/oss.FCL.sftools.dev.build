The distribution of the file is based on the follwing article ID:326922 Rev.5 from Microsoft Knowledge Base.

http://support.microsoft.com/kb/326922


Article ID: 326922 - Last Review: March 19, 2008 - Revision: 5.0
Redistribution of the shared C runtime component in Visual C++


SUMMARY

When you build an application in Microsoft Visual Studio, and the application uses the C run-time libraries (CRT), distribute the appropriate CRT DLL from the following list with your application:

    * Msvcr90.dll for Microsoft Visual C++ 2008
    * Msvcr80.dll for Microsoft Visual C++ 2005
    * Msvcr71.dll for Microsoft Visual C++ .NET 2003 with the Microsoft .NET Framework 1.1
    * Msvcr70.dll for Microsoft Visual C++ .NET 2002 with the Microsoft .NET Framework 1.0

For Msvcr70.dll or for Msvcr71.dll, you should install the CRT DLL into your application program files directory. You should not install these files into the Windows system directories. For Msvcr80.dll and for Msvcr90.dll, you should install the CRT as Windows side-by-side assemblies.

MORE INFORMATION

The shared CRT DLL has been distributed by Microsoft in the past as a shared system component. This may cause problems when you run applications that are linked to a different version of the CRT on computers that do not have the correct versions of the CRT DLL installed. This is commonly referred to as the "DLL Conflict" problem.

To address this issue, the CRT DLL is no longer considered a system file, therefore, distribute the CRT DLL with any application that relies on it. Because it is no longer a system component, install it in your applications Program Files directory with other application-specific code. This prevents your application from using other versions of the CRT library that may be installed on the system paths.

Visual C++ .NET 2003 or Visual C++ .NET 2002 installs the CRT DLL in the System32 directory on a development system. This is installed as a convenience for the developer. Otherwise, all projects that are built with Visual C++ that link with the shared CRT require a copy of the DLL in the build directory for debugging and execution. Visual C++ 2005 and Visual C++ 2008 install the CRT DLL as a Windows side-by-side assembly on Windows XP and later operating systems. Windows 2000 does not support side-by-side assemblies. On Windows 2000, the CRT DLL is installed in the System32 directory.

When you distribute applications that require the Shared CRT library in the CRT DLL, we recommend that you use the CRT.msm merge module that is included with Visual C++ instead of directly distributing the DLL file.

Windows side-by-side assemblies
Msvcr80.dll with Visual C++ 2005 and Msvcr90.dll with Visual C++ 2008 are redistributed as Windows side-by-side assemblies except on Windows 2000. You should install these versions of the CRT on target computers by running the Vcredist_x86.exe application that is included with Visual Studio. There are installers for the x64 and IA-64 platforms also. Alternatively, you can use the CRT msm merge module that is supplied with Visual Studio to package the CRT installer into your own setup application. This will make the CRT available as a shared assembly to all applications because it is installed in the \windows\winsxs directory on supported operating systems. 
