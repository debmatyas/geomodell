// Loop subdivision háromszöghálóra, nyitott élek kezelésével.
void applyLoopSubdivision() {
  ensureTriangles();

  int nV = vertices.size();
  EdgeData ed = buildEdges(faces, nV);
  int nE = ed.ends.size();
  ArrayList<ArrayList<Integer>> vEdges = buildVertexEdges(ed, nV);

  // Új (páratlan) csúcsok az éleken
  PVector[] edgePt = new PVector[nE];
  for (int e = 0; e < nE; e++) {
    int[] en = ed.ends.get(e);
    PVector a = vertices.get(en[0]);
    PVector b = vertices.get(en[1]);

    if (ed.isInterior(e)) {
      int[] ad = ed.adj.get(e);
      PVector c = vertices.get(oppositeVertex(faces.get(ad[0]), en[0], en[1]));
      PVector d = vertices.get(oppositeVertex(faces.get(ad[1]), en[0], en[1]));
      PVector p = PVector.add(a, b);
      p.mult(3.0 / 8.0);
      p.add(PVector.mult(PVector.add(c, d), 1.0 / 8.0));
      edgePt[e] = p;
    } else {
      edgePt[e] = PVector.lerp(a, b, 0.5);
    }
  }

  // Régi (páros) csúcsok új pozíciója
  ArrayList<PVector> newVertices = new ArrayList<PVector>();
  for (int v = 0; v < nV; v++) {
    PVector P = vertices.get(v);
    ArrayList<Integer> es = vEdges.get(v);

    ArrayList<Integer> boundaryEdges = new ArrayList<Integer>();
    for (int e : es) {
      if (!ed.isInterior(e)) boundaryEdges.add(e);
    }

    PVector np;
    if (es.size() == 0) {
      np = P.copy();
    } else if (boundaryEdges.size() == 0) {
      int n = es.size();
      float beta = (n == 3) ? 3.0 / 16.0 : 3.0 / (8.0 * n);
      np = PVector.mult(P, 1.0 - n * beta);
      for (int e : es) {
        int[] en = ed.ends.get(e);
        int other = (en[0] == v) ? en[1] : en[0];
        np.add(PVector.mult(vertices.get(other), beta));
      }
    } else if (boundaryEdges.size() == 2) {
      np = PVector.mult(P, 0.75);
      for (int e : boundaryEdges) {
        int[] en = ed.ends.get(e);
        int other = (en[0] == v) ? en[1] : en[0];
        np.add(PVector.mult(vertices.get(other), 0.125));
      }
    } else {
      np = P.copy();
    }
    newVertices.add(np);
  }
  for (int e = 0; e < nE; e++) newVertices.add(edgePt[e]);

  // Minden háromszögből négy lesz
  ArrayList<int[]> newFaces = new ArrayList<int[]>();
  for (int[] f : faces) {
    int i0 = f[0], i1 = f[1], i2 = f[2];
    int e01 = nV + ed.find(i0, i1);
    int e12 = nV + ed.find(i1, i2);
    int e20 = nV + ed.find(i2, i0);

    newFaces.add(new int[]{i0, e01, e20});
    newFaces.add(new int[]{i1, e12, e01});
    newFaces.add(new int[]{i2, e20, e12});
    newFaces.add(new int[]{e01, e12, e20});
  }

  vertices = newVertices;
  faces = newFaces;
}

int oppositeVertex(int[] tri, int a, int b) {
  for (int k : tri) {
    if (k != a && k != b) return k;
  }
  return a;
}
