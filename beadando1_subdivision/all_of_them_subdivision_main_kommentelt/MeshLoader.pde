// ============================================================
// MESHLOADER: OBJ beolvasása, normalizálás, tartalék kocka, másolók
// ============================================================

// Beolvassa az OBJ fájlt (a sketch data/ mappájából) a globális vertices és faces változókba
void loadObjFile(String filename) {
  vertices = new ArrayList<PVector>();
  faces = new ArrayList<int[]>();

  String[] lines = loadStrings(filename);   // a fájl sorai, vagy null ha nincs fájl
  if (lines == null) {
    println("Hiba: Nem található a megadott OBJ fájl: " + filename + " (a sketch data/ mappájába kell tenni). Beépített kockát használok.");
  } else {
    for (String line : lines) {
      line = line.trim();   // szóközök levágása a sor szélén
      if (line.startsWith("v ")) {
        // csúcs sor: v x y z
        String[] parts = splitTokens(line, " \t");   // szétvágás szóköz/tabulátor mentén
        if (parts.length >= 4) {
          vertices.add(new PVector(float(parts[1]), float(parts[2]), float(parts[3])));
        }
      } else if (line.startsWith("f ")) {
        // lap sor: f i1 i2 i3 ... (az elemek lehetnek i, i/t, i/t/n alakúak)
        String[] parts = splitTokens(line, " \t");
        if (parts.length >= 4) {
          // A lapokat eredeti alakjukban (háromszög, négyszög, n-szög) tartjuk meg,
          // mert a Catmull-Clark négyszögekkel dolgozik. A Loop/Butterfly maga háromszögel.
          int[] f = new int[parts.length - 1];
          for (int i = 1; i < parts.length; i++) {
            int idx = parseInt(split(parts[i], '/')[0]);        // csak a perjel előtti csúcsindex kell
            f[i - 1] = (idx < 0) ? vertices.size() + idx : idx - 1;  // negatív index: relatív; OBJ 1-től indexel, Java 0-tól
          }
          faces.add(f);
        }
      }
    }
  }

  // ha nincs használható modell, a beépített kocka kerül a helyére
  if (vertices.size() == 0 || faces.size() == 0) {
    createDefaultCube();
  }

  // Középre igazítás és méretezés
  // 1. súlypont: a csúcsok átlaga
  PVector sum = new PVector(0, 0, 0);
  for (PVector v : vertices) sum.add(v);
  PVector center = PVector.div(sum, vertices.size());

  // 2. eltolás az origóba, közben a legtávolabbi csúcs távolsága
  float maxDist = 0;
  for (PVector v : vertices) {
    v.sub(center);
    float d = v.mag();
    if (d > maxDist) maxDist = d;
  }

  // 3. méretezés: a legtávolabbi csúcs pontosan targetSize távolságra kerül az origótól
  float targetSize = 150.0;
  if (maxDist > 0) {
    float scaleFactor = targetSize / maxDist;
    for (PVector v : vertices) v.mult(scaleFactor);
  }
}

// Tartalék: egységkocka, kifelé néző (CCW) négyszöglapokkal
void createDefaultCube() {
  vertices = new ArrayList<PVector>();
  faces = new ArrayList<int[]>();
  // 8 csúcs: a ±1 koordináták összes kombinációja (0-3: hátsó négyzet, 4-7: elülső négyzet)
  float[][] p = {
    {-1, -1, -1}, {1, -1, -1}, {1, 1, -1}, {-1, 1, -1},
    {-1, -1,  1}, {1, -1,  1}, {1, 1,  1}, {-1, 1,  1}
  };
  for (float[] c : p) vertices.add(new PVector(c[0], c[1], c[2]));
  // 6 négyszöglap, a csúcssorrend adja a kifelé mutató normálist
  faces.add(new int[]{0, 3, 2, 1});   // hátsó
  faces.add(new int[]{4, 5, 6, 7});   // elülső
  faces.add(new int[]{0, 1, 5, 4});   // alsó
  faces.add(new int[]{3, 7, 6, 2});   // felső
  faces.add(new int[]{0, 4, 7, 3});   // bal
  faces.add(new int[]{1, 2, 6, 5});   // jobb
}

// Mély másolat a csúcslistáról (új PVector objektumok)
ArrayList<PVector> copyVertices(ArrayList<PVector> src) {
  ArrayList<PVector> dest = new ArrayList<PVector>();
  for (PVector v : src) dest.add(v.copy());
  return dest;
}

// Mély másolat a laplistáról (új int[] tömbök)
ArrayList<int[]> copyFaces(ArrayList<int[]> src) {
  ArrayList<int[]> dest = new ArrayList<int[]>();
  for (int[] f : src) dest.add(f.clone());
  return dest;
}
