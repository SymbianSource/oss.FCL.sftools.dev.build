/*
* Copyright (c) 2007-2008 Nokia Corporation and/or its subsidiary(-ies).
* All rights reserved.
* This component and the accompanying materials are made available
* under the terms of the License "Eclipse Public License v1.0"
* which accompanies this distribution, and is available
* at the URL "http://www.eclipse.org/legal/epl-v10.html".
*
* Initial Contributors:
* Nokia Corporation - initial contribution.
*
* Contributors:
*
* Description: 
*
*/

//javac CheckTools.java -source 1.3 -target 1.3

import java.io.*;

public class CheckTools
{
    public static void main(String[] args)
    {
        try {
            Runtime runtime = Runtime.getRuntime();
            
            Process toolProcess = runtime.exec("python -V");
            InputStream err = toolProcess.getErrorStream();
            String output = toString(err).trim();
            if (!(output.startsWith("Python 2.5")) && !(output.startsWith("Python 2.6")))
            {
                System.out.println("Error: Python 2.5/2.6 not found");
                System.out.println(output);
            }
            
            toolProcess = runtime.exec("java -version");
            err = toolProcess.getErrorStream();
            if (!(toString(err).trim().startsWith("java version \"1.6")))
            {
                System.out.println("Error: Java 6 not found");
                System.out.println(err);
            }
            
//            toolProcess = runtime.exec("ant -version");
//            err = toolProcess.getErrorStream();
//            if (!(toString(err).trim().startsWith("Apache Ant version 1.7.0")))
//            {
//                System.out.println("Error: Ant 1.7.0 not found");
//                System.out.println(err);
//            }
        } catch (Exception e) { System.out.println(e); }
    }
    
    private static String toString(InputStream inputStream) throws IOException
    {
        byte[] buffer = new byte[4096];
        OutputStream outputStream = new ByteArrayOutputStream();
         
        while (true) {
            int read = inputStream.read(buffer);
            
            if (read == -1) {
                break;
            }
         
            outputStream.write(buffer, 0, read);
        }
         
        outputStream.close();
        inputStream.close();
         
        return outputStream.toString();
    }

}


