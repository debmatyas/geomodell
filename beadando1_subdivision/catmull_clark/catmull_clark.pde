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

void loadOBJ(String filename) {
  baseVertices = new ArrayList<PVector>();
  baseFaces = new ArrayList<ArrayList<Integer>>();

  String[] lines = loadStrings(filename);
  if (lines == null) {
    println("Hiba: Nem található a fájl: " + filename);
    return;
  }

  for (String line : lines) {
    line = line.trim();
    if (line.startsWith("v ")) {
      String[] parts = line.split("\\s+");
      float x = float(parts[1]);
      float y = float(parts[2]);
      float z = float(parts[3]);
      baseVertices.add(new PVector(x, y, z));
    } else if (line.startsWith("f ")) {
      String[] parts = line.split("\\s+");
      ArrayList<Integer> face = new ArrayList<Integer>();
      for (int i = 1; i < parts.length; i++) {
        String[] indices = parts[i].split("/");
        int vIndex = Integer.parseInt(indices[0]) - 1;
        face.add(vIndex);
      }
      baseFaces.add(face);
    }
  }

  centerAndScaleModel();
}

void centerAndScaleModel() {
  if (baseVertices.isEmpty()) return;

  PVector center = new PVector(0, 0, 0);
  for (PVector v : baseVertices) {
    center.add(v);
  }
  center.div(baseVertices.size());

  for (PVector v : baseVertices) {
    v.sub(center);
  }

  float maxDist = 0;
  for (PVector v : baseVertices) {
    float d = v.mag();
    if (d > maxDist) maxDist = d;
  }

  if (maxDist > 0) {
    float scaleFactor = 150.0f / maxDist;
    for (PVector v : baseVertices) {
      v.mult(scaleFactor);
    }
  }
}

void keyPressed() {
  if (key == '1') {
    subLevel = constrain(subLevel + 1, 0, 4);
    rebuildMesh();
    redraw();
  } else if (key == '2') {
    subLevel = constrain(subLevel - 1, 0, 4);
    rebuildMesh();
    redraw();
  } else if (key == '3') {
    showWireframe = !showWireframe;
    updateMeshShape(); // Frissítjük a háló megjelenítést a PShape-en belül is
    redraw();
  } else if (key == CODED) {
    if (keyCode == UP) {
      zoom += 0.1f;
      redraw();
    } else if (keyCode == DOWN) {
      zoom = max(0.1f, zoom - 0.1f);
      redraw();
    }
  }
}

void mouseDragged() {
  float dx = mouseX - pmouseX;
  float dy = mouseY - pmouseY;
  rotY += dx * 0.01f;
  rotX -= dy * 0.01f;
  
  redraw(); // Mostantól villámgyors lesz a PShape miatt!
}

void rebuildMesh() {
  currentVertices = new ArrayList<PVector>();
  for (PVector v : baseVertices) currentVertices.add(v.copy());

  currentFaces = new ArrayList<ArrayList<Integer>>();
  for (ArrayList<Integer> f : baseFaces) {
    ArrayList<Integer> nf = new ArrayList<Integer>();
    for (int idx : f) nf.add(idx);
    currentFaces.add(nf);
  }

  for (int i = 0; i < subLevel; i++) {
    catmullClarkStep();
  }

  // A hálózat módosülése után generáljuk újra a GPU alakzatot
  updateMeshShape();
}

// Catmull-Clark lépés (változatlan marad)
void catmullClarkStep() {
  int numVerts = currentVertices.size();
  int numFaces = currentFaces.size();

  ArrayList<PVector> facePoints = new ArrayList<PVector>();
  for (int i = 0; i < numFaces; i++) {
    ArrayList<Integer> f = currentFaces.get(i);
    PVector fp = new PVector(0, 0, 0);
    for (int idx : f) {
      fp.add(currentVertices.get(idx));
    }
    fp.div(f.size());
    facePoints.add(fp);
  }

  HashMap<String, ArrayList<Integer>> edgeFaces = new HashMap<String, ArrayList<Integer>>();
  for (int fIdx = 0; fIdx < numFaces; fIdx++) {
    ArrayList<Integer> f = currentFaces.get(fIdx);
    int size = f.size();
    for (int i = 0; i < size; i++) {
      int u = f.get(i);
      int v = f.get((i + 1) % size);
      String key = Math.min(u, v) + "_" + Math.max(u, v);
      if (!edgeFaces.containsKey(key)) {
        edgeFaces.put(key, new ArrayList<Integer>());
      }
      edgeFaces.get(key).add(fIdx);
    }
  }

  HashMap<String, PVector> edgePoints = new HashMap<String, PVector>();
  for (String key : edgeFaces.keySet()) {
    String[] parts = key.split("_");
    int u = Integer.parseInt(parts[0]);
    int v = Integer.parseInt(parts[1]);
    PVector p1 = currentVertices.get(u);
    PVector p2 = currentVertices.get(v);

    PVector ep = new PVector(0, 0, 0);
    ep.add(p1);
    ep.add(p2);
    ArrayList<Integer> adjFaces = edgeFaces.get(key);
    for (int fIdx : adjFaces) {
      ep.add(facePoints.get(fIdx));
    }
    ep.div(2.0f + adjFaces.size());
    edgePoints.put(key, ep);
  }

  ArrayList<ArrayList<Integer>> vertexFaces = new ArrayList<ArrayList<Integer>>();
  ArrayList<ArrayList<String>> vertexEdges = new ArrayList<ArrayList<String>>();
  for (int i = 0; i < numVerts; i++) {
    vertexFaces.add(new ArrayList<Integer>());
    vertexEdges.add(new ArrayList<String>());
  }

  for (int fIdx = 0; fIdx < numFaces; fIdx++) {
    ArrayList<Integer> f = currentFaces.get(fIdx);
    for (int idx : f) {
      if (!vertexFaces.get(idx).contains(fIdx)) {
        vertexFaces.get(idx).add(fIdx);
      }
    }
  }

  for (String key : edgeFaces.keySet()) {
    String[] parts = key.split("_");
    int u = Integer.parseInt(parts[0]);
    int v = Integer.parseInt(parts[1]);
    if (!vertexEdges.get(u).contains(key)) vertexEdges.get(u).add(key);
    if (!vertexEdges.get(v).contains(key)) vertexEdges.get(v).add(key);
  }

  ArrayList<PVector> newVertexPositions = new ArrayList<PVector>();
  for (int i = 0; i < numVerts; i++) {
    PVector oldV = currentVertices.get(i);
    ArrayList<Integer> vFaces = vertexFaces.get(i);
    ArrayList<String> vEdges = vertexEdges.get(i);
    int n = vEdges.size();

    if (n == 0) {
      newVertexPositions.add(oldV.copy());
      continue;
    }

    PVector Q = new PVector(0, 0, 0);
    for (int fIdx : vFaces) {
      Q.add(facePoints.get(fIdx));
    }
    Q.div(vFaces.size());

    PVector R = new PVector(0, 0, 0);
    for (String eKey : vEdges) {
      String[] parts = eKey.split("_");
      int u = Integer.parseInt(parts[0]);
      int v = Integer.parseInt(parts[1]);
      PVector other = (u == i) ? currentVertices.get(v) : currentVertices.get(u);
      PVector mid = PVector.add(oldV, other).mult(0.5f);
      R.add(mid);
    }
    R.div(n);

    PVector newV = new PVector(0, 0, 0);
    newV.add(Q);
    newV.add(PVector.mult(R, 2.0f));
    newV.add(PVector.mult(oldV, n - 3));
    newV.div(n);

    newVertexPositions.add(newV);
  }

  ArrayList<PVector> nextVertices = new ArrayList<PVector>();
  for (PVector v : newVertexPositions) {
    nextVertices.add(v);
  }

  int facePointStartIndex = nextVertices.size();
  for (PVector fp : facePoints) {
    nextVertices.add(fp);
  }

  HashMap<String, Integer> edgePointIndices = new HashMap<String, Integer>();
  for (String key : edgePoints.keySet()) {
    edgePointIndices.put(key, nextVertices.size());
    nextVertices.add(edgePoints.get(key));
  }

  ArrayList<ArrayList<Integer>> nextFaces = new ArrayList<ArrayList<Integer>>();
  for (int fIdx = 0; fIdx < numFaces; fIdx++) {
    ArrayList<Integer> f = currentFaces.get(fIdx);
    int fpIdx = facePointStartIndex + fIdx;
    int size = f.size();
    for (int i = 0; i < size; i++) {
      int currV = f.get(i);
      int nextV = f.get((i + 1) % size);
      int prevV = f.get((i - 1 + size) % size);

      String edgeCurr = Math.min(currV, nextV) + "_" + Math.max(currV, nextV);
      String edgePrev = Math.min(currV, prevV) + "_" + Math.max(currV, prevV);

      int epCurr = edgePointIndices.get(edgeCurr);
      int epPrev = edgePointIndices.get(edgePrev);

      ArrayList<Integer> newQuad = new ArrayList<Integer>();
      newQuad.add(currV);
      newQuad.add(epCurr);
      newQuad.add(fpIdx);
      newQuad.add(epPrev);
      nextFaces.add(newQuad);
    }
  }

  currentVertices = nextVertices;
  currentFaces = nextFaces;
}

// --- ÚJ: A PShape felépítése (Háromszögelve a GPU számára) ---
void updateMeshShape() {
  meshShape = createShape();
  meshShape.beginShape(TRIANGLES);
  
  if (showWireframe) {
    meshShape.stroke(100, 200, 255);
  } else {
    meshShape.noStroke();
  }
  meshShape.fill(40, 90, 140, 220);

  for (ArrayList<Integer> f : currentFaces) {
    int size = f.size();
    if (size == 4) {
      // Quad feldarabolása 2 darab háromszögre
      int v0 = f.get(0);
      int v1 = f.get(1);
      int v2 = f.get(2);
      int v3 = f.get(3);
      
      addVert(v0); addVert(v1); addVert(v2);
      addVert(v0); addVert(v2); addVert(v3);
    } else if (size == 3) {
      addVert(f.get(0)); addVert(f.get(1)); addVert(f.get(2));
    } else {
      // Általános poligon fan trianguláció
      int v0 = f.get(0);
      for (int i = 1; i < size - 1; i++) {
        addVert(v0);
        addVert(f.get(i));
        addVert(f.get(i + 1));
      }
    }
  }
  meshShape.endShape();
}

void addVert(int idx) {
  PVector v = currentVertices.get(idx);
  meshShape.vertex(v.x, v.y, v.z);
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
