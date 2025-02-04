using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace HimoToon.Editor.ShaderGUI
{
    public class FxBaseShaderGUI : VFXShaderGUI
    {
        MaterialEditor materialEditor { get; set; }
        
        public override void OnGUI(MaterialEditor materialEditorIn, MaterialProperty[] properties)
        {
            if (materialEditorIn == null)
                throw new ArgumentNullException("materialEditorIn");

            materialEditor = materialEditorIn;
            Material material = materialEditor.target as Material;
            
            base.OnGUI(materialEditor, properties);
        }
        
    }
}