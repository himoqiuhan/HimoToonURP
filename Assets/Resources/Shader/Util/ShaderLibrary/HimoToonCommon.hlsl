#ifndef HIMOTOON_CH04_COMMON_INCLUDED
#define HIMOTOON_CH04_COMMON_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Macros.hlsl"

float2 RotateUV(float2 uv, float strength)
{
    float2 delta = uv - float2(0.5, 0.5);
    float angle = strength * PI;
    float2 rotatedDelta = float2(
        delta.x * cos(angle) - delta.y * sin(angle),
        delta.x * sin(angle) + delta.y * cos(angle)
    );
    return float2(0.5, 0.5) + rotatedDelta;
}

#define DOT_MATRIX_TRANSPARENT(screenUV, opacity) \
    float4x4 thresholdMatrix = \
    {  1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0, \
      13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0, \
       4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0, \
      16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0 \
    }; \
    float4x4 _RowAccess = { 1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1 }; \
    float2 pos = screenUV * _ScreenParams.xy; \
    clip(opacity - thresholdMatrix[fmod(pos.x, 4)] * _RowAccess[fmod(pos.y, 4)]); \

#define CALCULATE_ID_PROPERTY(matID, MatProperty) \
(MatProperty##0 * matID.x + MatProperty##1 * matID.y + MatProperty##2 * matID.z + MatProperty##3 * matID.w)

half4 GetMaterialIDMaskFromGrayValue(float idValue)
{
    //0
    //0.35
    //0.65
    //1
    half4 matID;
    matID.x = saturate(1.0 - step(0.3, idValue));
    matID.y = saturate(step(0.3, idValue) - step(0.6, idValue));
    matID.z = saturate(step(0.6, idValue) - step(0.9, idValue));
    matID.w = saturate(step(0.9, idValue));
    return matID;
}

half3 RGB2HSV(half3 rgb)
{
    half3 hsv;
    half maxC = max(max(rgb.r, rgb.g), rgb.b);
    half minC = min(min(rgb.r, rgb.g), rgb.b);
    half delta = maxC - minC;

    // Hue calculation
    if (delta == 0)
    {
        hsv.x = 0; // Undefined, but set to 0
    }
    else if (maxC == rgb.r)
    {
        hsv.x = fmod(((rgb.g - rgb.b) / delta), 6.0);
    }
    else if (maxC == rgb.g)
    {
        hsv.x = ((rgb.b - rgb.r) / delta) + 2.0;
    }
    else
    {
        hsv.x = ((rgb.r - rgb.g) / delta) + 4.0;
    }
    hsv.x /= 6.0; // Normalize to [0, 1]

    // Saturation calculation
    hsv.y = (maxC == 0) ? 0 : (delta / maxC);

    // Value calculation
    hsv.z = maxC;

    return hsv;
}

half3 HSV2RGB(half3 hsv)
{
    half3 rgb;
    half c = hsv.z * hsv.y; // Chroma
    half x = c * (1 - abs(fmod(hsv.x * 6, 2) - 1));
    half m = hsv.z - c;

    if (hsv.x < 1.0 / 6.0)
    {
        rgb = half3(c, x, 0);
    }
    else if (hsv.x < 2.0 / 6.0)
    {
        rgb = half3(x, c, 0);
    }
    else if (hsv.x < 3.0 / 6.0)
    {
        rgb = half3(0, c, x);
    }
    else if (hsv.x < 4.0 / 6.0)
    {
        rgb = half3(0, x, c);
    }
    else if (hsv.x < 5.0 / 6.0)
    {
        rgb = half3(x, 0, c);
    }
    else
    {
        rgb = half3(c, 0, x);
    }

    rgb.r += m;
    rgb.g += m;
    rgb.b += m;

    return rgb;
}

#endif
