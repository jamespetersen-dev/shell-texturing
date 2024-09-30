Shader "Custom/UniqueShellTexture"
{
        Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Extrusion("Extrusion", Range(0.0, 4.0)) = 0.5
        _Density("Density", Range(0.0, 256.0)) = 1.0
        _BaseColor("Base Color", Color) = (0, 0, 0, 0)
        _TipColor("Tip Color", Color) = (0, 0, 0, 0)
    }
    SubShader
    {
        Cull Off
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #define UNITY_INDIRECT_DRAW_ARGS IndirectDrawIndexedArgs
            #include "UnityIndirect.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Extrusion; //How far out from the mesh the shader goes
            float _Density;
            float4 _BaseColor, _TipColor;

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD1;
                float4 color : COLOR0;
                float heightIndex : TEXCOORD2;
                float instanceRatio : TEXCOORD3;
                float3 worldNormal : TEXCOORD4;
                float3 worldPos : TEXCOORD5;
            };

            uniform float4x4 _ObjectToWorld;
            uniform int _TotalInstances; 
            uniform float3 _Scale;

            // Lighting data
            float4 _LightColor0;       // Main directional light color
            //float4 _WorldSpaceLightPos0;  // Main directional light direction in world space


            float hash(uint n) {
				// integer hash copied from Hugo Elias
				n = (n << 13U) ^ n;
				n = n * (n * n * 15731U + 0x789221U) + 0x1376312589U;
				return float(n & uint(0x7fffffffU)) / float(0x7fffffff);
			}

            v2f vert(appdata_base v, uint svInstanceID : SV_InstanceID)
            {
                InitIndirectDrawArgs(0);

                float PI = 3.14159265;

                v2f o;

                uint cmdID = GetCommandID(0);
                uint instanceID = GetIndirectInstanceID(svInstanceID);

                o.instanceRatio = float(svInstanceID) / float(_TotalInstances);
                o.heightIndex = instanceID;

                o.uv = v.texcoord;

                float4 worldPos = mul(_ObjectToWorld, v.vertex);
                float3 worldNormal = normalize(mul((float3x3)_ObjectToWorld, v.normal));

                o.worldPos = worldPos;
                o.worldNormal = worldNormal;

                float3 extrudedPos = worldPos + worldNormal * _Extrusion * o.instanceRatio;

                o.pos = mul(UNITY_MATRIX_VP, float4(extrudedPos, 1.0));

                o.color = float4(o.instanceRatio, o.instanceRatio, o.instanceRatio, 1.0);

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 newUV = i.uv * _Density * _Scale.xz;
                float2 localUV = frac(newUV) * 2 - 1;
                float localDistanceFromCenter = length(localUV);

                //float noise = tex2D(_MainTex, i.uv);

                uint2 tid = newUV;
                uint seed = tid.x + 101 * tid.y + 101 * 10;
                float hashed_seed = hash(seed);
                
                //if (noise == 1) {
                //    noise = hashed_seed;
                //}

                bool bottom = i.heightIndex > 0;
                bool cylinder = localDistanceFromCenter > 1.0;
                bool cone = localDistanceFromCenter > (1.0 - i.instanceRatio - hashed_seed) * 3.0;

                if (bottom && (cone || cylinder)) {
                    discard;
                }

                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz); // Light direction from Unity
                float NdotL = dot(i.worldNormal, lightDir);             // Regular dot product of normal and light direction
                float halfLambert = saturate(NdotL * 0.5 + 0.5);        // Apply half-Lambert modification

                float3 diffuse = _LightColor0.rgb * halfLambert;        

                float4 color = lerp(_BaseColor, _TipColor, i.instanceRatio);

                return color * float4(diffuse, 1.0);
            }
            ENDCG
        }
    }
}
