import java.util.HashMap;
import java.util.ArrayList;

// Eredeti és aktuális adatok
ArrayList<PVector> baseVertices;
ArrayList<ArrayList<Integer>> baseFaces;
ArrayList<PVector> currentVertices;
ArrayList<ArrayList<Integer>> currentFaces;
int subLevel = 0;

// GPU-gyorsított alakzat a sima forgatáshoz
PShape meshShape;

// Forgatási szögek, zoom és hálózat kapcsoló
float rotX = 0;
float rotY = 0;
float zoom = 1.0f;
boolean showWireframe = true; 

void settings() {
  size(800, 600, P3D);
}

void setup() {
  surface.setLocation(100, 100);
  frameRate(30);
  noLoop(); // Megállítja az alap animációs ciklust

  loadOBJ("beetle.obj");
  rebuildMesh();
}

// Kirajzolásért felelős függvény
void draw() {
  background(30);
  lights();

  pushMatrix();
  translate(width / 2, height / 2, 0);
  scale(zoom);
  rotateX(rotX);
  rotateY(rotY);

  // Itt történik a varázslat: csak egyetlen GPU hívás!
  if (meshShape != null) {
    shape(meshShape);
  }
  
  popMatrix();

  // --- 2D HUD ---
  hint(DISABLE_DEPTH_TEST); 
  fill(255);
  textSize(16);
  text("Subdivision szint: " + subLevel, 20, 30);
  text("1-es / 2-es gomb: Szint növelés / csökkentés", 20, 55);
  text("3-as gomb: Háló / Sima felület váltás", 20, 80);
  text("Fel/Le nyíl: Közelítés / Távolodás", 20, 105);
  text("Forgatás: kattints és húzd az egeret", 20, 130);
  hint(ENABLE_DEPTH_TEST);  
}
