using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering.VirtualTexturing;
using UnityEngine.UI;

[ExecuteInEditMode]
public class BaseShellTexture : MonoBehaviour
{
    public Material material;
    public Mesh mesh;
    [SerializeField, Range(1, 8192)] uint shellCount;

    GraphicsBuffer commandBuf;
    GraphicsBuffer.IndirectDrawIndexedArgs[] commandData;
    const int commandCount = 1;
    RenderParams rp;

    private Vector3 previousPosition;
    private Quaternion previousRotation;
    private Vector3 previousScale;


    void OnValidate() {
        previousPosition = transform.position;
        previousRotation = transform.rotation;
        previousScale = transform.localScale;

        ApplyChange();
    }

    void ApplyChange() {
        ReleaseData();

        commandBuf = new GraphicsBuffer(GraphicsBuffer.Target.IndirectArguments, commandCount, GraphicsBuffer.IndirectDrawIndexedArgs.size);
        commandData = new GraphicsBuffer.IndirectDrawIndexedArgs[commandCount];

        rp = new RenderParams(material);
        rp.worldBounds = new Bounds(Vector3.zero, 10000 * Vector3.one); // use tighter bounds for better FOV culling
        rp.matProps = new MaterialPropertyBlock();
        rp.matProps.SetMatrix("_ObjectToWorld", transform.localToWorldMatrix);
        commandData[0].indexCountPerInstance = mesh.GetIndexCount(0);
        commandData[0].instanceCount = shellCount;
        //commandData[1].indexCountPerInstance = mesh.GetIndexCount(0);
        //commandData[1].instanceCount = 10;
        commandBuf.SetData(commandData);
        rp.matProps.SetInt("_TotalInstances", (int)shellCount);
        rp.matProps.SetVector("_Scale", transform.localScale);
    }

    void OnDestroy() {
        ReleaseData();
    }
    private void OnDisable() {
        ReleaseData();   
    }
    void ReleaseData() {
        commandBuf?.Release();
        commandBuf = null;
    }

    void Update() {
        if (transform.position != previousPosition || transform.rotation != previousRotation || transform.localScale != previousScale) {
            
            
            // Update the shader, buffer, or any other data when the transform changes
            ApplyChange();

            // Update the previous transform values
            previousPosition = transform.position;
            previousRotation = transform.rotation;
            previousScale = transform.localScale;
        }


        Graphics.RenderMeshIndirect(rp, mesh, commandBuf, commandCount);
    }
}
