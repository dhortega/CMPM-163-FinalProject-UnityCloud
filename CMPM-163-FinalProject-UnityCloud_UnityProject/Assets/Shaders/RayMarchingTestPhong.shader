Shader "Unlit/RayMarchingTestPhong"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Alpha("Alpha", Range(0, 0.7)) = 0
        _BlendStrength("Blend strength", Range(0.04,.1)) = 0.055
        _Bounce("Bounce", Range(0.1,5)) = 0
        _BounceA("BounceA", Range(0.1,5)) = 0
        _BounceB("BounceB", Range(0.1,5)) = 0
        _BounceC("BounceC", Range(0.1,5)) = 0
        _BounceD("BounceD", Range(0.1,5)) = 0
        _BounceE("BounceE", Range(0.1,5)) = 0
        _BounceF("BounceF", Range(0.1,5)) = 0
        _BounceG("BounceG", Range(0.1,5)) = 0
        _TimeDelay("Time Delay", range(0.1,10)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            // Debugging tool
            RWStructuredBuffer<float4> buffer : register(u1);

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

            // Flag for determining isDay
            // Declaring isDay to 1. This will be multiplied by -1 to be represent
            // notDay initially
            //uniform float isDay = 1;
            //uniform float _notDay = -1;
            //uniform float _currentDay;

            // Alpha
            float _Alpha;
            float isDay;
            uniform float isTriggerable = 1;

            // Blend strength
            float _BlendStrength;
            float _Bounce;
            float _BounceA;
            float _BounceB;
            float _BounceC;
            float _BounceD;
            float _BounceE;
            float _BounceF;
            float _BounceG;

            // Time delay
            float _TimeDelay;

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
                float distanceSphere1 = length(float3(length(position.x + 1.0 / ObjectScale().x),
                        position.y + 0.4 / ObjectScale().y + (_BounceA * sin(_Time + _TimeDelay).y) / ObjectScale().y,
                        position.z)
                    ) - 1.1 / ObjectScale(); //Sphere
                float distanceSphere2 = length(float3(length(position.x - 0.5 / ObjectScale().x),
                        position.y + 0.5 / ObjectScale().y + (_BounceB * sin(_Time + _TimeDelay).y) / ObjectScale().y,
                        position.z)
                    ) - 1 / ObjectScale(); //Sphere
                float distanceSphere3 = length(float3(length(position.x - 1.8 / ObjectScale().x),
                        position.y + 0.5 / ObjectScale().y + (_BounceC * sin(_Time + _TimeDelay).y) / ObjectScale().y,
                        position.z)
                    ) - 0.6 / ObjectScale(); //Sphere
                float distanceSphere4 = length(float3(length(position.x + 2.2 / ObjectScale().x),
                        position.y + 0.5 / ObjectScale().y + (_BounceD * sin(_Time + _TimeDelay).y) / ObjectScale().y,
                        position.z)
                    ) - 1 / ObjectScale(); //Sphere
                float distanceSphere5 = length(float3(length(position.x - 1.0 / ObjectScale().x),
                        position.y - 0.5  / ObjectScale().y + (_BounceE * sin(_Time + _TimeDelay).y) / ObjectScale().y,
                        position.z)
                    ) - .6 / ObjectScale(); //Sphere
                float distanceSphere6 = length(float3(length(position.x + 1.5 / ObjectScale().x),
                        position.y - 0.75 / ObjectScale().y + (_BounceF * sin(_Time + _TimeDelay).y) / ObjectScale().y,
                        position.z)
                    ) - .85 / ObjectScale(); //Sphere
                float distanceSphere7 = length(float3(length(position.x + 0.2 / ObjectScale().x),
                        position.y - 0.75 / ObjectScale().y + (_BounceG * sin(_Time + _TimeDelay).y) / ObjectScale().y,
                        position.z)
                    ) - 0.45 / ObjectScale() * 1.5; //Sphere
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
                    // Initializing _Alpha
                    //_Alpha = 0;
                    // Initializing isDay
                    isDay = 1;
                    

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
                    // Seeing value of L change with time
                    //buffer[0] = float4(L, 1);

                    if (L.y < 0 && isTriggerable == 1)  // When L.y hits negative toggle isDay to be positive or negative
                    {   // Setting isDay to positive
                        isDay = isDay * -1;
                        isTriggerable = 0;
                        //Shader.SetGlobalFloat("_isDay", (_isDay * -1));
                    }
                    // When in between values and daytime time decrease alpha
                    if ((L.y >= 0.30 || L.y <= 0.864) && (isDay >= 0))
                    {
                        _Alpha -= 0;
                    }
                    // When in between values and night time increase alpha
                    // isDay is positive and should have higher alpha 
                    else if ((L.y >= 0.30 || L.y <= 0.864) && (isDay <= 0)) 
                    {
                        _Alpha += 0.3;
                        isTriggerable = 1; 
                    } 
                    
                    // Debug lines
                    // Seeing L.y change over time
                    //buffer[0] = float4(L,1);
                    //buffer[0] = float4(isDay, 0, 0, 1);
                    // Seeing isDay change over time
                    //buffer[0] = float4(isDay, 0, 0, 1);
                    // Seeing _Alpha change with time
                    //buffer[0] = _Alpha;

                    float3 R = reflect(-L,N);
                    float3 H = normalize(L+V);
                    float4 Diffuse = _LightColor0 * tex * max(0,dot(N,L)) + _Alpha;
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
