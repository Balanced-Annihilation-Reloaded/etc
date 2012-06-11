import sys
import os
print 'usage: smoothanim.py [input.bos] [minsleep] [maxsleep] [output.bos]'
minsleep=30
maxsleep=300

class Piece:
	rx=0
	ry=0
	rz=0
	mx=0
	mz=0
	my=0

inputfile=[]
if len(sys.argv)>=2:
	inputfile=open(sys.argv[1]).readlines()
if len(sys.argv)>=3:
	minsleep=int(sys.argv[2])
if len(sys.argv)>=4:
	minsleep=int(sys.argv[3])
if len(sys.argv)>=5:
	output=sys.argv[4]
else:
	output=sys.arv[1].partition('.')[0]+'_smoothanim.bos'
pieces={}
#process the bos file
wholefile=''.join([line.strip().partition('//')[0] for line in inputfile])
piecenames=[pname.strip(' ,;') for pname in wholefile.partition('piece')[2].partition(';')[0].lower().strip().split(',')]
print piecenames
for p in piecenames:
	if p!='':
		pieces[p]={'move':{'x':0,'y':0,'z':0},'turn':{'x':0,'y':0,'z':0}}
print pieces
def parsebos(line): 
	#parses a move or turn command, returns false on any anomaly, 
	#else it returns a dict: {'c':command,'p':piece,'a':axis,'p':pos,'s':speed,'a':acc}
	l=line
	line=line.replace('  ',' ').lower().partition('//')[0] #remove commendte
	line=line.strip().strip(';').split(' ')
	
	#move rleg to y-axis [0.250000] now;
	if len(line)<5:
		print 'line split is less than 5, not a proper move/turn command!', line,l
		return False
	if line[0]!='turn' and line[0]!='move':
		print 'line[0] is not turn or move',l
		return False
	else:
		command=line[0]
	
	if line[1] not in pieces:
		print 'invalid piece',l,'not in piecelist',pieces
		return False
	else:
		piece=line[1]
	
	if line[2] != 'to':
		print "line[2] != to",l
		return False
	
	if '-axis' not in line[3] and not ('x-' in line[3] or 'y-' in line[3] or'z-' in line[3]):
		print 'bad axis in line[3]',l
		return False
	else:
		axis=line[3][0]
		print axis
		if axis not in 'xyz':
			print 'axis fail!', l,line[3],line[3][0]
			return False
	
	try:
		if command == 'move' and ('[' not in line[4] or ']' not in line[4]):
			print 'missing [ or ] in pos of move command',l
			return False
		elif command == 'turn' and ('<' not in line[4] or '>' not in line[4]):
			print 'missing < or > in pos of turn command',l
			return False
		else:
			pos=float(line[4].strip('[]<>'))
	except ValueError:
		print 'cant parse pos in',l,line
		return False
	
	if line[5] == 'now':
		speed='now'
	elif line[5] == 'speed':
		try:
			if command == 'move' and ('[' not in line[6] or ']' not in line[6]):
				print 'missing [ or ] in speed of move command',l
				return False
			elif command == 'turn' and ('<' not in line[6] or '>' not in line[6]):
				print 'missing < or > in speed of turn command',l
				return False
			else:
				speed=float(line[6].strip('[]<>'))
		except:
			print 'cant parse speed in',l,line
			return False
	else:
		print 'bad line[6]',line[6],l
		return False
	if len(line)>=9 and line[7]=='accelerate':
		try:
			if command == 'move' and ('[' not in line[8] or ']' not in line[8]):
				print 'missing [ or ] in speed of move command',l
				return False
			elif command == 'turn' and ('<' not in line[8] or '>' not in line[8]):
				print 'missing < or > in speed of turn command',l
				return False
			else:
				acc=float(line[8].strip('[]<>'))
		except:
			print 'cant parse accelerate in',l,line[8]
			return False
	else:
		acc=0
	return {'c':command,'p':piece,'a':axis,'pos':pos,'s':speed,'acc':acc}
i=-1
for line in inputfile:
	i+=1
	if ('move' in line or 'turn' in line) and 'now' in line: # search ahead and find a sleep before a bracket-close
		sleep=-1
		for k in range(i,len(inputfile)):
			if 'sleep' in inputfile[k].partition('//')[0]: # .partition('//')[0] is the remove comment operator :D
				try:
					sleep=float(inputfile[k].partition('sleep')[2].partition(';')[0])
					break
				except ValueError:
					print 'failed to parse sleep in line',inputfile[k],'skipping'
					continue
			if '}' in inputfile[k].partition('//')[0]:
				print 'no sleep after now'
				break
		if sleep>0: # we have the sleep value, time to find the last position the piece was at before this new NOW command!
			if parsebos(line):
				bos=parsebos(line)
				print bos
				oldpos=pieces[bos['p']][bos['c']][bos['a']]
				if bos['s']=='now':
					dist=abs(oldpos-bos['pos'])
					speed=dist/(sleep/1000)
					if dist!=0:
						if bos['c']=='turn':
							s='speed <%f>'
						else:
							s='speed [%f]'
						inputfile[i]=line.replace('now',s%(speed))
					
					
				pieces[bos['p']][bos['c']][bos['a']]=bos['pos']
			else:
				print 'error parsing line',i

outf=open(output,'w')
outf.write(''.join(inputfile))
outf.close()
print 'Done'
				
				
				
				
				