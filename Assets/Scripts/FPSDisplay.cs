using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class FPSDisplay : MonoBehaviour {
    private float deltaTime = 0.0f;

    void Update() {
        // Calculate the time it took to complete the last frame
        deltaTime += (Time.deltaTime - deltaTime) * 0.1f;

        // Calculate FPS
        float fps = 1.0f / deltaTime;

        // Print FPS to the first line in the console
        Debug.Log($"Current FPS: {fps:F2}");
    }
}