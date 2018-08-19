/*******************************************************
	ReShade Shader: ColorIsolation
	https://github.com/Daodan317081/reshade-shaders
*******************************************************/

#include "ReShade.fxh"
#ifdef COLORISOLATION_DEBUG
#include "Canvas.fxh"
#endif

uniform float3 fUITargetHue<
    ui_type = "color";
    ui_label = "Target Hue";
    ui_tooltip = "Use the vertical slider from the color-control\nto select the hue that should be isolated.\nOr right-click and set input to HSV.\nSaturation and value are ignored.";
> = float3(1.0, 0.0, 0.0);

uniform int cUIWindowFunction<
    ui_type = "combo";
    ui_label = "Window Function";
    ui_items = "Gauss\0Triangle\0";
> = 0;

uniform float fUIOverlap<
    ui_type = "drag";
    ui_label = "Hue Overlap";
    ui_tooltip = "Changes the width of the gaussian curve\nto include less or more colors in relation\nto the target hue.\n";
    ui_min = 0.001; ui_max = 2.0;
    ui_step = 0.001;
> = 0.3;

uniform float fUIWindowHeight<
    ui_type = "drag";
    ui_label = "Curve Steepness";
    ui_min = 0.0; ui_max = 10.0;
    ui_step = 0.01;
> = 1.0;

uniform int cUIType<
    ui_type = "combo";
    ui_label = "Isolate / Reject Hue";
    ui_items = "Isolate\0Reject\0";
> = 0;

uniform bool bUIShowDiff<
    ui_label = "Show Hue Difference";
> = false;

#ifdef COLORISOLATION_DEBUG
CANVAS_SETUP(ColorIsolationDebug, BUFFER_WIDTH/2, BUFFER_HEIGHT/6);
#endif

float3 RGBtoHSV(float3 color) {
    float H, S, V, maxVal, minVal, delta;
    maxVal = max(color.r, max(color.g, color.b));
    minVal = min(color.r, min(color.g, color.b));

    V = maxVal;

    delta = maxVal - minVal;
    if(delta < 1.0e-10) {
        S = 0.0;
        H = 0.0;
        return float3(H, S, V);	
    }

    if(maxVal > 0.0) {
        S = delta / maxVal;
    }
    else {
        S = 0.0;
        H = 0.0;
        return float3(H, S, V);
    }

    if(color.r >= maxVal)
        H = (color.g - color.b) / delta;
    else if(color.g >= maxVal)
        H = 2.0 + (color.b - color.r) / delta;
    else
        H = 4.0 + (color.r - color.g) / delta;

    H *= 60.0;

    if(H < 0.0)
        H += 360.0;

    return saturate(float3(H / 360.0, S, V));
}

float3 HSVtoRGB(float3 color) {
    float H = color.x * 360.0;
    float S = color.y;
    float V = color.z;

    float hi = floor(abs(H / 60.0));
    float f = H / 60.0 - hi;
    float p = V * (1.0 - S);
    float q = V * (1.0 - S * f);
    float t = V * (1.0 - S * (1.0 - f));

    if(S < 1.0e-10)
        return float3(V,V,V);

    if(hi == 0 || hi == 6)
        return float3(V,t,p);
    else if(hi == 1)
        return float3(q,V,p);
    else if(hi == 2)
        return float3(p,V,t);
    else if(hi == 3)
        return float3(p,q,V);
    else if(hi == 4)
        return float3(t,p,V);
    else //if(hi == 5)
        return float3(V,p,q);
}

#define GAUSS(x,height,offset,overlap) (height * exp(-((x - offset) * (x - offset)) / (2 * overlap * overlap)))
#define TRIANGLE(x,height,offset,overlap) saturate(height * ((2 / overlap) * ((overlap / 2) - abs(x - offset))))

float CalculateValue(float x, float height, float offset, float overlap) {
    float retVal;
    //Add three curves together, two of them are moved by 1.0 to the left and to the right respectively
    //in order to account for the borders at 0.0 and 1.0
    if(cUIWindowFunction == 0) {
        //Scale overlap so the gaussian has roughly the same span as the triangle
        overlap /= 5.0;
        retVal = saturate(GAUSS(x-1.0, height, offset, overlap) + GAUSS(x, height, offset, overlap) + GAUSS(x+1.0, height, offset, overlap));
    }
    else {
        retVal = saturate(TRIANGLE(x-1.0, height, offset, overlap) + TRIANGLE(x, height, offset, overlap) + TRIANGLE(x+1.0, height, offset, overlap));
    }
    
    if(cUIType == 1)
        return 1.0 - retVal;
    
    return retVal;
}

float3 ColorIsolationPS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float3 luma = dot(color, float3(0.2126, 0.7151, 0.0721)).rrr;
    float value = CalculateValue(RGBtoHSV(color).x, fUIWindowHeight, RGBtoHSV(fUITargetHue).x, fUIOverlap);
    if(bUIShowDiff)
        return value.rrr;
    return lerp(luma, color, value);
}

#ifdef COLORISOLATION_DEBUG
CANVAS_DRAW_BEGIN(ColorIsolationDebug, 1.0.rrr)
    float value = CalculateValue(texcoord.x, fUIWindowHeight, RGBtoHSV(fUITargetHue).x, fUIOverlap);
    float3 hsvStrip = HSVtoRGB(float3(texcoord.x, 1.0, 1.0));
    float3 luma = dot(hsvStrip, float3(0.2126, 0.7151, 0.0721));
    CANVAS_DRAW_BACKGROUND(ColorIsolationDebug, lerp(luma, hsvStrip, value));
    CANVAS_DRAW_CURVE_XY(ColorIsolationDebug, 0.0.rrr, value);
CANVAS_DRAW_END(ColorIsolationDebug)
#endif

technique ColorIsolation {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = ColorIsolationPS;
        /* RenderTarget = BackBuffer */
    }
}

#ifdef COLORISOLATION_DEBUG
    CANVAS_TECHNIQUE(ColorIsolationDebug)
#endif