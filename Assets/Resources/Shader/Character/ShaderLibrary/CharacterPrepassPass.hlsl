//Prepass use to render a RT before opaque, used for:
//R - Hair shadow on the face
//G - Full body mask
//B - Shrinking full body among inverse normal direction
#ifndef HIMOTOON_HLSL_CHARACTER_PREPASS_INCLUDED
#define HIMOTOON_HLSL_CHARACTER_PREPASS_INCLUDED

#include "../Character/ShaderLibrary/CharacterInput.hlsl"

struct Attributes
{
    float4 positionOS : POSITION;
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
};

struct AttributesShrinking
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    half4 vertexColor : COLOR;
};

Varyings Vertex(Attributes input)
{
    Varyings output;
    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    return output;
}

half4 Fragment() : SV_Target
{
    return 1.0;
}

#endif
