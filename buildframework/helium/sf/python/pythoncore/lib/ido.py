#============================================================================ 
#Name        : ido.py 
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

"""
IDO specific features
    * find layer_real_source_path from sysdef file.
    * time manipulation for robot releasing.
"""
import re
import datetime

MATCH_ENTITY = re.compile(r".*ENTITY\s+layer_real_source_path\s+\"(.+)\"\s*>?.*")

def get_sysdef_location(sysdef):
    """ Search for layer_real_source_path entity inside the sysdef file. """
    input = open(sysdef, 'r')
    for line in input.readlines():
        result = MATCH_ENTITY.match(line)
        if result != None:
            input.close()
            return result.groups()[0]
    input.close()
    print 'layer_real_source_path entity not found in ' + sysdef
    return None


def get_first_day_of_cycle(now = datetime.datetime.now()):
    """ This function returns a datetime object representing the monday from closest
        odd week.
    """
    isoyear, isoweek, isoday = now.isocalendar()
    week = isoweek - 1
    day = isoday - 1
    monday = now - datetime.timedelta(days=day + week.__mod__(2) * 7)
    monday = monday.replace(hour = 0, minute = 0, second = 0, microsecond = 0)
    return monday

def get_absolute_date(day, time, now = datetime.datetime.now()):
    """ Get the absolute date from the day and time. """
    time = datetime.datetime.strptime(time, "%H:%M")
    delta = datetime.timedelta(days = day-1, hours = time.hour, minutes= time.minute)
    return get_first_day_of_cycle(now) + delta


def is_in_interval(day1, time1, day2, time2, now = datetime.datetime.now()):
    """ Return True is get_absolute_date(day1, time1) < now < get_absolute_date(day2, time2). """
    delta1 = get_absolute_date(day1, time1, now)
    delta2 = get_absolute_date(day2, time2, now)
    if now <= delta1:
        return False
    if delta2 <= now:
        return False
    return True
    