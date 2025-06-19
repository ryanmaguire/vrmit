using UnityEngine;
using System;


using SurfaceFunction = System.Func<float, float, float>;

[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class SurfacePlot : MonoBehaviour
{
    static float SaddleFunction(float x, float y)
    {
        return (x * x - y * y) * 0.5F;
    }

    static float SinSinFunction(float x, float y)
    {
        return Mathf.Sin(x) * Mathf.Sin(y);
    }

    static float GaussianFunction(float x, float y)
    {
        float rsq = x * x + y * y;
        return Mathf.Exp(-rsq);
    }

    [Header("Grid Settings")]
    public int resolution = 50;
    public float xMin = -5f, xMax = 5f;
    public float yMin = -5f, yMax = 5f;

    public SurfaceFunction function = GaussianFunction;
    public System.String input_string = "abc";

    public bool active = true;

    // --- move the enum above any Header attribute ---
    //public enum Function { Saddle, SinProduct, Gaussian }

    [Header("Function Settings")]
    //public Function function = Function.SinProduct;
    //SurfaceFunction function = SinSinFunction;

    private Mesh mesh;

    void Start()
    {
        ToggleVisibility(active);
        BuildMesh(function);
    }

    public void ToggleVisibility(bool show)
    {
        GetComponent<MeshRenderer>().enabled = show;
        GetComponent<MeshFilter>().mesh = show ? mesh : null;
    }

    void BuildMesh(SurfaceFunction f)
    {
        mesh = new Mesh { name = "SurfacePlotMesh" };

        int vertCount = (resolution + 1) * (resolution + 1);
        Vector3[] verts = new Vector3[vertCount];
        Vector2[] uvs   = new Vector2[vertCount];
        int[] tris     = new int[resolution * resolution * 6];

        float dx = (xMax - xMin) / resolution;
        float dy = (yMax - yMin) / resolution;

        int vi = 0;
        for (int iy = 0; iy <= resolution; iy++)
        {
            float y = yMin + iy * dy;
            for (int ix = 0; ix <= resolution; ix++)
            {
                float x = xMin + ix * dx;
                float z = f(x, y);
                verts[vi] = new Vector3(x, z, y);
                uvs[vi]   = new Vector2((float)ix / resolution, (float)iy / resolution);
                vi++;
            }
        }

        int ti = 0;
        for (int y = 0; y < resolution; y++)
        for (int x = 0; x < resolution; x++)
        {
            int i0 =  y    * (resolution + 1) + x;
            int i1 =  y    * (resolution + 1) + x + 1;
            int i2 = (y+1) * (resolution + 1) + x;
            int i3 = (y+1) * (resolution + 1) + x + 1;

            tris[ti++] = i0; tris[ti++] = i3; tris[ti++] = i2;
            tris[ti++] = i0; tris[ti++] = i1; tris[ti++] = i3;
        }

        mesh.vertices  = verts;
        mesh.uv        = uvs;
        mesh.triangles = tris;
        mesh.RecalculateNormals();

        GetComponent<MeshFilter>().mesh = mesh;
    }

/*
    float EvaluateFunction(float x, float y)
    {
        //return Mathf.Sin(x) * Mathf.Cos(y);
        switch (function)
            {
                case Function.SinProduct:
                    return Mathf.Sin(x) * Mathf.Cos(y);
                case Function.Gaussian:
                    return Mathf.Exp(-(x*x + y*y) * 0.5f);
                case Function.Saddle:
                default:
                    return x * x - y * y;
            }
    }
*/
}
