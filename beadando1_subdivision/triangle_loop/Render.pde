// PShape felépítése a GPU számára
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
    if (f.size() == 3) {
      addVert(f.get(0)); 
      addVert(f.get(1)); 
      addVert(f.get(2));
    }
  }
  meshShape.endShape();
}

void addVert(int idx) {
  PVector v = currentVertices.get(idx);
  meshShape.vertex(v.x, v.y, v.z);
}
