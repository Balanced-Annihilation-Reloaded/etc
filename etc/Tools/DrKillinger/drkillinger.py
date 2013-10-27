import sys
import os
from s3o import S3O

from Tkinter import *
# from ttk import *
import tkFileDialog
import tkFont
# severities: wreck, heap, destroy

class VerticalScrolledFrame(Frame):
	"""A pure Tkinter scrollable frame that actually works!
	* Use the 'interior' attribute to place widgets inside the scrollable frame
	* Construct and pack/place/grid normally
	* This frame only allows vertical scrolling

	"""
	def __init__(self, parent, *args, **kw):
		Frame.__init__(self, parent, *args, **kw)			

		# create a canvas object and a vertical scrollbar for scrolling it
		vscrollbar = Scrollbar(self, orient=VERTICAL, width=24)
		vscrollbar.pack(fill=Y, side=RIGHT, expand=FALSE)
		canvas = Canvas(self, bd=0, highlightthickness=0,
						yscrollcommand=vscrollbar.set)
		canvas.pack(side=LEFT)#, fill=BOTH, expand=TRUE)
		vscrollbar.config(command=canvas.yview)
		self.vscrollbar=vscrollbar
		# reset the view
		canvas.xview_moveto(0)
		canvas.yview_moveto(0)
		self.canvas=canvas

		# create a frame inside the canvas which will be scrolled with it
		self.interior = interior = Frame(canvas,bg='red', bd=5)
		interior_id = canvas.create_window(0, 0, window=interior,
										   anchor=NW)

		# track changes to the canvas and frame width and sync them,
		# also updating the scrollbar
		def _configure_interior(event):
			# update the scrollbars to match the size of the inner frame
			size = (interior.winfo_reqwidth(), interior.winfo_reqheight())
			canvas.config(scrollregion="0 0 %s %s" % size)
			print '_configure_interior', size, interior.winfo_reqwidth(),interior.winfo_reqheight()
			if interior.winfo_reqwidth() != canvas.winfo_width():
				# update the canvas's width to fit the inner frame
				canvas.config(width=interior.winfo_reqwidth())
			if interior.winfo_reqheight() != canvas.winfo_height(): #uncommenting this makes it expand to full, but scrolling still does not work
				# update the canvas's width to fit the inner frame
				canvas.config(height=min(interior.winfo_reqheight(),900))
			
		interior.bind('<Configure>', _configure_interior)

		def _configure_canvas(event):
			if interior.winfo_reqwidth() != canvas.winfo_width():
				# update the inner frame's width to fill the canvas
				canvas.itemconfigure(interior_id, width=canvas.winfo_width())#, height=canvas.winfo_height())
			print '_configure_canvas', interior.winfo_reqwidth(),canvas.winfo_width(),interior.winfo_reqheight(),canvas.winfo_width()
		canvas.bind('<Configure>', _configure_canvas)

class App:

	def __init__(self, master):
		# root = Tk.__init__(self, *args, **kwargs)
		self.initialdir=os.getcwd()
		master.title('Dr. Killinger - By Beherith - Thanks to Muon\'s wonderful s3o library!')
		self.frame = Frame(master, bg='yellow', bd=10)
		self.topframe = Frame(self.frame, bd=1, relief = SUNKEN)
		self.bottomframe = Frame(self.frame, bd=5, bg='green', relief = SUNKEN)
		self.bottomframe.pack(side=RIGHT, fill=BOTH,expand=1)
		self.VSF = VerticalScrolledFrame(self.bottomframe)
		self.severitiesframe =Frame(self.VSF.interior, bg='blue',bd=10)
		#self.VSF.interior.pack(side=TOP)#,fill=BOTH,expand=1) #THIS MAKES IT ALL GO TO SHIT DO NOT UNCOMMENT
		self.VSF.pack(fill=BOTH)
		self.frame.pack(side=TOP,fill=BOTH, expand = 1)
		self.topframe.pack(side=LEFT,fill=BOTH)
		self.severitiesframe.pack(side=BOTTOM,fill=BOTH,expand=1)
		self.validflags=['SHATTER','EXPLODE','FALL','SMOKE','FIRE','NONE','NO_CEG_TRAIL','NO_HEATCLOUD']
		self.menuframe=Frame(self.topframe,bd=3,relief=SUNKEN)
		self.treeframe=Frame(self.topframe,bd=2,relief=SUNKEN)
		self.menuframe.pack(side=TOP,fill=Y)
		self.treeframe.pack(side=TOP,fill=Y)
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
		self.treefont=tkFont.Font(family='Courier New',size=8)
		self.treelabeltext=StringVar()
		
		self.treelabeltext.set('Tree goes here')
		self.treelabel=Label(self.treeframe, textvariable=self.treelabeltext, justify=LEFT, font=self.treefont)
		self.treelabel.pack(side=LEFT)
		
		##============================
		
		##==severityframe;
		self.wreckframe=Frame(self.severitiesframe,bd=3,relief=SUNKEN)
		self.wreckframe.pack(side=TOP,fill=X)
		Label(self.wreckframe, text='Wreck').pack(side=LEFT)		
		
		self.heapframe=Frame(self.severitiesframe,bd=3,relief=SUNKEN)
		self.heapframe.pack(side=TOP,fill=X)
		Label(self.heapframe, text='Heap').pack(side=LEFT)		
		
		self.destroyframe=Frame(self.severitiesframe,bd=3,relief=SUNKEN)
		self.destroyframe.pack(side=TOP,fill=X)
		Label(self.destroyframe, text='Destroy').pack(side=LEFT)
		
		self.annihilateframe=Frame(self.severitiesframe,bd=3,relief=SUNKEN)
		self.annihilateframe.pack(side=TOP,fill=X)
		Label(self.annihilateframe, text='SelfD').pack(side=LEFT)
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
		self.uiframes=[self.wreckframe,self.heapframe,self.destroyframe,self.annihilateframe]
		self.severitylevels=[25,50,99,-1]
		#=====
		self.loadunit('D:/spring/ETC/Tools/DrKillinger/units/aseadragon.lua')
	def loadmod(self):
		print 'vscrollbar.get',self.VSF.vscrollbar.get()
		self.VSF.canvas.yview_moveto(20)
		return
	def loadunit(self, default=''):
		if default=='':
			self.unitdefpath=tkFileDialog.askopenfilename(initialdir= self.initialdir,filetypes = [('Spring Model def (Lua)','*.lua'),('Any file','*')], multiple = False)
		else:
			self.unitdefpath=default
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
			self.killscript=self.loadbos(self.bos)
			print self.killscript
			self.createui(self.killscript)
		return
	def updatetree(self,model,pl):
		namejust=20
		treestr='NAME          volume (elmos) #tris  ox   oy   oz\n'+recursepiecetree(model.root_piece,0,(0,0,0),pl)
		self.treelabeltext.set(treestr)
	def createui(self,killtable):
		
		i=0
		for ctype in killtable:
			
			sevframe=Frame(self.uiframes[i])
			sevframe.pack(side=TOP,fill=X)
			sev=self.severitylevels[i]
			if 'severity' in ctype:
				sev=ctype['severity']
			ctype['severity']=StringVar()
			ctype['severity'].set(str(sev))
			
			Label(sevframe, text='Severity <=').pack(side=LEFT)
			Entry(sevframe,width=4,textvariable=ctype['severity']).pack(side=LEFT)
			
			for piece in self.piecelist:
				if piece in ctype:
					self.makerow(i,piece,ctype[piece])
				else:
					self.makerow(i,piece,[])
			i+=1
	def makerow(self, sevlevel, piece, flags):
		print sevlevel
		rowframe=Frame(self.uiframes[sevlevel])
		rowframe.pack(side=TOP,fill=X)
		Label(rowframe,text=piece.ljust(12),font=self.treefont).pack(side=LEFT)
		
		self.killscript[sevlevel][piece]={}
	
		for flag in self.validflags:
			val=IntVar()
			val.set(0)
			if flag in flags:
				val.set(1)
				print flag,piece,'should be set'
			self.killscript[sevlevel][piece][flag]=val
			Checkbutton(rowframe,text=flag, variable=val).pack(side=LEFT)
		
	def loadbos(self, boslines):
		bospiecelist=[]
		killtable=[{},{},{},{}]
		l=0
		killedindex=0
		for line in boslines:

			#strip comments:
			line=uncomment(line)
			if line[0:5]=='piece' and bospiecelist==[]:
	
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
						if 'EXPLODE_ON_HIT' in flags and 'EXPLODE' not in flags:
							del flags[flags.index('EXPLODE_ON_HIT')]
							flags.append('EXPLODE')
						for flag in flags:
							if flag not in self.validflags:
								del flags[flags.index(flag)]
								
						killtable[killedindex][p.lower()]=flags
						
				break

			l+=1	
		if len(bospiecelist)!=len(self.piecelist):
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
	s='%s %10.1f %5i %4.2f %4.2f %4.2f\n'%((' '*depth+piece.name).ljust(17),piecevolume(piece), len(piece.indices), piece.parent_offset[0]+offset[0], piece.parent_offset[1]+offset[1], piece.parent_offset[2]+offset[2])
	print s
	pl.append(piece.name.lower())
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
validflags=['SHATTER','EXPLODE','FALL','SMOKE','FIRE','NONE','NO_CEG_TRAIL','NO_HEATCLOUD']
#flagrules:
# EXPLODE=EXPLODE_ON_HIT  
# EXPLODE causes it to do 50 damage on impact!
#all pieces bounce with p=0.66
#void CUnitScript::Explode(int piece, int flags)
#flag processing order
#1. noheatcloud = obvious no heatcloud at site of explosion, heatcloudtex is bitmaps/explo.tga
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

#EXTENSIONS:
# if we dont want to explode all stuff at once, we can add a delay to it, even explode some pieces multiple times...
# pieces that get exploded and fall off MUST be hidden in the same frame as they are exploded, or else it looks funny
# bugs: units that dont finish their killscripts are put on a 'pause'
# they seem to be paralyzed, and somehow health bars are messing up
# units that are waiting on killscript stop dead in their tracks, and they wreck continues sliding after they finish the script
# units seem to return a corpsetype of 1 no matter what, if there are sleeps in the killscript...
# attacking units seem to retain their targets of dying units while the killscript executes, they do not fire, just target them like neutral units (and move to acquire target)
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