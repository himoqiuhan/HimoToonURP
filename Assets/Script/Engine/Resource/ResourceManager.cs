using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace CH04.Engine
{
    public class ResourceManager
    {
        private static ResourceManager s_Instance;
        private ResourceManager() { }
        public static ResourceManager instance
        {
            get
            {
                s_Instance ??= new ResourceManager();
                return s_Instance;
            }
        }
        
        #region ShaderResources
        
        Dictionary<string, ComputeShader> m_ComputeShaders = new Dictionary<string, ComputeShader>();
        Dictionary<string, Shader> m_Shaders = new Dictionary<string, Shader>();
        
        /// <summary>
        /// 加载ComputeShader的逻辑，包体中ResourceManager单例会Cache加载的ComputeShader
        /// </summary>
        /// <param name="path">相对于Resource文件夹的路径，不包含文件扩展名</param>
        /// <returns></returns>
        public ComputeShader LoadComputeShader(string path)
        {
            ComputeShader computeShader = null;
        #if UNITY_EDITOR
            computeShader = AssetDatabase.LoadAssetAtPath<ComputeShader>("Assets/Resources/" + path + ".compute");
        #else
            if (!m_ComputeShaders.TryGetValue(path.ToLower(), out computeShader))
            {
                computeShader = Resources.Load<ComputeShader>(path);
                if (computeShader != null)
                {
                    m_ComputeShaders.Add(path.ToLower(), computeShader);
                }
            }
        #endif
            return computeShader;
        }
        
        public Shader LoadShader(string name)
        {
            Shader shader = null;
            
#if UNITY_EDITOR
            shader = Shader.Find(name);
#else
            if (!m_Shaders.TryGetValue(name.ToLower(), out shader))
            {
                shader = Resources.Load<Shader>(name);
                if (shader != null)
                {
                    m_Shaders.Add(name.ToLower(), shader);
                }
            }
#endif
            return shader;
        }
        #endregion
    }
}