import sys
import os
print 'usage: smoothanim.py [input.bos] [minsleep] [maxsleep] [output.bos] [animspeed] [smooth]'
minsleep=33
maxsleep=400
animspeed=65
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
if len(sys.argv)>=6:
	animspeed=int(sys.argv[5])
if len(sys.argv)>=5:
	output=sys.argv[4]
else:
	output=sys.argv[1]#.partition('.')[0]+'_smoothanim.bos'
pieces={}
#process the bos file
wholefile=''.join([line.strip().partition('//')[0] for line in inputfile])
piecenames=[pname.strip(' ,;') for pname in wholefile.partition('piece')[2].partition(';')[0].lower().strip().split(',')]
print piecenames
for p in piecenames:
	if p!='':
		pieces[p]={'move':{'x':0,'y':0,'z':0},'turn':{'x':0,'y':0,'z':0}}
print pieces
def parsebos(line,verbose=True): 
	#parses a move or turn command, returns false on any anomaly, 
	#else it returns a dict: {'c':command,'p':piece,'a':axis,'p':pos,'s':speed,'a':acc}
	l=line
	line=line.replace('  ',' ').lower().partition('//')[0] #remove commendte
	line=line.strip().strip(';').split(' ')
	
	#move rleg to y-axis [0.250000] now;
	if len(line)<5:
		if verbose:
			print 'line split is less than 5, not a proper move/turn command!', line,l
		return False
	if line[0]!='turn' and line[0]!='move':
		if verbose:
			print 'line[0] is not turn or move',l
		return False
	else:
		command=line[0]
	
	if line[1] not in pieces:
		if verbose:
			print 'invalid piece',l,'not in piecelist',pieces
		return False
	else:
		piece=line[1]
	
	if line[2] != 'to':
		if verbose:
			print "line[2] != to",l
		return False
	
	if '-axis' not in line[3] and not ('x-' in line[3] or 'y-' in line[3] or'z-' in line[3]):
		if verbose:
			print 'bad axis in line[3]',l
		return False
	else:
		axis=line[3][0]
		if verbose:
			print axis
		if axis not in 'xyz':
			if verbose:
				print 'axis fail!', l,line[3],line[3][0]
			return False
	
	try:
		if command == 'move' and ('[' not in line[4] or ']' not in line[4]):
			if verbose:
				print 'missing [ or ] in pos of move command',l
			return False
		elif command == 'turn' and ('<' not in line[4] or '>' not in line[4]):
			if verbose:
				print 'missing < or > in pos of turn command',l
			return False
		else:
			pos=float(line[4].strip('[]<>'))
	except ValueError:
		if verbose:
			print 'cant parse pos in',l,line
		return False
	
	if line[5] == 'now':
		speed='now'
	elif line[5] == 'speed':
		try:
			if command == 'move' and ('[' not in line[6] or ']' not in line[6]):
				if verbose:
					print 'missing [ or ] in speed of move command',l
				return False
			elif command == 'turn' and ('<' not in line[6] or '>' not in line[6]):
				if verbose:
					print 'missing < or > in speed of turn command',l
				return False
			else:
				speed=float(line[6].strip('[]<>'))
		except:
			if verbose:
				print 'cant parse speed in',l,line
			return False
	else:
		if verbose:
			print 'bad line[6]',line[6],l
		return False
	if len(line)>=9 and line[7]=='accelerate':
		try:
			if command == 'move' and ('[' not in line[8] or ']' not in line[8]):
				if verbose:
					print 'missing [ or ] in speed of move command',l
				return False
			elif command == 'turn' and ('<' not in line[8] or '>' not in line[8]):
				if verbose:
					print 'missing < or > in speed of turn command',l
				return False
			else:
				acc=float(line[8].strip('[]<>'))
		except:
			if verbose:
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
		for k in range(i+1,len(inputfile)):
			#if there is another move-now after it, then we ignore that.
			if parsebos(line,False) and parsebos(inputfile[k],False):
				orig=parsebos(line,False)
				next=parsebos(inputfile[k],False)
				if orig['c']==next['c'] and orig['p']==next['p'] and orig['a']==next['a']:
					print 'There is an identical move order ',k-i,'lines after, we just need to update the piece pos!'
					pieces[orig['p']][orig['c']][orig['a']]=orig['pos']
					break
			if 'sleep' in inputfile[k].partition('//')[0]: # .partition('//')[0] is the remove comment operator :D
				if 'animSpeed' in inputfile[k].partition('//')[0]:
					sleep='animSpeed'
					break
				else:
					if 'currentSpeed' in inputfile[k].partition('//')[0]:
						sleep='currentSpeed'
						try:
							animspeed=int(inputfile[k].partition('sleep')[2].partition('/')[0])/100
							break
						except ValueError:
							print 'failed to parse sleep in line',inputfile[k],'skipping'
							continue

					else:
						try:
							sleep=float(inputfile[k].partition('sleep')[2].partition(';')[0])
							break
						except ValueError:
							print 'failed to parse sleep in line',inputfile[k],'skipping'
							continue
			if '}' in inputfile[k].partition('//')[0]:
				print 'no sleep after now'
				break
		if sleep=='animSpeed' or sleep=='currentSpeed' or (sleep>minsleep and sleep < maxsleep): # we have the sleep value, time to find the last position the piece was at before this new NOW command!
			#important thing about sleep: #of frames= CEILING(sleep/33) (which means sleep 33 sleeps 2 frames!)
			if parsebos(line):
				bos=parsebos(line)
				print bos
				oldpos=pieces[bos['p']][bos['c']][bos['a']]
				if bos['s']=='now':
					dist=abs(oldpos-bos['pos'])
					if sleep=='animSpeed':
						smanim=True
						sleep=animspeed
					else:
						smanim=False
					if sleep=='currentSpeed':
						sleep=animspeed
					sleep=(int(sleep)/33+1)*33
					print sleep
					speed=dist/(float(sleep)/990)
					if dist!=0:
						if bos['c']=='turn':
							
							s='speed <%f>'%(speed)
						else:
							s='speed [%f]'%(speed)
						if smanim:
							s+=' * 100 / currentSpeed'
						inputfile[i]=line.replace('now',s)
				
					
				pieces[bos['p']][bos['c']][bos['a']]=bos['pos']
			else:
				print 'error parsing line',i

outf=open(output,'w')
outf.write(''.join(inputfile))
outf.close()
print 'Done'
				
				
				
				
				