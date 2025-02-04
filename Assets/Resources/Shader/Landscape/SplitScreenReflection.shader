Shader "CH04/HimoToon/SplitScreenReflection"
{
    Properties
    {
        _SSRParams("SSR Params", Vector) = (0.1, 0.02, 25, 32)
        _NumSamples("Num Samples", Int) = 1
        
//        [Toggle(_IMPORTANCE_SAMPLE_GGX)]_ImportanceSampleGGX("Importance Sample GGX", Float) = 0
//        [Toggle(_DEBUG_SSR)]_DebugSSR("Debug SSR", Float) = 0
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
            "Queue"="Geometry"
            "UniversalMaterialType" = "Lit" 
            "IgnoreProjector" = "True" 
            "ShaderModel"="4.5"
        }
        LOD 100
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        TEXTURE2D(_LastFrameColorTexture);          SAMPLER(sampler_LastFrameColorTexture);
        TEXTURE2D(_LastFrameDepthTexture);          
        SamplerState my_point_clamp_sampler;

        float SampleLastFrameDepth(float2 uv)
        {
            return SAMPLE_TEXTURE2D_X(_LastFrameDepthTexture, my_point_clamp_sampler, uv).r;
        }

        half3 SampleLastFrameColor(float2 uv)
        {
            return SAMPLE_TEXTURE2D_X(_LastFrameColorTexture, sampler_LastFrameColorTexture, uv);
        }
        
        ENDHLSL

        Pass
        {
            Name "Screen Space Reflection"
            Tags
            {
                "LightMode"="HimoToonSSR"
            }

            Blend One Zero
            ZTest LEqual
            ZWrite On
            Cull Back
            
            HLSLPROGRAM
            #pragma target 3.0

            // #pragma multi_compile _ _PLANAR_REFLECTION
            #pragma multi_compile _ _IMPORTANCE_SAMPLE_GGX
            #pragma shader_feature_local _DEBUG_SSR
            
            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
            

            CBUFFER_START(UnityPerMaterial)
            float4 _SSRParams;
            uint _NumSamples;
            CBUFFER_END

            #define _Thickness _SSRParams.x
            #define _PotentialThickness _SSRParams.y
            #define _ReflectDistance _SSRParams.z
            #define _MaxStepCount _SSRParams.w

            // TEXTURE2D(_PlanarReflectionTexture);        SAMPLER(sampler_PlanarReflectionTexture);
            
            // TEXTURE2D_X_HALF(_GBuffer0);
            TEXTURE2D_X_HALF(_GBuffer1);
            TEXTURE2D_X_HALF(_GBuffer2);

            struct Attributes
            {
                float4 positionOS : POSITION;
                uint vertexID : SV_VertexID;
                float3 normalOS : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 screenUV : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 positionWS : TEXCOORD3;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float Pow2( float x )
            {
	            return x*x;
            }

            // Appoximation of joint Smith term for GGX
            // [Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"]
            float Vis_SmithJointApprox( float a2, float NoV, float NoL )
            {
	            float a = sqrt(a2);
	            float Vis_SmithV = NoL * ( NoV * ( 1 - a ) + a );
	            float Vis_SmithL = NoV * ( NoL * ( 1 - a ) + a );
	            return 0.5 * rcp( Vis_SmithV + Vis_SmithL );
            }
            
            // [ Duff et al. 2017, "Building an Orthonormal Basis, Revisited" ]
            // Discontinuity at TangentZ.z == 0
            float3x3 GetTangentBasis( float3 TangentZ )
            {
	            const float Sign = TangentZ.z >= 0 ? 1 : -1;
	            const float a = -rcp( Sign + TangentZ.z );
	            const float b = TangentZ.x * TangentZ.y * a;
	            
	            float3 TangentX = { 1 + Sign * a * Pow2( TangentZ.x ), Sign * b, -Sign * TangentZ.x };
	            float3 TangentY = { b,  Sign + a * Pow2( TangentZ.y ), -TangentZ.y };

	            return float3x3( TangentX, TangentY, TangentZ );
            }
            
            float3 TangentToWorld( float3 Vec, float3 TangentZ )
            {
	            return mul( Vec, GetTangentBasis( TangentZ ) );
            }

            float2 Hammersley( uint Index, uint NumSamples, uint2 Random )
            {
	            float E1 = frac( (float)Index / NumSamples + float( Random.x & 0xffff ) / (1<<16) );
	            float E2 = float( reversebits(Index) ^ Random.y ) * 2.3283064365386963e-10;
	            return float2( E1, E2 );
            }

            // PDF = D * NoH / (4 * VoH)
            float4 ImportanceSampleGGX( float2 E, float a2 )
            {
	            float Phi = 2 * PI * E.x;
	            float CosTheta = sqrt( (1 - E.y) / ( 1 + (a2 - 1) * E.y ) );
	            float SinTheta = sqrt( 1 - CosTheta * CosTheta );

	            float3 H;
	            H.x = SinTheta * cos( Phi );
	            H.y = SinTheta * sin( Phi );
	            H.z = CosTheta;
	            
	            float d = ( CosTheta * a2 - CosTheta ) * CosTheta + 1;
	            float D = a2 / ( PI*d*d );
	            float PDF = D * CosTheta;

	            return float4( H, PDF );
            } 

            void SSRReflection(inout half4 color, float3 reflectVector, float3 positionWS, float3 normalWS,
                    float thickness, float potentialMinThickness, float reflectDistance = 50, int maxStepCount = 64)
            {
                color = saturate(color);
                float fade = 1;
                half3 ssrColor = 0;

                float3 originWS = positionWS;
                float3 endWS = originWS + reflectVector * reflectDistance
                    * (1 - smoothstep(0.25, 1.0, dot(normalWS, reflectVector)));// Scale reflect distance by angle
                // float4 prevOriginCS = TransformWorldToHClip(originWS);
                // half4 prevEndCS = TransformWorldToHClip(endWS);
                float4 prevOriginCS = mul(_PrevViewProjMatrix, float4(originWS,1));
                half4 prevEndCS =  mul(_PrevViewProjMatrix, float4(endWS,1));
                // k0,k1: Origin,End's 1/positionCS.w
                // q0,q1: Origin,End's positionCS.xyz
                // p0,p1: Origin,End's positionNDC.xy
                // w: Increasing param in (0,1) by 1/_StepCount
                half k0 = 1 / prevOriginCS.w;
                half k1 = 1 / prevEndCS.w;
                half3 q0 = prevOriginCS.xyz;
                half3 q1 = prevEndCS.xyz;
                // Screen UV
                 half2 p0 = prevOriginCS.xy * half2(1.0f, _ProjectionParams.x) * k0 * 0.5f + 0.5f;
                 half2 p1 = prevEndCS.xy * half2(1.0f, _ProjectionParams.x) * k1 * 0.5f + 0.5f;
                
                //Ray Marching
                half w1 = 0.0f;// marching n weight
                half w2 = 0.0f;// marching n-1 weight
                bool hit = false;
                bool lastHit = false;
                bool potentialHit = false;
                half2 potentialW12 = half2(0,0);
                half2 binaryFade12 = half2(1,1);
                half minPotentialHitPos = 1e5;
                half invStepCount = 1 / half(maxStepCount);

                half4 traceFactor0 = half4(p0.x, p0.y, q0.z, k0);
                half4 traceFactor1 = half4(p1.x, p1.y, q1.z, k1);
                half4 traceFactor = traceFactor0;
                
                UNITY_LOOP
                for (int i = 1;
                    i <= maxStepCount &&
                        traceFactor.y > 0.001 && traceFactor.y < 0.999 && traceFactor.x > 0.001 && traceFactor.y < 0.999; // UV clamp because I don't implement VS frustum clipping
                    i++)
                {
                    w2 = w1;
                    w1 += invStepCount;

                    fade -= invStepCount;

                    traceFactor = lerp(traceFactor0, traceFactor1, w1);
                    
                    float sampleDepth = SampleLastFrameDepth(traceFactor.xy);
                    half linearSampleDepth = LinearEyeDepth(sampleDepth, _ZBufferParams);
                    half linearRayDepth = LinearEyeDepth(traceFactor.z * traceFactor.w, _ZBufferParams);
                    half hitDiff = linearRayDepth - linearSampleDepth;
                    half thicknessDiff = (hitDiff - potentialMinThickness) / linearSampleDepth;
                    half scaledThickness = thickness * lerp(3, 1,
                         1 - smoothstep(0.5, 0.75, (dot(normalWS, reflectVector))) // Angle Factor
                         - saturate(0.75 - sampleDepth) // Distance Factor
                        );
                    
                    if(hitDiff > 0)
                    {
                        if (hitDiff < scaledThickness)
                        {
                            hit = true;
                            binaryFade12 = half2(fade, fade + invStepCount);
                            break;
                        }
                        
                        if (!lastHit)
                        {                
                            potentialHit = true;
                            if (minPotentialHitPos > thicknessDiff)
                            {
                                minPotentialHitPos = thicknessDiff;
                                potentialW12 = half2(w1, w2);
                                binaryFade12 = half2(fade, fade + invStepCount);
                            }
                        }
                        lastHit = hitDiff > 0.0;
                    }
                }

                if (hit || potentialHit)
                    {
                        half fade1 = binaryFade12.x;
                        half fade2 = binaryFade12.y;
                        // If pass thickness testing, then binary search
                        // If not pass thickness testing, then test potential Hit
                        if (!hit)
                        {
                            w1 = potentialW12.x;
                            w2 = potentialW12.y;
            #if defined(_DEBUG_SSR)
                            color.rgb = half3(1,0,0);
            #endif
                        }
                    
                        bool realHit = false;
                        half2 hitPosSS;
                        half minThickness = potentialMinThickness;
                        half w = 0.5 * (w1 + w2);
                        UNITY_UNROLL
                        for (int i = 0; i < 5; ++i)
                        {
                            fade = 0.5 * (fade1 + fade2);
                            w = 0.5 * (w1 + w2);
                            
                            traceFactor = lerp(traceFactor0, traceFactor1, w);
                            float sampleDepth = SampleLastFrameDepth(traceFactor.xy);
                            float linearSampleDepth = LinearEyeDepth(sampleDepth, _ZBufferParams);
                            float linearRayDepth = LinearEyeDepth(traceFactor.z * traceFactor.w, _ZBufferParams);
                            float hitDiff = linearRayDepth - linearSampleDepth;

                            // Binary search
                            if (hitDiff > 0.0)
                            {
                                w1 = w;
                                fade1 = fade;
                                if (hit)
                                {
                                    hitPosSS = traceFactor.xy;
                                }
                            }
                            else
                            {
                                w2 = w;
                                fade2 = fade;
                            }

                            // Test potential hit if real hit or not
                            if (!hit && hitDiff > 0 && hitDiff < minThickness)
                            {
                                realHit = true;
                                minThickness = hitDiff;
                                hitPosSS = traceFactor.xy;
                            }
                        }

                        if (hit || realHit)
                        {
                            ssrColor = SampleLastFrameColor(hitPosSS);

                            // UV fade out
                            fade *= (1 - smoothstep(0.45, 0.5, abs(hitPosSS.x - 0.5))) *
                                        (1 - smoothstep(0.45, 0.5, abs(hitPosSS.y - 0.5)));
                            // Angle fade out
                            fade *= smoothstep(0.2, 0.5, 1 - saturate(dot(normalWS, reflectVector)));

                            color.rgb = lerp(color.rgb, ssrColor, saturate(fade));
                            color.a = fade;
                            
            #if defined(_DEBUG_SSR)
                            if (hit)
                            {
                                color.rgb = half3(0,1,0);
                            }
                            else if (realHit)
                            {
                                color.rgb = half3(1,1,0);
                            }
            #endif
                        }
                    }
            }

            Varyings VertexProgram(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                float3 positionOS = input.positionOS.xyz;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(positionOS);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);
                
                output.positionCS = positionInputs.positionCS;

                output.screenUV = output.positionCS.xyw;
                #if UNITY_UV_STARTS_AT_TOP
                output.screenUV.xy = output.screenUV.xy * float2(0.5, -0.5) + 0.5 * output.screenUV.z;
                #else
                output.screenUV.xy = output.screenUV.xy * 0.5 + 0.5 * output.screenUV.z;
                #endif

                output.positionWS = positionInputs.positionWS;
                output.normalWS = normalInputs.normalWS;
                
                return output;
            }

            half4 FragmentProgram(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float2 screen_uv = (input.screenUV.xy / input.screenUV.z);
                half4 reflectionColor = 0;
                
                clip(SampleLastFrameDepth(screen_uv) - input.positionCS.z / input.positionCS.w);
                
                float d        = SampleLastFrameDepth(screen_uv); // raw depth value has UNITY_REVERSED_Z applied on most platforms.
                half3 gbuffer0 = SampleLastFrameColor(screen_uv);
                half4 gbuffer1 = SAMPLE_TEXTURE2D_X_LOD(_GBuffer1, my_point_clamp_sampler, screen_uv, 0);
                half4 gbuffer2 = SAMPLE_TEXTURE2D_X_LOD(_GBuffer2, my_point_clamp_sampler, screen_uv, 0);
                
                // InputData inputData = InputDataFromGbufferAndWorldPosition(gbuffer2, posWS.xyz);
                InputData inputData = (InputData)0;
                inputData.positionWS = input.positionWS;
                inputData.viewDirectionWS = normalize(GetWorldSpaceViewDir(inputData.positionWS));
                inputData.normalWS = normalize(UnpackNormal(gbuffer2.xyz));
                
                float3 reflectionDir = (float3)0;
            #if defined(_IMPORTANCE_SAMPLE_GGX)

                float smoothness = gbuffer2.a;
                float roughness = PerceptualSmoothnessToRoughness(smoothness);
                float metallic = gbuffer1.r;
                half3 specularColor = lerp(kDieletricSpec.rgb, gbuffer0.rgb, metallic);
                
                float3 N = inputData.normalWS;
                float3 V = normalize(inputData.viewDirectionWS);
                
                UNITY_LOOP
                for( uint i = 0; i < _NumSamples; i++ )
                {
                    float2 E = Hammersley( i, _NumSamples, 0 );

                    E.y *= 0.995;
                
                    float3 H = TangentToWorld(ImportanceSampleGGX( E, Pow4(roughness) ).xyz, inputData.normalWS);
                    float3 L = 2 * dot( V, H ) * H - V;

                    float NoV = saturate( dot( N, V ) );
		            float NoL = saturate( dot( N, L ) );
		            float NoH = saturate( dot( N, H ) );
		            float VoH = saturate( dot( V, H ) );

                    if( NoL > 0 )
                    {
                        reflectionDir = L;

                        half4 sampleColor = 0;
                        SSRReflection(sampleColor, reflectionDir,
                        inputData.positionWS.xyz, inputData.normalWS,
                        _Thickness, _PotentialThickness, _ReflectDistance, _MaxStepCount);

                        float Vis = Vis_SmithJointApprox( Pow4(roughness), NoV, NoL );
			            float Fc = pow( 1 - VoH, 5 );
			            float3 F = (1 - Fc) * specularColor + Fc;

                        reflectionColor.rgb = sampleColor.rgb * F * ( NoL * Vis * (4 * VoH / NoH) );
                    }
                }
			    
            #else
                reflectionDir = reflect(-normalize(inputData.viewDirectionWS), inputData.normalWS);
                
                SSRReflection(reflectionColor, reflectionDir,
                    inputData.positionWS.xyz, inputData.normalWS,
                    _Thickness, _PotentialThickness, _ReflectDistance, _MaxStepCount);
            #endif
                
                return reflectionColor;
            }
            ENDHLSL
        }
    }
}
