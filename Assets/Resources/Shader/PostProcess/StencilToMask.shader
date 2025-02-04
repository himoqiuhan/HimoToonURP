Shader "HimoToon/Util/StencilToMask"
{
    Properties
    {
        _ColorMask("Color Mask", int) = 0
        
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
            
            ColorMask [_ColorMask]
            
            Stencil
            {
                Comp [_StencilComp]
                Pass [_StencilOp]
                Ref [_Stencil]
                ReadMask [_ReadMask]
                WriteMask [_WriteMask]
            }

            Blend One Zero
            ZTest Always
            ZWrite Off
            Cull Off
            
            HLSLPROGRAM
            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            CBUFFER_END


            struct Attributes
            {
                float4 positionOS : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings VertexProgram(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.positionCS = float4(input.positionOS.xy, UNITY_RAW_FAR_CLIP_VALUE, 1.0);
                return output;
            }

            half4 FragmentProgram(Varyings input) : SV_Target
            {
                return 1;
            }
            ENDHLSL
        }
    }
}
