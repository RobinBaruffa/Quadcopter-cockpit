int altitudeInitiale = 150;  //Nécessaire au calcul de l altitude par rapport au niveau de la mer


import processing.video.*;

Capture cam;



import processing.serial.*;
Serial myPort;  // Création de l'objet myPort désignant le port de série
                //nécessaire au transfert de donnée entre Arduino et Processing
int [] donnees_radio = {0,0,0,0,0,0};  //Définition du tableau stockant les valeurs des capteurs
String data;

int x=1280;
int y=720;
float altituderelative;
float horizona;
float horizonb;
float coord1y;
float coord2y;
float coord3y;
float coord4y;
float coord1x;
float coord2x;
float coord3x;
float coord4x;
float boussoledrone;
float boussole;
float potpourcentage;
float batterie;
float altimetre;
float altimetrea;
float altimetreb;
float ypot = y*20.5/24;
boolean interrupteur ;
PImage interrupteur_ouvert;
PImage interrupteur_ferme;
PImage milieuboussole;
PImage coteboussole;
PImage altimetreimage;




//Bienvenue sur notre programme d'ISN destiné à afficher la caméra et les instruments
//de bord de notre quadricoptère !! Vous remarquerez rapidement que le programme est
//presqu'intégralement rédigé avec des fonctions, afin qu'il soit compatible avec 
//toute taille d'écran désirée. Cela rend sa compréhension plus difficile, mais
//ne vous inquiétez pas, je serais la pour vous guider. Malhereusement à cause du fait
//que vous ne possédez pas le circuit électronique adéquat, vous ne pourrez pas éxécuter
//ce programme, car aucune donnée n'arrive du port de série, mais vous pourrez le voir évidemment
//en action le jour de notre oral.







void batterie(int batterie){//un simple affichage de texte dans un cadre
fill(0,0,0);
textSize(y/10);
text(int(batterie),x/12,y*39/40);
if(batterie<10){     //le if est là pour décaler le charactère "%" en fonction
text("%",x/7.5,y*39/40);}  // de la charge de la batterie.
if(batterie<100 && batterie>=10){
text("%",x/5.5,y*39/40);}
textSize(y/60);
text("batterie",1*x/7,y*159/160);
}



void altituderelative(int altituderelative){//idem
fill(0,0,0);
textSize(y/10);
text(int(altituderelative),6*x/8,y*39/40);
if(altituderelative>=0 && altituderelative<10){     
text("m",6.4*x/8,y*39/40);} 
if(altituderelative<100 && altituderelative>=10){
text("m",6.8*x/8,y*39/40);}
if(altituderelative<0 && altituderelative>=-10){
text("m",6.8*x/8,y*39/40);}
textSize(y/60);
text("altitude relative",6.25*x/8,y*159/160);
}


void altimetre(float altimetre){//ici, on fait tourner de très fins rectangles servant d'aiguilles
                                 //au dessus d'un cadran de potentiomètre
  altimetre = altimetre   + altitudeInitiale;
  fill(255,255,255);
  pushMatrix(); //le couple pushMatrix/popMatrix sert à ce que nos translations et                 
  float altimetrea = ((altimetre/100)*360) - 90;//rotations n'aient pas de conséquences 
  translate(x/2,y*17/24);                       //sur le reste du programme
  rotate(radians(altimetrea));   //ici, on effectue une translation puis une rotation
  rect(-x/200,-y/200,x/12,y/150);//pour pouvoir faire tourner l'aiguille autour du
  popMatrix();                   //centre du cercle, puis on recommence la maneuvre.
  pushMatrix();
  translate(x/2,y*17/24);
  textSize(y/60);
  text("1m par    graduation",-43,0);
  float altimetreb = ((altimetre/100)*360)/10 - 90;
  rotate(radians(altimetreb));
  rect(-x/120,-y/120,x/16,y/75);
  popMatrix();
  fill(0);
  textSize(y/10);
  text(int(altimetre),5*x/12,y*22.4/24);
  if(altimetre<10){    
  text("m",x/2.15,y*22.4/24);}  
  if(altimetre<100 && altimetre>=10){
  text("m",x/1.95,y*22.4/24);}
  textSize(y/60);
  text("altitude absolue",5.4*x/12,y*23/24);
  
}

void boussole(int boussole){//pour faire fonctionner la boussole, on a d'abord séparé le centre 
                //d'une image de boussole de son contour à l'aide de gimp, puis on 
                //a fait bouger le contour de la boussole autour de son centre, comme
                //le ferait une vraie boussole
  pushMatrix();                              //ici, on utilise le translate et le
  translate((x/15)+(x/10),(y*7.5/12)+(y/8)); //du contour de la boussole autour de 
  rotate(radians(boussole));                 //celle du centre de la boussile
  image(coteboussole,-x/10,-x/10,x/5,x/5);
  popMatrix();
  image(milieuboussole,x/15,y*7.4/12,x/5,x/5);
}



  
void interrupteur(){//les if servent à faire varier la valeur booléenne interrupteur:
                    //si interrupteur est vrai, alors l'interrupteur est fermé, sinon
                    //il est ouvert.
  if ( interrupteur == false && mousePressed == true && 
      mouseX>2*x/7 && mouseX<27*x/70 && mouseY>y*15/24 && mouseY<y*57/72){

     interrupteur = true;
     mousePressed = false;
   } 
  if( interrupteur == true && mousePressed == true  && 
      mouseX>2*x/7 && mouseX<27*x/70 && mouseY>y*15/24 && mouseY<y*57/72){
    image(interrupteur_ouvert,2*x/7,y*15/24,x/10,y/6);
     interrupteur = false;
     mousePressed = false;
   }
  if( interrupteur == true) {image(interrupteur_ferme,2*x/7,y*15/24,x/10,y/6);}
  if( interrupteur == false){image(interrupteur_ouvert,2*x/7,y*15/24,x/10,y/6);}
}


void potentiometre(){//le if mousePressed=true sert a verifier la condition que le 
                     //bouton de la souris soit enfoncé pour qu'on puisse bouger 
                     //l'interrupteur.
  if(mousePressed == true && mouseX > 7.6*x/12 && mouseX < 8.5*x/12
  && mouseY>y*14.5/24 && mouseY<(y*20.5/24+x/112)){
  ypot = mouseY-x/112;
  potpourcentage = (((y*20.5/24)-ypot)/(y*14.5/24)/0.4310)*100;
}
fill(0);
rect(7.4*x/12,y*21.5/24,x*1/9,y/14);
rect(7.9*x/12,y*14.5/24,x/56,y/4);  
fill(255,0,0);
rect(7.6*x/12,ypot,x/14,y/56);
fill(255);
textSize(y/12);
text(int(potpourcentage),7.35*x/12,y*23/24);
}  


void horizon(int horizona, int horizonb){//l'horizon artificiel est la partie la plus complexe, donc
               //j'espère pouvoir montrer ma manière de procéder au mieux
  // horizona correspond à l'inclinaison du drone
  //horizonb correspond à la prise de hauteur du drone
  if(horizonb>=5*y/60){horizonb=5*y/60;}
  if(horizonb<=-5*y/60){horizonb= -5*y/60;}
  coord1y = 0 + horizona  - horizonb; //ici,on détermine les coordonnées des coins des deux formes qui font 
  coord2y = 0 - horizona - horizonb;  //l'horizon artificiel (une forme bleue, et une brune)
  coord3y = 0-horizona - horizonb;
  coord4y = 0+horizona - horizonb;
  coord1x = -x/10;
  coord2x = x/10;
  coord3x = x/10;
  coord4x = -x/10;
  
  
  //ici, on détermine le déplacement du x de ces coins lorsque l'on atteint
  //la "zone de virage" de la forme du cadran. Il faut définir le déplacement
  //de manière assez fréquente car une fonction constante ne marche pas.
  if(coord1y>=y/10 && coord1y<=13*y/120){coord1x = coord1x+ coord1y/10;}
  if(coord1y>=13*y/120 && coord1y<=7*y/60){coord1x = coord1x+ coord1y/8;}
  if(coord1y>=7*y/60 && coord1y<=1*y/8){coord1x = coord1x+ coord1y/5;}
  if(coord1y>=1*y/8){coord1x = coord1x+ coord1y/4.3;}
  if(coord1y>=x/10){coord1y=x/10;coord1x=2.3*coord1x+horizona-horizonb;}
  if(coord1y>=-13*y/120 && coord1y<=-y/10){coord1x = coord1x- coord1y/10;}
  if(coord1y>=-7*y/60 && coord1y<=-13*y/120){coord1x = coord1x- coord1y/8;}
  if(coord1y>=-1*y/8 && coord1y<=-7*y/60){coord1x = coord1x- coord1y/5;}
  if(coord1y<=-1*y/8){coord1x = coord1x- coord1y/4.3;}
  if(coord1y<=-x/10){coord1y=-x/10;coord1x=2.3*coord1x-horizona+horizonb;}
  
  if(coord2y>=y/10 && coord2y<=13*y/120){coord2x = coord2x- coord2y/10;}
  if(coord2y>=13*y/120 && coord2y<=7*y/60){coord2x = coord2x- coord2y/8;}
  if(coord2y>=7*y/60 && coord2y<=1*y/8){coord2x = coord2x- coord2y/5;}
  if(coord2y>=1*y/8){coord2x = coord2x- coord2y/4.3;}
  if(coord2y>=x/10){coord2y=x/10;coord2x=2.3*coord2x+horizona+horizonb;}
  if(coord2y>=-13*y/120 && coord2y<=-y/10){coord2x = coord2x+ coord2y/10;}
  if(coord2y>=-7*y/60 && coord2y<=-13*y/120){coord2x = coord2x+ coord2y/8;} 
  if(coord2y>=-1*y/8 && coord2y<=-7*y/60){coord2x = coord2x+ coord2y/5;}
  if(coord2y<=-1*y/8){coord2x = coord2x+ coord2y/4.3;}
  if(coord2y<=-x/10){coord2y=-x/10;coord2x=2.3*coord2x-horizona-horizonb;}
  
  if(coord3y>=y/10 && coord3y<=13*y/120){coord3x = coord3x- coord3y/10;}
  if(coord3y>=13*y/120 && coord3y<=7*y/60){coord3x = coord3x- coord3y/8;}
  if(coord3y>=7*y/60 && coord3y<=1*y/8){coord3x = coord3x- coord3y/5;}
  if(coord3y>=1*y/8){coord3x = coord3x- coord3y/4.3;}
  if(coord3y>=x/10){coord3y=x/10;coord3x=2.3*coord3x+horizona+horizonb;}
  if(coord3y>=-13*y/120 && coord3y<=-y/10){coord3x = coord3x+ coord3y/10;}
  if(coord3y>=-7*y/60 && coord3y<=-13*y/120){coord3x = coord3x+ coord3y/8;}
  if(coord3y>=-1*y/8 && coord3y<=-7*y/60){coord3x = coord3x+ coord3y/5;}
  if(coord3y<=-1*y/8){coord3x = coord3x+ coord3y/4.3;}
  if(coord3y<=-x/10){coord3y=-x/10;coord3x=2.3*coord3x-horizona-horizonb;}
  
  if(coord4y>=y/10 && coord4y<=13*y/120){coord4x = coord4x+ coord4y/10;}
  if(coord4y>=13*y/120 && coord4y<=7*y/60){coord4x = coord4x+ coord4y/8;}
  if(coord4y>=7*y/60 && coord4y<=1*y/8){coord4x = coord4x+ coord4y/5;}
  if(coord4y>=1*y/8){coord4x = coord4x+ coord4y/4.3;}
  if(coord4y>=x/10){coord4y=x/10;coord4x=2.3*coord4x+horizona-horizonb;}
  if(coord4y>=-13*y/120 && coord4y<=-y/10){coord4x = coord4x- coord4y/10;}
  if(coord4y>=-7*y/60 && coord4y<=-13*y/120){coord4x = coord4x- coord4y/8;} 
  if(coord4y>=-1*y/8 && coord4y<=-7*y/60){coord4x = coord4x- coord4y/5;}
  if(coord4y<=-1*y/8){coord4x = coord4x- coord4y/4.3;}
  if(coord4y<=-x/10){coord4y=-x/10;coord4x=2.3*coord4x-horizona+horizonb;}
  
//on utilise un translate pour pouvoir travailler autour du centre de la
//forme, ce qui est plus pratique pour les rotations, car cela permet
//de tourner autour du centre de la forme.
translate(x-x/6,y*9/12);
noFill();
stroke(0);
beginShape();        //la forme que nous créons ici est celle du cadran.
vertex(-y/10,-x/10); //On utilise des vertex car ce n'est pas un polygone
vertex(y/10,-x/10);  //connu par processing.Un Vertex est un segment
vertex(x/10,-y/10);  //du polygone, défini par son x et y "d'arrivée"
vertex(x/10,y/10);
vertex(y/10,x/10);
vertex(-y/10,x/10);
vertex(-x/10,y/10);
vertex(-x/10,-y/10);
endShape(CLOSE);
fill(0,0,255);
beginShape();                                //cette forme est la forme 
vertex(coord1x ,coord1y);                    //bleue "du haut".Ses "coins
if (coord1y==x/10){vertex(-y/10 ,x/10);};    //mouvants" sont définis par
if (coord1y>0){vertex(-x/10 ,y/10);};        //les variables coord1 et coord2
if (coord1y==-x/10){vertex(-y/10 ,-x/10);};  //on est obligé de faire des 
vertex(-x/10 ,-y/10);                        //segments "alternatifs" pour
vertex(-y/10,-x/10);                         //éviter que la forme soit
vertex(y/10,-x/10);                          //incomplète lorsqu'elle 
vertex(x/10,-y/10);                          //passe par un point.
if (coord2y>0){vertex(x/10 ,y/10);};
if (coord2y==x/10){vertex(y/10 ,x/10);};
if (coord2y==-x/10){vertex(y/10 ,-x/10);};
vertex(coord2x,coord2y);
endShape();
fill(75,0,0);
beginShape();                               //cette forme est la forme 
vertex(coord3x,coord3y);                    //brune "du bas".Ses "coins
if (coord3y==-x/10){vertex(y/10 ,-x/10);};  //mouvants" sont définis par
if (coord3y<0){vertex(x/10 ,-y/10);};       //les variables coord3 et coord4
if (coord3y==x/10){vertex(y/10 ,x/10);};
vertex(x/10,y/10);
vertex(y/10,x/10);
vertex(-y/10,x/10);
vertex(-x/10,y/10);
if (coord4y<0){vertex(-x/10 ,-y/10);};
if (coord4y==-x/10){vertex(-y/10 ,-x/10);};
if (coord4y==x/10){vertex(-y/10 ,x/10);};
vertex(coord4x,coord4y);
endShape();
fill(255);
rect(-x/10,-1.5*y/600,2*x/10,3*y/600);
noFill();
stroke(255);
arc(0,0,x/5,x/5,PI,2*PI);
fill(255);
pushMatrix();
rotate(-80*PI/180);    //Ici, on met les traits de graduation à 10° près
rect(0,-x/10,2,10);      //exactement grâce aux rotations.On commence à-80°
rotate(10*PI/180);     //puis on va jusqu'à 80° petit à petit
rect(0,-x/10,2,10);
rotate(10*PI/180);
rect(0,-x/10,2,10);
rotate(10*PI/180);
rect(0,-x/10,2,10);
rotate(10*PI/180);
rect(0,-x/10,2,10);
rotate(10*PI/180);
rect(0,-x/10,2,10);
rotate(10*PI/180);
rect(0,-x/10,2,10);
rotate(10*PI/180);
rect(0,-x/10,2,10);
rotate(10*PI/180);
rect(0,-x/10,2,30);
rotate(10*PI/180);
rect(0,-x/10,2,10);
rotate(10*PI/180);
rect(0,-x/10,2,10);
rotate(10*PI/180);
rect(0,-x/10,2,10);
rotate(10*PI/180);
rect(0,-x/10,2,10);
rotate(10*PI/180);
rect(0,-x/10,2,10);
rotate(10*PI/180);
rect(0,-x/10,2,10);
rotate(10*PI/180);
rect(0,-x/10,2,10);
rotate(10*PI/180);
rect(0,-x/10,2,10);
popMatrix();
stroke(0);
fill(255);
textSize(y/60);
text("1 graduation vaut 10°",-y*1/11,x/10);
}

int [] getData(){    //Cette fonction récupère les données du port de série, les traite et
                     //les réinjecte dans le programme
  

  if ( myPort.available() > 0) //Si un périphérique est branché
  {  
  String buffer = myPort.readStringUntil('&');  //Lire le moniteur de série jusqu'au retour
                                                //à la ligne et le stocke dans un buffeur
  
  if(buffer != null && buffer.length() > 13){     //Si le buffeur n'est pas vide
  data = buffer;          //Affecter sa valeur à la chaine de caractère data
  buffer = null;          //Et réinitialiser le buffeur
  donnees_radio= int(split(data, ','));  //La chaîne de caractère venant du port de série 
                                         //etant composée d'entiers séparés par une virgule
                                         //on les sépare et on les stocke dans un tableau
  //donnees_radio[0] = int(map(donnees_radio[0], -180, 180, 0, 360));    //Ici grâce à un tableau en
  donnees_radio[1] = int(map(donnees_radio[1], -90, 90, 100, -100)); //croix, on rend les valeurs
  donnees_radio[2] = int(map(donnees_radio[2], -90, 90, -50, 50));   //utilisables par le programme
  //donnees_radio[4] = int(map(donnees_radio[4] * 0.0228 + 0.065, 11.1, 12.6, 0, 100)); //On utilise ici la fonction affine trouvée grâce à
                                                                              //une modélisation sur régressi avec une incertitude de 0.01V                                                                          //qu'on mappe de 0 à 100%
  donnees_radio[5] = int(map(donnees_radio[5], 0, 255, 0,360));                                
    }
  }

return donnees_radio;    //Finalement on retourne le tableau de valeur
}


void setup(){
  
  
  String[] cameras = Capture.list();
  
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    
    // The camera can be initialized directly using an 
    // element from the array returned by list():
    cam = new Capture(this, cameras[0]);
    cam.start();     
  }
  
  
  
  for(int a = 0; a < 30 ;a++){    //Affiche tous les ports de séries disponibles 
  println(Serial.list()[a]);
  }
  String portName = Serial.list()[32]; //On séléctionne le dernier port de série, qui correspond à l'Arduino
                                                         //Au lancement du programme vous allez avoir une erreur à cette ligne
                                                         //car le programme est conçu pour être lancé lorsque l'Arduino est branché
  myPort = new Serial(this, portName, 9600);             //Lancement de la lecture du moniteur de série 
  interrupteur_ouvert = loadImage("interouvert.jpg");
  interrupteur_ferme = loadImage("interferme.jpg");
  coteboussole = loadImage("coteboussole.png");
  milieuboussole = loadImage("milieuboussole.png");
  altimetreimage = loadImage("altimetre.png");
  size(1000,720);//On definit ici la taille puis le x et le y
  x=1000;        //permettant au programme de s'adapter
  y=720;        //il n'est cependant pas possible d'avoir
}               //y>x a cause de la forme de 
                //l'horizon artificiel



void draw(){
  
  
  if (cam.available() == true) {
    cam.read();
  }
  image(cam, 0, 0, 1000, 450);
  
  
  int [] donnees = getData(); //On stocke le tableau retourné par la fonction getData
  println();
  for(int a = 0; a < 6; a++){
    print(donnees[a]);
    print("  ");
  }
  
  //background(255);
  fill(125);
  ellipse(x/2,y,x*2.5,0.9*y);
  fill(255);
  rect(x/12,y*21.5/24,x/6,y/12);
  rect(9*x/12,y*21.5/24,x/6,y/12);
  rect(5*x/12,y*20.5/24,x/6,y/12);
  fill(255,60,60);
  fill(0);
  rect(3.25*x/12,y*20/24,x/8,y/12);
  fill(255);
  textSize(y/9);
  text("IR",3.5*x/12,y*22/24);
  interrupteur();
  potentiometre();
  boussole(donnees[5]);
  image(altimetreimage,2*x/5,y*14/24,x/5,y/4);
  altimetre(donnees[3]); 
  donnees = getData();
  batterie(donnees[4]);
  altituderelative(donnees[3]);
  horizon(donnees[1],donnees[2]);
}