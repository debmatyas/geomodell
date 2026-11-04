// ---- Közös segédek a subdivision algoritmusokhoz ----

// Élek nyilvántartása: minden élhez eltároljuk a végpontjait és a szomszédos lapokat.
class EdgeData {
  HashMap<Long, Integer> index = new HashMap<Long, Integer>();
  ArrayList<int[]> ends = new ArrayList<int[]>();  // {a, b}
  ArrayList<int[]> adj  = new ArrayList<int[]>();  // {lap0, lap1, laSzám}
  int vertexCount;

  EdgeData(int vertexCount) {
    this.vertexCount = vertexCount;
  }

  long key(int a, int b) {
    return (long) Math.min(a, b) * vertexCount + Math.max(a, b);
  }

  int find(int a, int b) {
    return index.get(key(a, b));
  }

  void addFace(int a, int b, int faceIdx) {
    long k = key(a, b);
    Integer e = index.get(k);
    if (e == null) {
      e = ends.size();
      index.put(k, e);
      ends.add(new int[]{a, b});
      adj.add(new int[]{-1, -1, 0});
    }
    int[] ad = adj.get(e);
    if (ad[2] < 2) ad[ad[2]] = faceIdx;
    ad[2]++;
  }

  // Belső él: pontosan két lap osztozik rajta
  boolean isInterior(int e) {
    return adj.get(e)[2] == 2;
  }
}

EdgeData buildEdges(ArrayList<int[]> fs, int vertexCount) {
  EdgeData ed = new EdgeData(vertexCount);
  for (int fi = 0; fi < fs.size(); fi++) {
    int[] f = fs.get(fi);
    for (int i = 0; i < f.length; i++) {
      ed.addFace(f[i], f[(i + 1) % f.length], fi);
    }
  }
  return ed;
}

// Minden csúcshoz a belőle induló élek listája
ArrayList<ArrayList<Integer>> buildVertexEdges(EdgeData ed, int vertexCount) {
  ArrayList<ArrayList<Integer>> vEdges = new ArrayList<ArrayList<Integer>>();
  for (int i = 0; i < vertexCount; i++) vEdges.add(new ArrayList<Integer>());
  for (int e = 0; e < ed.ends.size(); e++) {
    int[] en = ed.ends.get(e);
    vEdges.get(en[0]).add(e);
    vEdges.get(en[1]).add(e);
  }
  return vEdges;
}

// Többszögű lapok háromszögekre bontása (Loop és Butterfly háromszöghálót igényel)
void ensureTriangles() {
  ArrayList<int[]> tris = new ArrayList<int[]>();
  for (int[] f : faces) {
    if (f.length == 3) {
      tris.add(f);
    } else if (f.length > 3) {
      for (int i = 1; i < f.length - 1; i++) {
        tris.add(new int[]{f[0], f[i], f[i + 1]});
      }
    }
  }
  faces = tris;
}
