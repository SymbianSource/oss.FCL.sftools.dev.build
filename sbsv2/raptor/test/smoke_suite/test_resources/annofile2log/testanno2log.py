import sys
import os
sys.path.append(os.path.join(os.environ['SBS_HOME'],"python"))
from xml.sax.saxutils import escape
from xml.sax.saxutils import unescape

def XMLEscapeLog(stream):
	inRecipe = False

	for line in stream:
		if line.startswith("<recipe"):
			inRecipe = True
		elif line.startswith("</recipe"):
			inRecipe = False
			
		# unless we are inside a "recipe", any line not starting
		# with "<" is free text that must be escaped.
		if inRecipe or line.startswith("<"):
			yield line
		else:
			yield escape(line)

def AnnoFileParseOutput(annofile):
	af = open(annofile, "r")

	inOutput = False
	inParseJob = False
	for line in af:
		line = line.rstrip("\n\r")

		if not inOutput:
			if line.startswith("<output>"):
				inOutput = True	
				yield unescape(line[8:])
				# This is make output so don't unescape it.
			elif line.startswith('<output src="prog">'):
				line = line[19:]
				inOutput = True	
				yield unescape(line)
		else:
			end_output = line.find("</output>")
		
			if end_output != -1:
				line = line[:end_output]
				inOutput = False
			
			yield unescape(line)

	af.close()


retcode=0


annofile = sys.argv[1]
#print "File = ", annofile

sys.stdout.write("<build>\n")
try:
	for l in XMLEscapeLog(AnnoFileParseOutput(annofile)):
		sys.stdout.write(l+"\n")

except Exception,e:
	sys.stderr.write("error: " + str(e) + "\n")
	retcode = 1
sys.stdout.write("</build>\n")

sys.exit(retcode)
