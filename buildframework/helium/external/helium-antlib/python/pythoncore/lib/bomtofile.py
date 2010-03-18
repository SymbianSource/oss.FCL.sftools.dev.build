#============================================================================ 
#Name        : bomtofile.py
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

class BOMWriter(object):
    """
    Read BOM and output in text
    """
    def __init__(self, session, project_name, project, output_dir):
        self.project_name = project_name
        self.project = project
        self.output_dir = output_dir
        self.session = session
      
    def writeprojects(self):
        fileout = file(self.output_dir + '/' + self.project_name + '_projects.txt', 'w')
        
        i = 1
        for project in self.project.baseline:
            fileout.write(str(i) + ") " + str(project) + "\n")
            
            i += 1
        fileout.close()
        
    def writebaselines(self):
        fileout = file(self.output_dir + '/' + self.project_name + '_baselines.txt', 'w')    
        
        i = 1
        for project in self.project.baseline:
            fileout.write(str(i) + ") " + str(project) + "\n")
            
            cmproject = self.session.create(str(project))
            
            try:
                baseline = str(cmproject.baseline).strip()
                if baseline == "None":
                    fileout.write(str(i) + ") " + str(project) + "\n")
                else:
                    fileout.write(str(i) + ") " + baseline + "\n")
                i += 1
            except Exception, ex:
                print ex
        fileout.close()
            
    def writetasks(self):
        if self.project.xml_properties.has_key("task"):
            fileout = file(self.output_dir + '/' + self.project_name + '_tasks.txt', 'w')
            
            i = 1
            for task in self.project.task:
                fileout.write(str(i) + ") Task " + str(task) + "\n")
                i += 1
            fileout.close()



