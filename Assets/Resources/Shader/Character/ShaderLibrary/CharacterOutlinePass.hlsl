//Back Face outline base on ViewSpace, with smooth normal and Z-Offset to get correct outline expression
// - vertexColor.rg: smooth normal
// - vertexColor.a: Outline width scale, 0 for no back face offset
#ifndef HIMOTOON_HLSL_CHARACTER_OUTLINE_PASS_INCLUDED
#define HIMOTOON_HLSL_CHARACTER_OUTLINE_PASS_INCLUDED

#include "../Character/ShaderLibrary/CharacterSurfaceInput.hlsl"
#include "../Util/ShaderLibrary/HimoToonCommon.hlsl"
#include "../Character/ShaderLibrary/CharacterGBuffer.hlsl"

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float4 vertexColor : COLOR;
    float2 uv : TEXCOORD0;
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 normalWS : TEXCOORD1;
};

Varyings BackFaceOutlineVertex(Attributes input)
{
    Varyings output;
    VertexPositionInputs vertexPositionInputs = GetVertexPositionInputs(input.positionOS.xyz);
    
    input.vertexColor.r = input.vertexColor.r * 2.0 - 1.0;
    input.vertexColor.g = input.vertexColor.g * 2.0 - 1.0;
    float3 smoothNormalTS = normalize(
        float3(input.vertexColor.r, input.vertexColor.g,
            sqrt(1 - dot(float2(input.vertexColor.r, input.vertexColor.g), float2(input.vertexColor.r, input.vertexColor.g)))
                    ));
    float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
    float3 tangentWS = float3(TransformObjectToWorldDir(input.tangentOS.xyz));
    float3x3 tangentToWorld = CreateTangentToWorld(normalWS, tangentWS, input.tangentOS.w);
    float3 smoothNormalWS = TransformTangentToWorld(smoothNormalTS, tangentToWorld);
    float3 smoothNormalCS =TransformWorldToHClipDir(smoothNormalWS, true);
    float outlineWidth = _OutlineWidthScale * input.vertexColor.a * 0.01;

    output.positionCS = vertexPositionInputs.positionCS;
    output.positionCS.xyz += smoothNormalCS.xyz * outlineWidth;
    output.positionCS.z -= 1e-6;//To Avoid Z Fight between outline and model
    
    output.uv = input.uv;
    output.normalWS = smoothNormalWS;
    return output;
}

CharacterGBufferOutput BackFaceOutlineFragment(Varyings input) : SV_Target
{
    CharacterGBufferOutput output = (CharacterGBufferOutput)0;
    half idValue = SAMPLE_TEXTURE2D(_ParamTex, sampler_ParamTex, input.uv).g;
    half4 matID = GetMaterialIDMaskFromGrayValue(idValue);
    output.GBuffer0 = CALCULATE_ID_PROPERTY(matID, _OutlineColor);
    output.GBuffer0.rgb *= output.GBuffer0.a; //Premultiplied alpha
    output.GBuffer0.a = output.GBuffer0.a * (1 - _OutlineAlphaAdd);
    output.GBuffer1 = 0;
    half3 packedNormalWS = PackNormal(input.normalWS);
    output.GBuffer2 = half4(packedNormalWS, 0);
    output.GBuffer3 = 0;
    return output;
}

#endif
