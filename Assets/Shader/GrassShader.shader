Shader "Custom/GrassShader"
{
	Properties{
		_MainTex("MainTex", 2D) = "white" { }
		_HeightMap("HeightMap", 2D) = "white" { }
		_Length("Length", float) = 1
		_Scale("Scale", float) = 1
		_WindPower("WindPower", Range(0,1)) = 1
		_WindDirection("WindDirection",float) = (1,1,1)
		_ObstaclePosition("ObstaclePosition",float) = (1,1,1)
		_ObstacleRaidus("ObstacleRaidus",float) = 1
	}

   	SubShader {
		Cull off
        Pass {
	        CGPROGRAM
	        
	        // シェーダーモデルは5.0を指定
	        #pragma target 5.0
	        
	        // シェーダー関数を設定 
	        #pragma vertex vert
			#pragma geometry geom
	        #pragma fragment frag
	         
	        #include "UnityCG.cginc"
			#include "Common/ClassicNoise2D.cginc"
	        
			SamplerState samHeightmap
			{
				Filter = MIN_MAG_MIP_LINEAR;
				AddressU = Clamp;// of Mirror of Clamp of Border
				AddressV = Clamp;// of Mirror of Clamp of Border
			};

			bool IsGrass = false;
			bool IsWind = true;
			bool IsDense = true;
			bool AddOriginalGeometry = true;

			float _Length;
			float _WindPower;
			float3 _WindDirection;
			float _Scale;

			float m_Time : TIME;

			float3 _ObstaclePosition;
			float _ObstacleRaidus;

			Texture2D heightmap;
			Texture2D directionTexture;

			sampler2D _MainTex;
			sampler2D _HeightMap;

	        // 頂点シェーダからの出力
	        // 今回は頂点位置のみ
	        struct VSOut {
	            float4 pos : SV_POSITION;
				float3 normal : NORMAL;
				float2 texCoord : TEXCOORD0;
				float3 vertex : TEXCOORD1;
	        };
	        
	        // 頂点シェーダ
			VSOut vert (appdata_base v)
	       	{
	            VSOut output;
	            output.pos = v.vertex;
				output.normal = normalize(mul(v.normal, (float3x3)unity_ObjectToWorld));
				output.texCoord = v.texcoord * float2(1, 1);
	             
	            return output;
	       	}

			void CreateVertex(inout TriangleStream<VSOut> triStream, float3 pos, float3 normal, float2 texCoord, int channel = 1)
			{
				VSOut temp = (VSOut)0;
				temp.pos = UnityObjectToClipPos(float4(pos.xyz, 1.0f));
				temp.normal = mul(normal, (float3x3) unity_ObjectToWorld);
				temp.texCoord = texCoord;
				triStream.Append(temp);
			}

			void CreateGrass(inout TriangleStream<VSOut> triStream, float height, float direction, float3 pos0, float3 pos1, float3 pos2, float3 normal, float3 normal2, float3 normal3)
			{
				height *= 0.2;
				int maxHeight = _Length * _Scale;
				float maxWidth = 0.5;
				float unitHeightSegmentBottom = 0.4;
				float unitHeightSegmentMid = 0.4;
				float unitHeightSegmentTop = 0.2;

				float unitWidthSegmentBottom = 0.5;
				float unitWidthSegmentMid = 0.4;
				float unitWidthSegmentTop = 0.2;

				float bendSegmentBottom = 0.5;
				float bendSegmentMid = 1;
				float bendSegmentTop = 1.5;

				float m_WindVelocity = 2;
				float bendingWidth = 2;

				float3 basePoint = (pos0 + pos1 + pos2) / 3;
				float3 normalbasepoint = (normal + normal2 + normal3) / 3;

				float grassHeight = 4 + height * maxHeight;
				float segmentBottomHeight = grassHeight * unitHeightSegmentBottom;
				float segmentMidHeight = grassHeight * unitHeightSegmentMid;
				float segmentTopHeight = grassHeight * unitHeightSegmentTop;

				float grassWidth = maxWidth * _Scale;
				float segmentBottomWidth = grassWidth * unitWidthSegmentBottom;
				float segmentMidWidth = grassWidth * unitWidthSegmentMid;
				float segmentTopWidth = grassWidth * unitWidthSegmentTop;

				direction -= -0.5;
				float3 grassDirection = (pos2 - pos0) * direction;

				bendingWidth *= 0.3;
				float3 v[7]; //trianglestrip
				v[0] = basePoint - grassDirection * segmentBottomWidth;
				v[1] = basePoint + grassDirection * segmentBottomWidth;
				v[2] = basePoint - (grassDirection * segmentMidWidth) + (segmentBottomHeight * normalbasepoint);
				v[3] = basePoint + (grassDirection * segmentMidWidth) + (segmentBottomHeight * normalbasepoint);
				v[4] = v[3] - ((grassDirection)* segmentTopWidth) + (segmentMidHeight * normalbasepoint);
				v[5] = v[3] + ((grassDirection)* segmentTopWidth) + (segmentMidHeight * normalbasepoint);
				v[6] = v[5] + ((grassDirection)* segmentTopWidth) + (segmentTopHeight * normalbasepoint);

				float windNoise = cnoise(_Time.x * (24 * _WindPower) + (basePoint.x * _WindDirection.x + basePoint.z * _WindDirection.z) * 0.1f);
				windNoise = -abs((2 * windNoise) - 1);
				float time = 0.7 * _WindPower * windNoise + (3 * cnoise(_Time.x * 0.3 + pos0.xz));

				v[2] += _WindDirection * ((bendingWidth * bendSegmentBottom) * time);
				v[3] += _WindDirection * ((bendingWidth * bendSegmentBottom) * time);
				v[4] += _WindDirection * ((bendingWidth * bendSegmentMid) * time);
				v[5] += _WindDirection *  ((bendingWidth * bendSegmentMid) * time);
				v[6] += _WindDirection * ((bendingWidth * bendSegmentTop) * time);

				_ObstacleRaidus *= 1.0f;
				for (int i = 2; i <= 6; i++)
				{
					float2 diff = basePoint.xz - _ObstaclePosition.xz;
					float3 obstacleToP_distance = basePoint - _ObstaclePosition;// float3(diff.x, 0, diff.y);

					if (length(obstacleToP_distance) < _ObstacleRaidus)
					{
						//v[i] += normalize(obstacleToP_distance) * abs(_ObstacleRaidus - length(obstacleToP_distance)) * 0.2f;
						v[i] += normalize(obstacleToP_distance) * abs(_ObstacleRaidus - length(obstacleToP_distance)) * 0.5;
					}
				}

				CreateVertex(triStream, v[0], float3(0, 0, 0), float2(0, 0));
				CreateVertex(triStream, v[1], float3(0, 0, 0), float2(0.5, 0));
				CreateVertex(triStream, v[2], float3(0, 0, 0), float2(0.3, 0.3));
				CreateVertex(triStream, v[3], float3(0, 0, 0), float2(0.6, 0.3));
				CreateVertex(triStream, v[4], float3(0, 0, 0), float2(0.6, 0.3));
				CreateVertex(triStream, v[5], float3(0, 0, 0), float2(0.9, 0.6));
				CreateVertex(triStream, v[6], float3(0, 0, 0), float2(1, 1));

				triStream.RestartStrip();
			}

	       	// ジオメトリシェーダ
		   	[maxvertexcount(60)]
		   	void geom (triangle VSOut input[3], inout TriangleStream<VSOut> outStream)
		   	{
				float samplePoint = tex2Dlod(_HeightMap, float4(input[0].texCoord, 0, 0)).r;
				float samplePoint2 = tex2Dlod(_HeightMap, float4(input[1].texCoord, 0, 0)).r;
				float samplePoint3 = tex2Dlod(_HeightMap, float4(input[2].texCoord, 0, 0)).r;

				float directionSamplePoint = tex2Dlod(_HeightMap, float4(input[0].texCoord, 0, 0)).r;
				float directionSamplePoint2 = tex2Dlod(_HeightMap, float4(input[1].texCoord, 0, 0)).r;
				float directionSamplePoint3 = tex2Dlod(_HeightMap, float4(input[2].texCoord, 0, 0)).r;

				float3 m0 = (input[0].pos + input[1].pos) * 0.5;
				float3 m1 = (input[1].pos + input[2].pos) * 0.5;
				float3 m2 = (input[2].pos + input[0].pos) * 0.5;

				//CreateGrass(outStream, samplePoint, directionSamplePoint, m0, m1, m2, input[0].normal, input[1].normal, input[2].normal);
				CreateGrass(outStream, samplePoint, directionSamplePoint, m1, input[1].pos, m0, input[0].normal, input[1].normal, input[2].normal);
				CreateGrass(outStream, samplePoint2, directionSamplePoint2, input[0].pos, m0, m2, input[0].normal, input[1].normal, input[2].normal);
				CreateGrass(outStream, samplePoint3, directionSamplePoint3, m2, m1, input[2].pos, input[0].normal, input[1].normal, input[2].normal);

				//IsDense = true;
				//split the received triangle in 3 sub-triangles
				if (IsDense)
				{
					//CreateGrass(outStream, samplePoint2, directionSamplePoint2, input[0].pos, m0, m2, input[0].normal, input[1].normal, input[2].normal);
					//CreateGrass(outStream, samplePoint3, directionSamplePoint3, m2, m1, input[2].pos, input[0].normal, input[1].normal, input[2].normal);
				}
				else
				{
					//CreateGrass(outStream, samplePoint, directionSamplePoint, input[0].pos, input[1].pos, input[2].pos, input[0].normal, input[1].normal, input[2].normal);
				}

		   	}
			
			// ピクセルシェーダー
	        fixed4 frag (VSOut i) : COLOR
	        {
				float4 col = tex2D(_MainTex, i.texCoord);
				return col;
	        }
	         
	        ENDCG
	     } 
     }
}
 