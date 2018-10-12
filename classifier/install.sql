--
-- cIPT: column-store Image Processing Toolbox
--==============================================================================
-- author: Tobias Vincon
-- DualStudy@HPE: http://h41387.www4.hpe.com/dualstudy/index.html
-- DBLab: https://dblab.reutlingen-university.de/
--==============================================================================


-- INSTALL DATABASE
-- sets up the complete schema

DROP LIBRARY ImageTools CASCADE;
DROP LIBRARY TransformFunctions CASCADE;

DROP TABLE IF EXISTS image_rgb CASCADE;
DROP TABLE IF EXISTS image_rgb_grey CASCADE;
DROP TABLE IF EXISTS image_grey CASCADE;
DROP TABLE IF EXISTS histogram_v CASCADE;
DROP TABLE IF EXISTS histogram_h CASCADE;

DROP TABLE IF EXISTS image_class CASCADE;
DROP TABLE IF EXISTS image_characteristics CASCADE;
DROP TABLE IF EXISTS classifier_result CASCADE;

CREATE TABLE image_rgb (imageid INTEGER, x INTEGER, y INTEGER, red INTEGER, green INTEGER, blue INTEGER, PRIMARY KEY (imageid, x, y), UNIQUE (imageid, x, y));
CREATE TABLE image_rgb_grey (imageid INTEGER, x INTEGER, y INTEGER, red INTEGER, green INTEGER, blue INTEGER, grey INTEGER, PRIMARY KEY (imageid, x, y), UNIQUE (imageid, x, y));
CREATE TABLE image_grey (imageid INTEGER, x INTEGER, y INTEGER, grey INTEGER, PRIMARY KEY (imageid, x, y), UNIQUE (imageid, x, y));

CREATE TABLE histogram_v (imageid INTEGER, channel INTEGER, binnumber INTEGER, min INTEGER, max INTEGER, cutminmax BOOLEAN, bin INTEGER, frequency INTEGER, 
PRIMARY KEY (imageid, channel, binnumber, min, max, cutminmax, bin), UNIQUE (imageid, channel, binnumber, min, max, cutminmax, bin));
CREATE TABLE histogram_h (imageid INTEGER, channel INTEGER, binnumber INTEGER, min INTEGER, max INTEGER, cutminmax BOOLEAN, 
bin_0 INTEGER, bin_1 INTEGER, bin_2 INTEGER, bin_3 INTEGER, bin_4 INTEGER, bin_5 INTEGER, bin_6 INTEGER, bin_7 INTEGER, bin_8 INTEGER, bin_9 INTEGER, 
bin_10 INTEGER, bin_11 INTEGER, bin_12 INTEGER, bin_13 INTEGER, bin_14 INTEGER, bin_15 INTEGER, bin_16 INTEGER, bin_17 INTEGER, bin_18 INTEGER, bin_19 INTEGER, 
bin_20 INTEGER, bin_21 INTEGER, bin_22 INTEGER, bin_23 INTEGER, bin_24 INTEGER, bin_25 INTEGER, bin_26 INTEGER, bin_27 INTEGER, bin_28 INTEGER, bin_29 INTEGER, 
bin_30 INTEGER, bin_31 INTEGER, bin_32 INTEGER, bin_33 INTEGER, bin_34 INTEGER, bin_35 INTEGER, bin_36 INTEGER, bin_37 INTEGER, bin_38 INTEGER, bin_39 INTEGER, 
bin_40 INTEGER, bin_41 INTEGER, bin_42 INTEGER, bin_43 INTEGER, bin_44 INTEGER, bin_45 INTEGER, bin_46 INTEGER, bin_47 INTEGER, bin_48 INTEGER, bin_49 INTEGER, 
bin_50 INTEGER, bin_51 INTEGER, bin_52 INTEGER, bin_53 INTEGER, bin_54 INTEGER, bin_55 INTEGER, bin_56 INTEGER, bin_57 INTEGER, bin_58 INTEGER, bin_59 INTEGER, 
bin_60 INTEGER, bin_61 INTEGER, bin_62 INTEGER, bin_63 INTEGER, bin_64 INTEGER, bin_65 INTEGER, bin_66 INTEGER, bin_67 INTEGER, bin_68 INTEGER, bin_69 INTEGER, 
bin_70 INTEGER, bin_71 INTEGER, bin_72 INTEGER, bin_73 INTEGER, bin_74 INTEGER, bin_75 INTEGER, bin_76 INTEGER, bin_77 INTEGER, bin_78 INTEGER, bin_79 INTEGER, 
bin_80 INTEGER, bin_81 INTEGER, bin_82 INTEGER, bin_83 INTEGER, bin_84 INTEGER, bin_85 INTEGER, bin_86 INTEGER, bin_87 INTEGER, bin_88 INTEGER, bin_89 INTEGER, 
bin_90 INTEGER, bin_91 INTEGER, bin_92 INTEGER, bin_93 INTEGER, bin_94 INTEGER, bin_95 INTEGER, bin_96 INTEGER, bin_97 INTEGER, bin_98 INTEGER, bin_99 INTEGER, 
bin_100 INTEGER, bin_101 INTEGER, bin_102 INTEGER, bin_103 INTEGER, bin_104 INTEGER, bin_105 INTEGER, bin_106 INTEGER, bin_107 INTEGER, bin_108 INTEGER, bin_109 INTEGER, 
bin_110 INTEGER, bin_111 INTEGER, bin_112 INTEGER, bin_113 INTEGER, bin_114 INTEGER, bin_115 INTEGER, bin_116 INTEGER, bin_117 INTEGER, bin_118 INTEGER, bin_119 INTEGER, 
bin_120 INTEGER, bin_121 INTEGER, bin_122 INTEGER, bin_123 INTEGER, bin_124 INTEGER, bin_125 INTEGER, bin_126 INTEGER, bin_127 INTEGER, bin_128 INTEGER, bin_129 INTEGER, 
bin_130 INTEGER, bin_131 INTEGER, bin_132 INTEGER, bin_133 INTEGER, bin_134 INTEGER, bin_135 INTEGER, bin_136 INTEGER, bin_137 INTEGER, bin_138 INTEGER, bin_139 INTEGER, 
bin_140 INTEGER, bin_141 INTEGER, bin_142 INTEGER, bin_143 INTEGER, bin_144 INTEGER, bin_145 INTEGER, bin_146 INTEGER, bin_147 INTEGER, bin_148 INTEGER, bin_149 INTEGER, 
bin_150 INTEGER, bin_151 INTEGER, bin_152 INTEGER, bin_153 INTEGER, bin_154 INTEGER, bin_155 INTEGER, bin_156 INTEGER, bin_157 INTEGER, bin_158 INTEGER, bin_159 INTEGER, 
bin_160 INTEGER, bin_161 INTEGER, bin_162 INTEGER, bin_163 INTEGER, bin_164 INTEGER, bin_165 INTEGER, bin_166 INTEGER, bin_167 INTEGER, bin_168 INTEGER, bin_169 INTEGER, 
bin_170 INTEGER, bin_171 INTEGER, bin_172 INTEGER, bin_173 INTEGER, bin_174 INTEGER, bin_175 INTEGER, bin_176 INTEGER, bin_177 INTEGER, bin_178 INTEGER, bin_179 INTEGER, 
bin_180 INTEGER, bin_181 INTEGER, bin_182 INTEGER, bin_183 INTEGER, bin_184 INTEGER, bin_185 INTEGER, bin_186 INTEGER, bin_187 INTEGER, bin_188 INTEGER, bin_189 INTEGER, 
bin_190 INTEGER, bin_191 INTEGER, bin_192 INTEGER, bin_193 INTEGER, bin_194 INTEGER, bin_195 INTEGER, bin_196 INTEGER, bin_197 INTEGER, bin_198 INTEGER, bin_199 INTEGER, 
bin_200 INTEGER, bin_201 INTEGER, bin_202 INTEGER, bin_203 INTEGER, bin_204 INTEGER, bin_205 INTEGER, bin_206 INTEGER, bin_207 INTEGER, bin_208 INTEGER, bin_209 INTEGER, 
bin_210 INTEGER, bin_211 INTEGER, bin_212 INTEGER, bin_213 INTEGER, bin_214 INTEGER, bin_215 INTEGER, bin_216 INTEGER, bin_217 INTEGER, bin_218 INTEGER, bin_219 INTEGER, 
bin_220 INTEGER, bin_221 INTEGER, bin_222 INTEGER, bin_223 INTEGER, bin_224 INTEGER, bin_225 INTEGER, bin_226 INTEGER, bin_227 INTEGER, bin_228 INTEGER, bin_229 INTEGER, 
bin_230 INTEGER, bin_231 INTEGER, bin_232 INTEGER, bin_233 INTEGER, bin_234 INTEGER, bin_235 INTEGER, bin_236 INTEGER, bin_237 INTEGER, bin_238 INTEGER, bin_239 INTEGER, 
bin_240 INTEGER, bin_241 INTEGER, bin_242 INTEGER, bin_243 INTEGER, bin_244 INTEGER, bin_245 INTEGER, bin_246 INTEGER, bin_247 INTEGER, bin_248 INTEGER, bin_249 INTEGER, 
bin_250 INTEGER, bin_251 INTEGER, bin_252 INTEGER, bin_253 INTEGER, bin_254 INTEGER, bin_255 INTEGER, 
PRIMARY KEY (imageid, channel, binnumber, min, max, cutminmax), UNIQUE (imageid, channel, binnumber, min, max, cutminmax));

CREATE TABLE image_class (classid INTEGER, classname VARCHAR(255), PRIMARY KEY (classid), UNIQUE (classid));
CREATE TABLE image_characteristics (imageid INTEGER, is_training BOOLEAN, is_test BOOLEAN, classid INTEGER, PRIMARY KEY (imageid), UNIQUE (imageid));
CREATE TABLE classifier_result (paramset INTEGER, type VARCHAR(255), imageid INTEGER, classid INTEGER, metricname VARCHAR(255), metric_result NUMBER);

CREATE LIBRARY ImageTools AS '/data/verticaextension/build/ImageParserCImg.so' LANGUAGE 'C++';
CREATE PARSER ImageToRGBParser AS LANGUAGE 'C++' NAME 'ImageToRGBParserFactory' LIBRARY ImageTools  NOT FENCED;
CREATE PARSER ImageToRGBExtendedParser AS LANGUAGE 'C++' NAME 'ImageToRGBExtendedParserFactory' LIBRARY ImageTools  NOT FENCED;
CREATE PARSER ImageToRGBGreyParser AS LANGUAGE 'C++' NAME 'ImageToRGBGreyParserFactory' LIBRARY ImageTools  NOT FENCED;
CREATE PARSER ImageToGreyParser AS LANGUAGE 'C++' NAME 'ImageToGreyParserFactory' LIBRARY ImageTools  NOT FENCED;

CREATE LIBRARY TransformFunctions AS '/data/verticaextension/build/TransformFunctions.so' LANGUAGE 'C++';
CREATE TRANSFORM FUNCTION RGBToRGBGrey AS LANGUAGE 'C++' NAME 'RGBToRGBGreyFactory' LIBRARY TransformFunctions NOT FENCED;
CREATE TRANSFORM FUNCTION RGBToGrey AS LANGUAGE 'C++' NAME 'RGBToGreyFactory' LIBRARY TransformFunctions NOT FENCED;
CREATE TRANSFORM FUNCTION GetDetailedHistogramV AS LANGUAGE 'C++' NAME 'GetDetailedHistogramVFactory' LIBRARY TransformFunctions NOT FENCED;
CREATE TRANSFORM FUNCTION GetDetailedHistogramH AS LANGUAGE 'C++' NAME 'GetDetailedHistogramHFactory' LIBRARY TransformFunctions NOT FENCED;
CREATE TRANSFORM FUNCTION SimplifyHistogramV AS LANGUAGE 'C++' NAME 'SimplifyHistogramVFactory' LIBRARY TransformFunctions NOT FENCED;
CREATE TRANSFORM FUNCTION SimplifyHistogramH AS LANGUAGE 'C++' NAME 'SimplifyHistogramHFactory' LIBRARY TransformFunctions NOT FENCED;
CREATE TRANSFORM FUNCTION TransposeHistogram AS LANGUAGE 'C++' NAME 'TransposeHistogramFactory' LIBRARY TransformFunctions NOT FENCED;

CREATE USER classifier;
GRANT ALL ON ALL TABLES IN SCHEMA public TO classifier;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO classifier;
CREATE LOCATION '/data/images' ALL NODES USAGE 'USER';
GRANT ALL ON LOCATION '/data/images' TO classifier;
