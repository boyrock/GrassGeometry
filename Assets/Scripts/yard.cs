using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class yard : MonoBehaviour {

    Renderer renderer;

    [SerializeField]
    GameObject obstaclePrefab;
    GameObject obstacle;

    PlanMeshGenerator meshGenerator;

    private void Awake()
    {
        renderer = this.GetComponent<Renderer>();
        meshGenerator = this.GetComponent<PlanMeshGenerator>();
    }

    // Use this for initialization
    void Start () {


        meshGenerator.CreatePlaneMesh();

        obstacle = Instantiate(obstaclePrefab);
        obstacle.SetActive(true);
        obstacle.transform.SetParent(this.transform);
        obstacle.transform.localPosition = new Vector3(0, obstacle.transform.localScale.y * 0.5f, 0);
    }
	
	// Update is called once per frame
	void Update () {

        renderer.material.SetVector("_ObstaclePosition", obstacle.transform.localPosition);
        renderer.material.SetFloat("_ObstacleRaidus", obstacle.transform.localScale.magnitude * 0.60f);

        obstacle.transform.localPosition = new Vector3(10 * Mathf.Cos(Time.time * 0.5f), obstacle.transform.localScale.y * 0.5f, 8 * Mathf.Sin(Time.time * 1f));
    }

}
