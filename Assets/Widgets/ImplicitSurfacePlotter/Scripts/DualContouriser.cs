using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class DualContouriser : MonoBehaviour
{
    [Header("Grid Settings")]
    public int size = 32;
    public float cellSize = 1f;
    public Vector3 offset = Vector3.zero;



    [Header("Iso Surface")]
    public float isoLevel = 0f;

    public delegate float ScalarField(Vector3 p);
    public ScalarField fieldFunction;

    [Header("Field Animation")]
    public bool animateW = true;
    public float w = 1f;
    public float wMin = 0.5f;
    public float wMax = 2f;
    public float wSpeed = 1f;

    private Mesh mesh;

    void Start()
    {
        size = 40;
        cellSize = 0.1f;
        offset = new Vector3(-size / 2f, -size / 2f, -size / 2f) * cellSize;
        isoLevel = 0.0f;

        fieldFunction = p => {
            float x = p.x, y = p.y, z = p.z;
            float w2 = w * w;
            float f1 = Mathf.Pow(x * x + y * y - w2, 2) + Mathf.Pow(z * z - 1, 2);
            float f2 = Mathf.Pow(y * y + z * z - w2, 2) + Mathf.Pow(x * x - 1, 2);
            float f3 = Mathf.Pow(z * z + x * x - w2, 2) + Mathf.Pow(y * y - 1, 2);
            return f1 * f2 * f3 - 1;
        };
        BuildMesh();
    }

    void Update()
    {
        if (animateW)
        {
            // Oscillate w between wMin and wMax using a sine wave
            float t = Time.time * wSpeed;
            w = Mathf.Lerp(wMin, wMax, 0.5f + 0.5f * Mathf.Sin(t));
            BuildMesh();
        }
    }

    [ContextMenu("Rebuild IsoSurface")]
    void BuildMesh()
    {
        var verts = new List<Vector3>();
        var norms = new List<Vector3>();
        var tris = new List<int>();
        int[,,] cellVertexIndex = new int[size, size, size];

        float[,,] grid = new float[size + 1, size + 1, size + 1];
        for (int z = 0; z <= size; z++)
        for (int y = 0; y <= size; y++)
        for (int x = 0; x <= size; x++)
        {
            Vector3 pos = offset + new Vector3(x, y, z) * cellSize;
            grid[x, y, z] = fieldFunction(pos) - isoLevel;
        }

        for (int z = 0; z < size; z++)
        for (int y = 0; y < size; y++)
        for (int x = 0; x < size; x++)
        {
            var hermitePoints = new List<Vector3>();
            var hermiteNormals = new List<Vector3>();

            for (int oy = 0; oy <= 1; oy++)
                for (int oz = 0; oz <= 1; oz++)
                    TrySampleEdge(x, y + oy, z + oz, 1, 0, 0, grid, hermitePoints, hermiteNormals);

            for (int ox = 0; ox <= 1; ox++)
                for (int oz = 0; oz <= 1; oz++)
                    TrySampleEdge(x + ox, y, z + oz, 0, 1, 0, grid, hermitePoints, hermiteNormals);

            for (int ox = 0; ox <= 1; ox++)
                for (int oy = 0; oy <= 1; oy++)
                    TrySampleEdge(x + ox, y + oy, z, 0, 0, 1, grid, hermitePoints, hermiteNormals);

            if (hermitePoints.Count == 0)
            {
                cellVertexIndex[x, y, z] = -1;
                continue;
            }

            Vector3 avgPos = Vector3.zero;
            foreach (var p in hermitePoints) avgPos += p;
            avgPos /= hermitePoints.Count;

            cellVertexIndex[x, y, z] = verts.Count;
            verts.Add(avgPos);

            Vector3 avgNorm = Vector3.zero;
            foreach (var n in hermiteNormals) avgNorm += n;
            norms.Add(avgNorm.normalized);
        }

        for (int z = 0; z < size - 1; z++)
        for (int y = 0; y < size - 1; y++)
        for (int x = 0; x < size - 1; x++)
        {
            int v000 = cellVertexIndex[x, y, z];
            int v100 = cellVertexIndex[x + 1, y, z];
            int v110 = cellVertexIndex[x + 1, y + 1, z];
            int v010 = cellVertexIndex[x, y + 1, z];
            int v001 = cellVertexIndex[x, y, z + 1];
            int v101 = cellVertexIndex[x + 1, y, z + 1];
            int v111 = cellVertexIndex[x + 1, y + 1, z + 1];
            int v011 = cellVertexIndex[x, y + 1, z + 1];

            if (v000 >= 0 && v100 >= 0 && v110 >= 0 && v010 >= 0)
                AddQuad(tris, v000, v100, v110, v010);
            if (v000 >= 0 && v010 >= 0 && v011 >= 0 && v001 >= 0)
                AddQuad(tris, v000, v010, v011, v001);
            if (v000 >= 0 && v100 >= 0 && v101 >= 0 && v001 >= 0)
                AddQuad(tris, v000, v100, v101, v001);
            if (v100 >= 0 && v110 >= 0 && v111 >= 0 && v101 >= 0)
                AddQuad(tris, v100, v110, v111, v101);
            if (v010 >= 0 && v110 >= 0 && v111 >= 0 && v011 >= 0)
                AddQuad(tris, v010, v110, v111, v011);
            if (v001 >= 0 && v101 >= 0 && v111 >= 0 && v011 >= 0)
                AddQuad(tris, v001, v101, v111, v011);
        }

        mesh = new Mesh();
        mesh.name = "DualContourMesh";
        mesh.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;
        mesh.SetVertices(verts);
        mesh.SetNormals(norms);
        mesh.SetTriangles(tris, 0);
        mesh.RecalculateNormals(); // Smooths over broken lighting
        mesh.RecalculateBounds();  // Optional but good


        var mf = GetComponent<MeshFilter>();
        mf.sharedMesh = null;
        mf.sharedMesh = mesh;
        Debug.Log($"DualContouring: Verts={mesh.vertexCount}, Tris={mesh.triangles.Length / 3}");
    }

    void TrySampleEdge(int x, int y, int z,
                       int dx, int dy, int dz,
                       float[,,] grid,
                       List<Vector3> pts, List<Vector3> nms)
    {
        float v0 = grid[x, y, z];
        float v1 = grid[x + dx, y + dy, z + dz];
        if (v0 * v1 >= 0f) return;

        float t = v0 / (v0 - v1);
        Vector3 p0 = offset + new Vector3(x, y, z) * cellSize;
        Vector3 p1 = offset + new Vector3(x + dx, y + dy, z + dz) * cellSize;
        Vector3 p = Vector3.Lerp(p0, p1, t);
        pts.Add(p);

        Vector3 grad = new Vector3(
            fieldFunction(p + Vector3.right * 0.01f) - fieldFunction(p - Vector3.right * 0.01f),
            fieldFunction(p + Vector3.up    * 0.01f) - fieldFunction(p - Vector3.up    * 0.01f),
            fieldFunction(p + Vector3.forward * 0.01f) - fieldFunction(p - Vector3.forward * 0.01f)
        ).normalized;
        nms.Add(grad);
    }

    void AddQuad(List<int> tris, int v0, int v1, int v2, int v3)
    {
        tris.Add(v0); tris.Add(v1); tris.Add(v2);
        tris.Add(v0); tris.Add(v2); tris.Add(v3);
    }

    void OnDrawGizmos()
    {
        if (mesh == null) return;
        Gizmos.color = Color.green;
        foreach (var v in mesh.vertices)
        {
            Gizmos.DrawSphere(transform.TransformPoint(v), 0.05f);
        }
    }
}
