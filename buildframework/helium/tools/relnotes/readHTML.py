#============================================================================ 
#Name        : readHTML.py 
#Part of     : Helium 

#Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
#All rights reserved.
#This component and the accompanying materials are made available
#under the terms of the License "Eclipse Public License v1.0"
#which accompanies this distribution, and is available
#at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
#Initial Contributors:
#Nokia Corporation - initial contribution.
#
#Contributors:
#
#Description:
#===============================================================================

# Name: readHTML.py
# Synopsis: This script creates a CSV file from the Log File Summary (.html)

import htmllib
import sys
import formatter
import re

class HTMLComponent(object):
    """
    Represents a component in the log file summary
    """
    def __init__(self):
        self._name = ''
        self._errorCount = 0
        self._warningCount = 0
        
    def getCSV(self):
        return self._name + ',' + str(self._errorCount) + ',' + str(self._warningCount)
        
    def __setName(self, n):
        self._name = n
    def __setErrorCount(self, n):
        self._errorCount = n
    def __setWarningCount(self, n):
        self._warningCount = n
        
    name = property(None, __setName)    
    errorCount = property(None, __setErrorCount)
    warningCount = property(None, __setWarningCount)

class LogHTMLParser(htmllib.HTMLParser):
    """
    Parse the scan2log HTML file into CSV
    """
    def __init__(self, verbose=0):
        self.anchors = {}
        f = formatter.NullFormatter()
        htmllib.HTMLParser.__init__(self, f, verbose)
        
        self.state = -1 #represents column, 0 is first
        self.printFlag = False
        self.errorCount = 0
        self.warningCount = 0
        
        self._components = []
        self.component = None
        
    def __getComponents(self):
        return self._components
        
    components = property(__getComponents)
        
    def handle_data(self, text):
        text = text.strip()
        
        #ignore plain text links that appear eg. [9]
        p = re.compile('\[[0-9]*\]')
        if not text or p.match(text):
            return
      
        #start of area to parse
        if (text == 'Component'):
            self.state = 0
  
        #end of area to parse
        if (text == 'By Command'):
            self.state = -1
          
        #reset column if we get lost
        #if (self.state > 0 and not text.isdigit()):
        #    self.state = 0
        
        if (self.state == 0):
            self.component = HTMLComponent()
            self.component.name = text
        if (text.isdigit() and self.state == 2):
            self.errorCount += int(text)
            self.component.errorCount = text
        if (text.isdigit() and self.state == 3):
            self.warningCount += int(text)
            self.component.warningCount = text
            
        #if there are more than/ equal 5 errors or 50 warnings we print this row
        if (text.isdigit() and ((self.state == 2 and (int(text) >= 5)) or 
          (self.state == 3 and (int(text) >= 50)))):
            self.printFlag = True

        if (self.state == 5):
            if (self.printFlag):                
                self.components.append(self.component)
                
            self.printFlag = False
          
        if (self.state >= 0):
            self.state += 1
            self.state %= 6
        
def main():    
    if len(sys.argv) != 3:
        print "Usage: readHTML.pl LogFile.html errors.csv"
        sys.exit(1)
    
    parser = LogHTMLParser()
    
    inputFile = file( sys.argv[1], 'rb' )
    outFile = file( sys.argv[2], 'w' )
    
    outFile.write("Component,Errors (more than 5),Warnings (more than 50)\n")

    parser.feed(inputFile.read())

    for c in parser.components:
        outFile.write(c.getCSV() + "\n")
    
    outFile.write("Total," + str(parser.errorCount) + "," + str(parser.warningCount) + "\n")
    
    inputFile.close()
    outFile.close()
    parser.close()
        
if __name__ == '__main__' :
    main()