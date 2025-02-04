using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEditor.Rendering;
using UnityEditor.Rendering.Universal;
using UnityEditor.ShaderGraph;
using UnityEditor.ShaderGraph.Drawing;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using static Unity.Rendering.Universal.ShaderUtils;
using RenderQueue = UnityEngine.Rendering.RenderQueue;

namespace Rendering.HimoToon.ShaderGUI
{
    public class VisualEffectGUI : UnityEditor.ShaderGUI
    {
        #region EnumsAndClasses
        
        /// <summary>
        /// Flags for the foldouts used in the base shader GUI.
        /// </summary>
        [Flags]
        protected enum Expandable
        {
            /// <summary>
            /// Use this for surface options foldout.
            /// </summary>
            SurfaceOptions = 1 << 0,

            /// <summary>
            /// Use this for surface input foldout.
            /// </summary>
            SurfaceInputs = 1 << 1,

            /// <summary>
            /// Use this for advanced foldout.
            /// </summary>
            Advanced = 1 << 2,

            /// <summary>
            /// Use this for additional details foldout.
            /// </summary>
            Details = 1 << 3,
        }
        
        #endregion
        
        protected MaterialEditor materialEditor { get; set; }
        
        public bool m_FirstTimeApply = true;
        readonly MaterialHeaderScopeList m_MaterialScopeList = new MaterialHeaderScopeList(uint.MaxValue & ~(uint)Expandable.Advanced);

        #region General

        public virtual void FindProperties(MaterialProperty[] properties)
        {
            var material = materialEditor?.target as Material;
            if (material == null)
                return;
        }

        public void ShaderPropertiesGUI(Material material)
        {
            m_MaterialScopeList.DrawHeaders(materialEditor, material);
        }

        public override void OnGUI(MaterialEditor materialEditorIn, MaterialProperty[] properties)
        {
            if (materialEditorIn == null)
                throw new ArgumentNullException("materialEditorIn");

            materialEditor = materialEditorIn;
            Material material = materialEditor.target as Material;

            FindProperties(properties);   // MaterialProperties can be animated so we do not cache them but fetch them every event to ensure animated values are updated correctly

            // Make sure that needed setup (ie keywords/renderqueue) are set up if we're switching some existing
            // material to a universal shader.
            if (m_FirstTimeApply)
            {
                OnOpenGUI(material, materialEditorIn);
                m_FirstTimeApply = false;
            }

            ShaderPropertiesGUI(material);
        }
        
        /// <summary>
        /// Filter for the surface options, surface inputs, details and advanced foldouts.
        /// </summary>
        protected virtual uint materialFilter => uint.MaxValue;

        /// <summary>
        /// Draws the GUI for the material.
        /// </summary>
        /// <param name="material">The material to use.</param>
        /// <param name="materialEditor">The material editor to use.</param>
        public virtual void OnOpenGUI(Material material, MaterialEditor materialEditor)
        {
            var filter = (Expandable)materialFilter;

            // Generate the foldouts
            if (filter.HasFlag(Expandable.SurfaceOptions))
                m_MaterialScopeList.RegisterHeaderScope(EditorGUIUtility.TrTextContent("Surface Options Test", "Controls how URP Renders the material on screen.")
                    , (uint)Expandable.SurfaceOptions, DrawSurfaceOptions);

            // if (filter.HasFlag(Expandable.SurfaceInputs))
            //     m_MaterialScopeList.RegisterHeaderScope(Styles.SurfaceInputs, (uint)Expandable.SurfaceInputs, DrawSurfaceInputs);
            //
            // if (filter.HasFlag(Expandable.Details))
            //     FillAdditionalFoldouts(m_MaterialScopeList);
            //
            // if (filter.HasFlag(Expandable.Advanced))
            //     m_MaterialScopeList.RegisterHeaderScope(Styles.AdvancedLabel, (uint)Expandable.Advanced, DrawAdvancedOptions);
        }

        #endregion

        #region DrawingFunctions

        public virtual void DrawSurfaceOptions(Material material)
        {
        }

        #endregion
    }
}