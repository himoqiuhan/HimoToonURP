using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace HimoToon.Editor.ShaderGUI
{
    public class VFXShaderGUI : UnityEditor.ShaderGUI
    {
        #region GUIVariables

        private bool m_Initialized = false;
        private bool m_ShowRawView = false;
        MaterialEditor materialEditor { get; set; }

        #endregion
        
        public override void OnGUI(MaterialEditor materialEditorIn, MaterialProperty[] properties)
        {
            if (materialEditorIn == null)
                throw new ArgumentNullException("materialEditorIn");

            materialEditor = materialEditorIn;
            Material material = materialEditor.target as Material;

            FindProperties(properties); 
            
            if (!m_Initialized)
            {
                OnOpenGUI(material, materialEditor);
                m_Initialized = true;
            }
            
            ShaderPropertiesGUI(material);
            
            m_ShowRawView = EditorGUILayout.Foldout(m_ShowRawView, "RAW VIEW", true);
            if (m_ShowRawView)
            {
                base.OnGUI(materialEditor, properties);
                EditorGUILayout.Space();
            }
        }

        public void OnOpenGUI(Material material, MaterialEditor materialEditorIn)
        {
            InitializeSections(materialEditorIn);
        }
        
        public override void OnClosed(Material material)
        {
            m_Initialized = false;
        }
        
        private void ShaderPropertiesGUI(Material material)
        {
            EditorGUI.BeginChangeCheck();
            
            // DrawHeader();
            
            EditorGUILayout.Space();
            
            DrawGeneralSection(material);
            DrawMainVisualSection(material);
            DrawNoiseSection(material);
            DrawDissolveSection(material);
            DrawSoftParticleSection(material);
            DrawFresnelSection(material);
            DrawAdvanceSection(material);

            if (EditorGUI.EndChangeCheck())
            {
                
            }
        }
        
        // private void DrawHeader()
        // {
        //     if (EditorUserBuildSettings.activeBuildTarget == BuildTarget.Android || EditorUserBuildSettings.activeBuildTarget == BuildTarget.iOS)
        //     {
        //         if (PlayerSettings.GetUseDefaultGraphicsAPIs(EditorUserBuildSettings.activeBuildTarget) == false &&
        //             PlayerSettings.GetGraphicsAPIs(EditorUserBuildSettings.activeBuildTarget)[0] == GraphicsDeviceType.OpenGLES2)
        //         {
        //             UI.DrawNotification("You are targeting the OpenGLES 2.0 graphics API, which is not supported. Shader will not compile on the device", MessageType.Error);
        //         }
        //     }
        //     
        //     Rect rect = EditorGUILayout.GetControlRect();
        //     
        //     GUIContent c = new GUIContent("Version " + AssetInfo.INSTALLED_VERSION);
        //     rect.width = EditorStyles.miniLabel.CalcSize(c).x + 8f;
        //     //rect.x += (rect.width * 2f);
        //     rect.y -= 3f;
        //     GUI.Label(rect, c, EditorStyles.label);
        //
        //     rect.x += rect.width + 3f;
        //     rect.y += 2f;
        //     rect.width = 16f;
        //     rect.height = 16f;
        //     
        //     GUI.DrawTexture(rect, EditorGUIUtility.IconContent("preAudioLoopOff").image);
        //     if (Event.current.type == EventType.MouseDown)
        //     {
        //         if (rect.Contains(Event.current.mousePosition) && Event.current.button == 0)
        //         {
        //             AssetInfo.VersionChecking.GetLatestVersionPopup();
        //             Event.current.Use();
        //         }
        //     }
        //
        //     if (rect.Contains(Event.current.mousePosition))
        //     {
        //         Rect tooltipRect = rect;
        //         tooltipRect.y -= 20f;
        //         tooltipRect.width = 120f;
        //         GUI.Label(tooltipRect, "Check for update", GUI.skin.button);
        //     }
        //
        //     c = new GUIContent("Open asset window", EditorGUIUtility.IconContent("_Help").image, "Show help and third-party integrations");
        //     rect.width = (EditorStyles.miniLabel.CalcSize(c).x + 32f);
        //     rect.x = EditorGUIUtility.currentViewWidth - rect.width - 17f;
        //     rect.height = 17f;
        //
        //     if (GUI.Button(rect, c))
        //     {
        //         HelpWindow.ShowWindow();
        //     }
        //
        //     GUILayout.Space(3f);
        // }

        #region Properties
        
        // General
        protected MaterialProperty blendOperationProp { get; set; }
        
        protected MaterialProperty blendModeSrcProp { get; set; }
        
        protected MaterialProperty blendModeDstProp { get; set; }
        
        protected MaterialProperty cullingProp { get; set; }
        
        protected MaterialProperty zTestProp { get; set; }
        
        protected MaterialProperty zWriteProp { get; set; }
        
        protected MaterialProperty alphaClipThresholdProp { get; set; }
        
        // Main Visual
        private MaterialProperty generalColorProp { get; set; }
        
        protected MaterialProperty mainTextureProp { get; set; }
        
        protected MaterialProperty mainColorProp { get; set; }
        
        protected MaterialProperty secondaryTextureProp { get; set; }
        
        protected MaterialProperty secondaryColorProp { get; set; }
        
        protected MaterialProperty secondaryFxColorBlendModeProp { get; set; }
        
        protected MaterialProperty colorTextureFlowParamsProp { get; set; }
        
        // Noise
        protected MaterialProperty noiseTextureProp { get; set; }
        
        protected MaterialProperty noiseParamsProp { get; set; }
        
        // Mask
        protected MaterialProperty maskTextureProp { get; set; }
        
        protected MaterialProperty maskParamsProp { get; set; }
        
        // Dissolve
        protected MaterialProperty dissolveTextureProp { get; set; }
        
        protected MaterialProperty dissolveTexFlowParamsProp { get; set; }
        
        protected MaterialProperty dissolveParamsProp { get; set; }
        
        protected MaterialProperty dissolveEdgeColorProp { get; set; }
        
        // Soft particle
        protected MaterialProperty depthFadeThresholdProp { get; set; }
        
        // Fresnel
        protected MaterialProperty fresnelParamsProp { get; set; }
        
        protected MaterialProperty fresnelInnerColorProp { get; set; }
        
        protected MaterialProperty fresnelOuterColorProp { get; set; }
        
        // Stencil
        protected MaterialProperty stencilCompProp { get; set; }
        
        protected MaterialProperty stencilOpProp { get; set; }
        
        protected MaterialProperty stencilRefValueProp { get; set; }
        
        protected MaterialProperty stencilReadMaskProp { get; set; }
        
        protected MaterialProperty stencilWriteMaskProp { get; set; }
        
        public virtual void FindProperties(MaterialProperty[] properties)
        {
            var material = materialEditor?.target as Material;
            if (material == null)
                return;
            
            blendOperationProp = FindProperty("_Blend", properties, false);
            blendModeSrcProp = FindProperty("_SrcBlend", properties, false);
            blendModeDstProp = FindProperty("_DstBlend", properties, false);
            cullingProp = FindProperty("_Cull", properties, false);
            zTestProp = FindProperty("_ZTest", properties, false);
            zWriteProp = FindProperty("_ZWrite", properties, false);
            alphaClipThresholdProp = FindProperty("_AlphaClipThreshold", properties, false);
            
            generalColorProp = FindProperty("_Color", properties, false);
            mainTextureProp = FindProperty("_MainTex", properties, false);
            mainColorProp = FindProperty("_MainColor", properties, false);
            secondaryTextureProp = FindProperty("_SecondaryTex", properties, false);
            secondaryColorProp = FindProperty("_SecondaryColor", properties, false);
            secondaryFxColorBlendModeProp = FindProperty("_SecondaryTexBlendMode", properties, false);
            colorTextureFlowParamsProp = FindProperty("_ColorTexFlowParam", properties, false);
            
            noiseTextureProp = FindProperty("_NoiseTex", properties, false);
            noiseParamsProp = FindProperty("_NoiseTexParams", properties, false);
            maskTextureProp = FindProperty("_MaskTex", properties, false);
            maskParamsProp = FindProperty("_MaskTexParams", properties, false);
                        
            dissolveTextureProp = FindProperty("_DissolveTex", properties, false);
            dissolveTexFlowParamsProp = FindProperty("_DissolveTexFlowParams", properties, false);
            dissolveParamsProp = FindProperty("_DissolveParams", properties, false);
            dissolveEdgeColorProp = FindProperty("_DissolveEdgeColor", properties, false);
            
            depthFadeThresholdProp = FindProperty("_DepthFadeThreshold", properties, false);
            
            fresnelParamsProp = FindProperty("_FresnelParams", properties, false);
            fresnelInnerColorProp = FindProperty("_FresnelInnerColor", properties, false);
            fresnelOuterColorProp = FindProperty("_FresnelOuterColor", properties, false);
            
            stencilCompProp = FindProperty("_StencilComp", properties, false);
            stencilOpProp = FindProperty("_StencilOp", properties, false);
            stencilRefValueProp = FindProperty("_Stencil", properties, false);
            stencilReadMaskProp = FindProperty("_ReadMask", properties, false);
            stencilWriteMaskProp = FindProperty("_WriteMask", properties, false);
        }

        #endregion

        #region Sections

        protected enum BlendMode
        {
            AlphaBlend,
            Add,
            Multiply,
        }
        
        protected enum UVMode
        {
            Object,
            ScreenSpace
        }
        
        protected enum UVFlowQuality
        {
            Low,
            High
        }
        
        protected enum DissolveControlMode
        {
            SelfUV = 0,
            MainTexUV = 1
        }

        protected enum FxColorBlendMode
        {
            Replace = 0,
            Add = 1,
            Multiply = 2
        }
        
        private BlendMode m_GeneralBlendMode = BlendMode.AlphaBlend;
        
        private ShaderGUIUtil.Section generalSection;
        private ShaderGUIUtil.Section mainVisualSection;
        private ShaderGUIUtil.Section noiseSection;
        private ShaderGUIUtil.Section dissolveSection;
        private ShaderGUIUtil.Section softParticleSection;
        private ShaderGUIUtil.Section fresnelSection;
        private ShaderGUIUtil.Section advanceSection;

        private void SwitchSection(ShaderGUIUtil.Section s)
        {
            s.Expanded = !s.Expanded;
        }

        private void InitializeSections(MaterialEditor materialEditorIn)
        {
            generalSection = new ShaderGUIUtil.Section(materialEditorIn, "GENERAL", new GUIContent("整体效果"));
            mainVisualSection = new ShaderGUIUtil.Section(materialEditorIn, "MAINVISUAL", new GUIContent("主视觉效果"));
            noiseSection = new ShaderGUIUtil.Section(materialEditorIn, "NOISE", new GUIContent("扰动"));
            dissolveSection = new ShaderGUIUtil.Section(materialEditorIn, "DISSOLVE", new GUIContent("溶解"));
            softParticleSection = new ShaderGUIUtil.Section(materialEditorIn, "SOFTPARTICLE", new GUIContent("软粒子"));
            fresnelSection = new ShaderGUIUtil.Section(materialEditorIn, "FRESNEL", new GUIContent("菲涅尔"));
            advanceSection = new ShaderGUIUtil.Section(materialEditorIn, "ADVANCE", new GUIContent("额外效果"));
        }

        protected virtual void DrawGeneralSection(Material material)
        {
            generalSection.DrawHeader(() => SwitchSection(generalSection));
            if (EditorGUILayout.BeginFadeGroup(generalSection.anim.faded))
            {
                bool alphaClip = material.IsKeywordEnabled("_ALPHATEST_ON");
                UVMode generalUVMode = material.IsKeywordEnabled("_USE_SCREEN_SPACE_UV") ? UVMode.ScreenSpace : UVMode.Object;
                UVFlowQuality generalUVFlowQuality = material.IsKeywordEnabled("_HIGH_QUALITY_UV_FLOW") ? UVFlowQuality.High : UVFlowQuality.Low;
                
                EditorGUI.BeginChangeCheck();
                m_GeneralBlendMode = (BlendMode)EditorGUILayout.EnumPopup("混合模式", m_GeneralBlendMode);
                
                materialEditor.ShaderProperty(cullingProp, "剔除模式");
                materialEditor.ShaderProperty(zTestProp, "深度测试");
                materialEditor.ShaderProperty(zWriteProp, "深度写入");
                
                alphaClip = EditorGUILayout.Toggle("Alpha裁剪", alphaClip);
                if (alphaClip)
                {
                    EditorGUI.indentLevel++;
                    materialEditor.ShaderProperty(alphaClipThresholdProp, "Alpha裁剪阈值");
                    EditorGUI.indentLevel--;
                }
                
                generalUVMode = (UVMode)EditorGUILayout.EnumPopup("UV模式", generalUVMode);
                generalUVFlowQuality = (UVFlowQuality)EditorGUILayout.EnumPopup("UV流动质量", generalUVFlowQuality);
                
                if (EditorGUI.EndChangeCheck())
                {
                    materialEditor.RegisterPropertyChangeUndo("Blend Mode");
                    switch (m_GeneralBlendMode)
                    {
                        case BlendMode.AlphaBlend:
                            blendOperationProp.floatValue = (float)UnityEngine.Rendering.BlendOp.Add;
                            blendModeSrcProp.floatValue = (float)UnityEngine.Rendering.BlendMode.SrcAlpha;
                            blendModeDstProp.floatValue = (float)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha;
                            break;
                        case BlendMode.Add:
                            blendOperationProp.floatValue = (float)UnityEngine.Rendering.BlendOp.Add;
                            blendModeSrcProp.floatValue = (float)UnityEngine.Rendering.BlendMode.One;
                            blendModeDstProp.floatValue = (float)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha;
                            break;
                        case BlendMode.Multiply:
                            blendOperationProp.floatValue = (float)UnityEngine.Rendering.BlendOp.Multiply;
                            blendModeSrcProp.floatValue = (float)UnityEngine.Rendering.BlendMode.One;
                            blendModeDstProp.floatValue = (float)UnityEngine.Rendering.BlendMode.One;
                            break;
                    }

                    if (alphaClip)
                    {
                        material.EnableKeyword("_ALPHATEST_ON");
                    }
                    else
                    {
                        material.DisableKeyword("_ALPHATEST_ON");
                    }

                    if (generalUVMode == UVMode.ScreenSpace)
                    {
                        material.EnableKeyword("_USE_SCREEN_SPACE_UV");
                    }
                    else
                    {
                        material.DisableKeyword("_USE_SCREEN_SPACE_UV");
                    }
                    
                    if (generalUVFlowQuality == UVFlowQuality.High)
                    {
                        material.EnableKeyword("_HIGH_QUALITY_UV_FLOW");
                    }
                    else
                    {
                        material.DisableKeyword("_HIGH_QUALITY_UV_FLOW");
                    }
                    
                }
            }
            EditorGUILayout.EndFadeGroup();
        }
        
        protected virtual void DrawMainVisualSection(Material material)
        {
            mainVisualSection.DrawHeader(() => SwitchSection(mainVisualSection));
            if (EditorGUILayout.BeginFadeGroup(mainVisualSection.anim.faded))
            {
                Vector4 colorTextureFlowParams = colorTextureFlowParamsProp.vectorValue;
                Vector2 mainTextureFlow = new Vector2(colorTextureFlowParams.x, colorTextureFlowParams.y);
                Vector2 secondaryTextureFlow = new Vector2(colorTextureFlowParams.z, colorTextureFlowParams.w);
                
                Vector4 maskTextureParams = maskParamsProp.vectorValue;
                Vector2 maskTextureFlow = new Vector2(maskTextureParams.x, maskTextureParams.y);
                
                EditorGUI.BeginChangeCheck();
                
                materialEditor.ShaderProperty(generalColorProp, "整体颜色");
                GUILayout.Space(10);
                
                EditorGUILayout.LabelField("主帖图", EditorStyles.boldLabel);
                GUILayout.Space(5);
                EditorGUI.indentLevel++;
                materialEditor.ShaderProperty(mainColorProp, "主帖图颜色");
                materialEditor.ShaderProperty(mainTextureProp, "主贴图");
                mainTextureFlow = EditorGUILayout.Vector2Field("主贴图Flow", mainTextureFlow);
                EditorGUI.indentLevel--;
                GUILayout.Space(20);
                
                EditorGUILayout.LabelField("附加帖图", EditorStyles.boldLabel);
                GUILayout.Space(5);
                EditorGUI.indentLevel++;
                materialEditor.ShaderProperty(secondaryFxColorBlendModeProp, "附加颜色混合模式");
                materialEditor.ShaderProperty(secondaryColorProp, "附加颜色");
                materialEditor.ShaderProperty(secondaryTextureProp, "附加贴图");
                secondaryTextureFlow = EditorGUILayout.Vector2Field("附加贴图Flow", secondaryTextureFlow);
                EditorGUI.indentLevel--;
                GUILayout.Space(20);
                
                EditorGUILayout.LabelField("Mask", EditorStyles.boldLabel);
                GUILayout.Space(5);
                EditorGUI.indentLevel++;
                materialEditor.ShaderProperty(maskTextureProp, "Mask贴图");
                maskTextureFlow = EditorGUILayout.Vector2Field("Mask贴图Flow", maskTextureFlow);
                maskTextureParams.z = EditorGUILayout.Slider("扰动影响程度", maskTextureParams.z, 0, 1);
                EditorGUI.indentLevel--;
                GUILayout.Space(20);
                
                if (EditorGUI.EndChangeCheck())
                {
                    colorTextureFlowParamsProp.vectorValue = new Vector4(mainTextureFlow.x, mainTextureFlow.y, secondaryTextureFlow.x, secondaryTextureFlow.y);
                    maskParamsProp.vectorValue = new Vector4(maskTextureFlow.x, maskTextureFlow.y, maskTextureParams.z, maskTextureParams.w);
                    if (secondaryTextureProp.textureValue != null)
                    {
                        material.EnableKeyword("_USE_SECONDARY_TEXTURE");
                    }
                    else
                    {
                        material.DisableKeyword("_USE_SECONDARY_TEXTURE");
                    }
                }
            }
            EditorGUILayout.EndFadeGroup();
        }
        
        protected virtual void DrawNoiseSection(Material material)
        {
            noiseSection.DrawHeader(() => SwitchSection(noiseSection));
            if (EditorGUILayout.BeginFadeGroup(noiseSection.anim.faded))
            {
                Vector2 noiseTextureFlow = new Vector2(noiseParamsProp.vectorValue.z, noiseParamsProp.vectorValue.w);
                Vector2 noiseTextureDisturbance = new Vector2(noiseParamsProp.vectorValue.x, noiseParamsProp.vectorValue.y);
                
                EditorGUI.BeginChangeCheck();
                
                materialEditor.ShaderProperty(noiseTextureProp, "扰动贴图");
                noiseTextureFlow = EditorGUILayout.Vector2Field("扰动贴图Flow", noiseTextureFlow);
                noiseTextureDisturbance = EditorGUILayout.Vector2Field("扰动强度", noiseTextureDisturbance);

                if (EditorGUI.EndChangeCheck())
                {
                    noiseParamsProp.vectorValue = new Vector4(noiseTextureDisturbance.x, noiseTextureDisturbance.y, noiseTextureFlow.x, noiseTextureFlow.y);
                }
            }
            EditorGUILayout.EndFadeGroup();
        }
        
        protected virtual void DrawDissolveSection(Material material)
        {
            dissolveSection.DrawHeader(() => SwitchSection(dissolveSection));
            if (EditorGUILayout.BeginFadeGroup(dissolveSection.anim.faded))
            {
                Vector4 dissolveTexFlowParams = dissolveTexFlowParamsProp.vectorValue;
                Vector2 dissolveTextureFlow = new Vector2(dissolveTexFlowParams.x, dissolveTexFlowParams.y);
                Vector4 dissolveParams = dissolveParamsProp.vectorValue;
                
                DissolveControlMode dissolveControlMode = (DissolveControlMode)dissolveTexFlowParams.z;
                
                EditorGUI.BeginChangeCheck();
                
                dissolveControlMode = (DissolveControlMode)EditorGUILayout.EnumPopup("采样UV", dissolveControlMode);
                if (dissolveControlMode == DissolveControlMode.SelfUV)
                {
                    materialEditor.ShaderProperty(dissolveTextureProp, "溶解贴图");
                    dissolveTextureFlow = EditorGUILayout.Vector2Field("溶解贴图Flow", dissolveTextureFlow);
                    dissolveTexFlowParams.w = EditorGUILayout.Slider("扰动影响程度", dissolveTexFlowParams.w, 0, 1);
                }
                else
                {
                    dissolveTextureProp.textureValue = EditorGUILayout.ObjectField("溶解贴图", dissolveTextureProp.textureValue, typeof(Texture), false) as Texture;
                }
                
                GUILayout.Space(10);
                EditorGUILayout.LabelField("溶解参数", EditorStyles.boldLabel);
                bool useEdgeColor = dissolveParams.z > 0.5;
                
                dissolveParams.x = EditorGUILayout.Slider("溶解程度", dissolveParams.x, 0, 1f + dissolveParams.y + (useEdgeColor ? dissolveParams.w : 0));
                dissolveParams.y = EditorGUILayout.Slider("边缘软度", dissolveParams.y, 0, 1);
                
                useEdgeColor = EditorGUILayout.Toggle("亮边溶解", useEdgeColor);
                if (useEdgeColor)
                {
                    dissolveParams.z = 1;
                    EditorGUI.indentLevel++;
                    materialEditor.ShaderProperty(dissolveEdgeColorProp, "边缘颜色");
                    dissolveParams.w = EditorGUILayout.Slider("边缘宽度", dissolveParams.w, 0, 1);
                    EditorGUI.indentLevel--;
                }
                else
                {
                    dissolveParams.z = 0;
                }

                if (EditorGUI.EndChangeCheck())
                {
                    dissolveTexFlowParamsProp.vectorValue = new Vector4(
                        dissolveTextureFlow.x, dissolveTextureFlow.y, 
                        (int)dissolveControlMode, 
                        dissolveTexFlowParams.w
                        );
                    dissolveParamsProp.vectorValue = dissolveParams;
                }
            }
            EditorGUILayout.EndFadeGroup();
        }
        
        protected virtual void DrawSoftParticleSection(Material material)
        {
            softParticleSection.DrawHeader(() => SwitchSection(softParticleSection));
            if (EditorGUILayout.BeginFadeGroup(softParticleSection.anim.faded))
            {
                bool isSoftParticle = material.IsKeywordEnabled("_DEPTH_FADE_ON");
                
                EditorGUI.BeginChangeCheck();
                
                isSoftParticle = EditorGUILayout.Toggle("软粒子", isSoftParticle);
                if (isSoftParticle)
                {
                    materialEditor.ShaderProperty(depthFadeThresholdProp, "粒子软度");
                }
                
                if (EditorGUI.EndChangeCheck())
                {
                    if (isSoftParticle)
                    {
                        material.EnableKeyword("_DEPTH_FADE_ON");
                    }
                    else
                    {
                        material.DisableKeyword("_DEPTH_FADE_ON");
                    }
                }
            }
            EditorGUILayout.EndFadeGroup();
        }
        
        protected virtual void DrawFresnelSection(Material material)
        {
            fresnelSection.DrawHeader(() => SwitchSection(fresnelSection));
            if (EditorGUILayout.BeginFadeGroup(fresnelSection.anim.faded))
            {
                Vector4 fresnelParams = fresnelParamsProp.vectorValue;
                bool useFresnelColor = fresnelParams.x > 0.5;
                FxColorBlendMode fresnelColorMode;
                if (fresnelParams.w < 0.25)
                {
                    fresnelColorMode = FxColorBlendMode.Replace;
                }
                else if (fresnelParams.w > 0.75)
                {
                    fresnelColorMode = FxColorBlendMode.Multiply;
                }
                else
                {
                    fresnelColorMode = FxColorBlendMode.Add;
                }
                
                EditorGUI.BeginChangeCheck();
                useFresnelColor = EditorGUILayout.Toggle("开启", useFresnelColor);
                if (useFresnelColor)
                {
                    fresnelParams.x = 1;
                    fresnelParams.y = EditorGUILayout.Slider("菲涅尔强度", fresnelParams.y, 0, 1);
                    fresnelParams.z = EditorGUILayout.FloatField("菲涅尔Pow", fresnelParams.z);
                    if (fresnelParams.z <= 0f)
                        fresnelParams.z = 0.001f;
                    fresnelColorMode = (FxColorBlendMode)EditorGUILayout.EnumPopup("颜色叠加模式", fresnelColorMode);
                    materialEditor.ShaderProperty(fresnelInnerColorProp, "内部颜色");
                    materialEditor.ShaderProperty(fresnelOuterColorProp, "外部颜色");
                }
                else
                {
                    fresnelParams.x = 0;
                }
                
                if (EditorGUI.EndChangeCheck())
                {
                    switch (fresnelColorMode)
                    {
                        case FxColorBlendMode.Replace:
                            fresnelParams.w = 0;
                            break;
                        case FxColorBlendMode.Add:
                            fresnelParams.w = 0.5f;
                            break;
                        case FxColorBlendMode.Multiply:
                            fresnelParams.w = 1;
                            break;
                    }
                    fresnelParamsProp.vectorValue = fresnelParams;
                }
            }
            EditorGUILayout.EndFadeGroup();
        }
        
        protected virtual void DrawAdvanceSection(Material material)
        {
            advanceSection.DrawHeader(() => SwitchSection(advanceSection));
            if (EditorGUILayout.BeginFadeGroup(advanceSection.anim.faded))
            {
                EditorGUILayout.LabelField("Stencil", EditorStyles.boldLabel);
                GUILayout.Space(5);
                EditorGUI.indentLevel++;
                materialEditor.ShaderProperty(stencilCompProp, "Compare Function");
                materialEditor.ShaderProperty(stencilOpProp, "Pass Operation");
                materialEditor.ShaderProperty(stencilRefValueProp, "Reference");
                materialEditor.ShaderProperty(stencilReadMaskProp, "Read Mask");
                materialEditor.ShaderProperty(stencilWriteMaskProp, "Write Mask");
                EditorGUI.indentLevel--;
                GUILayout.Space(20);
            }
            EditorGUILayout.EndFadeGroup();
        }

        #endregion
    }
}