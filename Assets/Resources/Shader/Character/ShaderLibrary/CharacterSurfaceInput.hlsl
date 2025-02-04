#ifndef HIMOTOON_CHARACTER_SURFACE_INPUT_INCLUDED
#define HIMOTOON_CHARACTER_SURFACE_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "../Character/ShaderLibrary/CharacterInput.hlsl"

TEXTURE2D(_MainTex);                 SAMPLER(sampler_MainTex);
TEXTURE2D(_ParamTex);                SAMPLER(sampler_ParamTex);// shadowMask     id     highlightMask     LightAreaOffset (Linear)
TEXTURE2D(_CharacterPrePassTex);     SAMPLER(sampler_CharacterPrePassTex);
TEXTURE2D(_EmissionTex);             SAMPLER(sampler_EmissionTex);

struct CharacterSurfaceData
{
    half3 color;
    half opacity;
    float2 uv;
    float2 screenUV;
    float shadowMask;
    float id;
    float highlightMask;
    float blendModeAdd;
};

void InitializeCharacterSurfaceData(float2 uv, float2 screenUV, out CharacterSurfaceData output)
{
    output = (CharacterSurfaceData)0;
    output.color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv).rgb;
    output.opacity = _Opacity;
    output.uv = uv;
    output.screenUV = screenUV;
    float4 paramTexValue = SAMPLE_TEXTURE2D(_ParamTex, sampler_ParamTex, uv);
    output.shadowMask = paramTexValue.r;
    output.id = paramTexValue.g;
    output.highlightMask = paramTexValue.b;
    output.blendModeAdd = _AlphaAdd;
}

#endif
