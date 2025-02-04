Shader "HimoToon/Scene/SceneOutline"
{
    Properties
    {
        _SampleDistance("Sample Distance", Float) = 1.0
        _Sensitivity("Sensitivity", Vector) = (1.0, 1.0, 1.0, 1.0)
        _EdgeColor("Edge Color", Color) = (0, 0, 0, 1)
        
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
            Name "SceneOutline"
            Tags
            {
                "LightMode"="SRPDefaultUnlit"
            }
            
            Stencil
            {
                Comp [_StencilComp]
                Pass [_StencilOp]
                Ref [_Stencil]
                ReadMask [_ReadMask]
                WriteMask [_WriteMask]
            }

            Blend One OneMinusSrcAlpha
            ZTest Always
            ZWrite Off
            Cull Off
            
            HLSLPROGRAM
            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _Sensitivity;
            half4 _EdgeColor;
            half _SampleDistance;
            float4 _CameraDepthTexture_TexelSize;
            CBUFFER_END

            TEXTURE2D_X(_CameraDepthTexture);
            TEXTURE2D_X_HALF(_GBuffer0);
            TEXTURE2D_X_HALF(_GBuffer2);
            SamplerState my_point_clamp_sampler;
            
            TEXTURE2D(_CharacterMaskTexture);            SAMPLER(sampler_CharacterMaskTexture);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 screenUV : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            half CheckSame(half4 center, half4 sample)
            {
                //使用Roberts算子进行边缘检测
                half3 centerNormal = center.xyz;
                float centerDepth = center.w;
                half3 sampleNormal = sample.xyz;
                float sampleDepth = sample.w;

                half3 diffNormal = abs(centerNormal - sampleNormal) * _Sensitivity.x;
                int isSameNormal = abs(diffNormal.x + diffNormal.y + diffNormal.z) < 0.1;
                
                half diffDepth = abs(centerDepth - sampleDepth) * _Sensitivity.y;
                int isSameDepth = abs(diffDepth) < 0.1;
                
                return (isSameDepth * isSameNormal) ? 1.0 : 0.0; //如果法线和深度都满足差距极小，则不加描边；否则进行描边处理
            }

            Varyings VertexProgram(Attributes input)
            {
                Varyings output;
                VertexPositionInputs vertexPositions = GetVertexPositionInputs(input.positionOS.xyz);
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                float3 positionOS = input.positionOS.xyz;
                output.positionCS = float4(positionOS.xy, UNITY_RAW_FAR_CLIP_VALUE, 1.0);
                
                output.screenUV = output.positionCS.xyw;
                #if UNITY_UV_STARTS_AT_TOP
                output.screenUV.xy = output.positionCS.xy * float2(0.5, -0.5) + 0.5 * output.positionCS.w;
                #else
                output.screenUV.xy = output.positionCS.xy * 0.5 + 0.5 * output.positionCS.w;
                #endif
                
                return output;
            }

            half4 FragmentProgram(Varyings input) : SV_Target
            {
                float2 sampleUV[5];
                float2 screenUV = input.screenUV.xy / input.screenUV.z;
                sampleUV[0] = screenUV;
                
                // float depth = SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture, my_point_clamp_sampler, input.uv[0], 0).x;
                // _Sensitivity.x *= saturate(depth + 0.5);
                // _Sensitivity.y *= saturate(depth + 0.75);
                // half4 temp = 1;
                float d0      = SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture, my_point_clamp_sampler, sampleUV[0], 0).x;
                half4 normal0 = SAMPLE_TEXTURE2D_X_LOD(_GBuffer2, my_point_clamp_sampler, sampleUV[0], 0);
                
                float eyeSceneDepth = LinearEyeDepth(d0, _ZBufferParams);
                float normalSensitivityScale = 1 - smoothstep(5,20, eyeSceneDepth);
                float sampleDistanceScale = max(0.2, 1 - smoothstep(10,25, eyeSceneDepth));
                // return half4(depthSensitivityScale,depthSensitivityScale,depthSensitivityScale,1);
                _Sensitivity.x *= normalSensitivityScale;
                _SampleDistance *= sampleDistanceScale;
                // temp.rgb = smoothstep(20,50, eyeSceneDepth);
                // return temp;
                // return temp;

                sampleUV[1] = screenUV + _CameraDepthTexture_TexelSize.xy * half2( 1,  1) * _SampleDistance;
                sampleUV[2] = screenUV + _CameraDepthTexture_TexelSize.xy * half2(-1, -1) * _SampleDistance;
                sampleUV[3] = screenUV + _CameraDepthTexture_TexelSize.xy * half2( 1, -1) * _SampleDistance;
                sampleUV[4] = screenUV + _CameraDepthTexture_TexelSize.xy * half2(-1,  1) * _SampleDistance;
                
                
                float d1      = SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture, my_point_clamp_sampler, sampleUV[1], 0).x;
                half4 normal1 = SAMPLE_TEXTURE2D_X_LOD(_GBuffer2, my_point_clamp_sampler, sampleUV[1], 0);

                float d2      = SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture, my_point_clamp_sampler, sampleUV[2], 0).x;
                half4 normal2 = SAMPLE_TEXTURE2D_X_LOD(_GBuffer2, my_point_clamp_sampler, sampleUV[2], 0);

                float d3      = SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture, my_point_clamp_sampler, sampleUV[3], 0).x;
                half4 normal3 = SAMPLE_TEXTURE2D_X_LOD(_GBuffer2, my_point_clamp_sampler, sampleUV[3], 0);

                float d4      = SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture, my_point_clamp_sampler, sampleUV[4], 0).x;
                half4 normal4 = SAMPLE_TEXTURE2D_X_LOD(_GBuffer2, my_point_clamp_sampler, sampleUV[4], 0);
                
                float4 sample0;
                sample0.xyz = normalize(UnpackNormal(normal0));
                sample0.w = Linear01Depth(d0, _ZBufferParams);
                
                float4 sample1;
                float4 sample2;
                float4 sample3;
                float4 sample4;
                sample1.xyz = normalize(UnpackNormal(normal1));
                sample1.w = Linear01Depth(d1, _ZBufferParams);
                sample2.xyz = normalize(UnpackNormal(normal2));
                sample2.w = Linear01Depth(d2, _ZBufferParams);
                sample3.xyz = normalize(UnpackNormal(normal3));
                sample3.w = Linear01Depth(d3, _ZBufferParams);
                sample4.xyz = normalize(UnpackNormal(normal4));
                sample4.w = Linear01Depth(d4, _ZBufferParams);

                half noEdge = 1.0;
                // edge *= CheckSame(sample1, sample2);
                // edge *= CheckSame(sample3, sample4);
                noEdge *= CheckSame(sample0, sample1);
                noEdge *= CheckSame(sample0, sample2);
                noEdge *= CheckSame(sample0, sample3);
                noEdge *= CheckSame(sample0, sample4);

                for (int i = 0; i < 5; i++)
                {
                    float characterMask = SAMPLE_TEXTURE2D(_CharacterMaskTexture, sampler_CharacterMaskTexture, sampleUV[i]).r;
                    if (characterMask > 0.5)
                    {
                        noEdge = 1.0;
                    }
                }
                half4 color = _EdgeColor;
                color.a = 1 - noEdge;
                color.rgb = color.rgb * color.a;
                return color;
            }
            ENDHLSL
        }
    }
}
