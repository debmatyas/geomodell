import java.util.HashMap;
import java.util.HashSet;

// Jelenleg aktív csúcsok és lapok referenciája
ArrayList<PVector> vertices;
ArrayList<int[]> faces;

// Előre kiszámolt szintek tárolói (Cache)
ArrayList<ArrayList<PVector>> levelVertices = new ArrayList<ArrayList<PVector>>();
ArrayList<ArrayList<int[]>> levelFaces = new ArrayList<ArrayList<int[]>>();
int currentLevel = 0;

// Vizuális beállítások
int renderMode = 0; // 0: áttetsző+háló, 1: tömör+háló, 2: tömör sima (nincs háló)
float zoomZ = 50;   // Kezdeti kamera távolság

// Egérrel való forgatáshoz szükséges változók
float rotX = 0;
float rotY = 0;
float lastMouseX, lastMouseY;

void setup() {
  size(800, 600, P3D);
  hint(ENABLE_DEPTH_TEST);
  
  // 1. Betöltjük az alapmodellt a 0. szintre
  loadObjFile("beetle.obj"); 
  
  // Elmentjük a kezdőállapotot
  levelVertices.add(copyVertices(vertices));
  levelFaces.add(copyFaces(faces));
  
  // 2. ELŐRE KISZÁMOLJUK (Cache-eljük) az összes iterációs szintet (pl. 3 szintet előre)
  // Így futás közben már csak váltogatni kell, nem számol újra!
  println("Szintek előre számítása...");
  for (int i = 0; i < 3; i++) {
    applySubdivisionAndSmoothing();
    levelVertices.add(copyVertices(vertices));
    levelFaces.add(copyFaces(faces));
    println((i + 1) + ". szint elkészült. Csúcsok: " + vertices.size());
  }
  
  // Visszaállítjuk a kezdeti 0. szintre indításkor
  switchLevel(0);
}

void draw() {
  background(20);
  lights();
  
  translate(width / 2, height / 2, zoomZ);
  
  // Egérrel történő forgatás kezelése
  rotateX(rotX);
  rotateY(rotY);
  
  pushStyle();
  
  // Megjelenítési módok a 3-as gomb alapján
  if (renderMode == 0) {
    // 1. Áttetsző + háló
    stroke(0, 255, 200, 160);
    strokeWeight(1);
    fill(30, 100, 180, 120);
  } else if (renderMode == 1) {
    // 2. Tömör + háló
    stroke(0, 255, 200, 200);
    strokeWeight(1);
    fill(40, 120, 220, 255);
  } else {
    // 3. Tömör, nincs háló
    noStroke();
    fill(40, 120, 220, 255);
  }
  
  beginShape(TRIANGLES);
  for (int[] f : faces) {
    PVector v1 = vertices.get(f[0]);
    PVector v2 = vertices.get(f[1]);
    PVector v3 = vertices.get(f[2]);
    vertex(v1.x, v1.y, v1.z);
    vertex(v2.x, v2.y, v2.z);
    vertex(v3.x, v3.y, v3.z);
  }
  endShape();
  popStyle();
}

// Egér lenyomása a forgatás kezdetéhez
void mousePressed() {
  lastMouseX = mouseX;
  lastMouseY = mouseY;
}

// Egér húzása a forgatáshoz
void mouseDragged() {
  float dx = mouseX - lastMouseX;
  float dy = mouseY - lastMouseY;
  
  rotY += dx * 0.01;
  rotX -= dy * 0.01;
  
  lastMouseX = mouseX;
  lastMouseY = mouseY;
}

// OBJ fájl beolvasása automatikus középre igazítással és átméretezéssel
void loadObjFile(String filename) {
  vertices = new ArrayList<PVector>();
  faces = new ArrayList<int[]>();
  
  String[] lines = loadStrings(filename);
  if (lines == null) {
    println("Hiba: Nem található a megadott OBJ fájl a data mappában: " + filename);
    return;
  }
  
  for (String line : lines) {
    line = line.trim();
    if (line.startsWith("v ")) {
      String[] parts = splitTokens(line, " ");
      if (parts.length >= 4) {
        float x = float(parts[1]);
        float y = float(parts[2]);
        float z = float(parts[3]);
        vertices.add(new PVector(x, y, z));
      }
    } else if (line.startsWith("f ")) {
      String[] parts = splitTokens(line, " ");
      if (parts.length >= 4) {
        int i0 = parseInt(split(parts[1], '/')[0]) - 1;
        int i1 = parseInt(split(parts[2], '/')[0]) - 1;
        int i2 = parseInt(split(parts[3], '/')[0]) - 1;
        faces.add(new int[]{i0, i1, i2});
        
        if (parts.length >= 5) {
          int i3 = parseInt(split(parts[4], '/')[0]) - 1;
          faces.add(new int[]{i0, i2, i3});
        }
      }
    }
  }
  
  // Középre igazítás és méretezés
  if (vertices.size() > 0) {
    PVector sum = new PVector(0, 0, 0);
    for (PVector v : vertices) {
      sum.add(v);
    }
    PVector center = PVector.div(sum, vertices.size());
    
    float maxDist = 0;
    for (PVector v : vertices) {
      v.sub(center);
      float d = v.mag();
      if (d > maxDist) maxDist = d;
    }
    
    float targetSize = 150.0;
    if (maxDist > 0) {
      float scaleFactor = targetSize / maxDist;
      for (PVector v : vertices) {
        v.mult(scaleFactor);
      }
    }
  }
}

void keyPressed() {
  if (key == '1') {
    // Előre lépés a következő szintre (ha létezik)
    if (currentLevel < levelVertices.size() - 1) {
      currentLevel++;
      switchLevel(currentLevel);
      println("Előre lépve a(z) " + currentLevel + ". szintre.");
    } else {
      println("Elérted a maximum előre kiszámolt szintet.");
    }
  } else if (key == '2') {
    // Visszalépés az előző szintre (ha létezik)
    if (currentLevel > 0) {
      currentLevel--;
      switchLevel(currentLevel);
      println("Visszalépve a(z) " + currentLevel + ". szintre.");
    } else {
      println("Ez a kezdeti szint, nincs mit visszavonni.");
    }
  } else if (key == '3') {
    renderMode = (renderMode + 1) % 3; // Váltás a 3 mód között
    println("Megjelenítési mód: " + renderMode);
  } else if (key == CODED) {
    if (keyCode == UP) {
      zoomZ += 30; // Közelítés
    } else if (keyCode == DOWN) {
      zoomZ -= 30; // Távolodás
    }
  }
}

// Váltás a cache-elt szintek között
void switchLevel(int lvl) {
  currentLevel = lvl;
  vertices = copyVertices(levelVertices.get(lvl));
  faces = copyFaces(levelFaces.get(lvl));
}

// Segédfüggvények a mély másoláshoz
ArrayList<PVector> copyVertices(ArrayList<PVector> src) {
  ArrayList<PVector> dest = new ArrayList<PVector>();
  for (PVector v : src) dest.add(v.copy());
  return dest;
}

ArrayList<int[]> copyFaces(ArrayList<int[]> src) {
  ArrayList<int[]> dest = new ArrayList<int[]>();
  for (int[] f : src) dest.add(f.clone());
  return dest;
}

// Helyes felosztás élek megosztásával (csak indításkor fut le egyszer az összes szintre)
void applySubdivisionAndSmoothing() {
  ArrayList<PVector> newVertices = new ArrayList<PVector>(vertices);
  ArrayList<int[]> newFaces = new ArrayList<int[]>();
  HashMap<String, Integer> edgeMidpoints = new HashMap<String, Integer>();
  
  for (int[] f : faces) {
    int i0 = f[0];
    int i1 = f[1];
    int i2 = f[2];
    
    int im01 = getOrCreateMidpoint(i0, i1, newVertices, edgeMidpoints);
    int im12 = getOrCreateMidpoint(i1, i2, newVertices, edgeMidpoints);
    int im20 = getOrCreateMidpoint(i2, i0, newVertices, edgeMidpoints);
    
    newFaces.add(new int[]{i0, im01, im20});
    newFaces.add(new int[]{im01, i1, im12});
    newFaces.add(new int[]{im20, im12, i2});
    newFaces.add(new int[]{im01, im12, im20});
  }
  
  vertices = newVertices;
  faces = newFaces;
  
  smoothMesh();
}

int getOrCreateMidpoint(int a, int b, ArrayList<PVector> vList, HashMap<String, Integer> cache) {
  String key = (a < b) ? a + "_" + b : b + "_" + a;
  if (cache.containsKey(key)) {
    return cache.get(key);
  }
  
  PVector pA = vList.get(a);
  PVector pB = vList.get(b);
  PVector mid = PVector.lerp(pA, pB, 0.5);
  
  int index = vList.size();
  vList.add(mid);
  cache.put(key, index);
  return index;
}

// Simítás
void smoothMesh() {
  ArrayList<HashSet<Integer>> neighbors = new ArrayList<HashSet<Integer>>();
  for (int i = 0; i < vertices.size(); i++) {
    neighbors.add(new HashSet<Integer>());
  }
  
  for (int[] f : faces) {
    neighbors.get(f[0]).add(f[1]); neighbors.get(f[0]).add(f[2]);
    neighbors.get(f[1]).add(f[0]); neighbors.get(f[1]).add(f[2]);
    neighbors.get(f[2]).add(f[0]); neighbors.get(f[2]).add(f[1]);
  }
  
  ArrayList<PVector> smoothedVertices = new ArrayList<PVector>();
  
  for (int i = 0; i < vertices.size(); i++) {
    PVector v = vertices.get(i);
    HashSet<Integer> ns = neighbors.get(i);
    
    if (ns.size() == 0) {
      smoothedVertices.add(v.copy());
      continue;
    }
    
    PVector sum = new PVector(0, 0, 0);
    for (int nIdx : ns) {
      sum.add(vertices.get(nIdx));
    }
    sum.div(ns.size());
    
    PVector smoothed = PVector.lerp(v, sum, 0.5);
    smoothedVertices.add(smoothed);
  }
  
  vertices = smoothedVertices;
}
