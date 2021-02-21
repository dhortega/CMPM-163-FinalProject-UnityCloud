// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Shaders/PhongStarter"
{
	Properties{
		_MainTex("Albedo", 2D) = "white" {}
		_Color("Color", Color) = (1,1,1,1)
                [MaterialToggle] _Ambient("Ambient", Float) = 0
                [MaterialToggle] _Diffuse("Diffuse", Float) = 0
                [MaterialToggle] _Specular("Specular", Float) = 0
		_Shininess("Shininess", Float) = 0.0
                _SpecularColor("Specular Color", Color) = (1, 1, 1, 1)
	}

	SubShader
	{
		//PASS 1		
		Pass 
		{
			Tags { "LightMode" = "ForwardBase" } // Since we are doing forward rendering and we want to get directional light
			// Tags { "LightMode" = "ForwardAdd"} For point lights. One pass per light
			// Blend One One //Turn on additive blending if you have more than one point light (optional)
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc" // Predefined variables and helper functions Unity provides

			float4 _LightColor0; //Light color, declared in UnityCG
			sampler2D _MainTex;
			float4 _Color;
			float4 _SpecularColor;
                        float _Ambient;
                        float _Diffuse;
                        float _Specular;
                        float _Shininess;
			struct VertexShaderInput
			{
				float4 vertex : POSITION;
				float2 uv	  : TEXCOORD0;
                                float3 worldNormal : NORMAL;
                                float3 worldVertexPos : TEXCOORD2;
			};

			struct VertexShaderOutput
			{
				float4 pos:SV_POSITION;
				float2 uv: TEXCOORD0;
                                float4 worldNormal: TEXCOORD1;
                                float3 worldVertexPos: TEXCOORD2; //line 50
			};

			VertexShaderOutput vert(VertexShaderInput v)
			{
				VertexShaderOutput o;
				o.uv = v.uv;
				o.pos = UnityObjectToClipPos(v.vertex);
                                o.worldNormal = float4(UnityObjectToWorldNormal(v.worldNormal), 1);
                                o.worldVertexPos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}

			float4 frag(VertexShaderOutput i):SV_TARGET
			{
                                // P = world space position
                                // N = normal(normalize)
                                // V = view vector = Camera position - P (normalize)
                                // L = light vector(direction) = light position - P(for point light) (normalize)
                                // L = _WorldSpaceLightPos0.xyz (for directional light) (normalize)
                                // R = reflect vector = reflect(-light direction, normal)

                                float3 P = i.worldVertexPos;
                                float4 N = normalize(i.worldNormal);
                                float3 V = normalize( _WorldSpaceCameraPos - P);
                                float3 L;
                                float3 R; 
                                float3 newColor = float3(0, 0, 0);
                                _LightColor0 += float4(0,0,1,1) * 1; //change light color in the float4 and intensity by multiplying

                                if(_WorldSpaceLightPos0.w == 1){
                                      //point light
                                      L = normalize( _WorldSpaceLightPos0.xyz - P);
                                }else{
                                      //directional light
                                      L = normalize( _WorldSpaceLightPos0.xyz);
                                }
                                R = reflect(-L, N);
				float4 output;
				output = tex2D(_MainTex, i.uv);

                                //Ambient
                                if(_Ambient == 1){
                                      newColor += _Color.rgb;
                                      
                                }
                                //Diffuse = Light * Albedo * Diffuse_value
                                //Light = _LightColor0
                                // Albedo = Texture * _Color (output is the texture)
                                // Diffuse_value = cos(Normal, Light Direction) = dot(Normal, Light Direction)
                               
                                if( _Diffuse == 1){
                                       newColor += max( 0.0 , dot(N, L)) * _LightColor0.rgb * output * _Color.rgb;
                                }
                  

                                // Specular = Light * Specular_color * Specular_value * Specular_intensity
                                // Specular_color = color picker
                                // Specular_intensity = range(0,1)
                                // Specular_value = dot(R, V)^_Shininess (dot(R, V) > 0)
                                if(_Specular == 1){
                                     newColor += _LightColor0 * _SpecularColor * pow(max( 0.0, dot(R,V)), _Shininess) * 1; 
                                }
                                
                                


				return float4(newColor, 1.0);
                                
			}
			ENDCG
		}

		//// PASS 2	
		//Pass
		//{
		//	//Tags { "LightMode" = "ForwardBase" } // Since we are doing forward rendering and we want to get directional light
		//	Tags { "LightMode" = "ForwardAdd"} //For point lights. One pass per light
		//	// Blend One One //Turn on additive blending if you have more than one point light (optional)
		//	CGPROGRAM
		//	#pragma vertex vert
		//	#pragma fragment frag

		//	#include "UnityCG.cginc" // predefined variables and helper functions Unity provides

		//	float4 _LightColor0; //Light color, declared in UnityCG
		//	sampler2D _MainTex;
		//	float4 _Color;

		//	struct VertexShaderInput
		//	{
		//		float4 vertex : POSITION;
		//		float2 uv	  : TEXCOORD0;

		//	};

		//	struct VertexShaderOutput
		//	{
		//		float4 pos:SV_POSITION;
		//		float2 uv: TEXCOORD0;

		//	};

		//	VertexShaderOutput vert(VertexShaderInput v)
		//	{
		//		VertexShaderOutput o;
		//		o.uv = v.uv;
		//		o.pos = UnityObjectToClipPos(v.vertex);
		//		return o;
		//	}

		//	float4 frag(VertexShaderOutput i) :SV_TARGET
		//	{
		//		float4 output;
		//		output = tex2D(_MainTex, i.uv);
		//		return output * _LightColor0;
		//	}
		//	ENDCG
		//}
	}
}
