Shader "Unlit/RayMarchingTest2"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlendStrength("Blend strength", Range(0,1)) = 0
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
            #define MAX_DISTANCE 100
            #define MAX_STEPS 100
            #define COLLISION_DISTANCE 1e-3

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 ray_origin : TEXCOORD1; //Camera Position
                float3 hit_position : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            // Blend strength
            float _BlendStrength;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.ray_origin = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos,1)); //Convert World Space to Object Space
                o.hit_position = v.vertex; //Object Space
                return o;
            }
            
            // Not utilized properly
            float pythaDistance(float2 v)
            {
                return sqrt(v.x * v.x + v.y * v.y);
            }

            float smoothMin(float distA, float distB, float k)
            {
                float h = max(k-abs(distA - distB), 0) / k;
                return min(distA, distB) - h*h*h*k*1/6.0;
            }

            float get_distance(float3 position)
            {
                //float distance = pythaDistance(position);
                float distanceSphere = length(position) - 0.5; //Sphere
                float distanceTorus = length(float2(length(position.xz) - .5, position.y)) - .1; //Torus   
                return max(smoothMin(distanceSphere, distanceTorus, _BlendStrength), smoothMin(distanceSphere, distanceTorus, _BlendStrength));
            }
            float Raymarch(float3 ray_origin, float3 ray_direction)
            {
                float distance_origin = 0;
                float distance_scene;
                //March along the ray
                for(int i = 0; i < MAX_STEPS; i++)
                {
                    float3 position = ray_origin + distance_origin * ray_direction;
                    distance_scene = get_distance(position);
                    distance_origin += distance_scene;
                    if(distance_scene < COLLISION_DISTANCE || distance_origin > MAX_DISTANCE) {break;}
                }
                return distance_origin;
            }
            float3 GetNormal(float3 position) {
                //Point - Points around it
                float2 epsilon = float2(1e-2,0);
                float3 normal = get_distance(position) - float3(
                    get_distance(position-epsilon.xyy),
                    get_distance(position-epsilon.yxy),
                    get_distance(position-epsilon.yyx)
                );
                return normalize(normal);
            }
            float4 frag (v2f i) : SV_Target
            {
                //Offset origin to middle
                float2 uv = i.uv - 0.5;
                float3 ray_origin = i.ray_origin; //Turns this into camera
                float3 ray_direction = normalize(i.hit_position - ray_origin);
                //Get the distance
                float distance = Raymarch(ray_origin, ray_direction);
                float4 col = 0;
                fixed4 tex = tex2D(_MainTex, i.uv);
                float m = dot(uv, uv);
                //Display Raymarch
                if(distance < MAX_DISTANCE){
                    float3 position = ray_origin + ray_direction * distance;
                    float3 normal = GetNormal(position);
                    col.rgb = normal * tex;
                } else {
                    discard;
                }
                //col += lerp(col, tex, smoothstep(0.1, 0.2, m));
                return col;
            }
            ENDCG
        }
    }
}
