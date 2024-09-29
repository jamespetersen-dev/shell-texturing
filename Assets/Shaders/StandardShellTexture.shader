Shader "Custom/StandardShellTexture"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Extrusion("Extrusion", float) = 0.5
        _Shells("Shells", Range(0, 41)) = 1
        _Density("Density", float) = 1.0
        _BaseColor("Base Color", Color) = (0, 0, 0, 0)
        _TipColor("Tip Color", Color) = (1, 1, 1, 1)
        _LightDirection("Light Direction", Vector) = (1, 1, 1)
        _TiltDirection("Tilt Direction", Vector) = (1, 1, 1)
        _DisplacementStrength("Displacement Strength", float) = 1.0
        _Curvature("Curvature", float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        Cull Off
        LOD 100
 
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
 
            #include "UnityCG.cginc"
 
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };
 
            struct v2g
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };
 
            struct g2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float color : COLOR;
                float height_index : TEXCOORD1;
            };
 
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Extrusion; //How far out from the mesh the shader goes
            int _Shells; //How many shells are in the mesh
            float _Density;
            float4 _BaseColor;
            float4 _TipColor;
            float3 _LightDirection;
            float3 _TiltDirection;
            float _DisplacementStrength;
            float _Curvature;

            v2g vert (appdata v)
            {
                v2g o;
                o.vertex = v.vertex;
                o.uv = v.uv;
                o.normal = v.normal;
                return o;
            }

            float hash(uint n) {
				// integer hash copied from Hugo Elias
				n = (n << 13U) ^ n;
				n = n * (n * n * 15731U + 0x789221U) + 0x1376312589U;
				return float(n & uint(0x7fffffffU)) / float(0x7fffffff);
			}
 
            [maxvertexcount(126)]
            void geom(triangle v2g input[3], inout TriangleStream<g2f> triStream)
            {
                g2f o;

                for (int a = 0; a < _Shells; a++) {
                    for (int i = 0; i < 3; i++) {
                        float3 extrudedVertex = input[i].normal * a / (1.0 / _Extrusion) / 1000.0;
                        float3 displacedVertex = _TiltDirection * _DisplacementStrength / 1000.0 * pow(a / (float)_Shells, _Curvature);
                        o.vertex = UnityObjectToClipPos(input[i].vertex + extrudedVertex + displacedVertex);
                        o.uv = TRANSFORM_TEX(input[i].uv, _MainTex);
                        float shade = dot(input[i].normal, _LightDirection) / 2.0 + 0.5;
                        o.color = shade;
                        o.height_index = a;
                        triStream.Append(o);
                    }
                    triStream.RestartStrip();
                }
            }
 
            float4 frag (g2f i) : SV_Target
            {
                float2 newUV = i.uv * _Density;
                float2 localUV = frac(newUV) * 2 - 1;
                float localDistanceFromCenter = length(localUV);

                uint2 tid = newUV;
				uint seed = tid.x + 101 * tid.y + 101 * 10;
                float hashed_seed = hash(seed);
                
                float height_factor = i.height_index / (float)_Shells;

                bool bottom = i.height_index > 0;
                bool cylinder = localDistanceFromCenter > 1.0;
                bool cone = localDistanceFromCenter > (1.0 - height_factor - hashed_seed) * 3.0;

                if (bottom && (cone || cylinder)) {
                    discard;
                }
                float4 color = lerp(_BaseColor, _TipColor, height_factor) * float4(i.color, i.color, i.color, 1.0);
                return color;
            }
            ENDCG
        }
    }
}