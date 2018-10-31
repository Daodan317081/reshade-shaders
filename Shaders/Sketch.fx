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

#define UI_CATEGORY_LUMA "Edges: Luma"
#define UI_CATEGORY_CHROMA "Edges: Chroma"
#define UI_CATEGORY_OUTLINES "Edges: Outlines"
#define UI_CATEGORY_GRID "Edges: Grid"
#define UI_CATEGORY_MISC "Luma/Saturation Weight"
#define UI_CATEGORY_DEBUG "Debug"
#define UI_CATEGORY_EFFECT "Effect"

#define UI_EDGES_LABEL_ENABLE "Enable"
#define UI_EDGES_LABEL_DETAILS "Details"
#define UI_EDGES_LABEL_STRENGTH "Power, Slope"
#define UI_EDGES_LABEL_DISTANCE_STRENGTH "Distance Strength"
#define UI_EDGES_LABEL_DISTANCE_STRENGTH_TOOLTIP "x: Fade In\ny: Fade Out\nz: Slope"
#define UI_EDGES_LABEL_DEBUG "Add to Debug Layer"
//#define UI_EDGES_LABEL_ ""

#ifndef MAX2
#define MAX2(v) max(v.x, v.y)
#endif
#ifndef MIN2
#define MIN2(v) min(v.x, v.y)
#endif
#ifndef MAX3
#define MAX3(v) max(v.x, max(v.y, v.z))
#endif
#ifndef MIN3
#define MIN3(v) min(v.x, min(v.y, v.z))
#endif
#ifndef MAX4
#define MAX4(v) max(v.x, max(v.y, max(v.z, v.w)))
#endif
#ifndef MIN4
#define MIN4(v) min(v.x, min(v.y, min(v.z, v.w)))
#endif
#ifndef LumaCoeff
#define LumaCoeff float3(0.2126, 0.7151, 0.0721)
#endif
/******************************************************************************
    Uniforms
******************************************************************************/
uniform bool bUICheckDepthBuffer <
    ui_label = "Check Depth Buffer";
    ui_tooltip = "Near objects should be dark, far objects white.";
> = false;

////////////////////////// Luma //////////////////////////
uniform int iUILumaEdgeType <
    ui_type = "drag";
    ui_category = UI_CATEGORY_LUMA;
    ui_label = UI_EDGES_LABEL_ENABLE;
    ui_min = 0; ui_max = 3;
> = 1;

uniform float fUILumaDetails <
    ui_type = "drag";
    ui_category = UI_CATEGORY_LUMA;
    ui_label = UI_EDGES_LABEL_DETAILS;
    ui_tooltip = "Only for Type 1 & 2";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
> = 1.0;

uniform float2 fUILumaStrength <
    ui_type = "drag";
    ui_category = UI_CATEGORY_LUMA;
    ui_label = UI_EDGES_LABEL_STRENGTH;
    ui_min = 0.1; ui_max = 10.0;
    ui_step = 0.01;
> = float2(1.0, 1.0);

uniform float3 fUILumaEdgesDistanceFading<
    ui_type = "drag";
    ui_category = UI_CATEGORY_LUMA;
    ui_label = UI_EDGES_LABEL_DISTANCE_STRENGTH;
    ui_tooltip = UI_EDGES_LABEL_DISTANCE_STRENGTH_TOOLTIP;
    ui_min = -1.0; ui_max = 1.0;
    ui_step = 0.001;
> = float3(0.0, 1.0, 0.8);

uniform bool bUILumaEdgesDebugLayer <
    ui_label = UI_EDGES_LABEL_DEBUG;
    ui_category = UI_CATEGORY_LUMA;
> = true;

////////////////////////// Chroma //////////////////////////
uniform int iUIChromaEdgeType <
    ui_type = "drag";
    ui_category = UI_CATEGORY_CHROMA;
    ui_label = UI_EDGES_LABEL_ENABLE;
    ui_min = 0; ui_max = 3;
> = 0;

uniform float fUIChromaDetails <
    ui_type = "drag";
    ui_category = UI_CATEGORY_CHROMA;
    ui_label = UI_EDGES_LABEL_DETAILS;
    ui_tooltip = "Only for Type 1 & 2";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
> = 1.0;

uniform float2 fUIChromaStrength <
    ui_type = "drag";
    ui_category = UI_CATEGORY_CHROMA;
    ui_label = UI_EDGES_LABEL_STRENGTH;
    ui_min = 0.01; ui_max = 10.0;
    ui_step = 0.01;
> = float2(1.0, 1.0);

uniform float3 fUIChromaEdgesDistanceFading<
    ui_type = "drag";
    ui_category = UI_CATEGORY_CHROMA;
    ui_label = UI_EDGES_LABEL_DISTANCE_STRENGTH;
    ui_tooltip = UI_EDGES_LABEL_DISTANCE_STRENGTH_TOOLTIP;
    ui_min = -1.0; ui_max = 1.0;
    ui_step = 0.001;
> = float3(0.0, 1.0, 0.8);

uniform bool bUIChromaEdgesDebugLayer <
    ui_label = UI_EDGES_LABEL_DEBUG;
    ui_category = UI_CATEGORY_CHROMA;
> = true;

////////////////////////// Outlines //////////////////////////
uniform int iUIOutlinesEnable <
    ui_type = "drag";
    ui_category = UI_CATEGORY_OUTLINES;
    ui_label = UI_EDGES_LABEL_ENABLE;
    ui_tooltip = "-1: Disabled\00: Enabled";
    ui_min = 0; ui_max = 1;
    ui_step = 1;
> = 1;

uniform float2 fUIOutlinesStrength <
    ui_type = "drag";
    ui_category = UI_CATEGORY_OUTLINES;
    ui_label = UI_EDGES_LABEL_STRENGTH;
    ui_min = 0.01; ui_max = 10.0;
    ui_step = 0.01;
> = float2(1.0, 1.0);

uniform float3 fUIOutlinesDistanceFading<
    ui_type = "drag";
    ui_category = UI_CATEGORY_OUTLINES;
    ui_label = UI_EDGES_LABEL_DISTANCE_STRENGTH;
    ui_tooltip = UI_EDGES_LABEL_DISTANCE_STRENGTH_TOOLTIP;
    ui_min = -1.0; ui_max = 1.0;
    ui_step = 0.001;
> = float3(0.0, 1.0, 0.8);

uniform bool bUIOutlinesDebugLayer <
    ui_label = UI_EDGES_LABEL_DEBUG;
    ui_category = UI_CATEGORY_OUTLINES;
> = true;

////////////////////////// Grid //////////////////////////
uniform int iUIGridEnable <
    ui_type = "drag";
    ui_category = UI_CATEGORY_GRID;
    ui_label = UI_EDGES_LABEL_ENABLE;
    ui_tooltip = "-1: Disabled\00: Enabled";
    ui_min = 0; ui_max = 1;
    ui_step = 1;
> = 1;

uniform float2 fUIGridStrength <
    ui_type = "drag";
    ui_category = UI_CATEGORY_GRID;
    ui_label = UI_EDGES_LABEL_STRENGTH;
    ui_min = 0.01; ui_max = 10.0;
    ui_step = 0.01;
> = float2(1.0, 1.0);

uniform float3 fUIGridDistanceFading<
    ui_type = "drag";
    ui_category = UI_CATEGORY_GRID;
    ui_label = UI_EDGES_LABEL_DISTANCE_STRENGTH;
    ui_tooltip = UI_EDGES_LABEL_DISTANCE_STRENGTH_TOOLTIP;
    ui_min = -1.0; ui_max = 1.0;
    ui_step = 0.001;
> = float3(0.0, 0.1, 0.8);

uniform bool bUIGridDebugLayer <
    ui_label = UI_EDGES_LABEL_DEBUG;
    ui_category = UI_CATEGORY_GRID;
> = true;

////////////////////////// Misc //////////////////////////
uniform float3 fUIEdgesLumaFading <
    ui_type = "drag";
    ui_category = UI_CATEGORY_MISC;
    ui_label = "Luma";
    ui_tooltip = "Weight the sketch layer with the luma of the current pixel.\nx: Min Value\ny: Max Value\nz: Slope";
    ui_min = -1.0; ui_max = 1.0;
    ui_step = 0.001;
> = float3(0.0, 1.0, 0.8);

uniform float3 fUIEdgesSaturationFading <
    ui_type = "drag";
    ui_category = UI_CATEGORY_MISC;
    ui_label = "Saturation";
    ui_tooltip = "Weight the sketch layer with the saturation of the current pixel.\nx: Min Value\ny: Max Value\nz: Slope";
    ui_min = -1.0; ui_max = 1.0;
    ui_step = 0.001;
> = float3(0.0, 1.0, 0.8);

////////////////////////// Debug //////////////////////////

uniform bool bUIEnableDebugLayer <
    ui_label = "Enable Debug Layer";
    ui_category = UI_CATEGORY_DEBUG;
> = false;

uniform int iUIShowFadingOverlay <
    ui_type = "combo";
    ui_category = UI_CATEGORY_DEBUG;
    ui_label = "Show Strength Overlay";
    ui_items = "None\0Distance: Luma Edges\0Distance: Chroma Edges\0Distance: Outlines\0Distance: Grid\0Luma\0Saturation\0";
> = 0;

uniform float3 fUIOverlayColor<
    ui_type = "color";
    ui_category = UI_CATEGORY_DEBUG;
    ui_label = "Overlay Color";
> = float3(1.0, 0.0, 0.0);

////////////////////////// Effect //////////////////////////

uniform float3 fUIColor <
    ui_type = "color";
    ui_category = UI_CATEGORY_EFFECT;
    ui_label = "Color";
> = float3(0.0, 0.0, 0.0);

uniform float fUIStrength <
    ui_type = "drag";
    ui_category = UI_CATEGORY_EFFECT;
    ui_label = "Strength";
    ui_min = 0.0; ui_max = 1.0;
> = 1.0;

namespace Sketch {
    /******************************************************************************
        Textures
    ******************************************************************************/

    texture2D texSketchLuma { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
    sampler2D SamplerSketchLuma { Texture = texSketchLuma; };
    texture2D texSketchChroma { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
    sampler2D SamplerSketchChroma { Texture = texSketchChroma; };

    /******************************************************************************
        Functions
    ******************************************************************************/
    float DiffEdges(sampler s, int2 vpos) 
    {
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

    float3 Convolution(sampler s, int2 vpos, float kernel1[9], float kernel2[9], float weight, float divisor)
    {
        float3 acc;

        [unroll]
        for(int m = 0; m < 3; m++)
        {
            [unroll]
            for(int n = 0; n < 3; n++)
            {
                float k = lerp(kernel1[n + (m*3)], kernel2[n + (m*3)], weight);
                acc += k * tex2Dfetch(s, int4( (vpos.x - 1 + n), (vpos.y - 1 + m), 0, 0)).rgb;
            }
        }

        return acc / divisor;
    }

    float3 DepthEdges(float2 texcoord)
    {
        float retVal;
        float3 offset = float3(ReShade::PixelSize.xy, 0.0);
        float2 posCenter = texcoord.xy;
        float2 posNorth = posCenter - offset.zy;
        float2 posEast = posCenter + offset.xz;

        float3 vertCenter = float3(posCenter, ReShade::GetLinearizedDepth(posCenter));
        float3 vertNorth = float3(posNorth, ReShade::GetLinearizedDepth(posNorth));
        float3 vertEast = float3(posEast, ReShade::GetLinearizedDepth(posEast));
        
        float3 normalVector = normalize(cross(vertCenter - vertNorth, vertCenter - vertEast)) * 0.5 + 0.5;

        retVal = 1.0 - saturate(dot(float3(0.0, 0.0, 1.0), normalVector));
        
        return retVal.rrr;
    }

    float MeshGrid(float2 texcoord)
    {
        float4 pix = float4(ReShade::PixelSize, -ReShade::PixelSize);

        //Get depth of center pixel
        float c = ReShade::GetLinearizedDepth(texcoord);
        //Get depth of surrounding pixels
        float4 depthEven = float4(  
            ReShade::GetLinearizedDepth(texcoord + float2(0.0, pix.w)),
            ReShade::GetLinearizedDepth(texcoord + float2(0.0, pix.y)),
            ReShade::GetLinearizedDepth(texcoord + float2(pix.x, 0.0)),
            ReShade::GetLinearizedDepth(texcoord + float2(pix.z, 0.0))
        );

        float4 depthOdd  = float4(  
            ReShade::GetLinearizedDepth(texcoord + float2(pix.x, pix.w)),
            ReShade::GetLinearizedDepth(texcoord + float2(pix.z, pix.y)),
            ReShade::GetLinearizedDepth(texcoord + float2(pix.x, pix.y)),
            ReShade::GetLinearizedDepth(texcoord + float2(pix.z, pix.w))
        );
        
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
        float2 retVal = float2(
            max(abs(diffsEven.x - diffsEven.y), abs(diffsEven.z - diffsEven.w)),
            max(abs(diffsOdd.x - diffsOdd.y), abs(diffsOdd.z - diffsOdd.w))
        );

        float lineWeight = MAX2(retVal);

        return lineWeight;
    }

    float StrengthCurve(float3 fade, float depth)
    {
        float curveMin = smoothstep(0.0, 1.0 - fade.z, depth + (0.2 - 1.2 * fade.x));
        float curveMax = smoothstep(0.0, 1.0 - fade.z, 1.0 - depth + (1.2 * fade.y - 1.0));
        return curveMin * curveMax;
    }

    float3 DrawDebugCurve(float3 background, float2 texcoord, float value, float3 color, float curveDiv)
    {
        float p = exp(-(BUFFER_HEIGHT/curveDiv) * length(texcoord - float2(texcoord.x, 1.0 - value)));
        return lerp(background, color, saturate(p));
    }

    float GetEdges(sampler2D s, int2 vpos, int type, float detail)
    {
        float edges;
        if(type == 1)
        {
            edges = DiffEdges(s, vpos.xy);
        }
        else if(type > 1) {
            static const float Sobel_X[9]       = { 1.0,  0.0, -1.0,  2.0, 0.0, -2.0, 1.0,  0.0, -1.0};
            static const float Sobel_Y[9]       = { 1.0,  2.0,  1.0,  0.0, 0.0,  0.0,-1.0, -2.0, -1.0};
            static const float Sobel_X_M[9]     = {-1.0,  0.0,  1.0, -2.0, 0.0,  2.0,-1.0,  0.0,  1.0};
            static const float Sobel_Y_M[9]     = {-1.0, -2.0, -1.0,  0.0, 0.0,  0.0, 1.0,  2.0,  1.0};
            static const float Scharr_X[9]      = { 3.0,  0.0, -3.0, 10.0, 0.0,-10.0, 3.0,  0.0, -3.0};
            static const float Scharr_Y[9]      = { 3.0, 10.0,  3.0,  0.0, 0.0,  0.0,-3.0,-10.0, -3.0};
            static const float Scharr_X_M[9]    = {-3.0,  0.0,  3.0,-10.0, 0.0, 10.0,-3.0,  0.0,  3.0};
            static const float Scharr_Y_M[9]    = {-3.0,-10.0, -3.0,  0.0, 0.0,  0.0, 3.0, 10.0,  3.0};
            edges = Convolution(s, vpos.xy, Sobel_X, Scharr_X, detail, 1.0).r;
            edges = max(edges, Convolution(s, vpos.xy, Sobel_Y, Scharr_Y, detail, 1.0).r);
            if(type == 3) {
                edges = max(edges, Convolution(s, vpos.xy, Sobel_X_M, Scharr_X_M, detail, 1.0).r);
                edges = max(edges, Convolution(s, vpos.xy, Sobel_Y_M, Scharr_Y_M, detail, 1.0).r);
            }
        }

        return edges;
    }

    float GetSaturation(float3 color)
    {
        float maxVal = max(color.r, max(color.g, color.b));
        float minVal = min(color.r, min(color.g, color.b));         
        return maxVal - minVal;
    }

    /******************************************************************************
        Pixel Shader
    ******************************************************************************/

    //Convolution gets currently done with samplers, so rendering to a texture is necessary
    void LumaChroma_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float3 luma : SV_Target0, out float3 chroma : SV_Target1)
    {
        float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
        luma = dot(color, LumaCoeff);
        chroma = color - luma;
    }

    float3 Sketch_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
    {
        if(bUICheckDepthBuffer)
        {
            return ReShade::GetLinearizedDepth(texcoord);
        }

        //static const float3 LumaCoeff = float3(0.2126, 0.7151, 0.0721);
        float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
        float luma = tex2Dfetch(SamplerSketchLuma, int4(vpos.xy, 0, 0)).r;
        float currentDepth = ReShade::GetLinearizedDepth(texcoord);
        
        float4 edges = float4(
            pow(GetEdges(Sketch::SamplerSketchLuma, vpos.xy, iUILumaEdgeType, fUILumaDetails), fUILumaStrength.x) * fUILumaStrength.y,
            pow(GetEdges(Sketch::SamplerSketchChroma, vpos.xy, iUIChromaEdgeType, fUIChromaDetails), fUIChromaStrength.x) * fUIChromaStrength.y,
            iUIOutlinesEnable ? pow(DepthEdges(texcoord).r, fUIOutlinesStrength.x) * fUIOutlinesStrength.y : 0.0,
            iUIGridEnable ? pow(MeshGrid(texcoord), fUIGridStrength.x) * fUIGridStrength.y : 0.0
        );

        float2 fadeAll =  float2(   
            StrengthCurve(fUIEdgesLumaFading, luma.x),
            StrengthCurve(fUIEdgesSaturationFading, GetSaturation(color))
        );
        float4 fadeDist = float4(
            StrengthCurve(fUILumaEdgesDistanceFading, currentDepth),
            StrengthCurve(fUIChromaEdgesDistanceFading, currentDepth),
            StrengthCurve(fUIOutlinesDistanceFading, currentDepth),
            StrengthCurve(fUIGridDistanceFading, currentDepth)
        );

        edges *= fadeDist * MIN2(fadeAll);

        float edgeLayer = MAX4(edges);

        float3 result = saturate(lerp(color, fUIColor, edgeLayer * fUIStrength));

        float3 edgeDebugLayer = 0.0.rrr;
        if(bUIEnableDebugLayer)
        {
            if(bUILumaEdgesDebugLayer)
            {
                edgeDebugLayer = max(edgeDebugLayer, edges.x).rrr;
            }
            if(bUIChromaEdgesDebugLayer)
            {
                edgeDebugLayer = max(edgeDebugLayer, edges.y).rrr;
            }
            if(bUIOutlinesDebugLayer)
            {
                edgeDebugLayer = max(edgeDebugLayer, edges.z).rrr;
            }
            if(bUIGridDebugLayer)
            {
                edgeDebugLayer = max(edgeDebugLayer, edges.w).rrr;
            }
            if(iUIShowFadingOverlay != 0)
            {
                if(iUIShowFadingOverlay == 1)
                    edgeDebugLayer = lerp(fUIOverlayColor, edgeDebugLayer.rrr, fadeDist.x);
                else if(iUIShowFadingOverlay == 2)
                    edgeDebugLayer = lerp(fUIOverlayColor, edgeDebugLayer.rrr, fadeDist.y);
                else if(iUIShowFadingOverlay == 3)
                    edgeDebugLayer = lerp(fUIOverlayColor, edgeDebugLayer.rrr, fadeDist.z);
                else if(iUIShowFadingOverlay == 4)
                    edgeDebugLayer = lerp(fUIOverlayColor, edgeDebugLayer.rrr, fadeDist.w);
                else if(iUIShowFadingOverlay == 5)
                    edgeDebugLayer = lerp(fUIOverlayColor, edgeDebugLayer.rrr, fadeAll.x);
                else if(iUIShowFadingOverlay == 6)
                    edgeDebugLayer = lerp(fUIOverlayColor, edgeDebugLayer.rrr, fadeAll.y);
            }
            return edgeDebugLayer;
        }

        return result;
    }
}

technique Sketch
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = Sketch::LumaChroma_PS;
        RenderTarget0 = Sketch::texSketchLuma;
        RenderTarget1 = Sketch::texSketchChroma;
    }
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = Sketch::Sketch_PS;
    }
}
