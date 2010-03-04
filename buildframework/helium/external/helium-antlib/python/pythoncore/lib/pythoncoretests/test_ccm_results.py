#============================================================================ 
#Name        : test_ccm_results.py 
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

""" Test cases for ccm python toolkit.

"""
import unittest
import sys
import ccm
import os
import logging


logger = logging.getLogger('test.ccm_results')
logging.basicConfig(level=logging.INFO)

class CounterHandler(logging.Handler):
    def __init__(self, level=logging.NOTSET):
        logging.Handler.__init__(self, level)
        self.warnings = 0
        self.errors = 0
        self.infos = 0
    
    def emit(self, record):
        """ Handle the count the errors. """
        if record.levelno == logging.INFO:
            self.infos += 1
        elif record.levelno == logging.WARNING:
            self.warnings += 1
        elif record.levelno == logging.ERROR:
            self.errors += 1

class MockResultSession(ccm.AbstractSession):
    """ Fake session used to test Result"""
    def __init__(self, behave = {}, database="fakedb"):
        ccm.AbstractSession.__init__(self, None, None, None, None)
        self._behave = behave
        self._database = database
    
    def database(self):
        return self._database
    
    def execute(self, cmdline, result=None):
        if result == None:
            result = ccm.Result(self)        
        if self._behave.has_key(cmdline):
            result.statuserrors = 0  
            result.output = self._behave[cmdline]
        else:
            result.status = -1  
        return result

    
class ResultTest(unittest.TestCase):
    """ Testing Results parsers. """
    def test_Result(self):
        """ Test result. """
        result = ccm.Result(None)
        result.output = u"Nokia"
        assert result.output == u"Nokia"

    def test_Result_unicode_character(self):
        """ Test result with unicode character. """
        result = ccm.Result(None)
        result.output = u"Nokia\xc2"
        print result.output.encode('ascii', 'replace')
        assert result.output == u"Nokia?"

    def test_Result_str(self):
        """ Test result from str. """
        result = ccm.Result(None)
        result.output = "Nokia"
        assert result.output == "Nokia"

    def test_Result_str_not_ascii(self):
        """ Test result from str with not ascii. """
        result = ccm.Result(None)
        result.output = "Noki\xe4"
        print result.output
        assert result.output == "Noki"

   
    def test_ObjectListResult(self):
        behave = { 'test_ObjectListResult': """mc-mc_0638:project:vc1s60p1#1
mc-mc_4031_0642:project:vc1s60p1#1
mc-mc_4031_0646:project:vc1s60p1#1
mc-mc_4031_0650:project:vc1s60p1#1
mc-mc_4031_0702:project:vc1s60p1#1
mc-mc_4031_0704:project:vc1s60p1#1
mc-mc_4031_0706:project:vc1s60p1#1
mc-mc_4031_0706_v2:project:vc1s60p1#1
mc-mc_4032_0708:project:vc1s60p1#1
mc-mc_4032_0710:project:vc1s60p1#1
mc-mc_4032_0712:project:vc1s60p1#1
mc-mc_4032_0714:project:vc1s60p1#1
mc-mc_4032_0716:project:vc1s60p1#1
mc-mc_4032_0718:project:vc1s60p1#1
mc-mc_4032_0720:project:vc1s60p1#1
mc-mc_4032_0722:project:vc1s60p1#1
mc-mc_4032_0724:project:vc1s60p1#1
mc-mc_4032_0726.lum.09:project:vc1s60p1#1
mc-mc_4032_0726:project:vc1s60p1#1
mc-mc_4032_0728:project:vc1s60p1#1
mc-mc_4032_0730:project:vc1s60p1#1
mc-mc_4032_0732:project:vc1s60p1#1
mc-mc_4032_0734:project:vc1s60p1#1
mc-mc_4032_0736:project:vc1s60p1#1

"""}
        session = MockResultSession(behave)
        result = session.execute('test_ObjectListResult', ccm.ObjectListResult(session))
        assert len(result.output) == 24, "output doesn't contains the right number of result project."
        for o in result.output:
            assert o.type == 'project'
            assert o.name == 'mc'

    def test_WorkAreaInfoResult(self):
        behave = { 'test_WorkAreaInfoResult': """
Project                                            Maintain Copies Relative Time Translate Modify Path
-------------------------------------------------------------------
mc_5132_build-fa1f5132#loc_0734:project:jk1f5132#1 TRUE     TRUE   TRUE     TRUE TRUE      FALSE  'E:\\WBERNARD\\ccm_wa\\fa1f5132\\mc-fa1f5132#loc_0734\\mc\\mc_build'

"""}
        session = MockResultSession(behave)
        result = session.execute('test_WorkAreaInfoResult', ccm.WorkAreaInfoResult(session))
        print result.output
        print result.output['path']
        assert str(result.output['project']) == "mc_5132_build-fa1f5132#loc_0734:project:jk1f5132#1", "wrong project name."
        assert result.output['maintain'] == True, "maintain value is wrong."
        assert result.output['copies'] == True, "copies value is wrong."
        assert result.output['relative'] == True, "relative value is wrong."
        assert result.output['time'] == True, "time value is wrong."
        assert result.output['translate'] == True, "translate value is wrong."
        assert result.output['modify'] == False, "modify value is wrong."
        assert result.output['path'] == "E:\\WBERNARD\\ccm_wa\\fa1f5132\\mc-fa1f5132#loc_0734\\mc\\mc_build", "path value is wrong."
            
    def test_FinduseResult(self):
        """ Test the parsing of the FinduseResult class. """
        behave = { 'test_FinduseResult': """
Ibusal_internal-fa1f5132#wbernard16:project:jk1imeng#1 working wbernard project Ibusal_internal jk1imeng#1 fa1f5132#2561
        IBUSAL_RapidoYawe\Ibusal_internal-fa1f5132#wbernard16@IBUSAL_RapidoYawe-fa1f5132#wbernard16:project:jk1imeng#1
        
"""}
        session = MockResultSession(behave)
        object = session.create("Ibusal_internal-fa1f5132#wbernard16:project:jk1imeng#1")
        result = session.execute('test_FinduseResult', ccm.FinduseResult(object))
        print result.output
        assert len(result.output) == 1
        assert result.output[0]['project'].objectname == "IBUSAL_RapidoYawe-fa1f5132#wbernard16:project:jk1imeng#1"
        assert result.output[0]['path'] == "IBUSAL_RapidoYawe"
          
          
    def test_read_ccmwaid_info(self):
        """ Testing read_ccmwaid_info, open a _ccmwaid.inf file and check the extracted data. """
        data = ccm.read_ccmwaid_info(os.path.join(os.environ['TEST_DATA'], 'data', 'test_ccmwaid.inf'))
        logger.debug(data)
        assert data['database'] == "jk1f5132"
        assert data['objectname'] == "sa1spp#1/project/S60/jk1f5132#wbernard"

    def test_update_result(self):
        """ Validating UpdateResult."""        
        behave = {'test_update' :"""Starting update process...

Updating project 'Cartman-wbernard5:project:tr1test1#1' from object version 'Cartman-wbernard5:project:tr1test1#1'...
Refreshing baseline and tasks for project grouping 'My cartman/060530_v2 Collaborative Development Projects'.
Replacing tasks in folder tr1test1#2008
  Contents of folder tr1test1#2008 have not changed.
Replacing tasks in folder tr1test1#2009
  Contents of folder tr1test1#2009 have not changed.
Added the following tasks to project grouping 'My cartman/060530_v2 Collaborative Development Projects':
    Task tr1test1#3426: Update Cartman subprojects
    Task tr1test1#3429: Create Kyle subprojects
    Task tr1test1#3430: Add Kyle02 subpr hierarchy
    Task tr1test1#3431: Add a file to cartman_sub_sub02


Updating project 'Cartman_sub01-wbernard3:project:tr1test1#1', reselecting root object version...
Update for 'Cartman-wbernard5:project:tr1test1#1' complete with 0 out of 3 objects replaced.

Updating project 'Cartman_sub_sub01-wbernard3:project:tr1test1#1', reselecting root object version...
Update for 'Cartman_sub01-wbernard3:project:tr1test1#1' complete with 0 out of 2 objects replaced.

Updating project 'Cartman_sub02-wbernard3:project:tr1test1#1', reselecting root object version...
Update for 'Cartman_sub_sub01-wbernard3:project:tr1test1#1' complete with 0 out of 1 objects replaced.
    'Cartman_sub02-2:dir:tr1test1#1' replaces 'Cartman_sub02-1:dir:tr1test1#1' under 'Cartman_sub02-wbernard3:project:tr1test1#1'.

Updating project 'Cartman_sub_sub02-wbernard6:project:tr1test1#1', reselecting root object version...
Update for 'Cartman_sub02-wbernard3:project:tr1test1#1' complete with 2 out of 2 objects replaced.
    Subproject 'Cartman_sub_sub02-wbernard6:project:tr1test1#1' is now bound under 'Cartman_sub02-2:dir:tr1test1#1'.
    'Cartman_sub_sub02-2:dir:tr1test1#1' replaces 'Cartman_sub_sub02-1:dir:tr1test1#1' under 'Cartman_sub_sub02-wbernard6:project:tr1test1#1'.
Update for 'Cartman_sub_sub02-wbernard6:project:tr1test1#1' complete with 2 out of 2 objects replaced.
    'xzx.iby-1:epocrom:tr1test1#1' is now bound under 'Cartman_sub_sub02-2:dir:tr1test1#1'.


Update Summary:
 Cartman_sub_sub02:dir:tr1test1#1 in project Cartman_sub_sub02-wbernard2:project:tr1test1#1 had no candidates

Update complete.
"""}
        session = MockResultSession(behave)
        result = session.execute('test_update', ccm.UpdateResult(session))
        #logger.debug(result.output)
        assert len(result.output['tasks']) == 4, "Number of tasks doesn't match."
        assert len(result.output['modifications']) == 4, "Number of modifications doesn't match."
        assert len(result.output['errors']) == 1, "Number of errors doesn't match."

    def test_update_result_serious_failure(self):
        """ Validating UpdateResult with serious failure."""        
        behave = {'test_update' :"""Starting update process...

Updating project 'MinibuildDomain-wbernard3:project:tr1test1#1' from object version 'MinibuildDomain-wbernard3:project:tr1test1#1'...
Refreshing baseline and tasks for project grouping 'My MinibuildDomain/next Insulated Development Projects'.
Replacing tasks in folder tr1test1#2068
  Contents of folder tr1test1#2068 have not changed.
Setting path for work area of 'helloworldcons-wbernard2' to 'c:\users\ccm65\ccm_wa\tr1test1\MinibuildDomain'...
Warning: 'c:\users\ccm65\ccm_wa\tr1test1\MinibuildDomain\helloworldcons' already used as work area for project 'helloworldcons-wbernard'
Warning: Unable to update path for work area of 'helloworldcons-wbernard2'
Warning: Unable to update membership of project 'MinibuildDomain-wbernard3'
Work area delete of 'helloworldcons-wbernard2:project:tr1test1#1' failed
Warning: Unable to update membership of project MinibuildDomain-wbernard3 with MinibuildDomain-2:dir:tr1test1#1
Rebind of MinibuildDomain-1:dir:tr1test1#1 failed
Warning: Update for project 'MinibuildDomain-wbernard3:project:tr1test1#1' failed.

Update Summary
2 failures to use the selected object version
    Failed to remove selected object helloworldcons-wbernard2:project:tr1test1#1 under directory MinibuildDomain-1:dir:tr1test1#1 from project MinibuildDomain-wbernard3 : work area delete failed
    Failed to use selected object MinibuildDomain-2:dir:tr1test1#1 under directory MinibuildDomain-wbernard3:project:tr1test1#1 in project MinibuildDomain-wbernard3
Serious: 
Update failed.
"""}
        session = MockResultSession(behave)
        result = session.execute('test_update', ccm.UpdateResult(session))
        #logger.debug(result.output)
        #logger.debug(result.output.keys())
        #logger.debug(len(result.output['tasks']))
        #logger.debug(len(result.output['modifications']))
        #logger.debug(len(result.output['errors']))
        #logger.debug(len(result.output['warnings']))
        
        assert (len(result.output['tasks']) == 0), "Number of tasks doesn't match."
        assert (len(result.output['modifications']) == 0), "Number of modifications doesn't match."
        assert (len(result.output['errors']) == 1), "Number of errors doesn't match."
        assert (len(result.output['warnings']) == 5), "Number of warnings doesn't match."


    def test_UpdateTemplateInformation_result(self):        
        """ Validating UpdateTemplateInformation."""                
        behave = {'test_update' : """Baseline Selection Mode: Latest Baseline Projects
Prep Allowed:            No
Versions Matching:       *abs.50*
Release Purposes:
Use by Default:          Yes
Modifiable in Database:  tr1s60
In Use For Release:      Yes
Folder Templates and Folders:
    Template assigned or completed tasks for %owner for release %release
    Template all completed tasks for release %release
    Folder   tr1s60#4844: All completed Xuikon/Xuikon_rel_X tasks
    Folder   tr1s60#4930: All tasks for release AppBaseDo_50        
        """}
        session = MockResultSession(behave)
        result = session.execute('test_update', ccm.UpdateTemplateInformation(session))
        #logger.debug(result.output)
        assert result.output['baseline_selection_mode'] == "Latest Baseline Projects", "BSM doesn't match."
        assert result.output['prep_allowed'] == False, "Prep allowed doesn't match."
        assert result.output['version_matching'] == "*abs.50*", "Version matching doesn't match."
        assert result.output['release_purpose'] == "", "Release purpose doesn't match."
        assert result.output['modifiable_in_database'] == "tr1s60", "Modifiable in Database doesn't match."
        assert result.output['in_use_for_release'] == True, "In Use For Release doesn't match."
    
    def test_ConflictsResult_result(self):        
        """ Validating ConflictsResult."""                
        behave = {'test_update' : """        
Project: Cartman-Release_v4

         No conflicts detected.

Project: Cartman_sub03-next

         No conflicts detected.

Project: Cartman_sub01-Release_v2

         No conflicts detected.

Project: Cartman_sub02-Release_v4

         No conflicts detected.

Project: Cartman_sub_sub01-Release_v2

         No conflicts detected.

Project: Cartman_sub_sub02-Release_v4

         No conflicts detected.

Project: Cartman_sub_sub_sub02-Release_v4

tr1test1#5224   Explicitly specified but not included
tr1test1#5226   Explicitly specified but not included
        """}
        session = MockResultSession(behave)
        result = session.execute('test_update', ccm.ConflictsResult(session))
        #logger.debug(result.output)
        # pylint: disable-msg=E1103
        assert len(result.output.keys()) == 7, "Should detect 7 projects."
        subproj = session.create("Cartman_sub_sub_sub02-Release_v4:project:%s#1" % session.database())
        assert len(result.output[subproj]) == 2, "%s should contain 2 conflicts" % subproj.objectname


    def test_DataMapperListResult_result(self):        
        """ Validating DataMapperListResult."""                        
        behave = {'test_query' : """>>>objectname>>>task5204-1:task:tr1test1>>>task_synopsis>>>Create Cartman_sub03>>>
>>>objectname>>>task5223-1:task:tr1test1>>>task_synopsis>>>cartman/next test1>>>
>>>objectname>>>task5224-1:task:tr1test1>>>task_synopsis>>>test.txt>>>
>>>objectname>>>task5225-1:task:tr1test1>>>task_synopsis>>>test.txt 2>>>
>>>objectname>>>task5226-1:task:tr1test1>>>task_synopsis>>>test.txt merge>>>
>>>objectname>>>task5240-1:task:tr1test1>>>task_synopsis>>>add calculator>>>
"""}
        session = MockResultSession(behave)
        result = session.execute('test_query', ccm.DataMapperListResult(session, '>>>', ['objectname', 'task_synopsis'], ['ccmobject', 'string']))        
        logger.debug(result.output)
        assert len(result.output) == 6
        
    def test_UpdatePropertiesRefreshResult_result(self):        
        """ Validating UpdatePropertiesRefreshResult."""                        
        behave = {'test_refresh' : """Refreshing baseline and tasks for project grouping 'All cartman/next Integration Testing Projects from Database tr1test1'.
Replacing tasks in folder tr1test1#2045
  Removed the following tasks from folder tr1test1#2045
        Task tr1test1#5225: test.txt 2

  Added the following tasks to folder tr1test1#2045
        Task tr1test1#5223: cartman/next test1

Added the following tasks to project grouping 'All cartman/next Integration Testing Projects from Database tr1test1':
        Task tr1test1#5223: cartman/next test1

Removed the following tasks from project grouping 'All cartman/next Integration Testing Projects from Database tr1test1':
        Task tr1test1#5225: test.txt 2
"""}
        session = MockResultSession(behave)
        result = session.execute('test_refresh', ccm.UpdatePropertiesRefreshResult(session))        
        logger.debug(result.output)
        assert result.output['added'] == [session.create("Task tr1test1#5223")]
        assert result.output['removed'] == [session.create("Task tr1test1#5225")]

    def test_update_log_result(self):
        """ Testing update log parsing. """
        log = """Starting update process...

Updating project 'MinibuildDomain-wbernard3:project:tr1test1#1' from object version 'MinibuildDomain-wbernard3:project:tr1test1#1'...
Refreshing baseline and tasks for project grouping 'My MinibuildDomain/next Insulated Development Projects'.
Replacing tasks in folder tr1test1#2068
  Contents of folder tr1test1#2068 have not changed.
Setting path for work area of 'helloworldcons-wbernard2' to 'c:\users\ccm65\ccm_wa\tr1test1\MinibuildDomain'...
Warning: 'c:\users\ccm65\ccm_wa\tr1test1\MinibuildDomain\helloworldcons' already used as work area for project 'helloworldcons-wbernard'
Warning: Unable to update path for work area of 'helloworldcons-wbernard2'
Warning: Unable to update membership of project 'MinibuildDomain-wbernard3'
Work area delete of 'helloworldcons-wbernard2:project:tr1test1#1' failed
Warning: Unable to update membership of project MinibuildDomain-wbernard3 with MinibuildDomain-2:dir:tr1test1#1
Rebind of MinibuildDomain-1:dir:tr1test1#1 failed
Warning: Update for project 'MinibuildDomain-wbernard3:project:tr1test1#1' failed.
Warning: This work area 'c:\users\ccm65\ccm_wa\tr1sido\mrurlparserplugin\mrurlparserplugin' cannot be reused
Warning:  No candidates found for directory entry ecompluginnotifier.cpp:cppsrc:e003sa01#1.  It will be left empty!
WARNING: There is no matching baseline project for 'ci-hitchcock_nga' in baseline 'tr1s60#ABS_domain_mcl92-abs.mcl.92_200907'.  This baseline might not be complete

Update Summary
2 failures to use the selected object version
    Failed to remove selected object helloworldcons-wbernard2:project:tr1test1#1 under directory MinibuildDomain-1:dir:tr1test1#1 from project MinibuildDomain-wbernard3 : work area delete failed
    Failed to use selected object MinibuildDomain-2:dir:tr1test1#1 under directory MinibuildDomain-wbernard3:project:tr1test1#1 in project MinibuildDomain-wbernard3
Serious: 
Update failed.
"""
        logger = logging.getLogger('count.logger')
        logger.setLevel(logging.WARNING)
        handler = CounterHandler()
        logger.addHandler(handler)
        ccm.log_result(log, ccm.UPDATE_LOG_RULES, logger)
        print handler.warnings
        print handler.errors
        assert handler.warnings == 5
        assert handler.errors == 9


    def test_checkout_log_result(self):
        """ Testing checkout log parsing. """
        log = """Setting path for work area of 'swservices_domain-ssdo_7132_200912_Shakira_Gwen1' to 'E:\Build_E\DaveS\Integration\_no_context_\swservices_domain'...
Saved work area options for project: 'swservices_domain-ssdo_7132_200912_Shakira_Gwen1'
Derive failed for MobileSearch-MobileSearch_4_10_09w09_S60_3_2:project:sa1mosx1#1
Warning: Project name is either invalid or does not exist: 
Warning: fa1ssdo#MobileSearch_4_10_09w09_S60_3_3 too long, use name less than 32 characters long.
Warning: Object version 'fa1ssdo#MobileSearch_4_10_09w09_S60_3_3' too long, use version less than 32 characters long.
Copy Project complete with 1 errors.
WARNING: There is no matching baseline project for 'ci-hitchcock_nga' in baseline 'tr1s60#ABS_domain_mcl92-abs.mcl.92_200907'.  This baseline might not be complete
"""
        logger = logging.getLogger('count.logger')
        logger.setLevel(logging.WARNING)
        handler = CounterHandler()
        logger.addHandler(handler)
        ccm.log_result(log, ccm.CHECKOUT_LOG_RULES, logger)
        print handler.warnings
        print handler.errors
        assert handler.warnings == 4
        assert handler.errors == 1

        
    def test_sync_log_result(self):
        """ Testing sync log parsing. """
        log = """Synchronization summary:
       0 Update(s) for project MinibuildDomain-wbernard7
       0 Update(s) for project helloworldapi-wbernard7
       0 Update(s) for project helloworldcons-wbernard5
       0 Conflict(s) for project MinibuildDomain-wbernard7
       1 Conflict(s) for project helloworldapi-wbernard7
       0 Conflict(s) for project helloworldcons-wbernard5
You can use Reconcile to resolve work area conflicts
Warning: Conflicts detected during synchronization. Check your logs.
"""
        logger = logging.getLogger('count.logger')
        logger.setLevel(logging.WARNING)
        handler = CounterHandler()
        logger.addHandler(handler)
        ccm.log_result(log, ccm.SYNC_LOG_RULES, logger)
        print handler.warnings
        print handler.errors
        assert handler.warnings == 0
        assert handler.errors == 2

    def test_ResultWithError(self):
        """ Test result. """
        result = ccm.ResultWithError(None)
        result.output = u"Nokia"
        result.error = u"Nokio"
        assert result.output == u"Nokia"
        assert result.error == u"Nokio"

    def test_ResultWithError_unicode_character(self):
        """ Test result with unicode character. """
        result = ccm.ResultWithError(None)
        result.output = u"Nokia\xc2"
        result.error = u"Nokio\xc2"
        print result.output.encode('ascii', 'replace')
        print result.error.encode('ascii', 'replace')
        assert result.output == u"Nokia?"
        assert result.error == u"Nokio?"

    def test_ResultWithError_str(self):
        """ Test result from str. """
        result = ccm.ResultWithError(None)
        result.output = "Nokia"
        result.error = "Nokio"
        assert result.output == "Nokia"
        assert result.error == "Nokio"

    def test_ResultWithError_str_not_ascii(self):
        """ Test result from str with not ascii. """
        result = ccm.ResultWithError(None)
        result.output = "Noki\xe4"
        result.error = "Nokio\xe5"
        print result.output
        print result.error
        assert result.output == "Noki"
        assert result.error == "Nokio"

if __name__ == "__main__":
    unittest.main()
