import sys
import os
from s3o import S3O

from Tkinter import *
import tkFileDialog
import tkFont
# severities: wreck, heap, destroy

class App:

	def __init__(self, master):
		self.initialdir=os.getcwd()
		master.title('Dr. Killinger - By Beherith - Thanks to Muon\'s wonderful s3o library!')
		self.frame = Frame(master)
		self.topframe = Frame(self.frame, bd=1, relief = SUNKEN)
		self.severitiesframe = Frame(self.frame, bd=3, relief = SUNKEN)
		self.frame.pack()
		self.topframe.pack(side=TOP,fill=X)
		self.severitiesframe.pack(side=TOP,fill=X)
		
		self.menuframe=Frame(self.topframe,bd=3,relief=SUNKEN)
		self.treeframe=Frame(self.topframe,bd=2,relief=SUNKEN)
		self.menuframe.pack(side=LEFT,fill=Y)
		self.treeframe.pack(side=LEFT,fill=Y)
		#=========MENUFRAME STUFF:
		Button(self.menuframe, text="QUIT", fg="red", command=self.frame.quit).pack(side=TOP)
		Button(self.menuframe, text="Load mod",  command=self.loadmod).pack(side=TOP)
		Button(self.menuframe, text="Load unit", command=self.loadunit).pack(side=TOP)
		Button(self.menuframe, text="Write unit", command=self.saveunit).pack(side=TOP)
		Button(self.menuframe, text="Next unit", command=self.nextunit).pack(side=TOP)
		Button(self.menuframe, text="Prev unit", command=self.prevunit).pack(side=TOP)
		Button(self.menuframe, text="Wreck unit", command=self.wreckunit).pack(side=TOP)
		
		Label(self.menuframe,text='This is my magic murder bag').pack(side=LEFT)
		
		##========================
		
		##TREEFRAME:
		treefont=tkFont.Font(family='Courier New',size=10)
		self.treelabeltext=StringVar()
		
		self.treelabeltext.set('Tree goes here')
		self.treelabel=Label(self.treeframe, textvariable=self.treelabeltext, justify=LEFT, font=treefont)
		self.treelabel.pack(side=LEFT)
		
		##============================
		
		##==severityframe;
		self.wreckframe=Frame(self.severitiesframe,bd=3,relief=SUNKEN)
		self.wreckframe.pack(side=LEFT,fill=X)
		Label(self.wreckframe, text='Wreck').pack(side=LEFT)		
		
		self.heapframe=Frame(self.severitiesframe,bd=3,relief=SUNKEN)
		self.heapframe.pack(side=LEFT,fill=X)
		Label(self.heapframe, text='Heap').pack(side=LEFT)		
		
		self.destroyframe=Frame(self.severitiesframe,bd=3,relief=SUNKEN)
		self.destroyframe.pack(side=LEFT,fill=Y)
		Label(self.destroyframe, text='Destroy').pack(side=LEFT)
		#======
		
		#==== common objects:
		self.unitname=''
		self.modpath=''
		self.unitdefpath=''
		self.bospath=''
		self.s3opath=''
		self.s3o=0
		self.bos=0
		self.unitdef=0
		self.piecelist=[]
		self.killscript={}
		#=====
	def loadmod(self):
		return
	def loadunit(self):
		self.unitdefpath=tkFileDialog.askopenfilename(initialdir= self.initialdir,filetypes = [('Spring Model def (Lua)','*.lua'),('Any file','*')], multiple = False)
		print 'loading',self.unitdefpath
		if '.lua' in self.unitdefpath:
			self.modpath=self.unitdefpath.partition('units')[0]
			self.unitname=self.unitdefpath.rpartition('/')[2].partition('.')[0]
			self.bospath=self.modpath+'scripts/'+self.unitname+'.bos'
			self.s3opath=self.modpath+'objects3d/'+self.unitname+'.s3o'
			try:
				self.s3o=S3O(open(self.s3opath,'rb').read())
				self.bos=open(self.bospath,'r').readlines()
				self.unitdef=open(self.unitdefpath,'r').readlines()
			except:
				raise
			print 'loaded',self.unitname,'successfully'
			self.updatetree(self.s3o,self.piecelist)
			print self.piecelist
			self.loadbos(self.bos)
			
		return
	def updatetree(self,model,pl):
		namejust=20
		treestr='NAME                     vol #tris ox  oy  oz\n'+recursepiecetree(model.root_piece,0,(0,0,0),pl)
		
		self.treelabeltext.set(treestr)
	def loadbos(self, boslines):
		bospiecelist=[]
		killtable=[{},{},{},{}]
		l=0
		killedindex=0
		for line in boslines:

			#strip comments:
			line=uncomment(line)
			if line[0:5]=='piece':
	
				if ';' not in line:
					line+=uncomment(boslines[l+1])+uncomment(boslines[l+2])+uncomment(boslines[l+3]) #wow this is ugly, i cant write parsers for shit.
					line=line.partition(';')[0]+';'
				print line
				bospiecelist=[p.strip() for p in (line.partition('piece')[2].partition(';')[0]).split(',')]
				print 'bospiecelist',bospiecelist
			if 'Killed' in line:
				killedindex= -1
				for i in range(l+1,len(boslines)):
					line=uncomment(boslines[i])
					if 'corpsetype' in line: #lets hope to got that corpsetype always precedes explodes
						print line
						killedindex+=1	
					if 'explode' in line:
						p=delimit(line,'explode','type')
						flags=[x.strip() for x in delimit(line,'type',';').split('|')]
						print p,killedindex, flags
						killtable[killedindex][p]=flags
						
				break

			l+=1	
		if len(bospiecelist)!=self.piecelist:
			print 'WARNING: the bos piece list does not match the s3o piece list!', bospiecelist, self.piecelist
			
		return killtable
	def writebos(self):
		return
	def saveunit(self):
		return
	def nextunit(self):
		return
	def prevunit(self):
		return
	def wreckunit(self):
		return
	def opens3o(self):
		self.s3ofile = tkFileDialog.askopenfilename(initialdir= self.initialdir,filetypes = [('Spring Model file (S3O)','*.s3o'),('Any file','*')], multiple = True)
		self.s3ofile = string2list(self.s3ofile) 
		for file in self.s3ofile:
			if 's3o' in file.lower():
				self.initialdir=file.rpartition('/')[0]
				if self.promptobjfilename.get()==1:
					outputfilename=tkFileDialog.asksaveasfilename(initialdir= self.initialdir,filetypes = [('Object file','*.obj'),('Any file','*')])
					if '.obj' not in outputfilename.lower():
						outputfilename+='.obj'
				else:
					outputfilename=file.lower().replace('.s3o','.obj')
				S3OtoOBJ(file,outputfilename)
def delimit(s,l,r):
	return s.partition(l)[2].partition(r)[0].strip()
def uncomment(l):
	return l.partition('//')[0].strip()
def recursepiecetree(piece, depth,offset,pl): # we need the name offset by depth, the volume, the #triangles and the pos
	namejust=20
	s='%s %10.1f %5i %4.2f %4.2f %4.2f\n'%(('  '*depth+piece.name).ljust(30),piecevolume(piece), len(piece.indices), piece.parent_offset[0]+offset[0], piece.parent_offset[1]+offset[1], piece.parent_offset[2]+offset[2])
	print s
	pl.append(piece.name)
	for child in piece.children:
		s+=recursepiecetree(child, depth+1, (piece.parent_offset[0]+offset[0], piece.parent_offset[1]+offset[1], piece.parent_offset[2]+offset[2]),pl)
	return s
		
def piecevolume(piece):
	if len(piece.vertices)>0:
		xs=[x[0][0] for x in piece.vertices]
		ys=[x[0][1] for x in piece.vertices]
		zs=[x[0][2] for x in piece.vertices]
		#print xs
		return (max(xs)-min(xs))* (max(ys)-min(ys))* (max(zs)-min(zs))
	else:
		return 0
root = Tk()
app = App(root)
root.mainloop()
validflags=['SHATTER','EXPLODE','EXPLODE_ON_HIT','FALL','SMOKE','FIRE','NONE','NO_CEG_TRAIL','NO_HEATCLOUD']
#flagrules:
# EXPLODE=EXPLODE_ON_HIT  
# EXPLODE causes it to do 50 damage on impact!
#all pieces bounce with p=0.66
#void CUnitScript::Explode(int piece, int flags)
#flag processing order
#1. noheatcloud = obvious no heatcloud at site of explosion
#2. NONE: no stuff falls off, return
#3. SHATTER: shatters, return
#4. !! at this point, FALL IS TURNED ON!
#5. SMOKE is smoke, checked for particle saturation, uses projectileDrawer->smoketrailtex
#6. fire is fire, checked for particle saturation
#7. nocegtrail is passed, does not seem to be mutually exclusive with fire or smoke...
#UPDATE:
#if FIRE and hasvertices: rotate it and translate it (obvious since there is no need to rotate if it has no vertices)
# if nocegtrail and age%8!=0 and SMOKE: make a new smoke instance (gotta test this out)

##DRAW:
# if NOCEGTRAIL and SMOKE: default smoke drawn
# if FIRE: draw projectileDrawer->explofadetex
'''
	LuaPushNamedNumber(L, "SHATTER", PF_Shatter);
	LuaPushNamedNumber(L, "EXPLODE", PF_Explode);
	LuaPushNamedNumber(L, "EXPLODE_ON_HIT", PF_Explode);
	LuaPushNamedNumber(L, "FALL",  PF_Fall);
	LuaPushNamedNumber(L, "SMOKE", PF_Smoke);
	LuaPushNamedNumber(L, "FIRE",  PF_Fire);
	LuaPushNamedNumber(L, "NONE",  PF_NONE); // BITMAP_ONLY
	LuaPushNamedNumber(L, "NO_CEG_TRAIL", PF_NoCEGTrail);
	LuaPushNamedNumber(L, "NO_HEATCLOUD", PF_NoHeatCloud);
	'''