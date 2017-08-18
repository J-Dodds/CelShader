// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/CelShader2" 
{
	Properties
	{
		_MainTexture("Main Texture", 2D) = "white"{}
		_Color("Colour", Color) = (1,1,1,1)
		_UnlitColor("Unlit Colour", Color) = (0.5, 0.5, 0.5, 1)
		_DiffuseThreshold("Diffuse Lighting Threshold", Range(-1.1, 1)) = 0.1
		_SpecColor("Specular Material Colour", Color) = (1, 1, 1, 1)
		_Shininess("Shininess", Range(0.5, 1)) = 1
		_OutlineThickness("Outline Thickness", Range(0, 1)) = 0.1
	}

		SubShader
		{
			Pass
			{
				Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM
			// compile directives
	#pragma vertex vert //vertex shader
	#pragma fragment frag //fragment shader

		//Cel Shading uniforms
			uniform float4 _Color;
			uniform float4 _UnlitColor;
			uniform float _DiffuseThreshold;
			uniform float4 _SpecColor;
			uniform float _Shininess;
			uniform float _OutlineThickness;

			//Unity defined vars
			uniform float4 _LightColor0;
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;

			struct VertexInput
			{
				//Cel Shading vars
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};

			struct VertexOutput
			{
				float4 pos : SV_POSITION;
				float3 normalDir : TEXCOORD1;
				float4 lightDir : TEXCOORD2;
				float3 viewDir : TEXCOORD3;
				float2 uv : TEXCOORD0;
			};

			VertexOutput vert(VertexInput input)
			{
				VertexOutput output;

				//normalDirection
				output.normalDir = normalize(mul(float4(input.normal, 0.0), unity_WorldToObject).xyz);

				//World pos
				float4 posWorld = mul(unity_ObjectToWorld, input.vertex);

				//View direction
				//Vector from object to camera
				output.viewDir = normalize(_WorldSpaceCameraPos.xyz - posWorld.xyz);

				//Light direction
				float3 fragmentToLightSource = (_WorldSpaceCameraPos.xyz - posWorld.xyz);
				output.lightDir = float4 (normalize(lerp(_WorldSpaceLightPos0.xyz, fragmentToLightSource, _WorldSpaceLightPos0.w)),
										 lerp(1.0, 1.0 / length(fragmentToLightSource), _WorldSpaceLightPos0.w));

				//fragmentInput output
				output.pos = UnityObjectToClipPos(input.vertex);

				//UV-Map
				output.uv = input.texcoord;

				return output;
				}

					float4 frag(VertexOutput input) : COLOR
				{
					float nDotL = saturate(dot(input.normalDir, input.lightDir.xyz));

					//Diffuse lighting threshold calcualtion
					float diffuseCutoff = saturate((max(_DiffuseThreshold, nDotL) - _DiffuseThreshold) * 1000);

					//Specular threshold calcualtion
					float specularCutoff = saturate(max(_Shininess, dot(reflect(-input.lightDir.xyz, input.normalDir),
						input.viewDir)) - _Shininess) * 1000;

					//Outline calculation
					float outlineStrength = saturate((dot(input.normalDir, input.viewDir) - _OutlineThickness) * 1000);

					//adds general ambient lighting
					float3 ambientLight = (1 - diffuseCutoff) * _UnlitColor.xyz;
					float3 diffuseReflection = (1 - specularCutoff) * _Color.xyz * diffuseCutoff;
					float3 specularReflection = _SpecColor.xyz * specularCutoff;

					float3 combinedLight = (ambientLight + diffuseReflection) * outlineStrength + specularReflection;

					return float4(combinedLight, 1.0);
					}

						ENDCG
					}
		}

		FallBack "Specular"
		Fallback "Diffuse"
}