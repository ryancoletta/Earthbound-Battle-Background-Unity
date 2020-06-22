Shader "Unlit/Earthbound"
{
	// some helpful ref https://www.youtube.com/watch?v=zjQik7uwLIQ&vl=en

	// 6 things to solve
	// X palette cycling
	// X background scrolling
	// X horizontal oscillation
	// X vertical oscillation
	// X interleaved oscillation
	// X transparency

	Properties
	{
		[Toggle] _Blend("Blend?", int) = 0

		[Header(Texture A)]
		_TexA ("Texture", 2D) = "white" {}		// ensure "Repeat" wrap mode
		_PaletteA("Palette Cycle", 2D) = "white" {}	// ensure "Clamp" wrap mode
		[Enum(None,0,Horizontal,1,Interleaved,2,Vertical,3)] _OscillationVariantA("Oscillation Variant", int) = 0
		_ScrollDirXA("Scroll Direction X", float) = 1
		_ScrollDirYA("Scroll Direction Y", float) = 1
		_ScrollSpeedA("Scroll Speed", float) = 0
		_OscillationSpeedA("Oscillation Speed", float) = 1
		_OscillationAmplitudeA("Oscillation Amplitude", int) = 32
		_OscillationDelayA("Oscillation Delay", int) = 1

		[Header(Texture B)]
		_TexB("Texture", 2D) = "white" {}
		_PaletteB("Palette Cycle", 2D) = "white" {}
		[Enum(None,0,Horizontal,1,Interleaved,2,Vertical,3)] _OscillationVariantB("Oscillation Variant", int) = 0
		_ScrollDirXB("Scroll Direction X", float) = 1
		_ScrollDirYB("Scroll Direction Y", float) = 1
		_ScrollSpeedB("Scroll Speed", float) = 0
		_OscillationSpeedB("Oscillation Speed", float) = 1
		_OscillationAmplitudeB("Oscillation Amplitude", int) = 32
		_OscillationDelayB("Oscillation Delay", int) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
				float4 color : COLOR;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
				float4 vertex : SV_POSITION;
				float4 color : COLOR;
			};

			int _Blend;

			// texture A
			sampler2D _TexA;
			float4 _TexA_ST;
			sampler2D _PaletteA;
			float4 _PaletteA_ST;
			float4 _PaletteA_TexelSize;
			float _ScrollDirXA;
			float _ScrollDirYA;
			float _ScrollSpeedA;
			int _OscillationVariantA;
			float _OscillationSpeedA;
			int _OscillationAmplitudeA;
			int _OscillationDelayA;

			// texture B
			sampler2D _TexB;
			float4 _TexB_ST;
			sampler2D _PaletteB;
			float4 _PaletteB_ST;
			float4 _PaletteB_TexelSize;
			float _ScrollDirXB;
			float _ScrollDirYB;
			float _ScrollSpeedB;
			int _OscillationVariantB;
			float _OscillationSpeedB;
			int _OscillationAmplitudeB;
			int _OscillationDelayB;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _TexA);
				o.uv2 = TRANSFORM_TEX(v.uv2, _TexB);
				o.color = v.color;
				return o;
			}
			
			float2 calcUV(float2 uv, float scrollDirX, float scrollDirY, float scrollSpeed, int oscillationVariant, float oscillationSpeed, int oscillationAmplitude, int oscillationDelay)
			{
				// background scrolling
				float2 scrollDir = float2(scrollDirX, scrollDirY) * _Time.y * scrollSpeed;	//_Time is a float4 with different speeds in xyzw
				uv = uv + scrollDir;

				float pixelCount = 256;														// float so that the amp is not set to 0
				int scanline = uv.y * pixelCount;											// top = 0, bottom = 256
				float amp = oscillationAmplitude / pixelCount;
				float pixelDelay = scanline * (oscillationDelay / pixelCount);

				// choose which oscillation you'd like to display
				// note: switch statments are bad for performance in shaders, but this allows the most flexibility in-editor
				switch (oscillationVariant) {
				case 1:
					// horizontal oscillation
					uv.x = uv.x + sin((_Time.y + pixelDelay) * oscillationSpeed) * amp;
					break;
				case 2:
					// interleaved oscillation
					int sign = (scanline % 2) * 2 - 1; // returns either -1 or 1, saves an if statement with some math
					uv.x = uv.x + sign * sin((_Time.y + pixelDelay) * oscillationSpeed) * amp;
					break;
				case 3:
					// vertical oscillation
					uv.y = uv.y + sin((_Time.y + pixelDelay) * oscillationSpeed) * amp;
					break;
				}
				return uv;
			}

			// palette cycling
			// TODO wayyy too expensive rn, find a better way later
			float4 paletteCycle(float4 inCol, sampler2D paletteCycle, float paletteCount)
			{
				float4 outCol = inCol;

				int paletteIndex = -1;
				for (int i = 0; i < paletteCount; i++)
				{
					if (inCol.a == tex2D(paletteCycle, float2(i / paletteCount, 0)).a) // match alpha values (greyscale)
					{
						paletteIndex = i;
					}
				}
				if (paletteIndex >= 0)
				{
					int paletteOffset = (paletteIndex + _Time.y * 12) % paletteCount;
					outCol = tex2D(paletteCycle, float2(paletteOffset / paletteCount, 0));
				}
				return outCol;
			}

			// fragment shader, where the magic happens
			float4 frag (v2f i) : SV_Target
			{
				// oscillation effects
				float2 uv1 = calcUV(i.uv, _ScrollDirXA, _ScrollDirYA, _ScrollSpeedA, _OscillationVariantA, _OscillationSpeedA, _OscillationAmplitudeA, _OscillationDelayA);
				float2 uv2 = calcUV(i.uv2, _ScrollDirXB, _ScrollDirYB, _ScrollSpeedB, _OscillationVariantB, _OscillationSpeedB, _OscillationAmplitudeB, _OscillationDelayB);

				// palette cycling
				float4 col1 = tex2D(_TexA, uv1);
				float4 col2 = tex2D(_TexB, uv2);
				col1 = paletteCycle(col1, _PaletteA, _PaletteA_TexelSize.z);
				col2 = paletteCycle(col2, _PaletteB, _PaletteB_TexelSize.z);

				// transparency
				// _Blend is either 0 or 1, avoid an if statement here with some math
				col1 = col1 * (0.5 * (2 - _Blend)) + _Blend * col2 * 0.5;
				
				return col1;
			}
			ENDCG
		}
	}
}
