/*******************************************************
	ReShade Header: Tools
	https://github.com/Daodan317081/reshade-shaders
*******************************************************/

#include "ReShade.fxh"

#define BLACK	float3(0.0, 0.0, 0.0)
#define WHITE	float3(1.0, 1.0, 1.0)
#define GREY50  float3(0.5, 0.5, 0.5)
#define RED 	float3(1.0, 0.0, 0.0)
#define ORANGE 	float3(1.0, 0.5, 0.0)
#define GREEN 	float3(0.0, 1.0, 0.0)
#define BLUE 	float3(0.0, 0.0, 1.0)
#define CYAN 	float3(0.0, 1.0, 1.0)
#define MAGENTA float3(1.0, 0.0, 1.0)
#define YELLOW 	float3(1.0, 1.0, 0.0)

#define LumaCoeff float3(0.2126, 0.7151, 0.0721)
#define YIQ_I_RANGE float2(-0.5957, 0.5957)
#define YIQ_Q_RANGE float2(-0.5226, 0.5226)
#define FLOAT_RANGE float2(0.0, 1.0)

/*
uniform int iUILayerMode <
	ui_type = "combo";
	ui_label = "Layer Mode";
	ui_items = "LAYER_MODE_NORMAL\0LAYER_MODE_MULTIPLY\0LAYER_MODE_DIVIDE\0LAYER_MODE_SCREEN\0LAYER_MODE_OVERLAY\0LAYER_MODE_DODGE\0LAYER_MODE_BURN\0LAYER_MODE_HARDLIGHT\0LAYER_MODE_SOFTLIGHT\0LAYER_MODE_GRAINEXTRACT\0LAYER_MODE_GRAINMERGE\0LAYER_MODE_DIFFERENCE\0LAYER_MODE_ADDITION\0LAYER_MODE_SUBTRACT\0LAYER_MODE_DARKENONLY\0LAYER_MODE_LIGHTENONLY\0";
> = 0;
*/

#define LAYER_MODE_NORMAL			0
#define LAYER_MODE_MULTIPLY		    1
#define LAYER_MODE_DIVIDE			2
#define LAYER_MODE_SCREEN			3
#define LAYER_MODE_OVERLAY		    4
#define LAYER_MODE_DODGE			5
#define LAYER_MODE_BURN			    6
#define LAYER_MODE_HARDLIGHT		7
#define LAYER_MODE_SOFTLIGHT		8
#define LAYER_MODE_GRAINEXTRACT 	9
#define LAYER_MODE_GRAINMERGE		10
#define LAYER_MODE_DIFFERENCE		11
#define LAYER_MODE_ADDITION		    12
#define LAYER_MODE_SUBTRACT		    13
#define LAYER_MODE_DARKENONLY		14
#define LAYER_MODE_LIGHTENONLY	    15

/*
uniform int iUIEdgeType <
	ui_type = "combo";
	ui_label = "Edge detection kernel";
	ui_items = "CONV_SOBEL\0CONV_PREWITT\0CONV_SCHARR\0";
> = 0;
*/
#define CONV_SOBEL 0
#define CONV_PREWITT 1
#define CONV_SCHARR 2

/*
uniform int iUIEdgeMergeMethod <
	ui_type = "combo";
	ui_label = "Edge merge method";
	ui_items = "CONV_MUL\CONV_DOT\CONV_X\0CONV_Y\0CONV_ADD\0CONV_MAX\0";
> = 0;
*/
#define CONV_MUL 0
#define CONV_DOT 1
#define CONV_X	 2
#define CONV_Y   3
#define CONV_ADD 4
#define CONV_MAX 5


struct sctpoint {
    float3 color;
    float2 coord;
    float2 offset;
};


float3 ConvReturn(float3 X, float3 Y, int MulDotXYAddMax) {
        float3 ret = float3(1.0, 0.0, 1.0);

        if(MulDotXYAddMax == CONV_MUL)
            ret = X * Y;
        else if(MulDotXYAddMax == CONV_DOT)
            ret = dot(X,Y);
        else if(MulDotXYAddMax == CONV_X)
            ret = X;
        else if(MulDotXYAddMax == CONV_Y)
            ret = Y;
        else if(MulDotXYAddMax == CONV_ADD)
            ret = X + Y;
        else if(MulDotXYAddMax == CONV_MAX)
            ret = max(X, Y);
        return ret;
}


namespace Tools {

    namespace Color {

        float3 RGBtoYIQ(float3 color) {
            static const float3x3 YIQ = float3x3( 	0.299, 0.587, 0.144,
                                                    0.596, -0.274, -0.322,
                                                    0.211, -0.523, 0.312  );
            return mul(YIQ, color);
        }

        float3 YIQtoRGB(float3 yiq) {
            static const float3x3 RGB = float3x3( 	1.0, 0.956, 0.621,
                                                    1.0, -0.272, -0.647,
                                                    1.0, -1.106, 1.703  );
            return saturate(mul(RGB, yiq));
        }

        float4 RGBtoCMYK(float3 color) {
            float C, M, Y, K;
            K = 1.0 - max(color.r, max(color.g, color.b));
            C = (1.0 - color.r - K) / (1.0 - K);
            M = (1.0 - color.g - K) / (1.0 - K);
            Y = (1.0 - color.b - K) / (1.0 - K);
            return float4(C, M, Y, K);
        }

        float3 CMYKtoRGB(float4 cmyk) {
            return float3((1.0-cmyk.x)*(1.0-cmyk.w),(1.0-cmyk.y)*(1.0-cmyk.w),(1.0-cmyk.z)*(1.0-cmyk.w));
        }

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
            float H = color.x;
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

        float GetSaturation(float3 color) {
            float maxVal, minVal, delta;
            maxVal = max(color.r, max(color.g, color.b));
            minVal = min(color.r, min(color.g, color.b));

            delta = maxVal - minVal;
            if(delta < 1.0e-10) {
                return 0.0;
            }

            if(maxVal > 0.0) {
                return delta / maxVal;
            }
            
            return 0.0;
        }

        //https://docs.gimp.org/en/gimp-concepts-layer-modes.html
        //https://en.wikipedia.org/wiki/Blend_modes
        float3 LayerMerge(float3 mask, float3 image, int mode) {
            float3 E = float3(1.0, 0.0, 1.0);
        
            if(mode == LAYER_MODE_NORMAL)
                E = mask;
            else if(mode == LAYER_MODE_MULTIPLY)
                E = image * mask;
            else if(mode == LAYER_MODE_DIVIDE)
                E = image / (mask + 0.00001);
            else if(mode == LAYER_MODE_SCREEN || mode == LAYER_MODE_SOFTLIGHT) {
                E = 1.0 - (1.0 - image) * (1.0 - mask);
                if(mode == LAYER_MODE_SOFTLIGHT)
                    E = image * ((1.0 - image) * mask + E);
            }
            else if(mode == LAYER_MODE_OVERLAY)
                E = lerp(2*image*mask, 1.0 - 2.0 * (1.0 - image) * (1.0 - mask), max(image.r, max(image.g, image.b)) < 0.5 ? 0.0 : 1.0 );
            else if(mode == LAYER_MODE_DODGE)	
                E =  image / (1.00001 - mask);
            else if(mode == LAYER_MODE_BURN)
                E = 1.0 - (1.0 - image) / (mask + 0.00001);
            else if(mode == LAYER_MODE_HARDLIGHT)
                E = lerp(2*image*mask, 1.0 - 2.0 * (1.0 - image) * (1.0 - mask), max(image.r, max(image.g, image.b)) > 0.5 ? 0.0 : 1.0);
            else if(mode == LAYER_MODE_GRAINEXTRACT)
                E = image - mask + 0.5;
            else if(mode == LAYER_MODE_GRAINMERGE)
                E = image + mask - 0.5;
            else if(mode == LAYER_MODE_DIFFERENCE)
                E = abs(image - mask);
            else if(mode == LAYER_MODE_ADDITION)
                E = image + mask;
            else if(mode == LAYER_MODE_SUBTRACT)
                E = image - mask;
            else if(mode == LAYER_MODE_DARKENONLY)
                E = min(image, mask);
            else if(mode == LAYER_MODE_LIGHTENONLY)
                E = max(image, mask);

            return saturate(E);
        }

    }

    namespace Convolution {

        float3 ThreeByThree(sampler s, float2 texcoord, float kernel[9], float divisor) {
            float x, y, px, py;
            float3 acc;

            px = ReShade::PixelSize.x;
            py = ReShade::PixelSize.y;
            x = texcoord.x - px;
            y = texcoord.y - py;

            [loop]
            for(int m = 0; m < 3; m++) {
                [loop]
                for(int n = 0; n < 3; n++) {
                    acc += kernel[n + (m*3)] * tex2D(s, float2(x + n * px, y + m * py)).rgb;
                }
            }

            return acc / divisor;
        }

        float3 FiveByFive(sampler s, float2 texcoord, float kernel[25], float divisor) {
            float x, y, px, py;
            float3 acc = 0.0;

            px = ReShade::PixelSize.x;
            py = ReShade::PixelSize.y;
            x = texcoord.x - 2 * px;
            y = texcoord.y - 2 * py;

            [loop]
            for(int m = 0; m < 5; m++) {
                [loop]
                for(int n = 0; n < 5; n++) {
                    acc += kernel[n + (m*5)] * tex2D(s, float2(x + n * px, y + m * py)).rgb;
                }
            }

            return acc / divisor;
        }

        float3 Prewitt(sampler s, float2 texcoord, int type) {
            static const float Prewitt_X[9] = { -1.0,  0.0, 1.0,
                                                -1.0,  0.0, 1.0,
                                                -1.0,  0.0, 1.0	 };

            static const float Prewitt_Y[9] = { 1.0,  1.0,  1.0,
                                                0.0,  0.0,  0.0,
                                               -1.0, -1.0, -1.0  };
            
            float3 retValX = Convolution::ThreeByThree(s, texcoord, Prewitt_X, 1.0);
            float3 retValY = Convolution::ThreeByThree(s, texcoord, Prewitt_Y, 1.0);

            return ConvReturn(retValX, retValY, type);
        }

        float3 Sobel(sampler s, float2 texcoord, int type) {
            static const float Sobel_X[9] = { 	1.0,  0.0, -1.0,
                                                2.0,  0.0, -2.0,
                                                1.0,  0.0, -1.0	 };

            static const float Sobel_Y[9] = { 	1.0,  2.0,  1.0,
                                                0.0,  0.0,  0.0,
                                               -1.0, -2.0, -1.0	 };
            
            float3 retValX = Convolution::ThreeByThree(s, texcoord, Sobel_X, 1.0);
            float3 retValY = Convolution::ThreeByThree(s, texcoord, Sobel_Y, 1.0);

            return ConvReturn(retValX, retValY, type);
        }

        float3 Scharr(sampler s, float2 texcoord, int type) {
            static const float Scharr_X[9] = { 	 3.0,  0.0,  -3.0,
                                                10.0,  0.0, -10.0,
                                                 3.0,  0.0,  -3.0  };

            static const float Scharr_Y[9] = { 	3.0,  10.0,   3.0,
                                                0.0,   0.0,   0.0,
                                               -3.0, -10.0,  -3.0  };
            
            float3 retValX = Convolution::ThreeByThree(s, texcoord, Scharr_X, 1.0);
            float3 retValY = Convolution::ThreeByThree(s, texcoord, Scharr_Y, 1.0);

            return ConvReturn(retValX, retValY, type);
        }

        float3 Edges(sampler s, float2 texcoord, int type, int ret) {
            if(type == CONV_SOBEL)
                return Convolution::Sobel(s, texcoord, ret);
            else if(type == CONV_PREWITT)
                return Convolution::Prewitt(s, texcoord, ret);
            else if(type == CONV_SCHARR)
                return Convolution::Scharr(s, texcoord, ret);
            else
                return float3(1.0, 0.0, 1.0);
        }

        float3 Blur3x3(sampler s, float2 texcoord) {
            static const float kernel[9] = { 1.0,  1.0, 1.0,
                                             1.0,  1.0, 1.0,
                                             1.0,  1.0, 1.0  };
            

            return Convolution::ThreeByThree(s, texcoord, kernel, 9.0);
        }

        float3 BlurGauss3x3(sampler s, float2 texcoord) {
            static const float kernel[9] = { 1.0,  2.0, 1.0,
                                             2.0,  4.0, 2.0,
                                             1.0,  2.0, 1.0	 };
            

            return Convolution::ThreeByThree(s, texcoord, kernel, 16.0);
        }

        float3 Blur5x5(sampler s, float2 texcoord) {
            static const float kernel[25] = { 1.0, 1.0, 1.0, 1.0, 1.0,
                                              1.0, 1.0, 1.0, 1.0, 1.0,
                                              1.0, 1.0, 1.0, 1.0, 1.0,
                                              1.0, 1.0, 1.0, 1.0, 1.0,
                                              1.0, 1.0, 1.0, 1.0, 1.0 };
            

            return Convolution::FiveByFive(s, texcoord, kernel, 25.0);
        }

        float3 BlurGauss5x5(sampler s, float2 texcoord) {
            static const float kernel[25] = {   0.0030,    0.0133,    0.0219,    0.0133,    0.0030,
                                                0.0133,    0.0596,    0.0983,    0.0596,    0.0133,
                                                0.0219,    0.0983,    0.1621,    0.0983,    0.0219,
                                                0.0133,    0.0596,    0.0983,    0.0596,    0.0133,
                                                0.0030,    0.0133,    0.0219,    0.0133,    0.0030 };
            

            return Convolution::FiveByFive(s, texcoord, kernel, 1.0);
        }
    }

    namespace Draw {

        sctpoint NewPoint(float3 color, float2 offset, float2 coord) {
            sctpoint p;
            p.color = color;
            p.offset = offset;
            p.coord = coord;
            return p;
        }

        float3 Point(float3 texcolor, sctpoint p, float2 texcoord) {
            float2 pixelsize = ReShade::PixelSize * p.offset;
            
            if(p.coord.x == -1 || p.coord.y == -1)
                return texcolor;

            if(texcoord.x <= p.coord.x + pixelsize.x &&
            texcoord.x >= p.coord.x - pixelsize.x &&
            texcoord.y <= p.coord.y + pixelsize.y &&
            texcoord.y >= p.coord.y - pixelsize.y)
                return p.color;
            return texcolor;
        }

        float3 OverlaySampler(float3 image, sampler overlay, float scale, float2 texcoord, int2 offset, float opacity) {
            float3 retVal;
            float3 col = image;
            float fac = 0.0;

            float2 coord_pix = float2(BUFFER_WIDTH, BUFFER_HEIGHT) * texcoord;
            float2 overlay_size = (float2)tex2Dsize(overlay, 0) * scale;
            float2 border_min = (float2)offset;
            float2 border_max = border_min + overlay_size;

            if( coord_pix.x <= border_max.x &&
                coord_pix.y <= border_max.y &&
                coord_pix.x >= border_min.x &&
                coord_pix.y >= border_min.y   ) {
                    fac = opacity;
                    float2 coord_overlay = (coord_pix - border_min) / overlay_size;
                    col = tex2D(overlay, coord_overlay).rgb;
                }

            return lerp(image, col, fac);
        }

    }

    namespace Functions {
        
        float Map(float value, float2 span_old, float2 span_new) {
            float span_old_diff = abs(span_old.y - span_old.x) < 1e-6 ? 1e-6 : span_old.y - span_old.x;
            return lerp(span_new.x, span_new.y, (clamp(value, span_old.x, span_old.y)-span_old.x)/(span_old_diff));
        }

        float Level(float value, float black, float white) {
            value = clamp(value, black, white);
            return Map(value, float2(black, white), FLOAT_RANGE);
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

    }
}