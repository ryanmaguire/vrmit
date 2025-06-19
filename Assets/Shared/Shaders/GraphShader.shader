Shader "Custom/ProceduralGridHeightColor_YUp"
{
    Properties
    {
        // height color ramp
        _LowColor       ("Low Color",    Color) = (0,0,1,1)
        _MidColor       ("Mid Color",    Color) = (0,1,0,1)
        _HighColor      ("High Color",   Color) = (1,0,0,1)

        _LowThreshold   ("Low Threshold",  Float) = -10
        _MidThreshold   ("Mid Threshold",  Float) =  0
        _HighThreshold  ("High Threshold", Float) = 10

        // grid override
        _LineColor      ("Line Color",    Color) = (0,0,0,1)
        _GridDensity    ("Grid Density",  Float) = 10
        _LineWidth      ("Line Width",    Range(0.001,0.1)) = 0.02
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        LOD 100

        Pass
        {
            Cull Off
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            fixed4 _LowColor, _MidColor, _HighColor;
            float  _LowThreshold, _MidThreshold, _HighThreshold;

            fixed4 _LineColor;
            float  _GridDensity, _LineWidth;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv     : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos    : SV_POSITION;
                float2 uv     : TEXCOORD0;
                float  height : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos    = UnityObjectToClipPos(v.vertex);
                o.uv     = v.uv * _GridDensity;
                o.height = v.vertex.y;      // ← use Y as “up”
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // compute ramp t-values
                float t1 = saturate((i.height - _LowThreshold)  / (_MidThreshold - _LowThreshold));
                float t2 = saturate((i.height - _MidThreshold)  / (_HighThreshold - _MidThreshold));

                // choose between Low→Mid or Mid→High
                fixed4 baseColor = (i.height <= _MidThreshold)
                                    ? lerp(_LowColor,  _MidColor,  t1)
                                    : lerp(_MidColor,  _HighColor, t2);

                // grid overlay
                float2 grid = abs(frac(i.uv - 0.5) * 2.0);
                float lineDist = min(grid.x, grid.y);
                float m = smoothstep(0.0, _LineWidth, lineDist);

                // mix line vs. ramp
                fixed4 col;
                col.rgb = lerp(_LineColor.rgb, baseColor.rgb, m);
                col.a   = lerp(_LineColor.a,   baseColor.a,   m);
                return col;
            }
            ENDCG
        }
    }
    FallBack "Transparent/Diffuse"
}
