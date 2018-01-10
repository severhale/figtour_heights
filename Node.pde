class Node {
  PVector p, v;
  public Node(PVector p) {
    this.p = p.copy();
    v = new PVector(0, 0);
  }
  public Node(float x, float y) {
    this(new PVector(x, y));
  }
  public void addV(PVector dv) {
    v.add(dv);
  }
  public void applyZForce(float dz) {
    v.z += dz;
  }
  public void repelFrom(float z) {
    applyZForce(.01/(p.z - z + 1));
  }
  public void update() {
    float avz = abs(v.z);
    v.z = v.z * (1-.1*(avz / (avz + 10)));
    v.z = v.z * (.95 + .05*(avz / (avz + 10)));
    p.add(v);
  }
}