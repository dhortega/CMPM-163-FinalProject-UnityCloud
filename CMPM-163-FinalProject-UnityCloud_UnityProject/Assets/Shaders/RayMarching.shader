Shader "Unlit/RayMarching"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            //Parameters
            float MAX_DISTANCE = 100;
            float MAX_STEPS = 100;
            float COLLISION_DISTANCE = 1e-3;
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float get_distance(float3 position)
            {
                float distance = length(position ) - 0.5;
                return distance;
            }
            float Raymarch(float3 ray_origin, float3 ray_direction)
            {
                float distance_origin = 0;
                float distance_scene;
                for(int i = 0; i < MAX_STEPS; ++i)
                {
                    float3 position = ray_origin + distance_origin * ray_direction;
                    distance_scene = get_distance(position);
                    distance_origin += distance_scene;
                    if(distance_scene < COLLISION_DISTANCE || distance_origin > MAX_DISTANCE) {break;}
                }
                return distance_origin;
            }
            fixed4 frag (v2f i) : SV_Target
            {
                //offset origin to middle
                float2 uv = i.uv - 0.5;
                float3 ray_origin = float3(0,0,-3);
                float3 ray_direction = normalize(float3(uv.x, uv.y, 1));
                // sample the texture
                float distance = Raymarch(ray_origin, ray_direction);
                fixed4 col = 0;
                if(distance < MAX_DISTANCE){
                    col.r = 1;
                }
                col.rgb = ray_direction;
                return col;
            }
            ENDCG
        }
    }
}
