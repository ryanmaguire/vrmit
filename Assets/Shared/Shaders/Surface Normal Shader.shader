Shader "Debug/Normals"
{
    Properties
    {
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Cull Off // <<< disable backface culling

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 normal : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.normal = normalize(v.normal) * 0.5 + 0.5; // map [-1,1] to [0,1]
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return float4(i.normal, 1.0); // RGB visual of normal
            }
            ENDCG
        }
    }
}
