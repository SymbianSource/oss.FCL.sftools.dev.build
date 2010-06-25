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
# timings API
# This API can be used to start and stop timings in order to measure performance
#
import time

class Timing(object):
	
	@classmethod
	def discovery_string(cls, object_type, count):
		"""
			Returns a tag that can be used to show what is about to be
					"processed"
			Parameters:
				object_type - string
					Type of object that is about to be "processed" in this task
				count - int
					Number of objects of input "object_type" are about to be
							"processed"
			Returns:
				string
					XML tag in the format that can be printed directly to a
							Raptor log
		"""
		return "<progress:discovery object_type='" + str(object_type) + \
				"' count='" + str(count) + "' />\n"
				
	
	@classmethod
	def start_string(cls, object_type, task, key):
		"""
			Returns a tag that can be used to show what is being "processed"
					and the time it started
			Parameters:
				object_type - string
					Type of object that is being "processed" in this task
				task - string
					What is being done with the object being "processed"
				key - string
					Unique identifier for the object being "processed"
			Returns:
				string
					XML tag in the format that can be printed directly to a
							Raptor log
		"""
		return "<progress:start object_type='" + str(object_type) + \
				"' task='" + str(task) + "' key='" + str(key) + \
				"' time='" + str(time.time()) + "' />\n"
	
	
	@classmethod
	def end_string(cls, object_type, task, key):
		"""
			Returns a tag that can be used to show what was being "processed"
					and the time it finished
			Parameters:
				object_type - string
					Type of object that was being "processed" in this task
				task - string
					What was being done with the object being "processed"
				key - string
					Unique identifier for the object that was "processed"
			Returns:
				string
					XML tag in the format that can be printed directly to a
							Raptor log
		"""
		return "<progress:end object_type='" + str(object_type) + \
				"' task='" + str(task) + "' key='" + str(key) + \
				"' time='" + str(time.time()) + "' />\n"
	
	
	@classmethod
	def custom_string(cls, tag = "duration", object_type = "all", task = "all",
			key = "all", time = 0.0):
		"""
			Returns a custom tag in the 'progress' tag format
			
			Parameters:
				tag - string
					String to be used for the tag 
				object_type - string
					Type of object that was being "processed" in this task
				task - string
					What was being done with the object being "processed"
				key - string
					Unique identifier for the object that was "processed"
				time - float
					The time to be included in the tag
			Returns:
				string
					XML tag in the format that can be printed directly to a
							Raptor log
		"""		
		time_string = "time"
		if tag == "duration":
			time_string = "duration" 
		return "<progress:" + str(tag) + " object_type='" + str(object_type) + \
				"' task='" + str(task) + "' key='" + str(key) + \
				"' " + time_string + "='" + str(time) + "' />\n"
	
	
	@classmethod
	def extract_values(cls, source):
		"""
			Takes, as input, a single tag of the format returned by one of the
					above progress functions. Will extract the attributes and
					return them as a dictionary. Returns an empty dictionary {}
					if the tag name is not recognised or there is a parse error
			Parameters:
				source - string
					The input string from which extracted attributes are
							required
			Returns:
				dictionary
					Dictionary containing the attributes extracted from the
							input string. Returns an empty dictionary {} if the
							tag name is not recognised or there is a parse error
			NB: This function will not work correctly if the 'source' variable
					contains multiple tags
		"""
		import re
		
		attributes = {}
					
		try:
			match = re.match(re.compile(".*object_type='(?P<object_type>.*?)'"),
					source)
			attributes["object_type"] = match.group("object_type")
		except AttributeError, e:
			print e
			attributes["object_type"] = ""
		try:
			match = re.match(re.compile(".*task='(?P<task>.*?)'"), source)
			attributes["task"] = match.group("task")
		except AttributeError, e:
			print e
			attributes["task"] = ""
		try:
			match = re.match(re.compile(".*key='(?P<key>.*?)'"), source)
			attributes["key"] = match.group("key")
		except AttributeError:
			attributes["key"] = ""
		try:
			match = re.match(re.compile(".*time='(?P<time>.*?)'"), source)
			attributes["time"] = match.group("time")
		except AttributeError:
			attributes["time"] = ""
		try:
			match = re.match(re.compile(".*count='(?P<count>.*?)'"), source)
			attributes["count"] = match.group("count")
		except AttributeError:
			attributes["count"] = ""
			
		return attributes
