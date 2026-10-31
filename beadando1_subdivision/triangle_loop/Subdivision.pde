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
    loopSubdivisionStep();
  }

  updateMeshShape();
}

// Loop Subdivision Algoritmus
void loopSubdivisionStep() {
  int numVerts = currentVertices.size();
  int numFaces = currentFaces.size();

  // 1. Élek gyűjtése és szomszédos lapok / csúcsok feltérképezése
  HashMap<String, ArrayList<Integer>> edgeFaces = new HashMap<String, ArrayList<Integer>>();
  ArrayList<HashSet<Integer>> vertexNeighbors = new ArrayList<HashSet<Integer>>();
  for (int i = 0; i < numVerts; i++) {
    vertexNeighbors.add(new HashSet<Integer>());
  }

  for (int fIdx = 0; fIdx < numFaces; fIdx++) {
    ArrayList<Integer> f = currentFaces.get(fIdx);
    int size = f.size();
    for (int i = 0; i < size; i++) {
      int u = f.get(i);
      int v = f.get((i + 1) % size);
      
      vertexNeighbors.get(u).add(v);
      vertexNeighbors.get(v).add(u);

      String key = Math.min(u, v) + "_" + Math.max(u, v);
      if (!edgeFaces.containsKey(key)) {
        edgeFaces.put(key, new ArrayList<Integer>());
      }
      edgeFaces.get(key).add(fIdx);
    }
  }

  // 2. Új él-pontok (Odd vertices) számítása a Loop maszk alapján
  HashMap<String, PVector> edgePoints = new HashMap<String, PVector>();
  for (String key : edgeFaces.keySet()) {
    String[] parts = key.split("_");
    int u = Integer.parseInt(parts[0]);
    int v = Integer.parseInt(parts[1]);
    PVector pA = currentVertices.get(u);
    PVector pB = currentVertices.get(v);

    ArrayList<Integer> adjFaces = edgeFaces.get(key);
    PVector ep = new PVector(0, 0, 0);

    if (adjFaces.size() == 2) {
      // Belső él: 3/8 * (A + B) + 1/8 * (C + D)
      int f1Idx = adjFaces.get(0);
      int f2Idx = adjFaces.get(1);
      int c1 = getOppositeVertex(currentFaces.get(f1Idx), u, v);
      int c2 = getOppositeVertex(currentFaces.get(f2Idx), u, v);
      PVector pC = currentVertices.get(c1);
      PVector pD = currentVertices.get(c2);

      ep.add(PVector.mult(PVector.add(pA, pB), 3.0f / 8.0f));
      ep.add(PVector.mult(PVector.add(pC, pD), 1.0f / 8.0f));
    } else {
      // Határoló él (Boundary): 1/2 * (A + B)
      ep.add(PVector.mult(PVector.add(pA, pB), 0.5f));
    }
    edgePoints.put(key, ep);
  }

  // 3. Meglévő csúcsok új pozícióinak (Even vertices) számítása
  ArrayList<PVector> newVertexPositions = new ArrayList<PVector>();
  for (int i = 0; i < numVerts; i++) {
    PVector oldV = currentVertices.get(i);
    HashSet<Integer> neighbors = vertexNeighbors.get(i);
    int n = neighbors.size();

    if (n == 0) {
      newVertexPositions.add(oldV.copy());
      continue;
    }

    // Loop béta súlyképlet a csúcs valenciája (n) alapján
    float beta;
    if (n == 3) {
      beta = 3.0f / 16.0f;
    } else {
      beta = (5.0f / 8.0f - pow(3.0f / 8.0f + 0.25f * cos(TWO_PI / n), 2.0f)) / n;
    }

    PVector sumNeighbors = new PVector(0, 0, 0);
    for (int neighborIdx : neighbors) {
      sumNeighbors.add(currentVertices.get(neighborIdx));
    }

    PVector newV = new PVector(0, 0, 0);
    newV.add(PVector.mult(oldV, 1.0f - n * beta));
    newV.add(PVector.mult(sumNeighbors, beta));

    newVertexPositions.add(newV);
  }

  // Csúcsok listájának összeállítása (régi módosítottak + új él-pontok)
  ArrayList<PVector> nextVertices = new ArrayList<PVector>();
  for (PVector v : newVertexPositions) {
    nextVertices.add(v);
  }

  HashMap<String, Integer> edgePointIndices = new HashMap<String, Integer>();
  for (String key : edgePoints.keySet()) {
    edgePointIndices.put(key, nextVertices.size());
    nextVertices.add(edgePoints.get(key));
  }

  // 4. Új háromszöges lapok generálása (1 háromszögből 4 darab lesz)
  ArrayList<ArrayList<Integer>> nextFaces = new ArrayList<ArrayList<Integer>>();
  for (int fIdx = 0; fIdx < numFaces; fIdx++) {
    ArrayList<Integer> f = currentFaces.get(fIdx);
    int v0 = f.get(0);
    int v1 = f.get(1);
    int v2 = f.get(2);

    String e01Key = Math.min(v0, v1) + "_" + Math.max(v0, v1);
    String e12Key = Math.min(v1, v2) + "_" + Math.max(v1, v2);
    String e20Key = Math.min(v2, v0) + "_" + Math.max(v2, v0);

    int ep01 = edgePointIndices.get(e01Key);
    int ep12 = edgePointIndices.get(e12Key);
    int ep20 = edgePointIndices.get(e20Key);

    // 4 kis háromszög felépítése
    addTriangle(nextFaces, v0, ep01, ep20);
    addTriangle(nextFaces, ep01, v1, ep12);
    addTriangle(nextFaces, ep20, ep12, v2);
    addTriangle(nextFaces, ep01, ep12, ep20);
  }

  currentVertices = nextVertices;
  currentFaces = nextFaces;
}

// Segédfüggvény háromszög hozzáadásához
void addTriangle(ArrayList<ArrayList<Integer>> faces, int a, int b, int c) {
  ArrayList<Integer> t = new ArrayList<Integer>();
  t.add(a);
  t.add(b);
  t.add(c);
  faces.add(t);
}

// Segédfüggvény a háromszög harmadik (éggel szembeni) csúcsának megtalálásához
int getOppositeVertex(ArrayList<Integer> face, int u, int v) {
  for (int idx : face) {
    if (idx != u && idx != v) {
      return idx;
    }
  }
  return -1;
}
