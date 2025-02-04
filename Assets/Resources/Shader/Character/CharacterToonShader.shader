Shader "HimoToon/Character/CharacterToon"
{
    Properties
    {        
        [Header(Basic Textures)]
        _MainTex ("Texture", 2D) = "white" {}
        _ParamTex("Param Texture", 2D) = "white" {}
        
        [Space(20)]
        [Header(Diffuse)]
        _Opacity("Opacity", Range(0.0, 1.0)) = 1.0
        [Toggle]_AlphaAdd("Alpha混合模式为Add(不勾为半透混合)", Float) = 0
        
        [Space(20)]
        [Header(Outline)]
        _OutlineWidthScale("描边宽度", Range(0.0, 2.0)) = 1.0
        _OutlineColor0("描边颜色ID0", Color) = (0.0, 0.0, 0.0, 1.0)
        _OutlineColor1("描边颜色ID1", Color) = (0.0, 0.0, 0.0, 1.0)
        _OutlineColor2("描边颜色ID2", Color) = (0.0, 0.0, 0.0, 1.0)
        _OutlineColor3("描边颜色ID3", Color) = (0.0, 0.0, 0.0, 1.0)
        [Toggle]_OutlineAlphaAdd("描边Alpha混合模式为Add(不勾为半透混合)", Float) = 0
        
        [Space(20)]
        [Header(Emission)]
        _EmissionTex("自发光颜色", 2D) = "black" {}
        _EmissionIntensity("自发光强度", Range(0.0, 10.0)) = 0.0
        
        [Space(20)]
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("Z Test Mode", Float) = 4.0
        [Enum(Off, 0, On, 1)] _ZWrite("Z Write Mode", Float) = 1.0
        [Enum(UnityEngine.Rendering.CullMode)]_Cull("Cull Mode", Float) = 2.0
        
        [Space(20)]
        [Header(Blend State)]
        [Enum(UnityEngine.Rendering.BlendOp)]_Blend("BlendOp", Float) = 0.0
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("Src Blend Mode", Float) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)]_DstBlend("Dst Blend Mode", Float) = 0.0
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "UniversalMaterialType" = "CharacterLit"
        }
        LOD 100

        Pass
        {
            Name "Character GBuffer"
            Tags
            {
                "LightMode"="UniversalGBuffer"
            }
            
            // -------------------------------------
            // Render State Commands
            ZTest [_ZTest]
            ZWrite[_ZWrite]
            Cull [_Cull]
            
            // Use premultiplied alpha
            BlendOp Add
            Blend One OneMinusSrcAlpha 
            
            HLSLPROGRAM
            #pragma target 4.5

            // Deferred Rendering Path does not support the OpenGL-based graphics API:
            // Desktop OpenGL, OpenGL ES 3.0, WebGL 2.0.
            #pragma exclude_renderers gles3 glcore
            
            #pragma vertex HimoToonCharacterGBufferVertex
            #pragma fragment HimoToonCharacterGBufferFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
           
            //------------------Unity System Keywords------------------
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
            #pragma multi_compile_fog

            // -------------------------------------
            // Unity debug keywords
            #pragma multi_compile_fragment _ DEBUG_DISPLAY

            //--------------------------------------
            // GPU Instancing
            // 角色暂时不考虑Instancing
            
            #include "../Character/ShaderLibrary/CharacterGBufferPass.hlsl"
            
            ENDHLSL
        }

        Pass
        {
            Name"ShadowCaster"
            Tags
            {
                "LightMode"="ShadowCaster"
            }
            
            ZTest LEqual
            ZWrite On
            ColorMask 0
            Cull Back
            
            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment  ShadowPassFragment
            
            //------------------Unity System Keywords------------------
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #include "../Character/ShaderLibrary/CharacterInput.hlsl"
            #include "../Character/ShaderLibrary/CharacterShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "Character Outline"
            Tags
            {
                "LightMode"="BackFaceOutline"
            }

            ZTest LEqual
            ZWrite [_ZWrite]
            Cull Front
            
            // Use premultiplied alpha
            BlendOp Add
            Blend One OneMinusSrcAlpha 

            HLSLPROGRAM
            #pragma vertex BackFaceOutlineVertex
            #pragma fragment BackFaceOutlineFragment
            #include "../Character/ShaderLibrary/CharacterInput.hlsl"
            #include "../Character/ShaderLibrary/CharacterOutlinePass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "FaceAndBody"
            Tags
            {
                "LightMode"="CharacterPrePassFaceBody"
            }

            ColorMask G
            ZTest LEqual
            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            #include "../Character/ShaderLibrary/CharacterInput.hlsl"
            #include "../Character/ShaderLibrary/CharacterPrepassPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "HairMask"
            Tags
            {
                "LightMode"="CharacterPrePassHair"
            }

            ColorMask RG
            ZTest LEqual
            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            #include "../Character/ShaderLibrary/CharacterInput.hlsl"
            #include "../Character/ShaderLibrary/CharacterPrepassPass.hlsl"
            ENDHLSL
        }
    }
}
