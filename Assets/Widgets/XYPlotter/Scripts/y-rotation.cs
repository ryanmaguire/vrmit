using UnityEngine;

public class RotateAroundY : MonoBehaviour
{
    public float rotationSpeed = 45f; // degrees per second
    public bool enabled = true;

    void Update()
    {
        if(enabled) transform.Rotate(0, rotationSpeed * Time.deltaTime, 0);
    }
}
