Shader "Unlit/SimpleShader"
{
	Properties
	{
		//_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque"}

		Pass
		{
			CGPROGRAM //tells us, from here on, write CG code (language for shaders in Unity)

			#pragma vertex my_vert //name of vertex shader
			#pragma fragment my_frag //name of the fragment shater


			#include "UnityCG.cginc" //grabs unity CG library so you can use it
			//surf is usually included in surface shaders, unity's way of joining shaders with the lighting system
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			//mesh data (vertex positions, vertex normal, uvs, tangents, vertex colors)
			struct VertexInput
			{
				// determine what you want to grab, after colon is hard coded
				float4 vertex : POSITION;
				float4 colors : COLOR;
				float4 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 uv0 : TEXCOORD0; //2d coords on a 3d mesh (unwrap the mesh, describe point on that 2d mesh)
				float2 uv1 : TEXCOORD1; //you can set multiple UV coords in your modeling app
			};

			// output of the vertex shader that goes into the fragment shader
			struct VertexOutput
			{
				float4 clipSpacePosition : SV_POSITION; //clip (adjusted from local space) shader position
				float2 uv0 : TEXCOORD0;
				float3 normal : TEXCOORD1; // HERE TEXCOORD REFERS TO SOMETHING DIFFERENT, THIS IS AN "INTERPOLATOR", NOT TIED TO UVS
			};

			// variables, tied to what's defined in Properites
			sampler2D _MainTex;
			float4 _MainTex_ST;

			// vertex shader, returns the output struct we defined above
			VertexOutput my_vert(VertexInput v)
			{
				VertexOutput o;
				o.clipSpacePosition = UnityObjectToClipPos(v.vertex); //converts local space vertex to clip space of current camera
				o.uv0 = v.uv0;
				o.normal = v.normal;
				return o;
			}

			// returns a color for this fragment
			// float / fixed / half are different precisions, highest to lowest
			float4 my_frag(VertexOutput o) : SV_Target
			{
				float2 uv = o.uv0;

				//hard coded light source
				float3 lightDir = -_WorldSpaceLightPos0.xyz;
				float3 lightColor = _LightColor0.rgb; // unity build-in shader variable, from "Lighting.cginc"

				// lambert shader
				float3 normal = o.normal; // -1 to 1
				float lightFalloff = max(0, dot(lightDir, normal)); //saturate = clamp(0,1)
				float3 diffuseLight = lightFalloff * lightColor;
				float3 ambientLight = float3(0.2, 0.35, 0.4);
				float3 lambertShading = ambientLight + diffuseLight;

				return float4(lambertShading,1);
			}
			ENDCG // end CG code
		}
	}
}
