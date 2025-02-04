#ifndef HIMOTOON_HLSL_CHARACTER_INPUT_INCLUDED
#define HIMOTOON_HLSL_CHARACTER_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

CBUFFER_START(UnityPerMaterial)

float4 _MainTex_ST;
half4 _OutlineColor0;
half4 _OutlineColor1;
half4 _OutlineColor2;
half4 _OutlineColor3;
half _OutlineWidthScale;
half _Opacity;
half _EmissionIntensity;
half _AlphaAdd;
half _OutlineAlphaAdd;

CBUFFER_END



#endif
