#============================================================================ 
#Name        : rtfutils.py 
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

import csv
import os
import PyRTF
import StringIO
import re
import logging

class RTFUtils(object):
  
    def __init__(self, template):
        """ template would be a RTF file to modify """
        self.template = template
        
        self.logger = logging.getLogger('test.relnotes')
        logging.basicConfig(level=logging.DEBUG)
        
    def rtftable(self, errorsfilename, outputfilename, tagtoreplace):
        """ Create a .rtf file from the errors.csv file. """
        
        errors = file(errorsfilename, 'rb')
        template = file(self.template, 'rb' )
        output = file(outputfilename, 'w' )
        
        self._rtftable(errors, output, tagtoreplace, template)
        
        errors.close()
        output.close()
        template.close()
        
    def _rtftable(self, errors, output, tagtoreplace, template):
        PyRTF.Elements.StandardColours.append(PyRTF.PropertySets.Colour('NokiaBlue', 153, 204, 255))    
       
        DR = PyRTF.Renderer()
        doc     = PyRTF.Document()
        ss      = doc.StyleSheet
        section = PyRTF.Section()
        doc.Sections.append( section )
    
        table = PyRTF.Table( PyRTF.TabPS.DEFAULT_WIDTH * 7,
                             PyRTF.TabPS.DEFAULT_WIDTH * 3,
                             PyRTF.TabPS.DEFAULT_WIDTH * 3 )
                       
        reader = csv.reader(errors)
        
        style = None    
        for row in reader:
            assert len(row) == 3
            
            if style == None:
                style = ss.ParagraphStyles.Heading2
            else:
                style = ss.ParagraphStyles.Normal
            
            # Handle each value from the row
            rowcell = []
            
            for value in row:           
                cell = PyRTF.Text( value )
                rowcell.append(PyRTF.Cell( PyRTF.Paragraph(style, cell) ))
            table.AddRow( *rowcell )
    
        section.append( table )
        string = StringIO.StringIO()
        DR.Write( doc, string )
                
        keep = ''
        for line in string.getvalue().splitlines():
            if keep != '' or line.startswith('{\\trowd'):
                keep += line
                    
        #remove last '}'
        keep = keep[0:-1]
        
        for line in template:
            line = line.replace(tagtoreplace, keep)
            output.write(line)
    
    def rtfimage(self, image, outputfilename, tagtoreplace):
        """ Replaces tagtoreplace in a RTF file with a image """
        
        template = file(self.template, 'rb' )
        output = file(outputfilename, 'w' )
        
        self._rtfimage(image, output, tagtoreplace, template)
        
        output.close()
        template.close()
    
    def _rtfimage(self, image, output, tagtoreplace, template):
        TEMP_FILE = 'image_temp.rtf'
        
        DR = PyRTF.Renderer()
        doc = PyRTF.Document()
        ss = doc.StyleSheet
        section = PyRTF.Section()
        doc.Sections.append( section )
    
        section.append( PyRTF.Image( image ) )    
        
        tempOutput = file( TEMP_FILE, 'w' )
        DR.Write( doc, tempOutput )
        
        tempOutput = file( TEMP_FILE, 'rb' )
        
        keep = ''
        for line in tempOutput:
            if keep != '':
                keep += line
            elif line.startswith('{\pict'):
                keep = line
        
        #remove last '}'
        keep = keep[0:-1]
        
        tempOutput.close()
        
        for line in template:
            line = line.replace(tagtoreplace, keep)
            output.write(line)
        
        os.remove(TEMP_FILE)
        
    def rtfconvert(self, inputfilename, outputfilename):
        """ Converts a property file to be RTF link syntax """
        inputfile = file( inputfilename, 'r' )
        outputfile = file( outputfilename, 'w' )
        
        self._rtfconvert(inputfile, outputfile)
        
        inputfile.close()
        outputfile.close()
        
    def _rtfconvert(self, inputfile, outputfile):
        p = re.compile(r'(.+=)((\\\\|http|\.\\|ftp)(.+))')
        for line in inputfile:
            newline = line
            
            #fix bad links generated in ant
            if newline.count('\\\\')>0:
                newline = newline.replace('//','\\')
                newline = newline.replace('/','\\')
                
            if "\\n" in newline:
                newline = newline.replace("\\n", " \\\\line ")
            else:
                newline = newline.replace('\\','\\\\\\\\\\\\\\\\')
                
            
            newline = p.sub('\g<1>{_backslash_field{_backslash_*_backslash_fldinst HYPERLINK \g<2>}}', newline)
            
            newline = newline.replace('_backslash_', r'\\')
            
            outputfile.write(newline)
