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

  // A hálózat módosulása után generáljuk újra a GPU alakzatot
  updateMeshShape();
}

// Catmull-Clark lépés
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
