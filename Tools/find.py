import os
import sys
nokeys=[]
keys=[]
extensions=['lua','txt','fbi']
if len(sys.argv)<2:
	print 'Finds case sensitive strings in an entire mod. Looks in all lua, txt and fbi files.'
	print 'Usage: python find.py [key1] [key2] [-nokey] [*removefiletype]'
	print 'Example: python find.py category AIR -NOTSUB'
	print '	Marks all lines in every file that have the strings category and AIR and dont have NOTSUB'
	exit(1)
for a in range(1,len(sys.argv)):
	if sys.argv[a][0]=='-': #remove the key
		nokeys.append(sys.argv[a].partition('-')[2])
	elif sys.argv[a][0]=='*': #remove the extension
		if sys.argv[a].partition('*')[2] in extensions:
			extensions.remove(sys.argv[a].partition('*')[2])
		else:
			print sys.argv[a],'not an extension in ',extensions
	else:
		keys.append(sys.argv[a])
root=os.getcwd()
flist=os.listdir(root)
for base, dirs, files in os.walk(root):
	for file in files:
		flist.append( base+'\\'+file)
j=0
matches=0
for f in flist:
	j+=1
	ext=f.rpartition('.')[2].lower()
	if ext in extensions:
		flines=open(f).readlines()
		i=0
		for line in flines:
			i+=1
			good=1
			for key in keys:
				if key not in line:
					good=0
			if good==1:
				for key in nokeys:
					if key in line:
						good=0
			if good==1:
				print j,f.partition('.sdd')[2]
				print i,line.strip()
				matches+=1
print matches,'matches in',len(flist),'files'
log=open('findlog.log','a')
log.write(' '.join(sys.argv)+'	matches='+str(matches)+'\n')
log.close()