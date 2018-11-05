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

#define UI_CATEGORY_COLOR "Edges: Color"
#define UI_CATEGORY_CHROMA "Edges: Chroma"
#define UI_CATEGORY_OUTLINES "Outlines 1"
#define UI_CATEGORY_MESH_EDGES "Outlines 2 (Mesh Edges)"
#define UI_CATEGORY_MISC "Luma/Saturation Weight"
#define UI_CATEGORY_DEBUG "Debug"
#define UI_CATEGORY_EFFECT "Effect"

#define UI_EDGES_LABEL_ENABLE "Enable"
#define UI_EDGES_LABEL_DETAILS "Details"
#define UI_EDGES_LABEL_STRENGTH "Power, Slope"
#define UI_EDGES_LABEL_DISTANCE_STRENGTH "Distance Strength"
#define UI_EDGES_LABEL_DEBUG "Add to Debug Layer"

#define UI_EDGES_TOOLTIP_ENABLE "0: Disabled\n1: Value Difference\n2: Single Pass Convolution\n3: Two Pass Convolution"
#define UI_EDGES_TOOLTIP_DISTANCE_STRENGTH "x: Fade In\ny: Fade Out\nz: Slope"
#define UI_EDGES_TOOLTIP_WEIGHTS "x: Min\ny: Max\nz: Slope"
#define UI_EDGES_TOOLTIP_DETAILS "Only for Convolution"


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
////////////////////////// Color //////////////////////////
uniform int iUIColorEdgesType <
    ui_type = "drag";
    ui_tooltip = UI_EDGES_TOOLTIP_ENABLE;
    ui_category = UI_CATEGORY_COLOR;
    ui_label = UI_EDGES_LABEL_ENABLE;
    ui_min = 0; ui_max = 3;
> = 1;

uniform float fUIColorEdgesDetails <
    ui_type = "drag";
    ui_category = UI_CATEGORY_COLOR;
    ui_label = UI_EDGES_LABEL_DETAILS;
    ui_tooltip = UI_EDGES_TOOLTIP_DETAILS;
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
> = 1.0;

uniform float2 fUIColorEdgesStrength <
    ui_type = "drag";
    ui_category = UI_CATEGORY_COLOR;
    ui_label = UI_EDGES_LABEL_STRENGTH;
    ui_min = 0.1; ui_max = 10.0;
    ui_step = 0.01;
> = float2(1.0, 1.0);

uniform float3 fUIColorEdgesDistanceFading<
    ui_type = "drag";
    ui_category = UI_CATEGORY_COLOR;
    ui_label = UI_EDGES_LABEL_DISTANCE_STRENGTH;
    ui_tooltip = UI_EDGES_TOOLTIP_DISTANCE_STRENGTH;
    ui_min = -1.0; ui_max = 1.0;
    ui_step = 0.001;
> = float3(0.0, 1.0, 0.8);

uniform bool bUIColorEdgesDebugLayer <
    ui_label = UI_EDGES_LABEL_DEBUG;
    ui_category = UI_CATEGORY_COLOR;
> = true;

////////////////////////// Chroma //////////////////////////
uniform int iUIChromaEdgesType <
    ui_type = "drag";
    ui_tooltip = UI_EDGES_TOOLTIP_ENABLE;
    ui_category = UI_CATEGORY_CHROMA;
    ui_label = UI_EDGES_LABEL_ENABLE;
    ui_min = 0; ui_max = 3;
> = 3;

uniform float fUIChromaEdgesDetails <
    ui_type = "drag";
    ui_category = UI_CATEGORY_CHROMA;
    ui_label = UI_EDGES_LABEL_DETAILS;
    ui_tooltip = UI_EDGES_TOOLTIP_DETAILS;
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
> = 0.0;

uniform float2 fUIChromaEdgesStrength <
    ui_type = "drag";
    ui_category = UI_CATEGORY_CHROMA;
    ui_label = UI_EDGES_LABEL_STRENGTH;
    ui_min = 0.01; ui_max = 10.0;
    ui_step = 0.01;
> = float2(1.0, 0.5);

uniform float3 fUIChromaEdgesDistanceFading<
    ui_type = "drag";
    ui_category = UI_CATEGORY_CHROMA;
    ui_label = UI_EDGES_LABEL_DISTANCE_STRENGTH;
    ui_tooltip = UI_EDGES_TOOLTIP_DISTANCE_STRENGTH;
    ui_min = -1.0; ui_max = 1.0;
    ui_step = 0.001;
> = float3(0.0, 0.5, 0.8);

uniform bool bUIChromaEdgesDebugLayer <
    ui_label = UI_EDGES_LABEL_DEBUG;
    ui_category = UI_CATEGORY_CHROMA;
> = true;

////////////////////////// Outlines //////////////////////////
uniform int iUIOutlinesEnable <
    ui_type = "drag";
    ui_category = UI_CATEGORY_OUTLINES;
    ui_label = UI_EDGES_LABEL_ENABLE;
    ui_tooltip = "0: Disabled\n1: Enabled";
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
    ui_tooltip = UI_EDGES_TOOLTIP_DISTANCE_STRENGTH;
    ui_min = -1.0; ui_max = 1.0;
    ui_step = 0.001;
> = float3(0.0, 1.0, 0.8);

uniform bool bUIOutlinesDebugLayer <
    ui_label = UI_EDGES_LABEL_DEBUG;
    ui_category = UI_CATEGORY_OUTLINES;
> = true;

////////////////////////// Mesh Edges //////////////////////////
uniform int iUIMeshEdgesEnable <
    ui_type = "drag";
    ui_category = UI_CATEGORY_MESH_EDGES;
    ui_label = UI_EDGES_LABEL_ENABLE;
    ui_tooltip = "0: Disabled\n1: Enabled";
    ui_min = 0; ui_max = 1;
    ui_step = 1;
> = 1;

uniform float2 fUIMeshEdgesStrength <
    ui_type = "drag";
    ui_category = UI_CATEGORY_MESH_EDGES;
    ui_label = UI_EDGES_LABEL_STRENGTH;
    ui_min = 0.01; ui_max = 10.0;
    ui_step = 0.01;
> = float2(3.0, 3.0);

uniform float3 fUIMeshEdgesDistanceFading<
    ui_type = "drag";
    ui_category = UI_CATEGORY_MESH_EDGES;
    ui_label = UI_EDGES_LABEL_DISTANCE_STRENGTH;
    ui_tooltip = UI_EDGES_TOOLTIP_DISTANCE_STRENGTH;
    ui_min = -1.0; ui_max = 1.0;
    ui_step = 0.001;
> = float3(-1.0, 0.1, 0.8);

uniform bool bUIMeshEdgesDebugLayer <
    ui_label = UI_EDGES_LABEL_DEBUG;
    ui_category = UI_CATEGORY_MESH_EDGES;
> = true;

////////////////////////// Misc //////////////////////////
uniform float3 fUIEdgesLumaWeight <
    ui_type = "drag";
    ui_category = UI_CATEGORY_MISC;
    ui_label = "Luma";
    ui_tooltip = UI_EDGES_TOOLTIP_WEIGHTS;
    ui_min = -1.0; ui_max = 1.0;
    ui_step = 0.001;
> = float3(0.0, 1.0, 0.8);

uniform float3 fUIEdgesSaturationWeight <
    ui_type = "drag";
    ui_category = UI_CATEGORY_MISC;
    ui_label = "Saturation";
    ui_tooltip = UI_EDGES_TOOLTIP_WEIGHTS;
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
    ui_label = "Weight Overlay";
    ui_items = "None\0Luma Edges\0Chroma Edges\0Outlines\0Mesh Edges\0Luma\0Saturation\0";
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

/******************************************************************************
    Textures
******************************************************************************/
namespace Comic {
    /******************************************************************************
        Functions
    ******************************************************************************/
    float4 EdgeDetection(sampler s, int2 vpos, float2 texcoord, int luma_type, float luma_detail, int chroma_type, float chroma_detail, int outlines_enable, int mesh_edges_enable) {
        static const float4 Sobel_X1       = float4(  0.0, -1.0, -2.0, -1.0);
        static const float4 Sobel_X2       = float4(  0.0,  1.0,  2.0,  1.0);
        static const float4 Sobel_Y1       = float4(  2.0,  1.0,  0.0, -1.0);
        static const float4 Sobel_Y2       = float4( -2.0, -1.0,  0.0,  1.0);
        static const float4 Sobel_X_M1     = float4(  0.0,  1.0,  2.0,  1.0);
        static const float4 Sobel_X_M2     = float4(  0.0, -1.0, -2.0, -1.0);
        static const float4 Sobel_Y_M1     = float4( -2.0, -1.0,  0.0,  1.0);
        static const float4 Sobel_Y_M2     = float4(  2.0,  1.0,  0.0, -1.0);
        static const float4 Scharr_X1      = float4(  0.0, -3.0,-10.0, -3.0);
        static const float4 Scharr_X2      = float4(  0.0,  3.0, 10.0,  3.0);
        static const float4 Scharr_Y1      = float4( 10.0,  3.0,  0.0, -3.0);
        static const float4 Scharr_Y2      = float4(-10.0, -3.0,  0.0,  3.0);
        static const float4 Scharr_X_M1    = float4(  0.0,  3.0, 10.0,  3.0);
        static const float4 Scharr_X_M2    = float4(  0.0, -3.0,-10.0, -3.0);
        static const float4 Scharr_Y_M1    = float4(-10.0, -3.0,  0.0,  3.0);
        static const float4 Scharr_Y_M2    = float4(-10.0,  3.0,  0.0, -3.0);

        float4 retVal;

        float3 colorC = tex2Dfetch(s, int4(vpos, 0, 0)).rgb;//C
        float3 color1[4] = {
            tex2Dfetch(s, int4(vpos + int2( 0, -1), 0, 0)).rgb,//N
            tex2Dfetch(s, int4(vpos + int2( 1, -1), 0, 0)).rgb,//NE
            tex2Dfetch(s, int4(vpos + int2( 1,  0), 0, 0)).rgb,//E
            tex2Dfetch(s, int4(vpos + int2( 1,  1), 0, 0)).rgb,//SE
        };
        float3 color2[4] = {    
            tex2Dfetch(s, int4(vpos + int2( 0,  1), 0, 0)).rgb,//S
            tex2Dfetch(s, int4(vpos + int2(-1,  1), 0, 0)).rgb,//SW
            tex2Dfetch(s, int4(vpos + int2(-1,  0), 0, 0)).rgb, //W
            tex2Dfetch(s, int4(vpos + int2(-1, -1), 0, 0)).rgb //NW
        };

        float lumaC = dot(colorC, LumaCoeff);
        float4 luma1 = float4(
            dot(color1[0], LumaCoeff),
            dot(color1[1], LumaCoeff),
            dot(color1[2], LumaCoeff),
            dot(color1[3], LumaCoeff)
        );
        float4 luma2 = float4(
            dot(color2[0], LumaCoeff),
            dot(color2[1], LumaCoeff),
            dot(color2[2], LumaCoeff),
            dot(color2[3], LumaCoeff)
        );

        float chromaVC = dot(colorC - lumaC.xxx, LumaCoeff);
        float4 chromaV1 = float4(
            MAX3((color1[0] - luma1.xxx)),
            MAX3((color1[1] - luma1.yyy)),
            MAX3((color1[2] - luma1.zzz)),
            MAX3((color1[3] - luma1.www))
        );
        float4 chromaV2 = float4(
            MAX3((color2[0] - luma2.xxx)),
            MAX3((color2[1] - luma2.yyy)),
            MAX3((color2[2] - luma2.zzz)),
            MAX3((color2[3] - luma2.www))
        );

        float2 pix = ReShade::PixelSize;
        float depthC = ReShade::GetLinearizedDepth(texcoord);//C
        float4 depth1 = float4(
            ReShade::GetLinearizedDepth(texcoord + float2(   0.0, -pix.y)),//N
            ReShade::GetLinearizedDepth(texcoord + float2( pix.x, -pix.y)),//NE
            ReShade::GetLinearizedDepth(texcoord + float2( pix.x,    0.0)),//E
            ReShade::GetLinearizedDepth(texcoord + float2( pix.x,  pix.y))//SE
        );
        float4 depth2  = float4(
            ReShade::GetLinearizedDepth(texcoord + float2(   0.0,  pix.y)),//S
            ReShade::GetLinearizedDepth(texcoord + float2(-pix.x,  pix.y)),//SW
            ReShade::GetLinearizedDepth(texcoord + float2(-pix.x,    0.0)), //W
            ReShade::GetLinearizedDepth(texcoord + float2(-pix.x, -pix.y)) //NW
        );

        if(luma_type == 1)
        {
            float4 diffsLuma = abs(luma1 - luma2);
            retVal.x = (diffsLuma.x + diffsLuma.y + diffsLuma.z + diffsLuma.w) * (1.0 - lumaC);
        }
        else if(luma_type > 1)
        {
            float4 cX1 = luma1 * lerp(Sobel_X1, Scharr_X1, luma_detail);
            float4 cX2 = luma2 * lerp(Sobel_X2, Scharr_X2, luma_detail);
            float  cX  = cX1.x + cX1.y + cX1.z + cX1.w + cX2.x + cX2.y + cX2.z + cX2.w;
            float4 cY1 = luma1 * lerp(Sobel_Y1, Scharr_Y1, luma_detail);
            float4 cY2 = luma2 * lerp(Sobel_Y2, Scharr_Y2, luma_detail);
            float  cY  = cY1.x + cY1.y + cY1.z + cY1.w + cY2.x + cY2.y + cY2.z + cY2.w;
            retVal.x = max(cX, cY);
            if(luma_type == 3)
            {
                float4 cX1 = luma1 * lerp(Sobel_X_M1, Scharr_X_M1, luma_detail);
                float4 cX2 = luma2 * lerp(Sobel_X_M2, Scharr_X_M2, luma_detail);
                float  cX  = cX1.x + cX1.y + cX1.z + cX1.w + cX2.x + cX2.y + cX2.z + cX2.w;
                float4 cY1 = luma1 * lerp(Sobel_Y_M1, Scharr_Y_M1, luma_detail);
                float4 cY2 = luma2 * lerp(Sobel_Y_M2, Scharr_Y_M2, luma_detail);
                float  cY  = cY1.x + cY1.y + cY1.z + cY1.w + cY2.x + cY2.y + cY2.z + cY2.w;
                retVal.x = max(retVal.x, max(cX, cY));
            }
        }

        if(chroma_type == 1)
        {
            float4 diffsChromaLuma = abs(chromaV1 - chromaV2);
            retVal.y = (diffsChromaLuma.x + diffsChromaLuma.y + diffsChromaLuma.z + diffsChromaLuma.w) * (1.0 - chromaVC);
        }
        else if(chroma_type > 1)
        {
            float4 cX1 = chromaV1 * lerp(Sobel_X1, Scharr_X1, chroma_detail);
            float4 cX2 = chromaV2 * lerp(Sobel_X2, Scharr_X2, chroma_detail);
            float  cX  = cX1.x + cX1.y + cX1.z + cX1.w + cX2.x + cX2.y + cX2.z + cX2.w;
            float4 cY1 = chromaV1 * lerp(Sobel_Y1, Scharr_Y1, chroma_detail);
            float4 cY2 = chromaV2 * lerp(Sobel_Y2, Scharr_Y2, chroma_detail);
            float  cY  = cY1.x + cY1.y + cY1.z + cY1.w + cY2.x + cY2.y + cY2.z + cY2.w;
            retVal.y = max(cX, cY);
            if(chroma_type == 3)
            {
                float4 cX1 = chromaV1 * lerp(Sobel_X_M1, Scharr_X_M1, luma_detail);
                float4 cX2 = chromaV2 * lerp(Sobel_X_M1, Scharr_X_M2, luma_detail);
                float  cX  = cX1.x + cX1.y + cX1.z + cX1.w + cX2.x + cX2.y + cX2.z + cX2.w;
                float4 cY1 = chromaV1 * lerp(Sobel_Y_M1, Scharr_Y_M1, luma_detail);
                float4 cY2 = chromaV2 * lerp(Sobel_Y_M1, Scharr_Y_M2, luma_detail);
                float  cY  = cY1.x + cY1.y + cY1.z + cY1.w + cY2.x + cY2.y + cY2.z + cY2.w;
                retVal.y = max(retVal.y, max(cX, cY));
            }
        }

        if(outlines_enable)
        {
            float3 vertCenter = float3(texcoord, depthC);
            float3 vertNorth = float3(texcoord + float2(0.0, -pix.y), depth1.x);
            float3 vertEast = float3(texcoord + float2(pix.x, 0.0), depth1.z);
            retVal.z = 1.0 - saturate(dot(float3(0.0, 0.0, 1.0), normalize(cross(vertCenter - vertNorth, vertCenter - vertEast)) * 0.5 + 0.5));
        }

        if(mesh_edges_enable)
        {
            float2 mind = float2(MIN4(depth1), MIN4(depth2));
            float2 maxd = float2(MAX4(depth1), MAX4(depth2));
            float span = MAX2(maxd) - MIN2(mind) + 0.00001;

            float depthCenter = depthC;
            float4 depthCardinal = float4(depth1.x, depth2.x, depth1.z, depth2.z);
            float4 depthInterCardinal = float4(depth1.y, depth2.y, depth1.w, depth2.w);

            depthCenter /= span;
            depthCardinal /= span;
            depthInterCardinal /= span;
            //Calculate the distance of the surrounding pixels to the center
            float4 diffsCardinal = abs(depthCardinal - depthCenter);
            float4 diffsInterCardinal = abs(depthInterCardinal - depthCenter);
            //Calculate the difference of the (opposing) distances
            float2 meshEdge = float2(
                max(abs(diffsCardinal.x - diffsCardinal.y), abs(diffsCardinal.z - diffsCardinal.w)),
                max(abs(diffsInterCardinal.x - diffsInterCardinal.y), abs(diffsInterCardinal.z - diffsInterCardinal.w))
            );

            retVal.w = MAX2(meshEdge);
        }

        return saturate(retVal);
    }

    float StrengthCurve(float3 fade, float depth) {
        float curveMin = smoothstep(0.0, 1.0 - fade.z, depth + (0.2 - 1.2 * fade.x));
        float curveMax = smoothstep(0.0, 1.0 - fade.z, 1.0 - depth + (1.2 * fade.y - 1.0));
        return curveMin * curveMax;
    }

    /******************************************************************************
        Pixel Shader
    ******************************************************************************/
    float3 Sketch_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
        float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
        float currentDepth = ReShade::GetLinearizedDepth(texcoord);
        float4 edges = EdgeDetection(ReShade::BackBuffer, 
                                     vpos.xy,
                                     texcoord,
                                     iUIColorEdgesType,
                                     fUIColorEdgesDetails,
                                     iUIChromaEdgesType,
                                     fUIChromaEdgesDetails,
                                     iUIOutlinesEnable,
                                     iUIMeshEdgesEnable);
        
        edges = float4(
            pow(edges.x, fUIColorEdgesStrength.x) * fUIColorEdgesStrength.y,
            pow(edges.y, fUIChromaEdgesStrength.x) * fUIChromaEdgesStrength.y,
            pow(edges.z, fUIOutlinesStrength.x) * fUIOutlinesStrength.y,
            pow(edges.w, fUIMeshEdgesStrength.x) * fUIMeshEdgesStrength.y
        );
        

        float2 fadeAll =  float2(   
            StrengthCurve(fUIEdgesLumaWeight, dot(color, LumaCoeff)),
            StrengthCurve(fUIEdgesSaturationWeight, MAX3(color) - MIN3(color))
        );
        float4 fadeDist = float4(
            StrengthCurve(fUIColorEdgesDistanceFading, currentDepth),
            StrengthCurve(fUIChromaEdgesDistanceFading, currentDepth),
            StrengthCurve(fUIOutlinesDistanceFading, currentDepth),
            StrengthCurve(fUIMeshEdgesDistanceFading, currentDepth)
        );

        edges *= fadeDist * MIN2(fadeAll);
        
        float3 result = saturate(lerp(color, fUIColor, MAX4(edges) * fUIStrength));

        float3 edgeDebugLayer = 0.0.rrr;
        if(bUIEnableDebugLayer) {
            if(bUIColorEdgesDebugLayer) {
                edgeDebugLayer = max(edgeDebugLayer, edges.x).rrr;
            }
            if(bUIChromaEdgesDebugLayer) {
                edgeDebugLayer = max(edgeDebugLayer, edges.y).rrr;
            }
            if(bUIOutlinesDebugLayer) {
                edgeDebugLayer = max(edgeDebugLayer, edges.z).rrr;
            }
            if(bUIMeshEdgesDebugLayer) {
                edgeDebugLayer = max(edgeDebugLayer, edges.w).rrr;
            }
            if(iUIShowFadingOverlay != 0) {
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

technique Comic
{
    pass {
        VertexShader = PostProcessVS;
        PixelShader = Comic::Sketch_PS;
    }
}
