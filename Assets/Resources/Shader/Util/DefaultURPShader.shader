Shader "Unlit/DefaultURPShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        // Blending state
        [Enum(UnityEngine.Rendering.BlendOp)] _Blend("Blend Op", Float) = 0.0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Blend Src", Float) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Blend Dst", Float) = 0.0
        [Enum(UnityEngine.Rendering.CullMode)]_Cull("Cull", Float) = 2.0
        [Enum(UnityEngine.Rendering.CompareFunction)]_ZTest("ZTest", Float) = 4.0
        [Toggle]_ZWrite("ZWrite", Float) = 1.0
        
        // Stencil state
        [Space(20)]
        [Header(Stencil State)]
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp("Stencil Comp", Float) = 8.0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilOp("Stencil Operation", Float) = 2.0
        [Int]_Stencil("Stencil", Range(0, 255)) = 0.0
        [Int]_ReadMask("Stencil", Range(255, 255)) = 255.0
        [Int]_WriteMask("Stencil", Range(0, 255)) = 0.0
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
            "Queue"="Geometry"
        }
        LOD 100

        Pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
            }
            
            Stencil
            {
                Comp [_StencilComp]
                Pass [_StencilOp]
                Ref [_Stencil]
                ReadMask [_ReadMask]
                WriteMask [_WriteMask]
            }

            Blend [_SrcBlend] [_DstBlend]
            ZTest [_ZTest]
            ZWrite [_ZWrite]
            Cull [_Cull]
            
            HLSLPROGRAM
            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            TEXTURE2D(_MainTex);            SAMPLER(sampler_MainTex);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                half2 uv : TEXCOORD0;
            };

            Varyings VertexProgram(Attributes input)
            {
                Varyings output;
                VertexPositionInputs vertexPositions = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = vertexPositions.positionCS;
                output.uv = input.uv * _MainTex_ST.xy + _MainTex_ST.zw;
                return output;
            }

            half4 FragmentProgram(Varyings input) : SV_Target
            {
                half4 color;
                color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                return color;
            }
            ENDHLSL
        }
    }
}
