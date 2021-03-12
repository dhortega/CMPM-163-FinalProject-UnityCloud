Shader "Shaders/green"
{
  Properties
  {
      ColorB("ColorB", Color) = (0,1,0,1)
      
      
  }
  
  SubShader
  {

    Pass
    {
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      
      
      
   
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
        return ColorB;
        
      }


      ENDCG
    }

  }

}