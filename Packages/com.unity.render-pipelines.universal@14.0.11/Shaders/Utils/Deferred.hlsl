#ifndef UNIVERSAL_DEFERRED_INCLUDED
#define UNIVERSAL_DEFERRED_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"

// This structure is used in StructuredBuffer.
// TODO move some of the properties to half storage (color, attenuation, spotDirection, flag to 16bits, occlusionProbeInfo)
struct PunctualLightData
{
    float3 posWS;
    float radius2;              // squared radius
    float4 color;
    float4 attenuation;         // .xy are used by DistanceAttenuation - .zw are used by AngleAttenuation (for SpotLights)
    float3 spotDirection;       // spotLights support
    int flags;                  // Light flags (enum kLightFlags and LightFlag in C# code)
    float4 occlusionProbeInfo;
    uint layerMask;             // Optional light layer mask
};

Light UnityLightFromPunctualLightDataAndWorldSpacePosition(PunctualLightData punctualLightData, float3 positionWS, half4 shadowMask, int shadowLightIndex, bool materialFlagReceiveShadowsOff)
{
    // Keep in sync with GetAdditionalPerObjectLight in Lighting.hlsl

    half4 probesOcclusion = shadowMask;

    Light light;

    float3 lightVector = punctualLightData.posWS - positionWS.xyz;
    float distanceSqr = max(dot(lightVector, lightVector), HALF_MIN);

    half3 lightDirection = half3(lightVector * rsqrt(distanceSqr));

    // full-float precision required on some platforms
    float attenuation = DistanceAttenuation(distanceSqr, punctualLightData.attenuation.xy) * AngleAttenuation(punctualLightData.spotDirection.xyz, lightDirection, punctualLightData.attenuation.zw);

    light.direction = lightDirection;
    light.color = punctualLightData.color.rgb;

    light.distanceAttenuation = attenuation;

    [branch] if (materialFlagReceiveShadowsOff)
        light.shadowAttenuation = 1.0;
    else
    {
        light.shadowAttenuation = AdditionalLightShadow(shadowLightIndex, positionWS, lightDirection, shadowMask, punctualLightData.occlusionProbeInfo);
    }

    light.layerMask = punctualLightData.layerMask;

    return light;
}

struct CelLight
{
    // float3 posWS;
    // float radius2;              // squared radius
    // float3 spotDirection;       // spotLights support
    float3 color;
    float3 direction;
    float lightOffset;
    float  distanceAttenuation; // full-float precision required on some platforms
    half   shadowAttenuation;
    uint layerMask;
};

CelLight CelLightFromPunctualLightDataAndWorldSpacePosition(PunctualLightData punctualLightData, float3 positionWS, half4 shadowMask, int shadowLightIndex, bool materialFlagReceiveShadowsOff)
{
    CelLight light;

    float3 lightVector = punctualLightData.posWS - positionWS.xyz;
    float distanceSqr = max(dot(lightVector, lightVector), HALF_MIN);

    half3 lightDirection = half3(lightVector * rsqrt(distanceSqr));

    // full-float precision required on some platforms
    float attenuation = DistanceAttenuation(distanceSqr, punctualLightData.attenuation.xy) * AngleAttenuation(punctualLightData.spotDirection.xyz, lightDirection, punctualLightData.attenuation.zw);

    light.direction = lightDirection;
    light.color = punctualLightData.color.rgb;

    light.distanceAttenuation = attenuation;

    [branch] if (materialFlagReceiveShadowsOff)
        light.shadowAttenuation = 1.0;
    else
    {
        light.shadowAttenuation = AdditionalLightShadow(shadowLightIndex, positionWS, lightDirection, shadowMask, punctualLightData.occlusionProbeInfo);
    }

    light.layerMask = punctualLightData.layerMask;

    // TODO: Get light ID and light offset from C#
    light.lightOffset = 0;

    return light;
}

half3 HimoToonFragmentRampDiffuse(half3 albedo, CelLight light, float3 normalWS, TEXTURE2D_PARAM(_CharacterRampTexture, sampler_CharacterRampTexture))
{
    half3 diffuseColor = 0;
    // TODO: Support point lights and spotlights, and now temporally calculate directional light only
    float lambert = dot(light.direction, normalWS);
    float halfLambert = 0.5 * lambert + 0.5;
    float lightingFactor = halfLambert + light.lightOffset;
    lightingFactor *= light.distanceAttenuation * light.shadowAttenuation;
        
    float2 rampUV;
    rampUV.x =  max(0.01, min(0.99, lightingFactor));
    // TODO: Support ramp texture IDs
    rampUV.y = 0.5;
    half4 rampColor = SAMPLE_TEXTURE2D(_CharacterRampTexture, sampler_CharacterRampTexture, rampUV);
    // TODO: Use ramp texture alpha channel to control the ramp color intensity
    rampColor.a = 1;
    diffuseColor.rgb = albedo * lerp(half3(1, 1, 1), rampColor.rgb, rampColor.a) * light.color;
        
    return diffuseColor;
}

half3 HimoToonFragmentDiffuse(half3 albedo, CelLight light, float3 normalWS)
{
    half3 diffuseColor = 0;
    float lambert = dot(light.direction, normalWS);
    float halfLambert = 0.5 * lambert + 0.5;
    float lightingFactor = saturate(halfLambert + light.lightOffset);
    lightingFactor *= light.distanceAttenuation * light.shadowAttenuation;
    diffuseColor.rgb = albedo * lightingFactor * light.color;
    return diffuseColor;
}

half3 HimoToonFragmentMatcapSpecular(half3 specularColor, float specularIntensity, float3 viewDirectionWS, TEXTURE2D_PARAM(_MatcapTexture, sampler_MatcapTexture))
{
    // TODO: 完善一下Specular的计算，考虑一下光照相关的specular
    half3 color = 0;
    float2 viewDirectionSS = normalize(TransformWorldToHClip(viewDirectionWS).xy * float2(1.0, _ScreenParams.y / _ScreenParams.x) * 0.5 - float2(0.5f, 0.5f));
    half3 matCapColor = SAMPLE_TEXTURE2D(_MatcapTexture, sampler_MatcapTexture, viewDirectionSS).rgb;
    color = matCapColor * specularColor * specularIntensity;
    return color;
}


half3 HimoToonFragmentRimLight(float3 lightDir, float2 screen_uv, half3 lightColor, half3 diffuseColor, float rimLightWidth, float originSampleDepth, TEXTURE2D_PARAM(_CameraDepthTexture, my_point_clamp_sampler))
{
    float originDepth = LinearEyeDepth(originSampleDepth, _ZBufferParams);
    float2 normalCS_XY = normalize(TransformWorldToHClip(lightDir).xy * float2(1.0, _ScreenParams.y / _ScreenParams.x)) * 0.5 - float2(0.5f, 0.5f);
#if UNITY_UV_STARTS_AT_TOP
    normalCS_XY.y = -normalCS_XY.y;
#endif
    float2 offsetPositionSS = screen_uv + float2(normalCS_XY.x, normalCS_XY.y) * rimLightWidth;
    // return half4(offsetPositionSS.x, offsetPositionSS.y, 0.0, 1.0);
    float offsetDepth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, my_point_clamp_sampler, offsetPositionSS).x;
    offsetDepth = LinearEyeDepth(offsetDepth, _ZBufferParams);
    float depthDiff = offsetDepth - originDepth;
    return saturate(depthDiff) * lightColor * diffuseColor;
}

#endif
