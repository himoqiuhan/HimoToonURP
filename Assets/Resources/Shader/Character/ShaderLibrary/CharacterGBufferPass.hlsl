#ifndef HIMOTOON_HLSL_CHARACTER_GBUFFER_PASS_INCLUDED
#define HIMOTOON_HLSL_CHARACTER_GBUFFER_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
#include "../Util/ShaderLibrary/HimoToonCommon.hlsl"
#include "../Character/ShaderLibrary/CharacterSurfaceInput.hlsl"
#include "../Character/ShaderLibrary/CharacterGBuffer.hlsl"

struct Attributes
{
    float4 positionOS           : POSITION;
    float3 normalOS             : NORMAL;
    float4 tangentOS            : TANGENT;
    half4 vertexColor           : COLOR;
    float2 texcoord             : TEXCOORD0;
    float2 staticLightmapUV     : TEXCOORD1;
    float2 dynamicLightmapUV    : TEXCOORD2;
};

struct Varyings
{
    float4 positionCS       : SV_POSITION;
    float2 uv               : TEXCOORD0;
    float3 positionWS       : TEXCOORD1;
    float4 positionNDC      : TEXCOORD2;
    float3 normalWS         : TEXCOORD3;
    half  fogFactor         : TEXCOORD4;
    half4 vertexColor       : COLOR;
    DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 8);
#ifdef DYNAMICLIGHTMAP_ON
    float2  dynamicLightmapUV : TEXCOORD5; // Dynamic lightmap UVs
#endif
    float4 screenPos        : TEXCOORD6;
};

void InitializeInputData(Varyings input, out InputData inputData)
{
    inputData = (InputData)0;
    inputData.positionWS = input.positionWS;
    // TODO: Support character's normal map
    inputData.normalWS = NormalizeNormalPerPixel(input.normalWS);
    inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
    
    // TODO: Custom high-res character shadow(pre pass hair shadow, custom self shadow, and scene cast shadow)
#if defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
#else
    inputData.shadowCoord = float4(0, 0, 0, 0);
#endif

    inputData.fogCoord = InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactor);

    // TODO: Character influenced by lightmap/other GI
#if defined(DYNAMICLIGHTMAP_ON)
    inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV, input.vertexSH, inputData.normalWS);
#else
    inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, inputData.normalWS);
#endif

    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
    inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);

    // Unity Debug
#if defined(DEBUG_DISPLAY)
#if defined(DYNAMICLIGHTMAP_ON)
    inputData.dynamicLightmapUV = input.dynamicLightmapUV;
#endif
#if defined(LIGHTMAP_ON)
    inputData.staticLightmapUV = input.staticLightmapUV;
#else
    inputData.vertexSH = input.vertexSH;
#endif
#endif
    
}

Varyings HimoToonCharacterGBufferVertex(Attributes input)
{
    Varyings output = (Varyings)0;
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS);
    output.positionCS = vertexInput.positionCS;
    output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
    output.positionWS = vertexInput.positionWS;
    output.positionNDC = vertexInput.positionNDC;
    output.normalWS = vertexNormalInput.normalWS;
    output.fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
    output.vertexColor = input.vertexColor;
    output.screenPos = vertexInput.positionNDC;

    OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
#ifdef DYNAMICLIGHTMAP_ON
    output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
#endif
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
    
    return output;
}

CharacterGBufferOutput HimoToonCharacterGBufferFragment(Varyings input) : SV_Target
{
    float2 screenUV = input.screenPos.xy / input.screenPos.w;
    
    InputData inputData;
    InitializeInputData(input, inputData);

    CharacterSurfaceData surfaceData;
    InitializeCharacterSurfaceData(input.uv, screenUV, surfaceData);

    // 点阵半透
    DOT_MATRIX_TRANSPARENT(inputData.normalizedScreenSpaceUV, surfaceData.opacity)

    CharacterGBufferOutput output;
    ZERO_INITIALIZE(CharacterGBufferOutput, output);
    output = CalculateCharacterGBuffer(inputData, surfaceData);
    
    return output;
}

#endif
