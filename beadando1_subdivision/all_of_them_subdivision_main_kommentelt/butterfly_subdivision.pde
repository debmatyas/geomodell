// Felosztás az élek felezőpontjaival (minden háromszögből négy), majd simítás.
// Nem az igazi Modified Butterfly séma: a felosztás önmagában nem simít, a simítást a smoothMeshButterfly() végzi.
void applyButterflySubdivisionAndSmoothing() {
  ensureTriangles();   // csak háromszögekkel működik
  ArrayList<PVector> newVertices = new ArrayList<PVector>(vertices);   // a régi csúcsok ugyanazokon az indexeken maradnak
  ArrayList<int[]> newFaces = new ArrayList<int[]>();
  HashMap<String, Integer> edgeMidpoints = new HashMap<String, Integer>();   // gyorsítótár: él -> felezőpont indexe

  for (int[] f : faces) {
    int i0 = f[0], i1 = f[1], i2 = f[2];

    // a három él felezőpontjának indexe (ha még nincs, létrejön)
    int im01 = getOrCreateMidpoint(i0, i1, newVertices, edgeMidpoints);
    int im12 = getOrCreateMidpoint(i1, i2, newVertices, edgeMidpoints);
    int im20 = getOrCreateMidpoint(i2, i0, newVertices, edgeMidpoints);

    newFaces.add(new int[]{i0, im01, im20});     // három sarokháromszög
    newFaces.add(new int[]{im01, i1, im12});
    newFaces.add(new int[]{im20, im12, i2});
    newFaces.add(new int[]{im01, im12, im20});   // középső háromszög
  }

  // az új háló a helyére kerül, majd jön a simítás
  vertices = newVertices;
  faces = newFaces;
  smoothMeshButterfly();
}

// Visszaadja az a-b él felezőpontjának indexét; ha még nincs, létrehozza és a lista végére teszi
// A gyorsítótár miatt az élen osztozó két háromszög ugyanazt a csúcsot használja (nincs repedés)
int getOrCreateMidpoint(int a, int b, ArrayList<PVector> vList, HashMap<String, Integer> cache) {
  String key = (a < b) ? a + "_" + b : b + "_" + a;   // a kulcs nem függ a végpontok sorrendjétől
  if (cache.containsKey(key)) return cache.get(key);

  PVector mid = PVector.lerp(vList.get(a), vList.get(b), 0.5);   // az él felezőpontja
  int index = vList.size();
  vList.add(mid);
  cache.put(key, index);
  return index;
}

// Simítás: minden csúcsot félúton a szomszédai átlaga felé mozdít
void smoothMeshButterfly() {
  // minden csúcshoz a szomszédos csúcsok halmaza (a háromszögek éleiből, ismétlődés nélkül)
  ArrayList<HashSet<Integer>> neighbors = new ArrayList<HashSet<Integer>>();
  for (int i = 0; i < vertices.size(); i++) neighbors.add(new HashSet<Integer>());

  for (int[] f : faces) {
    neighbors.get(f[0]).add(f[1]);
    neighbors.get(f[0]).add(f[2]);
    neighbors.get(f[1]).add(f[0]);
    neighbors.get(f[1]).add(f[2]);
    neighbors.get(f[2]).add(f[0]);
    neighbors.get(f[2]).add(f[1]);
  }

  // az új pozíciók külön listába kerülnek, így a számítás a régi pozíciókból történik
  ArrayList<PVector> smoothedVertices = new ArrayList<PVector>();
  for (int i = 0; i < vertices.size(); i++) {
    PVector v = vertices.get(i);
    HashSet<Integer> ns = neighbors.get(i);

    if (ns.size() == 0) {
      smoothedVertices.add(v.copy());   // nincs szomszéd: marad
      continue;
    }

    // a szomszédok átlaga
    PVector sum = new PVector(0, 0, 0);
    for (int nIdx : ns) sum.add(vertices.get(nIdx));
    sum.div(ns.size());

    PVector smoothed = PVector.lerp(v, sum, 0.5);   // félúton az átlag felé
    smoothedVertices.add(smoothed);
  }
  vertices = smoothedVertices;
}
