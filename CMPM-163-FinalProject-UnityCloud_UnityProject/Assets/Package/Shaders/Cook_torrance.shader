Shader "Shaders/Cook_torrance"
{
  Properties
  {
    _Albedo("Albedo", 2D) = "white" {}
    _MetalTex("Metalness", 2D) = "white" {}
    _RoughTex("Roughness", 2D) = "white" {}
    _SpecularColor("Specular Color", Color) = (1, 1, 1, 1)
    _Cube("Cubemap", CUBE) = "" {}
  }
  
  SubShader
  {

    Pass
    {

      //Tags { "LightMode" = "ForwardBase" }
      
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag //line 20
      #include "UnityCG.cginc"

      samplerCUBE _Cube;
      float4 _LightColor0; //Light color, declared in UnityCG
      sampler2D _Albedo;
      sampler2D _MetalTex;
      sampler2D _RoughTex;
      float4 _SpecularColor;

      struct VertexShaderInput
      {
        float4 vertex : POSITION;
        float2 uv     : TEXCOORD0;
        float3 worldNormal : NORMAL;
        
      };

      struct VertexShaderOutput
      {
        float4 pos:SV_POSITION;
        float2 uv: TEXCOORD0; //line 40
        float3 worldNormal: TEXCOORD1;
        float3 worldVertexPos: TEXCOORD2;
      };

      //Normal Distribution Function (D)
      float DistributionGGX(float NdotH, float roughness)
      {
         float a2 = roughness * roughness;
         float NdotH2 = NdotH * NdotH;
         float nom = a2;
         float denom = (NdotH2 * (a2 - 1.0) + 1.0);
         denom = 3.14 * denom * denom;

         return nom/denom;
      }

      //Geometry Function (G)
      float GeometrySchlickGGX(float NdotV, float roughness)
      {
         float nom = NdotV;
         float denom = NdotV * (1.0 - roughness) + roughness;

         return nom/denom;
      }

      float GeometrySmith(float NdotV, float NdotL, float roughness)
      {
         float ggx1 = GeometrySchlickGGX(NdotV, roughness);
         float ggx2 = GeometrySchlickGGX(NdotL, roughness);

         return ggx1 * ggx2;
      }

      //Fresnel function (F)
      float3 FresnelSchlick(float3 F0, float NdotV)
      {
         return F0 + (1.0 - F0) * pow(1.0 - NdotV, 5.0);
      }

      VertexShaderOutput vert(VertexShaderInput v)
      {
        VertexShaderOutput o;
        o.uv = v.uv;
        o.pos = UnityObjectToClipPos(v.vertex);
        o.worldNormal = UnityObjectToWorldNormal(v.worldNormal);
        o.worldVertexPos = mul(unity_ObjectToWorld, v.vertex);
        return o;
      }

      float4 frag(VertexShaderOutput i):SV_TARGET
      {
        float3 P = i.worldVertexPos;
        float3 N = normalize(i.worldNormal);
        float3 V = normalize( _WorldSpaceCameraPos - P);
        float3 L;
        float3 R;
        float3 H; //line 60
        float NdotL;
        float NdotH;
        float NdotV;
        float3 Specular_BRDF;
        float3 Diffuse_BRDF;
        float4 _Color = float4(1,1,1,1);

        if(_WorldSpaceLightPos0.w == 1){
           L = normalize( _WorldSpaceLightPos0.xyz - P);
        }else{
           L = normalize( _WorldSpaceLightPos0.xyz);
        }
        R = reflect(-L, N);
        H = normalize(L + V);
             
        //dot products
        
        //angle between normal and light vector
        NdotL = max(dot(N, L), 0.0);


        //angle between normal and half vector
        NdotH = max(dot(N, H), 0.0);
        //angle between normal and view vector line 80
        NdotV = max(dot(N, V), 0.0);

        //roughness value
        float roughness = tex2D(_RoughTex, i.uv).r; 
        //metalness value
        float metalness = tex2D(_MetalTex, i.uv).r;

        //Material response
        float3 F0 = lerp(_SpecularColor, tex2D(_Albedo, i.uv).rgb, metalness);
        //used for Fresnel equation
        //linear interpolation = lerp

        //Specular BRDF
        float D = DistributionGGX(NdotH, roughness);
        float G = GeometrySmith(NdotV, NdotL, roughness);
        float3 F = FresnelSchlick(F0, NdotV);

        Specular_BRDF = (D*G*F)/(4*NdotV*NdotL + 0.000001);

        //Diffuse Factor
        float3 Diffuse_factor = 1 - F; //F is from fresnel function
        //control Difuse factor based on metalness
        Diffuse_factor = Diffuse_factor * (1 - metalness);
        
        Diffuse_BRDF = Diffuse_factor * tex2D(_Albedo, i.uv); // albedo = texture * color


        _Color = float4(Diffuse_BRDF + Specular_BRDF, 1) * _LightColor0 * NdotL;

        //incident vector
        
        
        //cook_torrance
        //return _Color
        //cook_torrance combined with cube mapping
        float4 reflect_color = texCUBE(_Cube, reflect(V, P));
        //return _Color + reflect_color;

        //refract cube mapping
        float4 refract_color = texCUBE(_Cube, refract(reflect(-V,P), N, 0.65));
        return _Color + lerp(reflect_color, refract_color, 0.7);
      
      }

      ENDCG
    }

  }

}