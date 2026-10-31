import java.util.HashMap;
import java.util.ArrayList;

class Face {
  ArrayList<Integer> vIdxs;
  Face(ArrayList<Integer> idxs) { this.vIdxs = idxs; }
}

class EdgeInfo {
  int a, b;
  ArrayList<Integer> faces = new ArrayList<Integer>();
  int newIndex = -1;
  EdgeInfo(int a, int b) {
    this.a = Math.min(a, b);
    this.b = Math.max(a, b);
  }
}

ArrayList<PVector> vertices;
ArrayList<Face> faces;
int currentIteration = 0;
int subStep = 0; // 0: Alapállapot, 1: Lap-pontok, 2: Él-pontok, 3: Csúcs-frissítés

ArrayList<PVector> tempFacePoints = new ArrayList<PVector>();
ArrayList<PVector> tempEdgePoints = new ArrayList<PVector>();
ArrayList<PVector> tempUpdatedVertices = new ArrayList<PVector>();

float rotX = -0.5;
float rotY = 0.5;
float lastMouseX, lastMouseY;

void setup() {
  size(800, 700, P3D);
  initMesh();
}

void initMesh() {
  vertices = new ArrayList<PVector>();
  faces = new ArrayList<Face>();
  currentIteration = 0;
  subStep = 0;
  clearTemp();

  // Kezdőtest: Tetraéder (háromszög alapú gúla)
  float s = 150;
  vertices.add(new PVector(0, -s, 0));          // 0
  vertices.add(new PVector(-s, s, s));          // 1
  vertices.add(new PVector(s, s, s));           // 2
  vertices.add(new PVector(0, s, -s));          // 3

  addTriangle(0, 1, 2);
  addTriangle(0, 2, 3);
  addTriangle(0, 3, 1);
  addTriangle(1, 3, 2);
}

void addTriangle(int a, int b, int c) {
  ArrayList<Integer> tri = new ArrayList<Integer>();
  tri.add(a); tri.add(b); tri.add(c);
  faces.add(new Face(tri));
}

void clearTemp() {
  tempFacePoints.clear();
  tempEdgePoints.clear();
  tempUpdatedVertices.clear();
}

// ELŐRE LÉPÉS [1-es gomb]
void executeNextSubStep() {
  if (subStep == 0) {
    // 1. LÉPÉS: Lap-pontok kiszámítása
    calculateFacePoints();
    subStep = 1;
  } 
  else if (subStep == 1) {
    // 2. LÉPÉS: Él-pontok kiszámítása
    calculateEdgePoints();
    subStep = 2;
  } 
  else if (subStep == 2) {
    // 3. LÉPÉS: Csúcsok frissítése
    calculateUpdatedVertices();
    subStep = 3;
  } 
  else if (subStep == 3) {
    // 4. LÉPÉS: Új háló összeállítása
    applySubdivision();
    currentIteration++;
    subStep = 0;
    clearTemp();
  }
}

// VISSZA LÉPÉS [2-es gomb]
void executePrevSubStep() {
  if (subStep == 3) {
    // 3 -> 2: Csúcsfrissítés visszavonása
    tempUpdatedVertices.clear();
    subStep = 2;
  } 
  else if (subStep == 2) {
    // 2 -> 1: Él-pontok törlése
    tempEdgePoints.clear();
    subStep = 1;
  } 
  else if (subStep == 1) {
    // 1 -> 0: Lap-pontok törlése
    tempFacePoints.clear();
    subStep = 0;
  } 
  else if (subStep == 0 && currentIteration > 0) {
    // Ha 0-s fázisban vagyunk, visszalépünk az előző iteráció utolsó (3.) fázisába
    int targetIteration = currentIteration - 1;
    initMesh();
    for (int i = 0; i < targetIteration; i++) {
      calculateFacePoints();
      calculateEdgePoints();
      calculateUpdatedVertices();
      applySubdivision();
      currentIteration++;
    }
    // Most újraszámoljuk a célfázis állapotát
    calculateFacePoints();
    calculateEdgePoints();
    calculateUpdatedVertices();
    subStep = 3;
  }
}

void calculateFacePoints() {
  tempFacePoints.clear();
  for (Face f : faces) {
    PVector fCenter = new PVector(0, 0, 0);
    for (int idx : f.vIdxs) {
      fCenter.add(vertices.get(idx));
    }
    fCenter.div(f.vIdxs.size());
    tempFacePoints.add(fCenter);
  }
}

void calculateEdgePoints() {
  tempEdgePoints.clear();
  HashMap<String, EdgeInfo> edgeMap = getEdgeMap();
  
  for (String key : edgeMap.keySet()) {
    EdgeInfo ei = edgeMap.get(key);
    PVector v1 = vertices.get(ei.a);
    PVector v2 = vertices.get(ei.b);
    
    PVector edgePoint = new PVector(0, 0, 0);
    edgePoint.add(v1);
    edgePoint.add(v2);
    
    if (ei.faces.size() == 2) {
      PVector f1 = getFaceCenter(faces.get(ei.faces.get(0)));
      PVector f2 = getFaceCenter(faces.get(ei.faces.get(1)));
      edgePoint.add(f1);
      edgePoint.add(f2);
      edgePoint.div(4.0);
    } else {
      edgePoint.div(2.0);
    }
    tempEdgePoints.add(edgePoint);
  }
}

void calculateUpdatedVertices() {
  tempUpdatedVertices.clear();
  HashMap<String, EdgeInfo> edgeMap = getEdgeMap();
  
  for (int i = 0; i < vertices.size(); i++) {
    PVector oldV = vertices.get(i);
    PVector Q = new PVector(0, 0, 0);
    int faceCount = 0;
    PVector R = new PVector(0, 0, 0);
    int edgeCount = 0;

    for (Face f : faces) {
      if (f.vIdxs.contains(i)) {
        Q.add(getFaceCenter(f));
        faceCount++;
      }
    }
    if (faceCount > 0) Q.div(faceCount);

    for (String key : edgeMap.keySet()) {
      EdgeInfo ei = edgeMap.get(key);
      if (ei.a == i || ei.b == i) {
        int otherIdx = (ei.a == i) ? ei.b : ei.a;
        PVector midpoint = PVector.add(vertices.get(i), vertices.get(otherIdx)).mult(0.5);
        R.add(midpoint);
        edgeCount++;
      }
    }
    if (edgeCount > 0) R.div(edgeCount);

    int n = edgeCount;
    if (n > 0) {
      PVector newV = new PVector(0, 0, 0);
      newV.add(Q);
      newV.add(R.copy().mult(2.0));
      newV.add(oldV.copy().mult(n - 3));
      newV.div(n);
      tempUpdatedVertices.add(newV);
    } else {
      tempUpdatedVertices.add(oldV.copy());
    }
  }
}

HashMap<String, EdgeInfo> getEdgeMap() {
  HashMap<String, EdgeInfo> edgeMap = new HashMap<String, EdgeInfo>();
  for (int fIdx = 0; fIdx < faces.size(); fIdx++) {
    Face f = faces.get(fIdx);
    int n = f.vIdxs.size();
    for (int i = 0; i < n; i++) {
      int u = f.vIdxs.get(i);
      int v = f.vIdxs.get((i + 1) % n);
      String key = Math.min(u, v) + "_" + Math.max(u, v);
      EdgeInfo ei = edgeMap.get(key);
      if (ei == null) {
        ei = new EdgeInfo(u, v);
        edgeMap.put(key, ei);
      }
      ei.faces.add(fIdx);
    }
  }
  return edgeMap;
}

PVector getFaceCenter(Face f) {
  PVector fCenter = new PVector(0, 0, 0);
  for (int idx : f.vIdxs) {
    fCenter.add(vertices.get(idx));
  }
  fCenter.div(f.vIdxs.size());
  return fCenter;
}

void applySubdivision() {
  int numOriginalVerts = vertices.size();
  HashMap<String, EdgeInfo> edgeMap = getEdgeMap();

  ArrayList<PVector> newVertices = new ArrayList<PVector>();
  for (PVector v : tempUpdatedVertices) {
    newVertices.add(v.copy());
  }

  int[] facePointIndices = new int[faces.size()];
  for (int fIdx = 0; fIdx < faces.size(); fIdx++) {
    facePointIndices[fIdx] = newVertices.size();
    newVertices.add(tempFacePoints.get(fIdx));
  }

  int epIdx = 0;
  for (String key : edgeMap.keySet()) {
    EdgeInfo ei = edgeMap.get(key);
    ei.newIndex = newVertices.size();
    newVertices.add(tempEdgePoints.get(epIdx));
    epIdx++;
  }

  ArrayList<Face> newFaces = new ArrayList<Face>();
  for (int fIdx = 0; fIdx < faces.size(); fIdx++) {
    Face f = faces.get(fIdx);
    int n = f.vIdxs.size();
    int fPointIdx = facePointIndices[fIdx];

    for (int i = 0; i < n; i++) {
      int vIdx = f.vIdxs.get(i);
      int nextVIdx = f.vIdxs.get((i + 1) % n);
      int prevVIdx = f.vIdxs.get((i - 1 + n) % n);

      String nextEdgeKey = Math.min(vIdx, nextVIdx) + "_" + Math.max(vIdx, nextVIdx);
      String prevEdgeKey = Math.min(prevVIdx, vIdx) + "_" + Math.max(prevVIdx, vIdx);

      int nextEdgePointIdx = edgeMap.get(nextEdgeKey).newIndex;
      int prevEdgePointIdx = edgeMap.get(prevEdgeKey).newIndex;

      ArrayList<Integer> quad = new ArrayList<Integer>();
      quad.add(vIdx);
      quad.add(nextEdgePointIdx);
      quad.add(fPointIdx);
      quad.add(prevEdgePointIdx);

      newFaces.add(new Face(quad));
    }
  }

  vertices = newVertices;
  faces = newFaces;
}

void draw() {
  background(20);
  
  pushMatrix();
  translate(width / 2, height / 2, 0);
  rotateX(rotX);
  rotateY(rotY);

  lights();
  directionalLight(220, 220, 220, 0.5, 1, -1);
  ambientLight(100, 100, 100);

  // 1. Átlátszó test lapjai
  stroke(100, 200, 255, 180);
  strokeWeight(1.5);
  fill(80, 160, 240, 70); 

  for (Face f : faces) {
    beginShape();
    for (int idx : f.vIdxs) {
      PVector p = vertices.get(idx);
      vertex(p.x, p.y, p.z);
    }
    endShape(CLOSE);
  }

  // --- PONTOK KIRAJZOLÁSA (Mindig látszódnak) ---
  hint(DISABLE_DEPTH_TEST);

  // Lap-pontok (Zöld)
  if (subStep >= 1) {
    fill(0, 255, 120);
    noStroke();
    for (PVector fp : tempFacePoints) {
      pushMatrix();
      translate(fp.x, fp.y, fp.z);
      sphere(8);
      popMatrix();
    }
  }

  // Él-pontok (Narancs)
  if (subStep >= 2) {
    fill(255, 140, 0);
    noStroke();
    for (PVector ep : tempEdgePoints) {
      pushMatrix();
      translate(ep.x, ep.y, ep.z);
      sphere(8);
      popMatrix();
    }
  }

  // Csúcsok (Lila vagy Piros)
  if (subStep >= 3) {
    fill(255, 50, 220);
    noStroke();
    for (PVector uv : tempUpdatedVertices) {
      pushMatrix();
      translate(uv.x, uv.y, uv.z);
      sphere(9);
      popMatrix();
    }
  } else {
    fill(250, 60, 60);
    noStroke();
    for (PVector v : vertices) {
      pushMatrix();
      translate(v.x, v.y, v.z);
      sphere(7);
      popMatrix();
    }
  }

  hint(ENABLE_DEPTH_TEST);
  
  popMatrix();

  // UI Szöveg
  hint(DISABLE_DEPTH_TEST);
  fill(255);
  textSize(15);
  text("Iteráció: " + currentIteration, 25, 30);
  
  String stepText = "0 - Alapállapot";
  if (subStep == 1) stepText = "1. Lépés: Lap-pontok (Zöld)";
  else if (subStep == 2) stepText = "2. Lépés: Él-pontok (Narancs)";
  else if (subStep == 3) stepText = "3. Lépés: Csúcsok frissítése (Lila)";
  
  text("Fázis: " + stepText, 25, 55);
  text("Lapok száma: " + faces.size(), 25, 80);
  
  textSize(13);
  text("[1] - Következő fázis (Előre)", 25, 120);
  text("[2] - Előző fázis (Vissza)", 25, 140);
  hint(ENABLE_DEPTH_TEST);
}

void mousePressed() {
  lastMouseX = mouseX;
  lastMouseY = mouseY;
}

void mouseDragged() {
  rotY += (mouseX - lastMouseX) * 0.01;
  rotX -= (mouseY - lastMouseY) * 0.01;
  lastMouseX = mouseX;
  lastMouseY = mouseY;
}

void keyPressed() {
  if (key == '1') {
    executeNextSubStep();
  } else if (key == '2') {
    executePrevSubStep();
  }
}
