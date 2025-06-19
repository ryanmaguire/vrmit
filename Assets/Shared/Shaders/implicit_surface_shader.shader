Shader "Custom/WorldGrid"
{
    Properties
    {
        _Color("Base Color", Color) = (1, 1, 1, 1)
        _LineColor("Grid Line Color", Color) = (0, 0, 0, 1)
        _GridScale("Grid Scale", Float) = 10.0
        _LineWidth("Line Width", Float) = 0.05
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
            };

            float4 _Color;
            float4 _LineColor;
            float _GridScale;
            float _LineWidth;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 coord = frac(i.worldPos * _GridScale);
                float3 dist = abs(coord - 0.5);
                float d = min(min(dist.x, dist.y), dist.z);
                float edge = smoothstep(_LineWidth, 0.0, d); // 1 near edge, 0 in center
                return lerp(_LineColor, _Color, edge);
            }
            ENDCG
        }
    }
}
