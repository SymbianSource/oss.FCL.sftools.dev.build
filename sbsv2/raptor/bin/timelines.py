#
# Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Raptor log visualisation program. Takes a raptor log as standard input
# and displays timelines that represent build progress and 
# how much actual parallelism there is in the build.
# This program requires the pygame and PyOpenGL modules.

from OpenGL.GL import *
from OpenGL.GLU import *
import pygame
from pygame.locals import *
import time

class Timeline(object):
	"""A bar representing a number of recipes which were executed in 
	   time sequence.  There is no guarantee about what host but in 
	   theory they could have been executed on the same host."""

	globalmax = 2.0

	def __init__(self,ylevel):
		self.maxtime = 0.0
		self.recipes = []
		self.ylevel = ylevel

	def append(self, recipe):
		"" add this recipe to this timeline if it happens after the latest recipe already in the timeline ""
		if recipe.starttime + recipe.duration > self.maxtime:
			self.maxtime = recipe.starttime + recipe.duration
			if self.maxtime > Timeline.globalmax:
				Timeline.globalmax = self.maxtime 
		else:
			pass

		self.recipes.append(recipe)

	def draw(self):
		glLoadIdentity()
		self.xscale = 4.0 / Timeline.globalmax

    		glTranslatef(-2.0, -1.5, -6.0)
		count = 0
		for r in self.recipes:
			if count % 2 == 0:
				coloff=0.8
			else:
				coloff = 1.0

			count += 1
			r.draw(self.xscale, self.ylevel, coloff)

class Recipe(object):
	"""Represents a task completed in a raptor build. 
	   Drawn as a colour-coded bar with different 
	   colours for the various recipe types."""
	STAT_OK = 0
	colours = {
		'compile': (0.5,0.5,1.0),
		'compile2object': (0.5,0.5,1.0),
		'win32compile2object': (0.5,0.5,1.0),
		'tools2linkexe': (0.5,1.0,0.5),
		'link': (0.5,1.0,0.5),
		'linkandpostlink': (0.5,1.0,0.5),
		'win32stageonelink': (0.5,1.0,0.5),
		'tools2lib': (0.5,1.0,1.0),
		'win32stagetwolink': (1.0,0.1,1.0),
		'postlink': (1.0,0.5,1.0)
		}

	def __init__(self, starttime, duration, name, status):
		self.starttime = starttime
		self.duration = duration
		self.status = status
		self.colour = (1.0, 1.0, 1.0)
		if name in Recipe.colours:
			self.colour = Recipe.colours[name]
		else:
			self.colour = (1.0,1.0,1.0)
		self.name = name 

	def draw(self, scale, ylevel, coloff):
		if self.status == Recipe.STAT_OK:
			glColor4f(self.colour[0]*coloff, self.colour[1]*coloff, self.colour[2]*coloff,0.2)
		else:
			glColor4f(1.0*coloff, 0.6*coloff, 0.6*coloff,0.2)


		x = self.starttime * scale
		y = ylevel
		x2 = x + self.duration * scale
		y2 = ylevel + 0.2
		glBegin(GL_QUADS)
		glVertex3f(x, y, 0)
		glVertex3f(x, y2, 0)
		glVertex3f(x2, y2, 0)
		glVertex3f(x2, y, 0)
		glEnd()


def resize((width, height)):
	if height==0:
		height=1
	glViewport(0, 0, width, height)
	glMatrixMode(GL_PROJECTION)
	glLoadIdentity()
	gluPerspective(45, 1.0*width/height, 0.1, 100.0)
	glMatrixMode(GL_MODELVIEW)
	glLoadIdentity()

def init():
	glShadeModel(GL_SMOOTH)
	glClearColor(0.0, 0.0, 0.0, 0.0)
	glClearDepth(1.0)
	glEnable(GL_DEPTH_TEST)
	glDepthFunc(GL_LEQUAL)
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST)


import sys
import re

def main():

	video_flags = OPENGL|DOUBLEBUF

	pygame.init()
	pygame.display.set_mode((800,600), video_flags)

	resize((800,600))
	init()

	frames = 0
	ticks = pygame.time.get_ticks()


	lines = 4
	timelines = []
	ylevel = 0.0
	for i in xrange(0,4):
		ylevel += 0.6 
		timelines.append(Timeline(ylevel))

	f = sys.stdin

	recipe_re = re.compile(".*<recipe name='([^']+)'.*")
	time_re = re.compile(".*<time start='([0-9]+\.[0-9]+)' *elapsed='([0-9]+\.[0-9]+)'.*")
	status_re = re.compile(".*<status exit='([^']*)'.*")

	alternating = 0
	start_time = 0.0

	
	for l in f.xreadlines():
		l2 = l.rstrip("\n")
		rm = recipe_re.match(l2)

		if rm is not None:
			rname = rm.groups()[0]
			continue


		tm = time_re.match(l2)
		if tm is not None:
			s = float(tm.groups()[0])
			elapsed = float(tm.groups()[1])

			if start_time == 0.0:
				start_time = s

			s -= start_time

			continue

		sm = status_re.match(l2)

		if sm is None:
			continue

		if sm.groups()[0] == 'ok':
			status = 0
		else:
			status = int(sm.groups()[0])

		olddiff = 999999999.0
		tnum = 0
		for t in timelines:
			newdiff = s - t.maxtime
			if newdiff < 0.0:
				continue
			if olddiff > newdiff:
				dest_timeline = t
				olddiff = newdiff
			tnum += 1

		dest_timeline.append(Recipe(s, elapsed, rname, status))
		event = pygame.event.poll()
		if event.type == QUIT or (event.type == KEYDOWN and event.key == K_ESCAPE):
			break

		glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT)
		for t in timelines:
			t.draw()
		pygame.display.flip()

		frames = frames+1

	print "fps:  %de" % ((frames*1000)/(pygame.time.get_ticks()-ticks))
	event = pygame.event.wait()


if __name__ == '__main__': main()
