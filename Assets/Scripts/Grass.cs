using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Grass : MonoBehaviour {

    Material mat;

    [SerializeField]
    Shader shader;
	// Use this for initialization
	void Start () {
        mat = new Material(shader);
	}
	
	// Update is called once per frame
	void Update () {
		
	}

    private void OnRenderObject()
    {
        mat.SetPass(0);
        //mat.SetFloat("m_Time", Time.time);
        Graphics.DrawProcedural(MeshTopology.Triangles, 2);
    }
}
