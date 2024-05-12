'------------------------YouTube-3DSage----------------------------------------
'Full video: https://www.youtube.com/watch?v=w0Bm4IA-Ii8
'E open door after picking up the key
' WADS to move player.
'
' conversion a FreeBasic https://www.freebasic.net/ por Joseba Epalza (jepalza) 2024 
' (jepalza arroba gmail punto com)


#include "GL/glut.bi"



#Ifndef M_PI
	#Define M_PI 3.14159265359
	#Define PI M_PI
#EndIf

Function degToRad(a As Single) As Single 
	return a*M_PI/180.0
End Function

Function FixAng(a As Single) As Single 
	if(a>359) Then 
  		a-=360 
	EndIf
	if(a<0) Then 
	  a+=360 
	EndIf
   return a
End Function

Function distance(ax As Single , ay As Single , bx As Single , by As Single , ang As Single) As Single 
	return cos(degToRad(ang))*(bx-ax)-sin(degToRad(ang))*(by-ay)
End Function

Dim Shared As Single px,py,pdx,pdy,pa 
Dim Shared As Single frame1,frame2,fps 

Dim Shared As Integer gameState=0, timers=0 ' game state. init, start screen, game loop, win/lose
Dim Shared As single fade=0             ' the 3 screens can fade up from black

Type ButtonKeys 
	As Integer w,a,d,s                      ' button state on off
End Type
Dim Shared As ButtonKeys Keys 


#Include "Textures/All_Textures.ppm"
#include "Textures/sky.ppm"
#include "Textures/title.ppm"
#include "Textures/won.ppm"
#include "Textures/lost.ppm"
#include "Textures/sprites.ppm"

#include "mapas.bi"



Type sprite 
	As Integer types  ' static, key, enemy
	As Integer state  ' on off
	As Integer map    ' texture to show
	As Single x,y,z   ' position
End Type
Dim Shared As sprite spr(4-1) 

Dim Shared As Integer depth(120-1)       ' hold wall line depth to compare for sprite depth


Sub drawSprite()
	
	Dim As Integer x,y,s 
	
	' pick up key 
	If (px<spr(0).x+30) AndAlso (px>spr(0).x-30) AndAlso (py<spr(0).y+30) AndAlso (py>spr(0).y-30) Then 
		spr(0).state=0 
	EndIf
	
	' enemy kills
	If (px<spr(3).x+30) AndAlso (px>spr(3).x-30) AndAlso (py<spr(3).y+30) AndAlso (py>spr(3).y-30) Then 
		gameState=4 
	EndIf
	
	' enemy attack
	Dim As Integer spx=Int(spr(3).x) Shr 6, spy=Int(spr(3).y) Shr 6 ' normal grid position
	Dim As Integer spx_add=(Int(spr(3).x)+15) Shr 6, spy_add=(Int(spr(3).y)+15) Shr 6  ' normal grid position plus     offset
	Dim As Integer spx_sub=(Int(spr(3).x)-15) Shr 6, spy_sub=(Int(spr(3).y)-15) Shr 6  ' normal grid position subtract offset
	
	If (spr(3).x>px) AndAlso (mapW(spy*8+spx_sub)=0) Then spr(3).x-=0.04*fps 
	If (spr(3).x<px) AndAlso (mapW(spy*8+spx_add)=0) Then spr(3).x+=0.04*fps 
	If (spr(3).y>py) AndAlso (mapW(spy_sub*8+spx)=0) Then spr(3).y-=0.04*fps 
	If (spr(3).y<py) AndAlso (mapW(spy_add*8+spx)=0) Then spr(3).y+=0.04*fps 
	
	For s=0 To 3
		Dim As Single sx=spr(s).x-px  ' temp float variables
		Dim As Single sy=spr(s).y-py 
		Dim As Single sz=spr(s).z 
		
		Dim As Single CS=cos(degToRad(pa)), SN=sin(degToRad(pa))  ' rotate around origin
		Dim As Single a=sy*CS+sx*SN 
		Dim As Single b=sx*CS-sy*SN 
		sx=a
		sy=b 
		
		sx=(sx*108.0/sy)+(120/2)  ' convert to screen x,y
		sy=(sz*108.0/sy)+( 80/2) 
		
		Dim As Integer scale=32*80/b    ' scale sprite based on distance
		if(scale< 0 ) Then scale=0 
		if(scale>120) Then scale=120 
		
		' texture
		Dim As Single t_x=0, t_y=31, t_x_step=31.5/scale, t_y_step=32.0/scale 
		
		For x=sx-scale/2 To (sx+scale/2)-1       
			t_y=31 
			For y=0 To scale-1       
				If (spr(s).state=1) AndAlso (x>0) AndAlso (x<120) AndAlso (b<depth(x)) Then 
					Dim As Integer pixel =(Int(t_y)*32+int(t_x))*3+(spr(s).map*32*32*3) 
					Dim As Integer red   =sprites(pixel+0) 
					Dim As Integer green =sprites(pixel+1) 
					Dim As Integer blue  =sprites(pixel+2) 
					If (red<>255) OrElse (green<>0) OrElse (blue<>255) Then ' dont draw if purple
					   ' draw point
						glPointSize(8)
						glColor3ub(red,green,blue)
						glBegin(GL_POINTS)
							glVertex2i(x*8,sy*8-y*8)
						glEnd()
					EndIf
					t_y-=t_y_step
					If (t_y<0) Then t_y=0 
				EndIf
			Next y
			t_x+=t_x_step 
		Next x
	Next s
End Sub


' ---------------------------Draw Rays and Walls--------------------------------
Sub drawRays2D()
	
 	Dim As Integer r,mx,my,mp,dof,side
 	Dim As Single vx,vy,rx,ry,ra,xo,yo,disV,disH 

 	ra=FixAng(pa+30) ' ray set back 30 degrees

	For r=0 To 119       
		
		Dim As Integer vmt=0,hmt=0  ' vertical and horizontal map texture number
		' ---Vertical---
		dof=0: side=0: disV=100000 
		Dim As Single Tang=tan(degToRad(ra)) 
		If (cos(degToRad(ra))> 0.001) Then  ' looking left  
			rx=((Int(px) Shr 6) Shl 6)+64
			ry=(px-rx)*Tang+py: xo= 64
			yo=-xo*Tang
		ElseIf (cos(degToRad(ra))<-0.001) Then
		   ' looking right
			rx=((Int(px) Shr 6) Shl 6) -0.0001
			ry=(px-rx)*Tang+py
			xo=-64
			yo=-xo*Tang
		Else ' looking up or down. no hit
			rx=px
			ry=py
			dof=8
		EndIf
                                                    
	   While(dof<8)
		   mx=Int(rx) Shr 6
		   my=Int(ry) Shr 6
		   mp=my*mapX+mx 
		   If (mp>0) AndAlso (mp<mapX*mapY) AndAlso (mapW(mp)>0) Then 
		  		vmt=mapW(mp)-1
		  		dof=8
		  		disV=cos(degToRad(ra))*(rx-px)-sin(degToRad(ra))*(ry-py)  ' hit
		   Else
		   	' check next horizontal
		      rx+=xo
		      ry+=yo
		      dof+=1 
		   EndIf
	   Wend
	    
	   vx=rx: vy=ry 
	
	   ' ---Horizontal---
	   dof=0: disH=100000 
	   Tang=1.0/Tang 
	   If (sin(degToRad(ra))>0.001) Then ' looking up
		  	ry=((Int(py) Shr 6) Shl 6) -0.0001
		  	rx=(py-ry)*Tang+px: yo=-64
		  	xo=-yo*Tang
	   ElseIf (sin(degToRad(ra))<-0.001) Then ' looking down
	  		ry=((Int(py) Shr 6) Shl 6)+64
	  		rx=(py-ry)*Tang+px
	  		yo= 64
	  		xo=-yo*Tang
	   Else ' looking straight left or right
	     	rx=px
	     	ry=py
	     	dof=8 
	   EndIf                                    
	
	   While(dof<8)
		   mx=Int(rx) Shr 6
		   my=Int(ry) Shr 6
		   mp=my*mapX+mx 
		   if(mp>0) AndAlso (mp<mapX*mapY) AndAlso (mapW(mp)>0) Then 
		   	hmt=mapW(mp)-1
		   	dof=8
		   	disH=cos(degToRad(ra))*(rx-px)-sin(degToRad(ra))*(ry-py)  ' hit
		   Else ' check next horizontal
		   	rx+=xo
		   	ry+=yo
		   	dof+=1 
		   EndIf
	   Wend
	
	   Dim As Single shade=1 
	   glColor3f(0,0.8,0) 
	   ' horizontal hit first
	   If(disV<disH) Then 
	  		hmt=vmt
	  		shade=0.5
	  		rx=vx
	  		ry=vy
	  		disH=disV
	  		glColor3f(0,0.6,0) 
	   EndIf
	
	   Dim As Integer ca=FixAng(pa-ra): disH=disH*cos(degToRad(ca)) ' fix fisheye
	   Dim As Integer lineH = (mapS*640)/(disH) 
	   Dim As Single ty_step=32.0/lineH 
	   Dim As Single ty_off=0 
	   If (lineH>640) Then ty_off=(lineH-640)/2.0: lineH=640 :End If ' line height and limit
	   Dim As Integer lineOff = 320 - (lineH Shr 1) ' line offset
	
	   depth(r)=disH  ' save this line´s depth
	  
	   ' ---draw walls---
	   Dim As Integer y 
	   Dim As Single ty=ty_off*ty_step ' +hmt*32;
	   Dim As Single tx 
	   If(shade=1) Then 
	   	tx=Int(rx/2.0) Mod 32
	   	If(ra>180) Then tx=31-tx   
	   Else
	      tx=int(ry/2.0) Mod 32
	   	If(ra>90) AndAlso (ra<270) Then tx=31-tx 
	   EndIf
	  
	   For y=0 To lineH-1       
		   Dim As Integer pixel=(Int(ty)*32+Int(tx))*3+(hmt*32*32*3) 
		   Dim As Integer red   =All_Textures(pixel+0)*shade 
		   Dim As Integer green =All_Textures(pixel+1)*shade 
		   Dim As Integer blue  =All_Textures(pixel+2)*shade 
		   glPointSize(8)
		   glColor3ub(red,green,blue)
		   glBegin(GL_POINTS)
		   	glVertex2i(r*8,y+lineOff)
		   glEnd() 
		   ty+=ty_step 
	   Next
	
		  ' ---draw floors---
		For y=lineOff+lineH To 640-1       
		  
		  Dim As Single dy=y-(640/2.0), deg=degToRad(ra), raFix=cos(degToRad(FixAng(pa-ra))) 
		  tx=px/2 + cos(deg)*158*2*32/dy/raFix 
		  ty=py/2 - sin(deg)*158*2*32/dy/raFix 
		  Dim As Integer mp=mapF(Int(ty/32.0)*mapX+Int(tx/32.0))*32*32 
		  Dim As Integer pixel=((Int(ty) And 31)*32 + (Int(tx) And 31))*3+mp*3 
		  Dim As Integer red   =All_Textures(pixel+0)*0.7 
		  Dim As Integer green =All_Textures(pixel+1)*0.7 
		  Dim As Integer blue  =All_Textures(pixel+2)*0.7 
		  glPointSize(8)
		  glColor3ub(red,green,blue)
		  glBegin(GL_POINTS)
		  		glVertex2i(r*8,y)
		  glEnd() 
		
		 ' ---draw ceiling---
		  mp=mapC(Int(ty/32.0)*mapX+Int(tx/32.0))*32*32 
		  pixel=((Int(ty) And 31)*32 + (Int(tx) And 31))*3+mp*3 
		  red   =All_Textures(pixel+0) 
		  green =All_Textures(pixel+1) 
		  blue  =All_Textures(pixel+2) 
		  If (mp>0) Then 
			  glPointSize(8)
			  glColor3ub(red,green,blue)
			  glBegin(GL_POINTS)
			  		glVertex2i(r*8,640-y)
			  glEnd() 
		  EndIf
		  
		Next
 		ra=FixAng(ra-0.5) ' go to next ray, 60 total
	Next
	
End Sub
' -----------------------------------------------------------------------------


Sub drawSky()  ' draw sky and rotate based on player rotation
	Dim As Integer x,y 
	for y=0 To 39       
		for x=0 To 119       	
			Dim As Integer xo=Int(pa)*2-x
			If (xo<0) Then xo+=120 
			xo=xo Mod 120  ' return 0-120 based on player angle
			Dim As Integer pixel =(y*120+xo)*3 
			Dim As Integer red   =sky(pixel+0) 
			Dim As Integer green =sky(pixel+1) 
			Dim As Integer blue  =sky(pixel+2) 
			glPointSize(8)
			glColor3ub(red,green,blue)
			glBegin(GL_POINTS)
				glVertex2i(x*8,y*8)
			glEnd() 	
		Next
	Next
End Sub


Sub screens(v As Integer) ' draw any full screen image. 120x80 pixels
	
	Dim As Integer x,y 
	Dim As Integer Ptr T 
	
	If (v=1) Then T=@title(0) 
	If (v=2) Then T=@won(0)
	If (v=3) Then T=@lost(0)
	
	for y=0 To 79       
		for x=0 To 119       
			Dim As Integer pixel =(y*120+x)*3 
			Dim As Integer red   =T[pixel+0]*fade 
			Dim As Integer green =T[pixel+1]*fade 
			Dim As Integer blue  =T[pixel+2]*fade 
			glPointSize(8)
			glColor3ub(red,green,blue)
			glBegin(GL_POINTS)
				glVertex2i(x*8,y*8)
			glEnd() 
		Next
	Next
	
	If (fade<1) Then fade+=0.001*fps 
	If (fade>1) Then fade=1 
	
End Sub


Sub init() ' init all variables when game starts
	glClearColor(0.3,0.3,0.3,0) 
	px=150: py=400: pa=90 
	
	' init player
	pdx=cos(degToRad(pa))
	pdy=-sin(degToRad(pa))
	
	' close doors
	mapW(19)=4
	mapW(26)=4
	
	spr(0).types=1: spr(0).state=1: spr(0).map=0: spr(0).x=1.5*64: spr(0).y=5*64:   spr(0).z=20  ' key
	spr(1).types=2: spr(1).state=1: spr(1).map=1: spr(1).x=1.5*64: spr(1).y=4.5*64: spr(1).z= 0  ' light 1
	spr(2).types=2: spr(2).state=1: spr(2).map=1: spr(2).x=3.5*64: spr(2).y=4.5*64: spr(2).z= 0  ' light 2
	spr(3).types=3: spr(3).state=1: spr(3).map=2: spr(3).x=2.5*64: spr(3).y=2*64:   spr(3).z=20  ' enemy
End Sub


Sub display cdecl()
	
	' frames per second
	frame2=glutGet(GLUT_ELAPSED_TIME)
	fps=(frame2-frame1)
	frame1=glutGet(GLUT_ELAPSED_TIME) 
	glClear(GL_COLOR_BUFFER_BIT Or GL_DEPTH_BUFFER_BIT) 
	
	If (gameState=0) Then ' init game
		init()
		fade=0
		timers=0
		gameState=1 
	EndIf
	
	' start screen
	If (gameState=1) Then 
		screens(1)
		timers+=1*fps
		If (timers>2000) Then 
			fade=0
			timers=0
			gameState=2 
		EndIf
	EndIf
	
	' The main game loop
	If (gameState=2) Then 
		' buttons
		If (Keys.a=1) Then 
			pa+=0.2*fps
			pa=FixAng(pa)
			pdx= Cos(degToRad(pa))
			pdy=-sin(degToRad(pa)) 
		EndIf
		
		If (Keys.d=1) Then 
			pa-=0.2*fps
			pa=FixAng(pa)
			pdx= Cos(degToRad(pa))
			pdy=-sin(degToRad(pa)) 
		EndIf
		
		Dim As Integer xo=0 ' x offset to check map
		If (pdx<0) Then 
			xo=-20
		else
			xo=20 
		EndIf
		                             
		Dim As Integer yo=0 ' y offset to check map
		If (pdy<0) Then 
			yo=-20
		else
			yo=20 
		EndIf
		                             
		Dim As Integer ipx=px\64.0, ipx_add_xo=(px+xo)\64.0, ipx_sub_xo=(px-xo)\64.0 ' x position and offset
		Dim As Integer ipy=py\64.0, ipy_add_yo=(py+yo)\64.0, ipy_sub_yo=(py-yo)\64.0 ' y position and offset
		
		If (Keys.w=1) Then ' move forward
			If (mapW(ipy*mapX + ipx_add_xo)=0) Then px+=pdx*0.2*fps 
			If (mapW(ipy_add_yo*mapX + ipx)=0) Then py+=pdy*0.2*fps 
		EndIf
	
		If (Keys.s=1) Then ' move backward
			If (mapW(ipy*mapX + ipx_sub_xo)=0) Then px-=pdx*0.2*fps 
			If (mapW(ipy_sub_yo*mapX + ipx)=0) Then py-=pdy*0.2*fps 
		EndIf
		
		drawSky() 
		drawRays2D() 
		drawSprite() 
		' Entered block 1, Win game!!
		If ((Int(px) Shr 6)=1) AndAlso ((Int(py) Shr 6)=1) Then 
			fade=0
			timers=0
			gameState=3 
		EndIf
	EndIf
	
	' won screen
	If (gameState=3) Then 
		screens(2)
		timers+=1*fps
		If (timers>2000) Then 
			fade=0
			timers=0
			gameState=0 
		EndIf
	EndIf
	
	' lost screen
	If (gameState=4) Then 
		screens(3)
		timers+=1*fps
		If (timers>2000) Then 
			fade=0
			timers=0
			gameState=0 
		EndIf
	EndIf
	
	glutPostRedisplay() 
	glutSwapBuffers() 
End Sub


Sub ButtonDown cdecl(ByVal key As UByte ,byval x As Integer ,byval y As Integer) ' keyboard button pressed down

 If key=Asc("a") Then Keys.a=1 
 If key=Asc("d") Then Keys.d=1 
 If key=Asc("w") Then Keys.w=1 
 If key=Asc("s") Then Keys.s=1 

 If key=Asc("e") AndAlso (spr(0).state=0) Then  ' open doors
	
	Dim As Integer xo=0
	if(pdx<0) Then 
		xo=-25
	else
		xo=25 
	EndIf
	
	Dim As Integer yo=0
	if(pdy<0) Then 
		yo=-25
	else
		yo=25 
	EndIf
	
	Dim As Integer ipx=px\64.0, ipx_add_xo=(px+xo)\64.0 
	Dim As Integer ipy=py\64.0, ipy_add_yo=(py+yo)\64.0 
	If (mapW(ipy_add_yo*mapX+ipx_add_xo)=4) Then 
		 mapW(ipy_add_yo*mapX+ipx_add_xo)=0 
	EndIf
	
 EndIf
  
 glutPostRedisplay() 
End Sub


Sub ButtonUp cdecl(ByVal key As UByte ,byval x As Integer ,byval y As Integer) ' keyboard button pressed up

 If key=Asc("a") Then Keys.a=0 
 If key=Asc("d") Then Keys.d=0 
 If key=Asc("w") Then Keys.w=0 
 If key=Asc("s") Then Keys.s=0 
  
 glutPostRedisplay() 
End Sub

Sub resize cdecl(w As Integer , h As Integer) ' screen window rescaled, snap back
	glutReshapeWindow(960,640) 
End Sub


 glutinit(1," ") ' argc=1, argv=" "
 
 glutInitDisplayMode(GLUT_DOUBLE Or GLUT_RGB) 
 glutInitWindowSize(960,640) 
 glutInitWindowPosition( glutGet(GLUT_SCREEN_WIDTH)/2-960/2 ,glutGet(GLUT_SCREEN_HEIGHT)/2-640/2 ) 
 glutCreateWindow("YouTube-3DSage")
 gluOrtho2D(0,960,640,0)
 
 init() 
 
 glutDisplayFunc(@display) 
 glutReshapeFunc(@resize) 
 glutKeyboardFunc(@ButtonDown) 
 glutKeyboardUpFunc(@ButtonUp) 
 
 glutMainLoop() 

