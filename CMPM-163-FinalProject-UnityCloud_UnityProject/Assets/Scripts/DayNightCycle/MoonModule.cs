using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MoonModule : DN_Module_Base
{
    [SerializeField]
    private Light moon;
    [SerializeField]
    private Gradient moonColor;
    [SerializeField]
    private float baseIntensity;


    public override void UpdateModule(float intensity)
    {
        moon.color = moonColor.Evaluate(1 - intensity); //effect of playing the gradient backwards of the sun
        moon.intensity = (1 - intensity) * baseIntensity + 0.05f;

    }
}
