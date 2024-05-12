
' he separado la matriz de mapas, para hacer mas comoda su edicion

' --------- MAPA DE 8x8 ------------
#define mapX  8      ' map width
#define mapY  8      ' map height
#define mapS mapX*MapY  ' map cube size 64

' Edit these 3 arrays with values 0-4 to create your own level!
' nota jepalza: el "4" es la "puerta(door)" que podemos abrir con la tecla "e"
Dim Shared As Integer mapW(mapS -1)=_          ' walls
{_
 1,1,1,1,2,2,2,2,_
 6,0,0,1,0,0,0,2,_ ' 6=salida
 1,0,0,4,0,2,0,2,_ ' 4=puerta 1
 1,5,4,5,0,0,0,2,_ ' 4=puerta 2
 2,0,0,0,0,0,0,1,_
 2,0,0,0,0,1,0,1,_
 2,0,0,0,0,0,0,1,_
 1,1,1,1,1,1,1,1 _
} 

Dim Shared As Integer mapF(mapS -1)=_          ' floors
{_
 0,0,0,0,0,0,0,0,_
 0,0,0,0,2,2,2,0,_
 0,0,0,0,6,0,2,0,_
 0,0,8,0,2,7,6,0,_
 0,0,2,0,0,0,0,0,_
 0,0,2,0,8,0,0,0,_
 0,1,1,1,1,0,8,0,_
 0,0,0,0,0,0,0,0 _
} 

Dim Shared As Integer mapC(mapS -1)=_          ' ceiling
{_
 0,0,0,0,0,0,0,0,_
 0,0,0,0,0,0,0,0,_
 0,0,0,0,0,0,0,0,_
 0,0,0,0,0,0,0,0,_
 0,4,2,4,0,0,0,0,_
 0,0,2,0,0,0,0,0,_
 0,0,2,0,0,0,0,0,_
 0,0,0,0,0,0,0,0 _
} 
