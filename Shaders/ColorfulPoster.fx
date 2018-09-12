///////////////////////////////////////////////////////////////////////////////
//
//ReShade Shader: ColorfulPoster
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

#define UI_CATEGORY_POSTERIZATION "Posterization"
#define UI_CATEGORY_PENCIL "Pencil Layer"
#define UI_CATEGORY_COLOR "Color"
#define UI_CATEGORY_DEBUG "Debug"
#define UI_CATEGORY_EFFECT "Effect"

/******************************************************************************
	Uniforms
******************************************************************************/

////////////////////////// Posterization //////////////////////////
uniform int iUILumaLevels <
	ui_type = "drag";
	ui_category = UI_CATEGORY_POSTERIZATION;
	ui_label = "Luma Posterize Levels";
	ui_min = 1; ui_max = 20;
> = 8;

uniform int iUIStepType <
	ui_type = "combo";
	ui_category = UI_CATEGORY_POSTERIZATION;
	ui_label = "Curve Type";
	ui_items = "Linear\0Smoothstep\0Logistic\0";
> = 2;

uniform float fUIStepContinuity <
	ui_type = "drag";
	ui_category = UI_CATEGORY_POSTERIZATION;
	ui_label = "Continuity";
	ui_tooltip = "Broken up <-> Connected";
	ui_min = 0.0; ui_max = 1.0;
	ui_step = 0.01;
> = 1.0;

uniform float fUISlope <
	ui_type = "drag";
	ui_category = UI_CATEGORY_POSTERIZATION;
	ui_label = "Slope Logistic Curve";
	ui_min = 0.0; ui_max = 40.0;
	ui_step = 0.1;
> = 10.0;

uniform bool iUIDebugOverlayPosterizeLevels <
	ui_category = UI_CATEGORY_POSTERIZATION;
	ui_label = "Show Posterization as Curve";
> = 0;

////////////////////////// Pencil Layer //////////////////////////

uniform float3 fUIDepthOutlines <
	ui_type = "drag";
	ui_category = UI_CATEGORY_PENCIL;
	ui_label = "Depth Outlines";
	ui_tooltip = "x:Strength\ny:Fade Out Start\nz:Fade Out End";
	ui_min = 0.0; ui_max = 1.0;
> = float3(1.0, 0.0, 1.0);

//Edge Detection
uniform float fUILumaEdges <
	ui_type = "drag";
	ui_category = UI_CATEGORY_PENCIL;
	ui_label = "Luma Edges Strength";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;

uniform float fUIChromaEdges <
	ui_type = "drag";
	ui_category = UI_CATEGORY_PENCIL;
	ui_label = "Chroma Edges Strength";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;

////////////////////////// Color //////////////////////////

uniform float fUITint <
	ui_type = "drag";
	ui_category = UI_CATEGORY_COLOR;
	ui_label = "Tint Strength";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;

uniform float3 fUILineColor <
	ui_type = "color";
	ui_category = UI_CATEGORY_COLOR;
	ui_label = "Line Color";
> = float3(0.0, 0.0, 0.0);

////////////////////////// Debug //////////////////////////

uniform int iUIDebugMaps <
	ui_type = "combo";
	ui_category = UI_CATEGORY_DEBUG;
	ui_label = "Show Debug Maps";
	ui_items = "Off\0Posterized Luma\0Depth Buffer Outlines\0Luma Edges\0Chroma Edges\0Pencil Layer\0Show Depth Buffer\0Show Chroma Layer\0";
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

texture2D texColorfulPosterChroma { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler2D SamplerColorfulPosterChroma { Texture = texColorfulPosterChroma; };
texture2D texColorfulPosterLuma { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler2D SamplerColorfulPosterLuma { Texture = texColorfulPosterLuma; };

/******************************************************************************
	Functions
******************************************************************************/

#define MAX_VALUE(v) max(v.x, max(v.y, v.z))

float DiffEdges(sampler s, int2 vpos) {
	static const float3 LumaCoeff = float3(0.2126, 0.7151, 0.0721);
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

float ConvEdges(sampler s, int2 vpos) {
	static const float sobelX[9] = { 1.0,  0.0, -1.0, 2.0, 0.0, -2.0, 1.0,  0.0, -1.0 };
	static const float sobelY[9] = { 1.0,  2.0,  1.0, 0.0,  0.0,  0.0, -1.0, -2.0, -1.0 };
	static const float sobelXM[9] = { -1.0,  0.0, 1.0, -2.0,  0.0, 2.0, -1.0,  0.0, 1.0 };
	static const float sobelYM[9] = { -1.0, -2.0, -1.0, 0.0,  0.0,  0.0, 1.0,  2.0,  1.0 };
	float4 acc = 0.0.rrrr;

	[unroll]
	for(int m = 0; m < 3; m++) {
		[unroll]
		for(int n = 0; n < 3; n++) {
			float3 pixel = tex2Dfetch(s, int4( (vpos.x - 1 + n), (vpos.y - 1 + m), 0, 0)).rgb;
			pixel = MAX_VALUE(pixel);
			acc += float4(sobelX[n + (m*3)], sobelY[n + (m*3)], sobelXM[n + (m*3)], sobelYM[n + (m*3)]) * pixel.x;
		}
	}
	return max(acc.x, max(acc.y, max(acc.z, acc.w)));
}

float3 DepthEdges(float2 texcoord) {

    float2 posCenter = texcoord.xy;
    float2 posNorth = posCenter + float2(0.0, -ReShade::PixelSize.y);
    float2 posEast = posCenter + float2(ReShade::PixelSize.x, 0.0);

    float3 vertCenter = float3(posCenter, ReShade::GetLinearizedDepth(posCenter));
    float3 vertNorth = float3(posNorth, ReShade::GetLinearizedDepth(posNorth));
    float3 vertEast = float3(posEast, ReShade::GetLinearizedDepth(posEast));

    float3 normalLayer = cross(normalize(vertCenter - vertNorth), normalize(vertCenter - vertEast));

    return 1.0 - saturate(dot(float3(0.0, 0.0, 1.0), normalLayer).rrr);
}

float Posterize(float x, int numLevels, float continuity, float slope, int type) {
	float stepheight = 1.0 / numLevels;
	float stepnum = floor(x * numLevels);
	float frc = frac(x * numLevels);
	float step1 = floor(frc) * stepheight;
	float step2;

	if(type == 1)
		step2 = smoothstep(0.0, 1.0, frc) * stepheight;
	else if(type == 2)
		step2 = (1.0 / (1.0 + exp(-slope*(frc - 0.5)))) * stepheight;
	else
		step2 = frc * stepheight;

	return lerp(step1, step2, continuity) + stepheight * stepnum;
}

float4 RGBtoCMYK(float3 color) {
	float3 CMY;
	float K;
	K = 1.0 - max(color.r, max(color.g, color.b));
	CMY = (1.0 - color - K) / (1.0 - K);
	return float4(CMY, K);
}

float3 CMYKtoRGB(float4 cmyk) {
	return (1.0.xxx - cmyk.xyz) * (1.0 - cmyk.w);
}

/******************************************************************************
	Pixel Shader
******************************************************************************/

//Convolution gets currently done with samplers, so rendering to a texture is necessary
void Chroma_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float3 chroma : SV_Target0, out float3 luma : SV_Target1) {
	static const float3 LumaCoeff = float3(0.2126, 0.7151, 0.0721);
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	luma = dot(color, LumaCoeff);
	chroma = color - luma;
}

float3 ColorfulPoster_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
	static const float3 LumaCoeff = float3(0.2126, 0.7151, 0.0721);
	/*******************************************************
		Get BackBuffer
	*******************************************************/
	float3 backbuffer = tex2D(ReShade::BackBuffer, texcoord).rgb;

	/*******************************************************
		Calculate chroma and luma; posterize luma
	*******************************************************/
	float luma = dot(backbuffer, LumaCoeff);
	float3 chroma = backbuffer - luma;
	float3 lumaPoster = Posterize(luma, iUILumaLevels, fUIStepContinuity, fUISlope, iUIStepType).rrr;

	/*******************************************************
		Color
	*******************************************************/
	float3 mask, image, colorLayer;

	//Convert RGB to CMYK, add cyan tint, set K to 0.0
	float4 backbufferCMYK = RGBtoCMYK(backbuffer);
	backbufferCMYK.xyz += float3(0.2, -0.1, -0.2);
	backbufferCMYK.w = 0.0;

	//Convert back to RGB
	mask = CMYKtoRGB(saturate(backbufferCMYK));
	
	//add luma to chroma
	image = chroma + lumaPoster;

	//Blend with 'hard light'
	colorLayer = lerp(2*image*mask, 1.0 - 2.0 * (1.0 - image) * (1.0 - mask), step(0.5, luma.r));
	colorLayer = lerp(image, colorLayer, fUITint);

	/*******************************************************
		Create PencilLayer
	*******************************************************/
	float currentDepth = ReShade::GetLinearizedDepth(texcoord);
	float3 outlinesDepthBuffer = DepthEdges(texcoord).rrr * (currentDepth < fUIDepthOutlines.z ? (currentDepth > fUIDepthOutlines.y ? 1.0 : 0.0 ) : 0.0) * fUIDepthOutlines.x;
	float3 lumaEdges = DiffEdges(SamplerColorfulPosterLuma, vpos.xy).rrr * fUILumaEdges;
	float3 chromaEdges = ConvEdges(SamplerColorfulPosterChroma, vpos.xy).rrr * fUIChromaEdges;

	float3 pencilLayer = max(outlinesDepthBuffer, max(lumaEdges, chromaEdges));

	/*******************************************************
		Create result
	*******************************************************/
	float3 result = lerp(colorLayer, fUILineColor, pencilLayer);

	/*******************************************************
		Show debug stuff
	*******************************************************/
	if(iUIDebugMaps == 1)
		result = lumaPoster;
	else if(iUIDebugMaps == 2)
		result = lerp(1.0.rrr, fUILineColor, outlinesDepthBuffer);
	else if(iUIDebugMaps == 3)
		result = lerp(1.0.rrr, fUILineColor, lumaEdges);
	else if(iUIDebugMaps == 4)
		result = lerp(1.0.rrr, fUILineColor, chromaEdges);
	else if(iUIDebugMaps == 5)
		result = lerp(1.0.rrr, fUILineColor, pencilLayer);
	else if(iUIDebugMaps == 6)
		return ReShade::GetLinearizedDepth(texcoord).rrr;
	else if(iUIDebugMaps == 7)
		return tex2D(SamplerColorfulPosterChroma, texcoord).rgb;

	if(iUIDebugOverlayPosterizeLevels == 1) {
		result = lerp(result, float3(1.0, 0.0, 1.0), saturate(exp(-BUFFER_HEIGHT * length(texcoord - float2(texcoord.x, 1.0 - Posterize(texcoord.x, iUILumaLevels, fUIStepContinuity, fUISlope, iUIStepType))))));
		backbuffer = lerp(backbuffer, float3(1.0, 0.0, 1.0), saturate(exp(-BUFFER_HEIGHT * length(texcoord - float2(texcoord.x, 1.0 - Posterize(texcoord.x, iUILumaLevels, fUIStepContinuity, fUISlope, iUIStepType))))));
	}

	/*******************************************************
		Set overall strength and return
	*******************************************************/
	return lerp(backbuffer, result, fUIStrength);
}

technique ColorfulPoster
{
	pass {
		VertexShader = PostProcessVS;
		PixelShader = Chroma_PS;
		RenderTarget0 = texColorfulPosterChroma;
		RenderTarget1 = texColorfulPosterLuma;
	}
	pass {
		VertexShader = PostProcessVS;
		PixelShader = ColorfulPoster_PS;
	}
}