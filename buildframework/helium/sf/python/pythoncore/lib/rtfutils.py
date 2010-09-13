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
""" rtf utilis"""

# pylint: disable=R0201

import csv
import os
import PyRTF
import StringIO
import re
import logging

class RTFUtils(object):
    """ RTF utility module """
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
        
        self.rtftable_file(errors, output, tagtoreplace, template)
        
        errors.close()
        output.close()
        template.close()
        
    def rtftable_file(self, errors, output, tagtoreplace, template):
        """rtf table"""
        PyRTF.Elements.StandardColours.append(PyRTF.PropertySets.Colour('NokiaBlue', 153, 204, 255))
       
        d_r = PyRTF.Renderer()
        doc     = PyRTF.Document()
        s_s      = doc.StyleSheet
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
                style = s_s.ParagraphStyles.Heading2
            else:
                style = s_s.ParagraphStyles.Normal
            
            # Handle each value from the row
            rowcell = []
            
            for value in row:
                cell = PyRTF.Text( value )
                rowcell.append(PyRTF.Cell( PyRTF.Paragraph(style, cell) ))
            table.AddRow( *rowcell )
    
        section.append( table )
        string = StringIO.StringIO()
        d_r.Write( doc, string )
                
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
        
        self.rtfimage_file(image, output, tagtoreplace, template)
        
        output.close()
        template.close()
    
    def rtfimage_file(self, image, output, tagtoreplace, template):
        """rtf image"""
        temp_file = 'image_temp.rtf'
        
        d_r = PyRTF.Renderer()
        doc = PyRTF.Document()
        _ = doc.StyleSheet
        section = PyRTF.Section()
        doc.Sections.append( section )
    
        section.append( PyRTF.Image( image ) )
        
        tempOutput = file( temp_file, 'w' )
        d_r.Write( doc, tempOutput )
        
        tempOutput = file( temp_file, 'rb' )
        
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
        
        os.remove(temp_file)
        
    def rtfconvert(self, inputfilename, outputfilename):
        """ Converts a property file to be RTF link syntax """
        inputfile = file( inputfilename, 'r' )
        outputfile = file( outputfilename, 'w' )
        
        self.rtfconvert_file(inputfile, outputfile)
        
        inputfile.close()
        outputfile.close()
        
    def rtfconvert_file(self, inputfile, outputfile):
        """rtf convert"""
        ppp = re.compile(r'(.+=)((\\\\|http|\.\\|ftp)(.+))')
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
                
            
            newline = ppp.sub('\g<1>{_backslash_field{_backslash_*_backslash_fldinst HYPERLINK \g<2>}}', newline)
            
            newline = newline.replace('_backslash_', r'\\')
            
            outputfile.write(newline)
