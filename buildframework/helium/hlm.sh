#!/bin/csh

#
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

if (`alias module` != "") then
    module load "java/1.6.0"
    module load "tww/ant/1.7.1"
    module load "tww/python/2.5.2"
    module load "tww/p7zip/4.58"
    module load "rvct/2.2_616"
    module load "tww/graphviz/2.12"
    module load mercurial
endif

setenv LANG en_US.UTF-8

if (! $?HELIUM_HOME ) then
    setenv HELIUM_HOME `pwd`
endif

setenv JEP_HOME $HELIUM_HOME/external/jep_1.6_2.5


setenv ANT_ARGS "-lib $HELIUM_HOME/extensions/nokia/external/antlibs -lib $HELIUM_HOME/extensions/nokia/external/helium-nokia-antlib/bin -lib $HELIUM_HOME/external/helium-antlib/bin -lib $HELIUM_HOME/external/antlibs -lib $HELIUM_HOME/tools/common/java/lib -lib $JEP_HOME -logger com.nokia.ant.HeliumLogger -Dant.executor.class=com.nokia.helium.core.ant.HeliumExecutor -listener com.nokia.helium.diamonds.ant.HeliumListener"

setenv LD_LIBRARY_PATH $JEP_HOME
if (-e /nokia/apps/tww/@sys/python252/lib/python2.5/config/libpython2.5.so) then
    setenv LD_PRELOAD /nokia/apps/tww/@sys/python252/lib/python2.5/config/libpython2.5.so
else
    setenv LD_PRELOAD /usr/lib/libpython2.5.so.1
endif

setenv PYTHONPATH $HELIUM_HOME/external/python/lib/2.5/linux:$HELIUM_HOME/tools/common/python/lib:$HELIUM_HOME/extensions/nokia/external/python/lib/2.5:$HELIUM_HOME/extensions/nokia/tools/common/python/lib
setenv JYTHONPATH "$HELIUM_HOME/external/python/lib/2.5/jython-2.5-py2.5.egg:$HELIUM_HOME/external/python/lib/2.5:$PYTHONPATH"
setenv PERL5LIB $HELIUM_HOME/tools/common/packages

setenv USERNAME $USER
setenv TEMP /tmp/$USER
if ($?HOST) then
    setenv COMPUTERNAME $HOST
else
    setenv COMPUTERNAME `hostname`
endif

if (! $?EPOCROOT) then
    setenv EPOCROOT /
endif

setenv SYMSEE_VERSION not_in_use
setenv PID $$
setenv HELIUM_CACHE_DIR $TEMP/helium/$USER
setenv ANT_OPTS "-Dlog4j.configuration=com/nokia/log4j.xml -Dlog4j.cache.dir=$HELIUM_CACHE_DIR"
ant -Dpython.cachedir=$HELIUM_HOME/temp -Dhelium.dir=$HELIUM_HOME -Dpython.path=$PYTHONPATH $* 
