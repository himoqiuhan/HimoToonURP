#ifndef HIMOTOON_HLSL_CHARACTER_DEFERRED_INCLUDED
#define HIMOTOON_HLSL_CHARACTER_DEFERRED_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

struct Attributes
{
    float4 positionOS : POSITION;
    uint vertexID : SV_VertexID;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float3 screenUV : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

Varyings CharacterDeferredVertex(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    float3 positionOS = input.positionOS.xyz;
    
    output.positionCS = float4(positionOS.xy, UNITY_RAW_FAR_CLIP_VALUE, 1.0); // Force triangle to be on zfar

    output.screenUV = output.positionCS.xyw;
#if UNITY_UV_STARTS_AT_TOP
    output.screenUV.xy = output.screenUV.xy * float2(0.5, -0.5) + 0.5 * output.screenUV.z;
#else
    output.screenUV.xy = output.screenUV.xy * 0.5 + 0.5 * output.screenUV.z;
#endif

    return output;
}

TEXTURE2D_X(_CameraDepthTexture);
TEXTURE2D_X_HALF(_GBuffer0);
TEXTURE2D_X_HALF(_GBuffer1);
TEXTURE2D_X_HALF(_GBuffer2);

float4x4 _ScreenToWorld[2];
SamplerState my_point_clamp_sampler;

float3 _LightPosWS;
half3 _LightColor;
half4 _LightAttenuation; // .xy are used by DistanceAttenuation - .zw are used by AngleAttenuation *for SpotLights)
half3 _LightDirection;   // directional/spotLights support
half4 _LightOcclusionProbInfo;
int _LightFlags;
int _ShadowLightIndex;
uint _LightLayerMask;
int _CookieLightIndex;

#ifdef _GBUFFER_NORMALS_OCT
half3 PackNormal(half3 n)
{
    float2 octNormalWS = PackNormalOctQuadEncode(n);                  // values between [-1, +1], must use fp32 on some platforms.
    float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);   // values between [ 0, +1]
    return half3(PackFloat2To888(remappedOctNormalWS));               // values between [ 0, +1]
}

half3 UnpackNormal(half3 pn)
{
    half2 remappedOctNormalWS = half2(Unpack888ToFloat2(pn));          // values between [ 0, +1]
    half2 octNormalWS = remappedOctNormalWS.xy * half(2.0) - half(1.0);// values between [-1, +1]
    return half3(UnpackNormalOctQuadEncode(octNormalWS));              // values between [-1, +1]
}

#else
half3 PackNormal(half3 n)
{ return n; }                                                         // values between [-1, +1]

half3 UnpackNormal(half3 pn)
{ return pn; }                                                        // values between [-1, +1]
#endif

// 处理边缘光
half4 CharacterDeferredShading(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    // return half4(1,0,0,1);

    float2 screen_uv = (input.screenUV.xy / input.screenUV.z);
    
    float d        = SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture, my_point_clamp_sampler, screen_uv, 0).x; // raw depth value has UNITY_REVERSED_Z applied on most platforms.
    half4 gbuffer0 = SAMPLE_TEXTURE2D_X_LOD(_GBuffer0, my_point_clamp_sampler, screen_uv, 0);
    half4 gbuffer2 = SAMPLE_TEXTURE2D_X_LOD(_GBuffer2, my_point_clamp_sampler, screen_uv, 0);

    float3 normalWS = normalize(UnpackNormal(gbuffer2.xyz));
    float2 normalVS = TransformWorldToViewNormal(normalWS, true).xy;

    half3 color = (half3)0;
    half alpha = 1.0;
    
    float linearSampleDepth = LinearEyeDepth(d, _ZBufferParams);
    float2 rimOffsetUV = screen_uv + 0.1 * (0.5 * normalVS + 0.5);
    float rimDepth = SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture, my_point_clamp_sampler, rimOffsetUV, 0).x;
    float linearRimDepth = LinearEyeDepth(rimDepth, _ZBufferParams);

    float rimMask = saturate(linearRimDepth - linearSampleDepth);

    color = gbuffer0.rgb * (rimMask + 2);
    return half4(rimMask, rimMask, rimMask, 1);
    return half4(screen_uv.x, screen_uv.y, 0.0, 1.0);
    return half4(linearRimDepth, rimMask, rimMask, alpha);
}

#endif
