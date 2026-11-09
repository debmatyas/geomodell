// Catmull-Clark subdivision tetszőleges (n-szög) lapokra, nyitott élek (boundary) kezelésével.
// Minden lapból n darab négyszög lesz, így az első lépés után a háló csupa négyszögből áll.
void applyCatmullClarkSubdivision() {
  // --- Előkészítés ---
  int nV = vertices.size();                  // csúcsok száma (finomítás előtt)
  int nF = faces.size();                     // lapok száma
  EdgeData ed = buildEdges(faces, nV);       // élkatalógus
  int nE = ed.ends.size();                   // élek száma
  ArrayList<ArrayList<Integer>> vEdges = buildVertexEdges(ed, nV);   // csúcsonként a belőle induló élek

  // 1) Laponti pontok: a lap csúcsainak átlaga. Közben csúcs -> lapok lista.
  PVector[] facePt = new PVector[nF];
  ArrayList<ArrayList<Integer>> vFaces = new ArrayList<ArrayList<Integer>>();   // csúcsonként a hozzá tartozó lapok
  for (int i = 0; i < nV; i++) vFaces.add(new ArrayList<Integer>());

  for (int fi = 0; fi < nF; fi++) {
    int[] f = faces.get(fi);
    PVector c = new PVector(0, 0, 0);
    for (int idx : f) {
      c.add(vertices.get(idx));        // csúcsok összegzése
      vFaces.get(idx).add(fi);         // a csúcs ehhez a laphoz tartozik
    }
    c.div(f.length);                   // átlag = laponti pont
    facePt[fi] = c;
  }

  // 2) Élpontok: belső élen (A + B + F1 + F2) / 4, nyitott élen az él felezőpontja
  PVector[] edgeMid = new PVector[nE];   // az élek sima felezőpontjai (a csúcsmozgatáshoz kellenek)
  PVector[] edgePt = new PVector[nE];    // az élpontok (az új háló csúcsai)
  for (int e = 0; e < nE; e++) {
    int[] en = ed.ends.get(e);
    PVector a = vertices.get(en[0]);
    PVector b = vertices.get(en[1]);
    PVector mid = PVector.lerp(a, b, 0.5);
    edgeMid[e] = mid;

    if (ed.isInterior(e)) {
      // belső él: a két szomszédos lap laponti pontja befelé húzza az élpontot
      int[] ad = ed.adj.get(e);
      PVector sum = PVector.add(a, b);
      sum.add(facePt[ad[0]]);
      sum.add(facePt[ad[1]]);
      sum.div(4);
      edgePt[e] = sum;
    } else {
      // nyitott (vagy szabálytalan) él: marad az él vonalán
      edgePt[e] = mid.copy();
    }
  }

  // 3) Az eredeti csúcsok új pozíciója
  ArrayList<PVector> newVertices = new ArrayList<PVector>();   // külön lista, hogy a számítás a régi hálóból történjen
  for (int v = 0; v < nV; v++) {
    PVector P = vertices.get(v);                 // a csúcs régi helye
    ArrayList<Integer> es = vEdges.get(v);       // a belőle induló élek

    // a csúcsból induló nem belső élek
    ArrayList<Integer> boundaryEdges = new ArrayList<Integer>();
    for (int e : es) {
      if (!ed.isInterior(e)) boundaryEdges.add(e);
    }

    PVector np;
    if (es.size() == 0) {
      // elszigetelt csúcs: marad
      np = P.copy();
    } else if (boundaryEdges.size() == 0) {
      // Belső csúcs: (F + 2R + (n-3)P) / n
      int n = es.size();                         // valencia
      // F: a csúcs körüli laponti pontok átlaga
      PVector F = new PVector(0, 0, 0);
      ArrayList<Integer> fs = vFaces.get(v);
      for (int fi : fs) F.add(facePt[fi]);
      F.div(max(1, fs.size()));

      // R: a csúcsból induló élek felezőpontjainak átlaga
      PVector R = new PVector(0, 0, 0);
      for (int e : es) R.add(edgeMid[e]);
      R.div(n);

      // súlyozott átlag: F súlya 1, R súlya 2, P súlya n-3, az osztó a súlyok összege (n)
      np = PVector.mult(F, 1.0);
      np.add(PVector.mult(R, 2.0));
      np.add(PVector.mult(P, n - 3));
      np.div(n);
    } else if (boundaryEdges.size() == 2) {
      // Nyitott szélű csúcs: 3/4 P + 1/8 (két szélső szomszéd)
      np = PVector.mult(P, 0.75);
      for (int e : boundaryEdges) {
        int[] en = ed.ends.get(e);
        int other = (en[0] == v) ? en[1] : en[0];   // az él másik végpontja
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
    if (n < 3) continue;                         // degenerált lap kimarad
    for (int i = 0; i < n; i++) {
      int cur = f[i];                            // a sarok csúcsa
      int next = f[(i + 1) % n];                 // következő csúcs a lapon
      int prev = f[(i - 1 + n) % n];             // előző csúcs a lapon
      // négyszög: sarok, következő él élpontja, laponti pont, előző él élpontja
      newFaces.add(new int[]{
        cur,
        nV + nF + ed.find(cur, next),
        nV + fi,
        nV + nF + ed.find(prev, cur)
      });
    }
  }

  // az új háló a helyére kerül
  vertices = newVertices;
  faces = newFaces;
}
