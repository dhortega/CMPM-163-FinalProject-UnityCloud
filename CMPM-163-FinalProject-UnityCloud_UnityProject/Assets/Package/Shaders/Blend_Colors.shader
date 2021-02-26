Shader "Shaders/Blend_Colors"
{
  Properties
  {
      ColorA("ColorA", Color) = (1,0,0,1)
      ColorB("ColorB", Color) = (0,1,0,1)
      blendFactor("BlendFactor", Range(0,1)) = 0
      
  }
  
  SubShader
  {

    Pass
    {
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      
      
      float4 blendColor;
      float blendFactor;
      float4 ColorA;
      float4 ColorB;

      struct VertexShaderInput
      {
        float4 vertex: POSITION;
        
      };

      struct VertexShaderOutput
      {
        float4 pos: SV_POSITION;

      };

      VertexShaderOutput vert(VertexShaderInput v)
      {
        VertexShaderOutput o;
        o.pos = UnityObjectToClipPos(v.vertex);
        return o;
      }
      
      float4 frag(VertexShaderOutput i): SV_TARGET
      {
        blendFactor = sin(_Time).y;
        blendColor = (blendFactor*ColorA) + ((1-blendFactor)*ColorB);
        return blendColor;
        
      }


      ENDCG
    }

  }

}