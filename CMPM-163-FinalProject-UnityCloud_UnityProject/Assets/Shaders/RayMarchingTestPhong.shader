Shader "Unlit/RayMarchingTestPhong"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlendStrength("Blend strength", Range(0.07,.1)) = 0
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
            float4 _LightColor0; //Light color, declared in UnityCG
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
            half3 ObjectScale() {
            return half3(
                length(unity_ObjectToWorld._m00_m10_m20),
                length(unity_ObjectToWorld._m01_m11_m21),
                length(unity_ObjectToWorld._m02_m12_m22)
            );
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
                float distanceSphere1 = length(float3(length(position.x + 0.5 / ObjectScale().x),
                        position.y + 0.5 / ObjectScale().y,
                        position.z)
                    ) - 1 / ObjectScale(); //Sphere
                float distanceSphere2 = length(float3(length(position.x - 0.5 / ObjectScale().x),
                        position.y + 0.5 / ObjectScale().y,
                        position.z)
                    ) - 1 / ObjectScale(); //Sphere
                float distanceSphere3 = length(float3(length(position.x - 2.0 / ObjectScale().x),
                        position.y + 0.5 / ObjectScale().y,
                        position.z)
                    ) - 0.5 / ObjectScale(); //Sphere
                float distanceSphere4 = length(float3(length(position.x + 2.5 / ObjectScale().x),
                        position.y + 0.5 / ObjectScale().y,
                        position.z)
                    ) - 1 / ObjectScale(); //Sphere
                float distanceSphere5 = length(float3(length(position.x - 1.0 / ObjectScale().x),
                        position.y - 0.5 / ObjectScale().y,
                        position.z)
                    ) - 0.5 / ObjectScale(); //Sphere
                float distanceSphere6 = length(float3(length(position.x + 1.5 / ObjectScale().x),
                        position.y - 0.5 / ObjectScale().y,
                        position.z)
                    ) - 1 / ObjectScale(); //Sphere
                float distanceSphere7 = length(float3(length(position.x + 0.0 / ObjectScale().x),
                        position.y - 0.5 / ObjectScale().y,
                        position.z)
                    ) - 0.5 / ObjectScale() * 1.5; //Sphere
                //float distanceSphere2 = length(float2(length(position.xz) - .5, position.y)) - .1; //Torus   

                //Change _BlendStrength form 0.07 to 0. 1 with noise
                float output = smoothMin(distanceSphere1, distanceSphere2, _BlendStrength);
                output = smoothMin(output, distanceSphere3, _BlendStrength);
                output = smoothMin(output, distanceSphere4, _BlendStrength);
                output = smoothMin(output, distanceSphere5, _BlendStrength);
                output = smoothMin(output, distanceSphere6, _BlendStrength);
                output = smoothMin(output, distanceSphere7, _BlendStrength);
                return output;
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
                float4 tex = tex2D(_MainTex, i.uv);
                float4 col = 0;
                //Display Raymarch
                if(distance < MAX_DISTANCE){
                    float3 position = ray_origin + ray_direction * distance;
                    float3 normal = GetNormal(position);
                    //Diffusion
                    float3 P = position;
                    float3 N = normal;
                    //float3 NSCP = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos,1)); //NormalSpaceCameraPos
                    //float4 NSLP = mul(unity_WorldToObject,  _WorldSpaceLightPos0); //NormalSpaceLightPos
                    float3 V = normalize(_WorldSpaceCameraPos - P);
                    float3 L;
                    if(_WorldSpaceLightPos0.w == 0)
                    {
                        //Directional
                        L = normalize(_WorldSpaceLightPos0.xyz);
                    } 
                    else
                    {
                        //Point
                        L = normalize(_WorldSpaceLightPos0.xyz - P);
                    }
                    float3 R = reflect(-L,N);
                    float3 H = normalize(L+V);
                    float4 Diffuse = _LightColor0 * tex * max(0,dot(N,L));
                    //col.rgb = tex;
                    col = Diffuse;
                } else {
                    discard;
                }
                return col;
            }
            ENDCG
        }
    }
}
