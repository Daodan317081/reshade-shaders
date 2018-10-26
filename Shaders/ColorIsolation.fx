///////////////////////////////////////////////////////////////////////////////
//
//ReShade Shader: ColorIsolation
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

#define COLORISOLATION_CATEGORY_SETUP "Setup"
#define COLORISOLATION_CATEGORY_DEBUG "Debug"

uniform float fUITargetHue<
    ui_type = "drag";
    ui_category = COLORISOLATION_CATEGORY_SETUP;
    ui_label = "Target Hue";
    ui_tooltip = "Set the desired hue from 0 - 360";
    ui_min = 0.0; ui_max = 360.0; ui_step = 0.5;
> = 0.0;

uniform int cUIWindowFunction<
    ui_type = "combo";
    ui_category = COLORISOLATION_CATEGORY_SETUP;
    ui_label = "Window Function";
    ui_items = "Gauss\0Triangle\0";
> = 0;

uniform float fUIOverlap<
    ui_type = "drag";
    ui_category = COLORISOLATION_CATEGORY_SETUP;
    ui_label = "Hue Overlap";
    ui_tooltip = "Changes the width of the gaussian curve\nto include less or more colors in relation\nto the target hue.\n";
    ui_min = 0.001; ui_max = 2.0;
    ui_step = 0.001;
> = 0.3;

uniform float fUIWindowHeight<
    ui_type = "drag";
    ui_category = COLORISOLATION_CATEGORY_SETUP;
    ui_label = "Curve Steepness";
    ui_min = 0.0; ui_max = 10.0;
    ui_step = 0.01;
> = 1.0;

uniform int cUIType<
    ui_type = "combo";
    ui_category = COLORISOLATION_CATEGORY_SETUP;
    ui_label = "Isolate / Reject Hue";
    ui_items = "Isolate\0Reject\0";
> = 0;

uniform bool bUIShowDiff <
    ui_category = COLORISOLATION_CATEGORY_DEBUG;
    ui_label = "Show Hue Difference";
> = false;

uniform int2 iUIOverlayPosition <
    ui_type = "drag";
    ui_category = COLORISOLATION_CATEGORY_DEBUG;
    ui_label = "Overlay Position";
    ui_min = 0; ui_max = BUFFER_WIDTH;
    ui_step = 1;
> = int2(0, 0);

uniform float iUIOverlayOpacity <
    ui_type = "drag";
    ui_category = COLORISOLATION_CATEGORY_DEBUG;
    ui_label = "Overlay Opacity";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
> = 1.0;

texture2D texColorIsolationOverlay { Width = BUFFER_WIDTH/2; Height = BUFFER_HEIGHT/6; Format = RGBA8; };
sampler2D sColorIsolationOverlay { Texture = texColorIsolationOverlay; };

float3 DrawTexture(float3 image, sampler overlay, float2 texcoord, int2 offset, float opacity) {
    float3 retVal;
    float3 col = image;
    float fac = 0.0;

    float2 screencoord = float2(BUFFER_WIDTH, BUFFER_HEIGHT) * texcoord;
    float2 overlay_size = (float2)tex2Dsize(overlay, 0);
    offset.x = clamp(offset.x, 0, BUFFER_WIDTH - overlay_size.x);
    offset.y = clamp(offset.y, 0, BUFFER_HEIGHT - overlay_size.y);
    float2 border_min = (float2)offset;
    float2 border_max = border_min + overlay_size;

    if( screencoord.x <= border_max.x &&
        screencoord.y <= border_max.y &&
        screencoord.x >= border_min.x &&
        screencoord.y >= border_min.y   ) {
            fac = opacity;
            float2 coord_overlay = (screencoord - border_min) / overlay_size;
            col = tex2D(overlay, coord_overlay).rgb;
    }

    return lerp(image, col, fac);
}

//These RGB/HSV conversion functions are based on the blogpost from:
//http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
float3 RGBtoHSV(float3 c) {
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = c.g < c.b ? float4(c.bg, K.wz) : float4(c.gb, K.xy);
    float4 q = c.r < p.x ? float4(p.xyw, c.r) : float4(c.r, p.yzx);

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 HSVtoRGB(float3 c) {
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
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
    float value = CalculateValue(RGBtoHSV(color).x, fUIWindowHeight, fUITargetHue / 360.0, fUIOverlap);
    if(bUIShowDiff)
        return value.rrr;
    return lerp(luma, color, value);
}

float3 DrawOverlayPS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
    float value = CalculateValue(texcoord.x, fUIWindowHeight, fUITargetHue / 360.0, fUIOverlap);
    float3 hsvStrip = HSVtoRGB(float3(texcoord.x, 1.0, 1.0));
    float3 luma = dot(hsvStrip, float3(0.2126, 0.7151, 0.0721));
    float3 color = lerp(luma, hsvStrip, value);
    color = lerp(color, 0.0.rrr, exp(-BUFFER_HEIGHT/6 * length(float2(texcoord.x, 1.0 - texcoord.y) - float2(texcoord.x, value))));
    return color;
}

float3 DrawTexturePS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
    float3 backbuffer = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float3 overlay = backbuffer;
    float fac = 0.0;

    float2 overlay_size = (float2)tex2Dsize(sColorIsolationOverlay, 0);
    int2 offset;
    offset.x = clamp(iUIOverlayPosition.x, 0, BUFFER_WIDTH - overlay_size.x);
    offset.y = clamp(iUIOverlayPosition.y, 0, BUFFER_HEIGHT - overlay_size.y);
    float2 border_min = (float2)offset;
    float2 border_max = border_min + overlay_size;

    float2 screencoord = float2(BUFFER_WIDTH, BUFFER_HEIGHT) * texcoord;
    if( screencoord.x <= border_max.x &&
        screencoord.y <= border_max.y &&
        screencoord.x >= border_min.x &&
        screencoord.y >= border_min.y   ) {
            fac = iUIOverlayOpacity;
            float2 coord_overlay = (screencoord - border_min) / overlay_size;
            overlay = tex2D(sColorIsolationOverlay, coord_overlay).rgb;
    }

    return lerp(backbuffer, overlay, fac);
}

technique ColorIsolation {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = ColorIsolationPS;
        /* RenderTarget = BackBuffer */
    }
}

technique ColorIsolationDebug {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = DrawOverlayPS;
        RenderTarget = texColorIsolationOverlay;
    }
    pass {
        VertexShader = PostProcessVS;
        PixelShader = DrawTexturePS;
    }
}