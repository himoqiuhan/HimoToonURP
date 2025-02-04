#ifndef HIMOTOON_HLSL_CHARACTER_GBUFFER_INCLUDED
#define HIMOTOON_HLSL_CHARACTER_GBUFFER_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"

struct CharacterGBufferOutput
{
    half4 GBuffer0 : SV_Target0; // albedo          albedo          albedo          materialFlags   (sRGB rendertarget)
    half4 GBuffer1 : SV_Target1; // specular        specular        specular        occlusion
    half4 GBuffer2 : SV_Target2; // encoded-normal  encoded-normal  encoded-normal  smoothness
    half4 GBuffer3 : SV_Target3; // GI              GI              GI              unused          (lighting buffer)

    #ifdef GBUFFER_OPTIONAL_SLOT_1
    GBUFFER_OPTIONAL_SLOT_1_TYPE GBuffer4 : SV_Target4;
    #endif
    #ifdef GBUFFER_OPTIONAL_SLOT_2
    half4 GBuffer5 : SV_Target5;
    #endif
    #ifdef GBUFFER_OPTIONAL_SLOT_3
    half4 GBuffer6 : SV_Target6;
    #endif
};

CharacterGBufferOutput CalculateCharacterGBuffer(InputData inputData, CharacterSurfaceData surfaceData)
{
    CharacterGBufferOutput output = (CharacterGBufferOutput)0;

    output.GBuffer0.rgb = surfaceData.color.rgb * surfaceData.opacity;
    output.GBuffer0.a = surfaceData.opacity * (1 - surfaceData.blendModeAdd);
    
    output.GBuffer1 = 0;

    half3 packedNormalWS = PackNormal(inputData.normalWS);
    output.GBuffer2 = half4(packedNormalWS, 0);

    output.GBuffer3 = 0;
    
    return output;
}

#endif
