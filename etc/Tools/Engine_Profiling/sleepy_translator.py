description='This script uses the Very Sleepy profilers .CSV output and the Spring stack trace translator at http://springrts.com:8000 to make a readable output. Its not perfect'


from optparse import OptionParser
import traceback
# import datetime, os, re, xmlrpclib
from xmlrpclib import ServerProxy, Error
import zipfile
import os
import sys

parser=OptionParser(usage="usage: python sleepy_tranlator.py -i capture.csv", version= "0.1")
parser.add_option('-i', '--input',action='store',dest='input', default='capture.csv',help='input csv file from Very Sleepy')
parser.add_option('-o', '--output',action='store',dest='output', default='capture_translated.xls',help='translated output file name')
parser.add_option('-v', '--spring_version',action='store',dest='springversion', default='Spring 95.0.',help='Spring engine version')
parser.add_option('-t', '--threshold',action='store',dest='threshold', default='0.01',help='Minimum % inclusive time for translation')
parser.add_option('-s', '--sourcepath',action='store',dest='sourcepath',help='Source path for spring source')

options, args=parser.parse_args()
sleepytype='csv'
print options

dbgmax=1000000
cnt=0

if '.csv' in options.input:
	sleepyfile=open(options.input).readlines()
	print 
elif '.sleepy' in options.input:
	sleepytype='sleepy'
	fh=open(options.input, 'rb') 
	z=zipfile.ZipFile(fh)
	for name in z.namelist():
		print name
		z.extract(name, os.getcwd())

	symbols=open('Symbols.txt')
	sleepyfile=symbols.readlines()
	symbols.close()
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
		if sleepytype == 'sleepy':
			(sym, module, address, sourcefile, sourceline)=sleepyline.strip().split(' ')#sym1473 "nvoglv32" "[687BAD05]" "" 0
			#print name, module,inpercent
			print module, address
			if module=='"spring"' and '[' in address:
				if cnt<dbgmax:
					cnt+=1
					to_translate.append(address)
					infolog.append("[f=0055926] Error: (%i) C:\\fake_path\\spring.exe [0x%s]\n"%(address_count,address.strip('\"[]')))
					address_count+=1		
		else:
			(name, extime, intime, expercent, inpercent, module, sourcefile, sourceline)=sleepyline.strip().split(',')
			#print name, module,inpercent
			if module=='spring' and float(inpercent)>float(options.threshold) and '[' in name:
				to_translate.append(name)
				infolog.append("[f=0055926] Error: (%i) C:\\fake_path\\spring.exe [0x%s]\n"%(address_count,name.strip('[]')))
				address_count+=1
	except:
		print 'Failed to parse line',sleepyline,'in',options.input,sleepyline.strip().split(' ')
		traceback.print_exc()

		pass
print 'querying',address_count,'lines with fakeinfolog.txt',len(infolog)
fakeinfolog=open('fakeinfolog.txt','w')
fakeinfolog.write(''.join(infolog))
fakeinfolog.close()

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

print 'Query successful, stacktrace results',len(translated)
# this will return a 2d list: [['C:\\fake_path\\spring.exe', '0x0062AAB5', 'build/default/../../rts/Map/SMF/SMFReadMap.cpp', 820], ['C:\\fake_path\\spring.exe', '0x00622D4A', 'build/default/../../rts/Map/SMF/SMFGroundDrawer.cpp', 372], ['C:\\fake_path\\spring.exe', '0x00881864', '/slave/mingwlibs/include/boost/optional/optional.hpp', 438], ['C:\\fake_path\\spring.exe', '0x00870AA6', 'build/default/../../rts/System/Misc/SpringTime.cpp', 145], ['C:\\fake_path\\spring.exe','0x0086E146', 'build/default/../../rts/System/Main.cpp', 132], ['C:\\fake_path\\spring.exe', '0x0086D556', 'build/default/../../rts/System/Main.cpp', 64],['C:\\fake_path\\spring.exe', '0x008550CD', 'build/default/../../rts/System/EventHandler.cpp', 280], ['C:\\fake_path\\spring.exe', '0x0079AC66', 'build/def .....
giturl="http://github.com/spring/spring/tree/master/%s#L%i"
def getcodeline(path, i): #fetches line i of the code, removes double quotes, replace with singles, max length of 80 chars
	
	try:
		codef=open(path)
		codelines=codef.readlines()
		line=codelines[i-1] #because lines are indexed from 1!
		line=line.strip().replace('\"','\'')
		if len(line)>75:
			line=line[0:74]+'...'
		#print 'got code line:',line
		if len(line)<1:
			print 'got suspiciosly short line',path,i,line
		return line
	except:
		#print 'warning, cant fine code line',path,line
		pass
		return ''
	
if sleepytype=='csv':

	outf=open(options.output,'w')
	outf.write('Name(address)	Exclusive_time	Inclusive_time	Exclusive%	Inclusive%	module	source_file	source_line	source_link\n')
else:
	outf=open('Symbols.txt','w')
for sleepyline in sleepyfile:
	#print sleepyline
	try:
		if sleepytype=='csv':
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
		else:
			(sym, module, address, sourcefile, sourceline)=sleepyline.strip().split(' ')

			if address in to_translate:
				found=False
				for entry in translated:
					if address.strip('[]\"') in entry[1]:
					
						#shortname='\"['+entry[2].replace('build/default/../../','')+':'+str(entry[3])+']\"'
						shortname=entry[2].replace('build/default/../../','')+'_'+str(entry[3])
						if options.sourcepath and 'build/default/../../' in entry[2]:
							path=options.sourcepath+entry[2].replace('build/default/../../','')
							codeline=getcodeline(path, entry[3])
							if codeline !='':
								if '/' in shortname:
									shortname=shortname.rpartition('/')[2] # so we only have the filename like Unit.cpp
									shortname='<'+shortname+'> '+codeline
							shortname= '\"'+shortname+'\"'
							outf.write(' '.join([sym,module,shortname,'\"'+path+'\" '+str(entry[3])+'\n']))
						else:
							shortname= '\"'+shortname+'\"'
							outf.write(' '.join([sym,module,shortname,'\"" 0\n']))
						found=True
						break
				if not found:
					print sleepyline,'not found in tranlated trace!'
				
					outf.write(sleepyline)
			else:
				outf.write(sleepyline)
	except:
		print 'Failed to translate line',sleepyline,'in',options.input
		traceback.print_exc()
		outf.write(sleepyline)
		pass

outf.close() # GOD FUCKING DAMMIT!
if sleepytype == 'sleepy':
	outfname=options.input.partition('.sleepy')[0]+'_translated.sleepy'
	cmd='zip -1 '+outfname+' Stats.txt IPCounts.txt Symbols.txt Callstacks.txt "Version 0.82 required"'
	print cmd
	os.system(cmd)
	print 'Done zipping'
#zip -1 ziptest.sleepy Stats.txt IPCounts.txt Symbols.txt Callstacks.txt "Version 0.82 required"



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