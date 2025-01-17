description='This script uses the Very Sleepy profilers .CSV output and the Spring stack trace translator at http://springrts.com:8000 to make a readable output. Its not perfect'


from optparse import OptionParser
# import datetime, os, re, xmlrpclib
from xmlrpclib import ServerProxy, Error


parser=OptionParser(usage="usage: python sleepy_tranlator.py -i capture.csv", version= "0.1")
parser.add_option('-i', '--input',action='store',dest='input', default='capture.csv',help='input csv file from Very Sleepy')
parser.add_option('-o', '--output',action='store',dest='output', default='capture_translated.xls',help='translated output file name')
parser.add_option('-v', '--spring_version',action='store',dest='springversion', default='Spring 95.0.',help='Spring engine version')
parser.add_option('-t', '--threshold',action='store',dest='threshold', default='1',help='Minimum % inclusive time for translation')

options, args=parser.parse_args()

if options.input:
	sleepyfile=open(options.input).readlines()
else:
	print 'failed to open',options.input



infolog=[] #a list of lines in our fake infolog
infolog.append('[f=0055926] Error: Error handler invoked for %s\n'%(options.springversion))
infolog.append('[f=0055926] Error: DLL information:\n')
infolog.append('[f=0055926] Error: Stacktrace:\n')
address_count=0
to_translate=[]
for sleepyline in sleepyfile:
	#print sleepyline
	try:
		(name, extime, intime, expercent, inpercent, module, sourcefile, sourceline)=sleepyline.strip().split(',')
		#print name, module,inpercent
		if module=='spring' and float(inpercent)>float(options.threshold) and '[' in name:
			to_translate.append(name)
			infolog.append("[f=0055926] Error: (%i) C:\\fake_path\\spring.exe [0x%s]\n"%(address_count,name.strip('[]')))
			address_count+=1
	except:
		print 'Failed to parse line',sleepyline,'in',options.inputs
		pass
print 'querying',address_count,'lines with',''.join(infolog)

buildbot=ServerProxy('http://springrts.com:8000')
try:
	translated = buildbot.translate_stacktrace (''.join(infolog))
except Error as v:
	print v
	if False and Error.faultString.index ('Unable to parse detailed version string') != -1:
		print 'UNKNOWN SPRING VERSION'
	else:
		print 'UNKNOWN ERROR'
		print "A fault occurred"
		print "Fault code: %d" % err.faultCode
		print "Fault string: %s" % err.faultString
		print err
		exit(1)

print 'Query successful, stacktrace results',translated
# this will return a 2d list: [['C:\\fake_path\\spring.exe', '0x0062AAB5', 'build/default/../../rts/Map/SMF/SMFReadMap.cpp', 820], ['C:\\fake_path\\spring.exe', '0x00622D4A', 'build/default/../../rts/Map/SMF/SMFGroundDrawer.cpp', 372], ['C:\\fake_path\\spring.exe', '0x00881864', '/slave/mingwlibs/include/boost/optional/optional.hpp', 438], ['C:\\fake_path\\spring.exe', '0x00870AA6', 'build/default/../../rts/System/Misc/SpringTime.cpp', 145], ['C:\\fake_path\\spring.exe','0x0086E146', 'build/default/../../rts/System/Main.cpp', 132], ['C:\\fake_path\\spring.exe', '0x0086D556', 'build/default/../../rts/System/Main.cpp', 64],['C:\\fake_path\\spring.exe', '0x008550CD', 'build/default/../../rts/System/EventHandler.cpp', 280], ['C:\\fake_path\\spring.exe', '0x0079AC66', 'build/def .....
giturl="http://github.com/spring/spring/tree/master/%s#L%i"

outf=open(options.output,'w')
outf.write('Name(address)	Exclusive_time	Inclusive_time	Exclusive%	Inclusive%	module	source_file	source_line	source_link\n')
for sleepyline in sleepyfile:
	#print sleepyline
	try:
		(name, extime, intime, expercent, inpercent, module, sourcefile, sourceline)=sleepyline.strip().split(',')
		if name in to_translate:
			found=False
			for entry in translated:
				if name.strip('[]') in entry[1]:
					link=giturl%(entry[2].replace('build/default/../../',''),entry[3])
					outf.write('	'.join([entry[2].rpartition('/')[2],extime,intime,expercent,inpercent,module,entry[2],str(entry[3]),link])+'\n')
					found=True
					break
			if not found:
				print sleepyline,'not found in tranlated trace!'
			
				outf.write(sleepyline.replace(',','	'))
		else:
			outf.write(sleepyline.replace(',','	'))
	except:
		print 'Failed to parse line',sleepyline,'in',options.inputs
		pass





#The most basic infolog that works:
# [f=0055926] Error: Error handler invoked for Spring 95.0.\n
# [f=0055926] Error: DLL information:
# [f=0055926] Error: Stacktrace:
# [f=0055926] Error: (0) C:\\Programs\\spring.exe [0x008CBD39]

#Sleepy line format:
#0. Name (or address, if unable to resolve)
#1. Exclusive time
#2. Inclusive time
#3. Exclusive %
#4. Inclusive 
#5. module (check for spring and hex in NAME field!)
#6. source file (blank for stuff we want)
#7. source line (default 0 for unknown source files)
#free,12.500104,12.500104,40.476944,40.476944,msvcrt,[unknown],0
#[008053AF],0.050003,0.050003,0.161916,0.161916,spring,,0