// Catmull-Clark subdivision tetszőleges (n-szög) lapokra, nyitott élek (boundary) kezelésével.
// Minden lapból n darab négyszög lesz, így az első lépés után a háló csupa négyszögből áll.
void applyCatmullClarkSubdivision() {
  int nV = vertices.size();
  int nF = faces.size();
  EdgeData ed = buildEdges(faces, nV);
  int nE = ed.ends.size();
  ArrayList<ArrayList<Integer>> vEdges = buildVertexEdges(ed, nV);

  // 1) Laponti pontok: a lap csúcsainak átlaga. Közben csúcs -> lapok lista.
  PVector[] facePt = new PVector[nF];
  ArrayList<ArrayList<Integer>> vFaces = new ArrayList<ArrayList<Integer>>();
  for (int i = 0; i < nV; i++) vFaces.add(new ArrayList<Integer>());

  for (int fi = 0; fi < nF; fi++) {
    int[] f = faces.get(fi);
    PVector c = new PVector(0, 0, 0);
    for (int idx : f) {
      c.add(vertices.get(idx));
      vFaces.get(idx).add(fi);
    }
    c.div(f.length);
    facePt[fi] = c;
  }

  // 2) Élpontok: belső élen (A + B + F1 + F2) / 4, nyitott élen az él felezőpontja
  PVector[] edgeMid = new PVector[nE];
  PVector[] edgePt = new PVector[nE];
  for (int e = 0; e < nE; e++) {
    int[] en = ed.ends.get(e);
    PVector a = vertices.get(en[0]);
    PVector b = vertices.get(en[1]);
    PVector mid = PVector.lerp(a, b, 0.5);
    edgeMid[e] = mid;

    if (ed.isInterior(e)) {
      int[] ad = ed.adj.get(e);
      PVector sum = PVector.add(a, b);
      sum.add(facePt[ad[0]]);
      sum.add(facePt[ad[1]]);
      sum.div(4);
      edgePt[e] = sum;
    } else {
      edgePt[e] = mid.copy();
    }
  }

  // 3) Az eredeti csúcsok új pozíciója
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
      // Belső csúcs: (F + 2R + (n-3)P) / n
      int n = es.size();
      PVector F = new PVector(0, 0, 0);
      ArrayList<Integer> fs = vFaces.get(v);
      for (int fi : fs) F.add(facePt[fi]);
      F.div(max(1, fs.size()));

      PVector R = new PVector(0, 0, 0);
      for (int e : es) R.add(edgeMid[e]);
      R.div(n);
      
      // (F + 2R + (n − 3)P) / n.
      /**
      * - n a valencia, vagyis a csúcsból induló élek száma.
      *
      * - F a csúcsot körülvevő lapok laponti pontjainak átlaga. 
      *   A lapokat a vFaces (5.2) adja, a laponti pontok az facePt 
      *   tömbből jönnek. A max(1, fs.size()) védelem a nullával 
      *   osztás ellen. Egy belső csúcsnál mindig van lap, de a védelem nem árt.
      *
      * - R a csúcsból induló élek felezőpontjainak átlaga. Itt jön 
      *   elő az edgeMid tömb (5.3), és fontos, hogy a felezőpontokat 
      *   használjuk, nem az élpontokat. Az élpont már befelé van húzva, 
      *   a felezőpont viszont az él tényleges közepe.
      *
      * - P a csúcs régi helye.
      */
      np = PVector.mult(F, 1.0);
      np.add(PVector.mult(R, 2.0));
      np.add(PVector.mult(P, n - 3));
      np.div(n);
    } else if (boundaryEdges.size() == 2) {
      // Nyitott szélű csúcs: 3/4 P + 1/8 (két szélső szomszéd)
      np = PVector.mult(P, 0.75);
      for (int e : boundaryEdges) {
        int[] en = ed.ends.get(e);
        int other = (en[0] == v) ? en[1] : en[0];
        np.add(PVector.mult(vertices.get(other), 0.125));
      }
    } else {
      np = P.copy(); // nem-manifold csúcs, nem mozgatjuk
    }
    newVertices.add(np);
  }

  // Indexek: [0..nV) eredeti csúcsok, [nV..nV+nF) laponti pontok, [nV+nF..) élpontok
  for (int fi = 0; fi < nF; fi++) newVertices.add(facePt[fi]);
  for (int e = 0; e < nE; e++) newVertices.add(edgePt[e]);

  // 4) Új lapok: minden lap minden sarkából egy négyszög
  ArrayList<int[]> newFaces = new ArrayList<int[]>();
  for (int fi = 0; fi < nF; fi++) {
    int[] f = faces.get(fi);
    int n = f.length;
    if (n < 3) continue;
    for (int i = 0; i < n; i++) {
      int cur = f[i];
      int next = f[(i + 1) % n];
      int prev = f[(i - 1 + n) % n];
      newFaces.add(new int[]{
        cur,
        nV + nF + ed.find(cur, next),
        nV + fi,
        nV + nF + ed.find(prev, cur)
      });
    }
  }

  vertices = newVertices;
  faces = newFaces;
}
