using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.AnimatedValues;
using UnityEditor.Rendering;
using UnityEngine;

namespace HimoToon.Editor.ShaderGUI
{
    public static class ShaderGUIUtil
    {
        private static Color RedColor = new Color(1f, 0.31f, 0.34f);
        private static Color OrangeColor = new Color(1f, 0.68f, 0f);
        
        public class Section
        {
            private const float ANIM_SPEED = 16f;
                
            public bool Expanded
            {
                get { return SessionState.GetBool(id, false); }
                set { SessionState.SetBool(id, value); }
            }
            public bool showHelp;
            public AnimBool anim;

            public readonly string id;
            public GUIContent title;

            public Section(MaterialEditor owner, string id, GUIContent title)
            {
                this.id = "HIMOTOON_SHADERGUI" + "_" + id + "_SECTION";
                this.title = title;

                anim = new AnimBool(true);
                anim.valueChanged.AddListener(owner.Repaint);
                anim.speed = ANIM_SPEED;
                anim.target = Expanded;
            }
                
            public void DrawHeader(Action clickAction)
            {
                ShaderGUIUtil.DrawHeader(title, Expanded, clickAction);
                anim.target = Expanded;
            }
        }
        
        private const float HeaderHeight = 25f;
        public static bool DrawHeader(GUIContent content, bool isExpanded, Action clickAction = null)
        {
            CoreEditorUtils.DrawSplitter();

            Rect backgroundRect = GUILayoutUtility.GetRect(1f, HeaderHeight);

            var labelRect = backgroundRect;
            labelRect.xMin += 8f;
            labelRect.xMax -= 20f + 16 + 5;

            var foldoutRect = backgroundRect;
            foldoutRect.xMin -= 8f;
            foldoutRect.y += 0f;
            foldoutRect.width = HeaderHeight;
            foldoutRect.height = HeaderHeight;

            // Background rect should be full-width
            backgroundRect.xMin = 0f;
            backgroundRect.width += 4f;

            // Background
            float backgroundTint = (EditorGUIUtility.isProSkin ? 0.1f : 1f);
            if (backgroundRect.Contains(Event.current.mousePosition)) 
                backgroundTint *= EditorGUIUtility.isProSkin ? 2f : 0.8f;
                
            EditorGUI.DrawRect(backgroundRect, new Color(backgroundTint, backgroundTint, backgroundTint, 0.2f));

            // Title
            EditorGUI.LabelField(labelRect, content, EditorStyles.boldLabel);

            // Foldout
            GUI.Label(foldoutRect, new GUIContent(isExpanded ? "−" : "≡"), EditorStyles.boldLabel);
                
            // Handle events
            var e = Event.current;

            if (e.type == EventType.MouseDown)
            {
                if (backgroundRect.Contains(e.mousePosition))
                {
                    if (e.button == 0)
                    {
                        isExpanded = !isExpanded;
                        if(clickAction != null) 
                            clickAction.Invoke();
                    }

                    e.Use();
                }
            }
                
            return isExpanded;
        }
    }
}