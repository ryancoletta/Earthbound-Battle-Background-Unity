Shader "Unlit/Earthbound"
{
	// 6 things to solve
	// - palette cycling
	// X background scrolling
	// X horizontal oscillation
	// X vertical oscillation
	// X interleaved oscillation
	// X transparency / blending

	// ref https://www.youtube.com/watch?v=zjQik7uwLIQ&vl=en
	Properties
	{
		[Toggle] _Blend("Blend?", int) = 0

		[Header(Texture A)]
		_TexA ("Texture", 2D) = "white" {}
		[Enum(None,0,Horizontal,1,Interleaved,2,Vertical,3)] _OscillationVariantA("Oscillation Variant", int) = 0
		_ScrollDirXA("Scroll Direction X", int) = 1
		_ScrollDirYA("Scroll Direction Y", int) = 1
		_ScrollSpeedA("Scroll Speed", float) = 0
		_OscillationSpeedA("Oscillation Speed", float) = 1
		_OscillationAmplitudeA("Oscillation Amplitude", int) = 32
		_OscillationDelayA("Oscillation Delay", int) = 1

		[Header(Texture B)]
		_TexB("Texture", 2D) = "white" {}
		[Enum(None,0,Horizontal,1,Interleaved,2,Vertical,3)] _OscillationVariantB("Oscillation Variant", int) = 0
		_ScrollDirXB("Scroll Direction X", int) = 1
		_ScrollDirYB("Scroll Direction Y", int) = 1
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
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
				float4 vertex : SV_POSITION;
			};

			int _Blend;

			// texture A
			sampler2D _TexA;
			float4 _TexA_ST;
			int _ScrollDirXA;
			int _ScrollDirYA;
			float _ScrollSpeedA;
			int _OscillationVariantA;
			float _OscillationSpeedA;
			int _OscillationAmplitudeA;
			int _OscillationDelayA;

			// texture B
			sampler2D _TexB;
			float4 _TexB_ST;
			int _ScrollDirXB;
			int _ScrollDirYB;
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
				return o;
			}
			
			float2 calcUV(float2 uv, int scrollDirX, int scrollDirY, float scrollSpeed, int oscillationVariant, float oscillationSpeed, int oscillationAmplitude, int oscillationDelay)
			{
				// background scrolling
				float2 scrollDir = float2(scrollDirX, scrollDirY) * _Time.y * scrollSpeed; //_Time is a float4 with different speeds in xyzw
				uv = uv + scrollDir;

				float pixelCount = 256; // float so that the amp is not set to 0
				int scanline = uv.y * pixelCount; // top = 0, bottom = 256
				float amp = oscillationAmplitude / pixelCount; // original game has the effect by 8 pixels in either direction
				float pixelDelay = scanline * (oscillationDelay / pixelCount);

				// choose which oscillation you'd like to display
				switch (oscillationVariant) {
				case 1:
					// horizontal oscillation
					uv.x = uv.x + sin((_Time.y + pixelDelay) * oscillationSpeed) * amp;
					break;
				case 2:
					// interleaved oscillation
					int sign = (scanline % 2) * 2 - 1; // returns either -1 or 1
					uv.x = uv.x + sign * sin((_Time.y + pixelDelay) * oscillationSpeed) * amp;
					break;
				case 3:
					// vertical oscillation
					uv.y = uv.y + sin((_Time.y + pixelDelay) * oscillationSpeed) * amp;
					break;
				}
				return uv;
			}

			// fragment shader, where the magic happens
			float4 frag (v2f i) : SV_Target
			{
				float2 uv1 = calcUV(i.uv, _ScrollDirXA, _ScrollDirYA, _ScrollSpeedA, _OscillationVariantA, _OscillationSpeedA, _OscillationAmplitudeA, _OscillationDelayA);
				float2 uv2 = calcUV(i.uv2, _ScrollDirXB, _ScrollDirYB, _ScrollSpeedB, _OscillationVariantB, _OscillationSpeedB, _OscillationAmplitudeB, _OscillationDelayB);

				float4 col = tex2D(_TexA, uv1);
				if (_Blend == 1) {
					col = tex2D(_TexA, uv1) * 0.5 + tex2D(_TexB, uv2) * 0.5;
				}
				
				return col;
			}
			ENDCG
		}
	}
}
