///////////////////////////////////////////////////////////////////////////////
//
//ReShade Shader: Sketch
//https://github.com/Daodan317081/reshade-shaders
//
//BSD 3-Clause License
//
//Copyright (c) 2018, Alexander Federwisch
//All rights reserved.
//
//Redistribution and use in source and binary forms, with or without
//modification, are permitted provided that the following conditions are met:
//
//* Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//* Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//* Neither the name of the copyright holder nor the names of its
//  contributors may be used to endorse or promote products derived from
//  this software without specific prior written permission.
//
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
///////////////////////////////////////////////////////////////////////////////

#include "ReShade.fxh"
#include "Tools.fxh"

#define UI_CATEGORY_LUMA "Luma"
#define UI_CATEGORY_CHROMA "Chroma"
#define UI_CATEGORY_DEPTH "Depth"
#define UI_CATEGORY_GRID "Grid"
#define UI_CATEGORY_MISC "Misc"
#define UI_CATEGORY_DEBUG "Debug"
#define UI_CATEGORY_EFFECT "Effect"


/******************************************************************************
    Uniforms
******************************************************************************/
uniform int iUILumaEdgeType <
    ui_type = "combo";
    ui_category = UI_CATEGORY_LUMA;
    ui_label = "Type";
    ui_items = "DiffEdges\0Convolution\0";
> = 0;

uniform int iUILumaKernel <
    ui_type = "combo";
    ui_category = UI_CATEGORY_LUMA;
    ui_label = "Kernel";
    ui_items = "CONV_PREWITT\0CONV_PREWITT_FULL\0CONV_SOBEL\0CONV_SOBEL_FULL\0CONV_SCHARR\0CONV_SCHARR_FULL\0";
> = 0;

uniform int iUILumaMerge <
	ui_type = "combo";
    ui_category = UI_CATEGORY_LUMA;
	ui_label = "Edge merge method";
	ui_items = "CONV_MUL\0CONV_DOT\0CONV_X\0CONV_Y\0CONV_ADD\0CONV_MAX\0";
> = 0;

uniform float fUILumaStrength <
    ui_type = "drag";
    ui_category = UI_CATEGORY_LUMA;
    ui_label = "Strength";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
> = 1.0;

uniform int iUIChromaEdgeType <
    ui_type = "combo";
    ui_category = UI_CATEGORY_CHROMA;
    ui_label = "Type";
    ui_items = "DiffEdges\0Convolution\0";
> = 0;

uniform int iUIChromaKernel <
    ui_type = "combo";
    ui_category = UI_CATEGORY_CHROMA;
    ui_label = "Kernel";
    ui_items = "CONV_PREWITT\0CONV_PREWITT_FULL\0CONV_SOBEL\0CONV_SOBEL_FULL\0CONV_SCHARR\0CONV_SCHARR_FULL\0";
> = 0;

uniform int iUIChromaMerge <
	ui_type = "combo";
    ui_category = UI_CATEGORY_CHROMA;
	ui_label = "Edge merge method";
	ui_items = "CONV_MUL\0CONV_DOT\0CONV_X\0CONV_Y\0CONV_ADD\0CONV_MAX\0";
> = 0;

uniform float fUIChromaStrength <
    ui_type = "drag";
    ui_category = UI_CATEGORY_CHROMA;
    ui_label = "Strength";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
> = 1.0;

uniform int iUIDepthEdgesType <
    ui_type = "combo";
    ui_category = UI_CATEGORY_DEPTH;
    ui_label = "Type";
    ui_items = "Normal Vector\0Diffs\0";
> = 0;

uniform float2 fUIDepthBias<
    ui_type = "drag";
    ui_category = UI_CATEGORY_DEPTH;
    ui_label = "Depth Outlines Bias";
    ui_min = 0.0; ui_max = 10.0;
    ui_step = 0.01;
> = float2(7.0, 2.9);

uniform float fUIDepthStrength <
    ui_type = "drag";
    ui_category = UI_CATEGORY_DEPTH;
    ui_label = "Strength";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
> = 1.0;

uniform float fUIGridStrength <
    ui_type = "drag";
    ui_category = UI_CATEGORY_GRID;
    ui_label = "Strength";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
> = 1.0;

uniform float3 fUIOutlinesDistanceFading<
    ui_type = "drag";
    ui_category = UI_CATEGORY_MISC;
    ui_label = "Fade outlines in/out with distance";
    ui_tooltip = "x: Fade Out Start\ny: Fade Out End\nz: Curve Steepness";
    ui_min = -1.0; ui_max = 1.0;
    ui_step = 0.001;
> = float3(0.0, 1.0, 0.8);

uniform float3 fUIGridDistanceFading<
    ui_type = "drag";
    ui_category = UI_CATEGORY_MISC;
    ui_label = "Fade grid in/out with distance";
    ui_tooltip = "x: Fade Out Start\ny: Fade Out End\nz: Curve Steepness";
    ui_min = -1.0; ui_max = 1.0;
    ui_step = 0.001;
> = float3(0.0, 1.0, 0.8);

uniform float3 fUIEdgesDistanceFading<
    ui_type = "drag";
    ui_category = UI_CATEGORY_MISC;
    ui_label = "Fade edges in/out with distance";
    ui_tooltip = "x: Fade Out Start\ny: Fade Out End\nz: Curve Steepness";
    ui_min = -1.0; ui_max = 1.0;
    ui_step = 0.001;
> = float3(0.0, 1.0, 0.8);

uniform float3 fUIEdgesLumaFading <
    ui_type = "drag";
    ui_category = UI_CATEGORY_MISC;
    ui_label = "Weight Pencil-layer with luma";
    ui_min = -1.0; ui_max = 1.0;
    ui_step = 0.001;
> = float3(0.0, 1.0, 0.8);

uniform float3 fUIEdgesSaturationFading <
    ui_type = "drag";
    ui_category = UI_CATEGORY_MISC;
    ui_label = "Weight Pencil-layer with saturation";
    ui_min = -1.0; ui_max = 1.0;
    ui_step = 0.001;
> = float3(0.0, 1.0, 0.8);

////////////////////////// Debug //////////////////////////

uniform bool bUIOverlayFadingCurves<
    ui_label = "Show Curves";
    ui_category = UI_CATEGORY_DEBUG;
> = false;

uniform float3 fUIDepthOutlinesCurveColor<
    ui_type = "color";
    ui_category = UI_CATEGORY_DEBUG;
    ui_label = "Outlines Fading Curve Color";
> = float3(1.0, 0.0, 0.0);

uniform float3 fUIGridCurveColor<
    ui_type = "color";
    ui_category = UI_CATEGORY_DEBUG;
    ui_label = "Grid Fading Curve Color";
> = float3(0.0, 1.0, 0.0);

uniform float3 fUIEdgesCurveColor<
    ui_type = "color";
    ui_category = UI_CATEGORY_DEBUG;
    ui_label = "Edges Fading Curve Color";
> = float3(0.0, 0.0, 1.0);

uniform float3 fUILumaCurveColor<
    ui_type = "color";
    ui_category = UI_CATEGORY_DEBUG;
    ui_label = "Luma Weight Curve Color";
> = float3(0.0, 1.0, 1.0);

uniform float3 fUISaturationCurveColor<
    ui_type = "color";
    ui_category = UI_CATEGORY_DEBUG;
    ui_label = "Saturation Weight Curve Color";
> = float3(1.0, 0.5, 0.0);

uniform float fUICurveWidth<
    ui_type = "drag";
    ui_category = UI_CATEGORY_DEBUG;
    ui_label = "Curve Width";
    ui_min = 1.0; ui_max = 10.0;
    ui_step = 0.1;
> = 2.0;

uniform int iUIDebugMaps <
    ui_type = "combo";
    ui_category = UI_CATEGORY_DEBUG;
    ui_label = "Show Debug Maps";
    ui_items = "Off\0"
               "Luma Edges\0"
               "Chroma Edges\0"
               "Outlines\0"
               "Mesh Grid\0"
               "All\0"
               "Luma\0"
               "Saturation\0";
> = 0;

////////////////////////// Effect //////////////////////////

uniform float fUIStrength <
    ui_type = "drag";
    ui_category = UI_CATEGORY_EFFECT;
    ui_label = "Strength";
    ui_min = 0.0; ui_max = 1.0;
> = 1.0;

/******************************************************************************
    Textures
******************************************************************************/

texture2D texSketchLuma { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler2D SamplerSketchLuma { Texture = texSketchLuma; };
texture2D texSketchChroma { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler2D SamplerSketchChroma { Texture = texSketchChroma; };
texture2D texSketchDepth { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16F; };
sampler2D SamplerSketchDepth { Texture = texSketchDepth; };

/******************************************************************************
    Functions
******************************************************************************/

#define MAX_VALUE(v) max(v.x, max(v.y, v.z))

float DiffEdges(sampler s, int2 vpos) {
    //static const float3 LumaCoeff = float3(0.2126, 0.7151, 0.0721);
    float valC = dot(tex2Dfetch(s, int4(vpos, 0, 0)).rgb, LumaCoeff);
    float4 val1 = float4(    
            dot(tex2Dfetch(s, int4(vpos + int2( 0, -1), 0, 0)).rgb, LumaCoeff),//N
            dot(tex2Dfetch(s, int4(vpos + int2( 1, -1), 0, 0)).rgb, LumaCoeff),//NE
            dot(tex2Dfetch(s, int4(vpos + int2( 1,  0), 0, 0)).rgb, LumaCoeff),//E
            dot(tex2Dfetch(s, int4(vpos + int2( 1,  1), 0, 0)).rgb, LumaCoeff)//SE
        );
    float4 val2 = float4(    
            dot(tex2Dfetch(s, int4(vpos + int2( 0,  1), 0, 0)).rgb, LumaCoeff),//S
            dot(tex2Dfetch(s, int4(vpos + int2(-1,  1), 0, 0)).rgb, LumaCoeff),//SW
            dot(tex2Dfetch(s, int4(vpos + int2(-1,  0), 0, 0)).rgb, LumaCoeff),//W
            dot(tex2Dfetch(s, int4(vpos + int2(-1, -1), 0, 0)).rgb, LumaCoeff)//NW
        );

    float4 diffs = abs(val1 - val2);
    return saturate((diffs.x + diffs.y + diffs.z + diffs.w) * (1.0 - valC));
}

float3 DepthEdges(float2 texcoord, float2 bias) {
    float retVal;
    if(iUIDepthEdgesType == 0) {
        float3 offset = float3(ReShade::PixelSize.xy, 0.0);
        float2 posCenter = texcoord.xy;
        float2 posNorth = posCenter - offset.zy;
        float2 posEast = posCenter + offset.xz;

        float3 vertCenter = float3(posCenter, ReShade::GetLinearizedDepth(posCenter));
        float3 vertNorth = float3(posNorth, ReShade::GetLinearizedDepth(posNorth));
        float3 vertEast = float3(posEast, ReShade::GetLinearizedDepth(posEast));
        
        float3 normalVector = normalize(cross(vertCenter - vertNorth, vertCenter - vertEast)) * 0.5 + 0.5;

        retVal = 1.0 - saturate(dot(float3(0.0, 0.0, 1.0), normalVector));
        retVal = exp(bias.x * retVal - bias.y) - 1.0;
    }
    else {
        retVal = Tools::Functions::GetDepthBufferOutlines(texcoord, 2);
    }
    
    return saturate(retVal.rrr);
}

float MeshGrid(float2 texcoord) {
    float4 pix = float4(ReShade::PixelSize, -ReShade::PixelSize);

    //Get depth of center pixel
    float c = ReShade::GetLinearizedDepth(texcoord);
    //Get depth of surrounding pixels
    float4 depthEven = float4(  ReShade::GetLinearizedDepth(texcoord + float2(0.0, pix.w)),
                                ReShade::GetLinearizedDepth(texcoord + float2(0.0, pix.y)),
                                ReShade::GetLinearizedDepth(texcoord + float2(pix.x, 0.0)),
                                ReShade::GetLinearizedDepth(texcoord + float2(pix.z, 0.0))   );

    float4 depthOdd  = float4(  ReShade::GetLinearizedDepth(texcoord + float2(pix.x, pix.w)),
                                ReShade::GetLinearizedDepth(texcoord + float2(pix.z, pix.y)),
                                ReShade::GetLinearizedDepth(texcoord + float2(pix.x, pix.y)),
                                ReShade::GetLinearizedDepth(texcoord + float2(pix.z, pix.w)) );
    
    //Normalize values
    float2 mind = float2(MIN4(depthEven), MIN4(depthOdd));
    float2 maxd = float2(MAX4(depthEven), MAX4(depthOdd));
    float span = MAX2(maxd) - MIN2(mind) + 0.00001;
    c /= span;
    depthEven /= span;
    depthOdd /= span;
    //Calculate the distance of the surrounding pixels to the center
    float4 diffsEven = abs(depthEven - c);
    float4 diffsOdd = abs(depthOdd - c);
    //Calculate the difference of the (opposing) distances
    float2 retVal = float2( max(abs(diffsEven.x - diffsEven.y), abs(diffsEven.z - diffsEven.w)),
                            max(abs(diffsOdd.x - diffsOdd.y), abs(diffsOdd.z - diffsOdd.w))     );

    float lineWeight = MAX2(retVal);

    return lineWeight;
}

float StrengthCurve(float3 fade, float depth) {
    float curveMin = smoothstep(0.0, 1.0 - fade.z, depth + (0.2 - 1.2 * fade.x));
    float curveMax = smoothstep(0.0, 1.0 - fade.z, 1.0 - depth + (1.2 * fade.y - 1.0));
    return curveMin * curveMax;
}

float3 DrawDebugCurve(float3 background, float2 texcoord, float value, float3 color, float curveDiv) {
    float p = exp(-(BUFFER_HEIGHT/curveDiv) * length(texcoord - float2(texcoord.x, 1.0 - value)));
    return lerp(background, color, saturate(p));
}

float GetEdges(sampler2D s, float2 texcoord, int2 vpos, int type, int kernel, int merge) {
    float edges;
    if(type == 0)
        edges = DiffEdges(s, vpos.xy);
    else
        edges = Tools::Convolution::Edges(s, vpos.xy, kernel, merge).r;

    return edges;
}

float GetSaturation(float3 color) {
    float maxVal = max(color.r, max(color.g, color.b));
    float minVal = min(color.r, min(color.g, color.b));         
    return maxVal - minVal;
}

/******************************************************************************
    Pixel Shader
******************************************************************************/

//Convolution gets currently done with samplers, so rendering to a texture is necessary
void LumaChroma_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float3 luma : SV_Target0, out float3 chroma : SV_Target1) {
    //static const float3 LumaCoeff = float3(0.2126, 0.7151, 0.0721);
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    luma = dot(color, LumaCoeff);
    chroma = color - luma;
}

float3 Sketch_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
    //static const float3 LumaCoeff = float3(0.2126, 0.7151, 0.0721);
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float luma = tex2Dfetch(SamplerSketchLuma, int4(vpos.xy, 0, 0)).r;
    float currentDepth = ReShade::GetLinearizedDepth(texcoord);
    
    float4 edges = 2.0 * float4(
                            fUILumaStrength   * GetEdges(SamplerSketchLuma, texcoord, vpos.xy, iUILumaEdgeType, iUILumaKernel, iUILumaMerge),
                            fUIChromaStrength * GetEdges(SamplerSketchChroma, texcoord, vpos.xy, iUIChromaEdgeType, iUIChromaKernel, iUIChromaMerge),
                            fUIDepthStrength  * DepthEdges(texcoord, fUIDepthBias).r,
                            fUIGridStrength   * MeshGrid(texcoord)
                        );

    float2 fadeAll =  float2(   
                                StrengthCurve(fUIEdgesLumaFading, luma.x),
                                StrengthCurve(fUIEdgesSaturationFading, GetSaturation(color))
                            );
    float3 fadeDist = float3(
                                StrengthCurve(fUIEdgesDistanceFading, currentDepth),
                                StrengthCurve(fUIOutlinesDistanceFading, currentDepth),
                                StrengthCurve(fUIGridDistanceFading, currentDepth)
                            );

    edges *= float4(fadeDist.xx, fadeDist.yz) * MIN2(fadeAll);

    float edgeLayer = MAX4(edges);

    float3 result = saturate(lerp(color, 0.0.rrr, edgeLayer * fUIStrength));

    if(iUIDebugMaps == 1)
        result = 1.0 - edges.xxx;
    else if(iUIDebugMaps == 2)
        result = 1.0 - edges.yyy;
    else if(iUIDebugMaps == 3)
        result = 1.0 - edges.zzz;
    else if(iUIDebugMaps == 4)
        result = 1.0 - edges.www;
    else if(iUIDebugMaps == 5)
        result = 1.0 - edgeLayer.rrr;
    else if(iUIDebugMaps == 6)
        result = luma;
    else if(iUIDebugMaps == 7)
        result = GetSaturation(color).rrr;

    if(bUIOverlayFadingCurves == 1) {
        result = DrawDebugCurve(result, texcoord, StrengthCurve(fUIOutlinesDistanceFading, texcoord.x), fUIDepthOutlinesCurveColor, fUICurveWidth);
        result = DrawDebugCurve(result, texcoord, StrengthCurve(fUIGridDistanceFading, texcoord.x), fUIGridCurveColor, fUICurveWidth);
        result = DrawDebugCurve(result, texcoord, StrengthCurve(fUIEdgesDistanceFading, texcoord.x), fUIEdgesCurveColor, fUICurveWidth);
        result = DrawDebugCurve(result, texcoord, StrengthCurve(fUIEdgesLumaFading, texcoord.x), fUILumaCurveColor, fUICurveWidth);
        result = DrawDebugCurve(result, texcoord, StrengthCurve(fUIEdgesSaturationFading, texcoord.x), fUISaturationCurveColor, fUICurveWidth);
    }

    return result;
}

technique Sketch
{
    pass {
        VertexShader = PostProcessVS;
        PixelShader = LumaChroma_PS;
        RenderTarget0 = texSketchLuma;
        RenderTarget1 = texSketchChroma;
    }
    pass {
        VertexShader = PostProcessVS;
        PixelShader = Sketch_PS;
    }
}
