#!/bin/bash
#
# cIPT: column-store Image Processing Toolbox
#==============================================================================
# author: Tobias Vincon
# DualStudy@HPE: http://h41387.www4.hpe.com/dualstudy/index.html
# DBLab: https://dblab.reutlingen-university.de/
#==============================================================================

databasename='ImageToolset'
username='classifier'
username_admin='dbadmin'
password='ImageToolset'

dir='/data/verticaextension/classifier'

paramset=0

# storeMeasuringData
# $1 timestamp date
# $2 timestamp time
# $3 type
storeMeasuringData(){
	local starttimestamp="$1 $2"
	local filetimestamp="$1_$2"
	local type="$3"
	filetimestamp=${filetimestamp//[:]/-}

	#/opt/vertica/bin/vsql -d $databasename -U $username_admin -w $password -F $'|' -A -o ${dir}/measuring_results/measuring_resources-${type}-${paramset}-$filetimestamp.csv -c "SELECT ${paramset} as paramset, '${type}' as type, DENSE_RANK() OVER (ORDER BY cpu.start_time ASC) AS timeid, cpu.start_time, cpu.end_time, cpu.average_cpu_usage_percent, memory.average_memory_usage_percent, io.read_kbytes_per_sec, io.written_kbytes_per_sec FROM v_monitor.cpu_usage AS cpu LEFT OUTER JOIN v_monitor.memory_usage memory ON (cpu.start_time = memory.start_time) LEFT OUTER JOIN v_monitor.io_usage io ON (cpu.start_time = io.start_time) WHERE cpu.start_time >= TIMESTAMPADD(mi ,0 , '${starttimestamp}') ORDER BY cpu.start_time ASC;"
	#/opt/vertica/bin/vsql -d $databasename -U $username_admin -w $password -F $'|' -A -o ${dir}/measuring_results/measuring_requests-${type}-${paramset}-$filetimestamp.csv -c "SELECT ${paramset} as paramset, '${type}' as type, DENSE_RANK() OVER (ORDER BY qr.start_timestamp ASC) AS timeid, qr.start_timestamp, qr.end_timestamp, qr.request_duration_ms, qr.memory_acquired_mb, qr.request FROM v_monitor.query_requests qr WHERE qr.user_name = 'classifier' AND qr.start_timestamp >= TIMESTAMPADD(mi ,0 , '${starttimestamp}') ORDER BY qr.start_timestamp ASC;"
	#/opt/vertica/bin/vsql -d $databasename -U $username_admin -w $password -F $'|' -A -o ${dir}/measuring_results/measuring_storage-${type}-${paramset}-$filetimestamp.csv -c "SELECT ${paramset} as paramset, '${type}' as type, NOW() as current_timestamp, column_storage.anchor_table_schema, column_storage.anchor_table_name, column_storage.used_compressed_gb AS used_compressed_gb_column, projection_storage.used_compressed_gb AS used_compressed_gb_projection FROM (SELECT anchor_table_schema, anchor_table_name, SUM(used_bytes) / ( 1024^3 ) AS used_compressed_gb FROM v_monitor.column_storage GROUP BY anchor_table_schema, anchor_table_name ORDER BY SUM(used_bytes) DESC) AS column_storage LEFT OUTER JOIN ( SELECT anchor_table_schema, anchor_table_name, SUM(used_bytes) / ( 1024^3 ) AS used_compressed_gb FROM v_monitor.projection_storage GROUP BY anchor_table_schema, anchor_table_name ORDER BY SUM(used_bytes) DESC) projection_storage ON (column_storage.anchor_table_name = projection_storage.anchor_table_name);"
}

# reset
reset(){
	/opt/vertica/bin/vsql -d $databasename -U $username_admin -w $password -f "/data/verticaextension/classifier/reset.sql"
}

# calcHistogramBoundingBox
# $1: channelid
# $2: channelname
# $3: binnumber
# $4: min
# $5: max
# $6: cutminmax
# $7: x
# $8: y
# $9: width
# $10: height
calcHistogramBoundingBox(){
	echo 'Calculate histogram_v Bounding Box'
	local timestamp=$(date +"%Y-%m-%d %H:%M:00")
	/opt/vertica/bin/vsql -At -d $databasename -U $username -w $password -c "INSERT INTO histogram_v SELECT h.imageid, $1, $3, $4, $5, $6, h.bin, COUNT(h.bin) FROM (SELECT imageid, $2, WIDTH_BUCKET($2,$4,$5,$3) as bin FROM image_rgb_grey WHERE BB_WITHIN(x,y,$7,$8,$9+$7,${10}+$8)) as h GROUP BY h.imageid, h.bin ORDER BY bin;COMMIT;"
	storeMeasuringData $timestamp "histogram_v"
	
	echo 'Calculate histogram_h Bounding Box'
	timestamp=$(date +"%Y-%m-%d %H:%M:00")
	/opt/vertica/bin/vsql -At -d $databasename -U $username -w $password -c "INSERT INTO histogram_h SELECT TransposeHistogram(hist.imageid, hist.channel, hist.binnumber, hist.min, hist.max, hist.cutminmax, hist.bin, hist.frequency) OVER (PARTITION BY imageid) FROM (SELECT  h.imageid  as imageid, $1 as channel, $3 as binnumber, $4 as min, $5 as max, $6 as cutminmax, h.bin, COUNT(h.bin) as frequency FROM (SELECT imageid, $2, WIDTH_BUCKET($2,$4,$5,$3) as bin FROM image_rgb_grey WHERE BB_WITHIN(x,y,$7,$8,$9+$7,${10}+$8)) as h GROUP BY h.imageid, h.bin ORDER BY h.bin) as hist;COMMIT;"
	storeMeasuringData $timestamp "histogram_h"
}

# calcHistogramCircle
# $1: channelid
# $2: channelname
# $3: binnumber
# $4: min
# $5: max
# $6: cutminmax
# $7: x
# $8: y
# $9: radius
calcHistogramCircle(){
	echo 'Calculate histogram_v Circle'
	local timestamp=$(date +"%Y-%m-%d %H:%M:00")
	/opt/vertica/bin/vsql -At -d $databasename -U $username -w $password -c "INSERT INTO histogram_v SELECT h.imageid, $1, $3, $4, $5, $6, h.bin, COUNT(h.bin) FROM (SELECT imageid, $2, WIDTH_BUCKET($2,$4,$5,$3) as bin FROM image_rgb_grey WHERE LLD_WITHIN(x,y,$7,$8,$9)) as h GROUP BY h.imageid, h.bin ORDER BY bin;COMMIT;"
	storeMeasuringData $timestamp "histogram_v"
	
	echo 'Calculate histogram_h Circle'
	timestamp=$(date +"%Y-%m-%d %H:%M:00")
	/opt/vertica/bin/vsql -At -d $databasename -U $username -w $password -c "INSERT INTO histogram_h SELECT TransposeHistogram(hist.imageid, hist.channel, hist.binnumber, hist.min, hist.max, hist.cutminmax, hist.bin, hist.frequency) OVER (PARTITION BY imageid) FROM (SELECT  h.imageid  as imageid, $1 as channel, $3 as binnumber, $4 as min, $5 as max, $6 as cutminmax, h.bin, COUNT(h.bin) as frequency FROM (SELECT imageid, $2, WIDTH_BUCKET($2,$4,$5,$3) as bin FROM image_rgb_grey WHERE LLD_WITHIN(x,y,$7,$8,$9)) as h GROUP BY h.imageid, h.bin ORDER BY h.bin) as hist;COMMIT;"
	storeMeasuringData $timestamp "histogram_h"
}

# calcAvgHistogram
# $1: classid
calcAvgHistogram(){
	echo 'Calculate average histogram_v'
	timestamp=$(date +"%Y-%m-%d %H:%M:00")
	/opt/vertica/bin/vsql -At -d $databasename -U $username -w $password -c "INSERT INTO histogram_v SELECT (-$1)-1, AVG(channel), AVG(binnumber), AVG(min), AVG(max), false, bin, avg(frequency) FROM histogram_v h, image_characteristics c WHERE h.imageid = c.imageid and c.is_training = true and c.classid = $1 GROUP BY bin;COMMIT;"
	storeMeasuringData $timestamp "calavg_v"
	
	echo 'Calculate average histogram_h'
	local timestamp=$(date +"%Y-%m-%d %H:%M:00")
	/opt/vertica/bin/vsql -At -d $databasename -U $username -w $password -c "INSERT INTO histogram_h SELECT (-$1)-1, AVG(channel), AVG(binnumber), AVG(min), AVG(max), false, AVG(bin_0), AVG(bin_1), AVG(bin_2), AVG(bin_3), AVG(bin_4), AVG(bin_5), AVG(bin_6), AVG(bin_7), AVG(bin_8), AVG(bin_9), AVG(bin_10), AVG(bin_11), AVG(bin_12), AVG(bin_13), AVG(bin_14), AVG(bin_15), AVG(bin_16), AVG(bin_17), AVG(bin_18), AVG(bin_19), AVG(bin_20), AVG(bin_21), AVG(bin_22), AVG(bin_23), AVG(bin_24), AVG(bin_25), AVG(bin_26), AVG(bin_27), AVG(bin_28), AVG(bin_29), AVG(bin_30), AVG(bin_31), AVG(bin_32), AVG(bin_33), AVG(bin_34), AVG(bin_35), AVG(bin_36), AVG(bin_37), AVG(bin_38), AVG(bin_39), AVG(bin_40), AVG(bin_41), AVG(bin_42), AVG(bin_43), AVG(bin_44), AVG(bin_45), AVG(bin_46), AVG(bin_47), AVG(bin_48), AVG(bin_49), AVG(bin_50), AVG(bin_51), AVG(bin_52), AVG(bin_53), AVG(bin_54), AVG(bin_55), AVG(bin_56), AVG(bin_57), AVG(bin_58), AVG(bin_59), AVG(bin_60), AVG(bin_61), AVG(bin_62), AVG(bin_63), AVG(bin_64), AVG(bin_65), AVG(bin_66), AVG(bin_67), AVG(bin_68), AVG(bin_69), AVG(bin_70), AVG(bin_71), AVG(bin_72), AVG(bin_73), AVG(bin_74), AVG(bin_75), AVG(bin_76), AVG(bin_77), AVG(bin_78), AVG(bin_79), AVG(bin_80), AVG(bin_81), AVG(bin_82), AVG(bin_83), AVG(bin_84), AVG(bin_85), AVG(bin_86), AVG(bin_87), AVG(bin_88), AVG(bin_89), AVG(bin_90), AVG(bin_91), AVG(bin_92), AVG(bin_93), AVG(bin_94), AVG(bin_95), AVG(bin_96), AVG(bin_97), AVG(bin_98), AVG(bin_99), AVG(bin_100), AVG(bin_101), AVG(bin_102), AVG(bin_103), AVG(bin_104), AVG(bin_105), AVG(bin_106), AVG(bin_107), AVG(bin_108), AVG(bin_109), AVG(bin_110), AVG(bin_111), AVG(bin_112), AVG(bin_113), AVG(bin_114), AVG(bin_115), AVG(bin_116), AVG(bin_117), AVG(bin_118), AVG(bin_119), AVG(bin_120), AVG(bin_121), AVG(bin_122), AVG(bin_123), AVG(bin_124), AVG(bin_125), AVG(bin_126), AVG(bin_127), AVG(bin_128), AVG(bin_129), AVG(bin_130), AVG(bin_131), AVG(bin_132), AVG(bin_133), AVG(bin_134), AVG(bin_135), AVG(bin_136), AVG(bin_137), AVG(bin_138), AVG(bin_139), AVG(bin_140), AVG(bin_141), AVG(bin_142), AVG(bin_143), AVG(bin_144), AVG(bin_145), AVG(bin_146), AVG(bin_147), AVG(bin_148), AVG(bin_149), AVG(bin_150), AVG(bin_151), AVG(bin_152), AVG(bin_153), AVG(bin_154), AVG(bin_155), AVG(bin_156), AVG(bin_157), AVG(bin_158), AVG(bin_159), AVG(bin_160), AVG(bin_161), AVG(bin_162), AVG(bin_163), AVG(bin_164), AVG(bin_165), AVG(bin_166), AVG(bin_167), AVG(bin_168), AVG(bin_169), AVG(bin_170), AVG(bin_171), AVG(bin_172), AVG(bin_173), AVG(bin_174), AVG(bin_175), AVG(bin_176), AVG(bin_177), AVG(bin_178), AVG(bin_179), AVG(bin_180), AVG(bin_181), AVG(bin_182), AVG(bin_183), AVG(bin_184), AVG(bin_185), AVG(bin_186), AVG(bin_187), AVG(bin_188), AVG(bin_189), AVG(bin_190), AVG(bin_191), AVG(bin_192), AVG(bin_193), AVG(bin_194), AVG(bin_195), AVG(bin_196), AVG(bin_197), AVG(bin_198), AVG(bin_199), AVG(bin_200), AVG(bin_201), AVG(bin_202), AVG(bin_203), AVG(bin_204), AVG(bin_205), AVG(bin_206), AVG(bin_207), AVG(bin_208), AVG(bin_209), AVG(bin_210), AVG(bin_211), AVG(bin_212), AVG(bin_213), AVG(bin_214), AVG(bin_215), AVG(bin_216), AVG(bin_217), AVG(bin_218), AVG(bin_219), AVG(bin_220), AVG(bin_221), AVG(bin_222), AVG(bin_223), AVG(bin_224), AVG(bin_225), AVG(bin_226), AVG(bin_227), AVG(bin_228), AVG(bin_229), AVG(bin_230), AVG(bin_231), AVG(bin_232), AVG(bin_233), AVG(bin_234), AVG(bin_235), AVG(bin_236), AVG(bin_237), AVG(bin_238), AVG(bin_239), AVG(bin_240), AVG(bin_241), AVG(bin_242), AVG(bin_243), AVG(bin_244), AVG(bin_245), AVG(bin_246), AVG(bin_247), AVG(bin_248), AVG(bin_249), AVG(bin_250), AVG(bin_251), AVG(bin_252), AVG(bin_253), AVG(bin_254), AVG(bin_255) FROM histogram_h h, image_characteristics c WHERE h.imageid = c.imageid and c.is_training = true and c.classid = $1;COMMIT;"
	storeMeasuringData $timestamp "calavg_h"	
}

# calcDistanceMetric
# $1: classid
calcDistanceMetric(){
	echo 'Calculate Distance Metric manhatten_v'
	local timestamp=$(date +"%Y-%m-%d %H:%M:00")
	/opt/vertica/bin/vsql -At -d $databasename -U $username -w $password -c "INSERT INTO classifier_result SELECT ${paramset}, 'histogram_v', hist.imageid, $1, 'manhatten', SUM(hist.dist) FROM (SELECT h.imageid, h.bin, h.frequency, a.frequency, ABS(h.frequency-a.frequency) as dist FROM histogram_v h LEFT JOIN image_characteristics c ON h.imageid = c.imageid LEFT JOIN (SELECT bin, frequency FROM histogram_v h WHERE imageid = (-$1)-1) a ON h.bin = a.bin WHERE c.is_test = true) as hist GROUP BY hist.imageid;COMMIT;"
	storeMeasuringData $timestamp "manhatten_v"
	
	echo 'Calculate Distance Metric euclidean_v'
	local timestamp=$(date +"%Y-%m-%d %H:%M:00")
	/opt/vertica/bin/vsql -At -d $databasename -U $username -w $password -c "INSERT INTO classifier_result SELECT ${paramset}, 'histogram_v' , hist.imageid, $1, 'euclidean', SQRT(SUM(hist.dist)) FROM (SELECT h.imageid, h.bin, h.frequency, a.frequency, POWER(h.frequency-a.frequency,2.0) as dist FROM histogram_v h LEFT JOIN image_characteristics c ON h.imageid = c.imageid LEFT JOIN (SELECT bin, frequency FROM histogram_v h WHERE imageid = (-$1)-1) a ON h.bin = a.bin WHERE c.is_test = true) as hist GROUP BY hist.imageid;COMMIT;"
	storeMeasuringData $timestamp "euclidean_v"

	echo 'Calculate Distance Metric manhatten_h'
	local timestamp=$(date +"%Y-%m-%d %H:%M:00")
	/opt/vertica/bin/vsql -At -d $databasename -U $username -w $password -c "INSERT INTO classifier_result SELECT ${paramset}, 'histogram_h' , h.imageid, $1, 'manhatten', ( ABS(h.bin_0-avgh.bin_0)+ ABS(h.bin_1-avgh.bin_1)+ ABS(h.bin_2-avgh.bin_2)+ ABS(h.bin_3-avgh.bin_3)+ ABS(h.bin_4-avgh.bin_4)+ ABS(h.bin_5-avgh.bin_5)+ ABS(h.bin_6-avgh.bin_6)+ ABS(h.bin_7-avgh.bin_7)+ ABS(h.bin_8-avgh.bin_8)+ ABS(h.bin_9-avgh.bin_9)+ ABS(h.bin_10-avgh.bin_10)+ ABS(h.bin_11-avgh.bin_11)+ ABS(h.bin_12-avgh.bin_12)+ ABS(h.bin_13-avgh.bin_13)+ ABS(h.bin_14-avgh.bin_14)+ ABS(h.bin_15-avgh.bin_15)+ ABS(h.bin_16-avgh.bin_16)+ ABS(h.bin_17-avgh.bin_17)+ ABS(h.bin_18-avgh.bin_18)+ ABS(h.bin_19-avgh.bin_19)+ ABS(h.bin_20-avgh.bin_20)+ ABS(h.bin_21-avgh.bin_21)+ ABS(h.bin_22-avgh.bin_22)+ ABS(h.bin_23-avgh.bin_23)+ ABS(h.bin_24-avgh.bin_24)+ ABS(h.bin_25-avgh.bin_25)+ ABS(h.bin_26-avgh.bin_26)+ ABS(h.bin_27-avgh.bin_27)+ ABS(h.bin_28-avgh.bin_28)+ ABS(h.bin_29-avgh.bin_29)+ ABS(h.bin_30-avgh.bin_30)+ ABS(h.bin_31-avgh.bin_31)+ ABS(h.bin_32-avgh.bin_32)+ ABS(h.bin_33-avgh.bin_33)+ ABS(h.bin_34-avgh.bin_34)+ ABS(h.bin_35-avgh.bin_35)+ ABS(h.bin_36-avgh.bin_36)+ ABS(h.bin_37-avgh.bin_37)+ ABS(h.bin_38-avgh.bin_38)+ ABS(h.bin_39-avgh.bin_39)+ ABS(h.bin_40-avgh.bin_40)+ ABS(h.bin_41-avgh.bin_41)+ ABS(h.bin_42-avgh.bin_42)+ ABS(h.bin_43-avgh.bin_43)+ ABS(h.bin_44-avgh.bin_44)+ ABS(h.bin_45-avgh.bin_45)+ ABS(h.bin_46-avgh.bin_46)+ ABS(h.bin_47-avgh.bin_47)+ ABS(h.bin_48-avgh.bin_48)+ ABS(h.bin_49-avgh.bin_49)+ ABS(h.bin_50-avgh.bin_50)+ ABS(h.bin_51-avgh.bin_51)+ ABS(h.bin_52-avgh.bin_52)+ ABS(h.bin_53-avgh.bin_53)+ ABS(h.bin_54-avgh.bin_54)+ ABS(h.bin_55-avgh.bin_55)+ ABS(h.bin_56-avgh.bin_56)+ ABS(h.bin_57-avgh.bin_57)+ ABS(h.bin_58-avgh.bin_58)+ ABS(h.bin_59-avgh.bin_59)+ ABS(h.bin_60-avgh.bin_60)+ ABS(h.bin_61-avgh.bin_61)+ ABS(h.bin_62-avgh.bin_62)+ ABS(h.bin_63-avgh.bin_63)+ ABS(h.bin_64-avgh.bin_64)+ ABS(h.bin_65-avgh.bin_65)+ ABS(h.bin_66-avgh.bin_66)+ ABS(h.bin_67-avgh.bin_67)+ ABS(h.bin_68-avgh.bin_68)+ ABS(h.bin_69-avgh.bin_69)+ ABS(h.bin_70-avgh.bin_70)+ ABS(h.bin_71-avgh.bin_71)+ ABS(h.bin_72-avgh.bin_72)+ ABS(h.bin_73-avgh.bin_73)+ ABS(h.bin_74-avgh.bin_74)+ ABS(h.bin_75-avgh.bin_75)+ ABS(h.bin_76-avgh.bin_76)+ ABS(h.bin_77-avgh.bin_77)+ ABS(h.bin_78-avgh.bin_78)+ ABS(h.bin_79-avgh.bin_79)+ ABS(h.bin_80-avgh.bin_80)+ ABS(h.bin_81-avgh.bin_81)+ ABS(h.bin_82-avgh.bin_82)+ ABS(h.bin_83-avgh.bin_83)+ ABS(h.bin_84-avgh.bin_84)+ ABS(h.bin_85-avgh.bin_85)+ ABS(h.bin_86-avgh.bin_86)+ ABS(h.bin_87-avgh.bin_87)+ ABS(h.bin_88-avgh.bin_88)+ ABS(h.bin_89-avgh.bin_89)+ ABS(h.bin_90-avgh.bin_90)+ ABS(h.bin_91-avgh.bin_91)+ ABS(h.bin_92-avgh.bin_92)+ ABS(h.bin_93-avgh.bin_93)+ ABS(h.bin_94-avgh.bin_94)+ ABS(h.bin_95-avgh.bin_95)+ ABS(h.bin_96-avgh.bin_96)+ ABS(h.bin_97-avgh.bin_97)+ ABS(h.bin_98-avgh.bin_98)+ ABS(h.bin_99-avgh.bin_99)+ ABS(h.bin_100-avgh.bin_100)+ ABS(h.bin_101-avgh.bin_101)+ ABS(h.bin_102-avgh.bin_102)+ ABS(h.bin_103-avgh.bin_103)+ ABS(h.bin_104-avgh.bin_104)+ ABS(h.bin_105-avgh.bin_105)+ ABS(h.bin_106-avgh.bin_106)+ ABS(h.bin_107-avgh.bin_107)+ ABS(h.bin_108-avgh.bin_108)+ ABS(h.bin_109-avgh.bin_109)+ ABS(h.bin_110-avgh.bin_110)+ ABS(h.bin_111-avgh.bin_111)+ ABS(h.bin_112-avgh.bin_112)+ ABS(h.bin_113-avgh.bin_113)+ ABS(h.bin_114-avgh.bin_114)+ ABS(h.bin_115-avgh.bin_115)+ ABS(h.bin_116-avgh.bin_116)+ ABS(h.bin_117-avgh.bin_117)+ ABS(h.bin_118-avgh.bin_118)+ ABS(h.bin_119-avgh.bin_119)+ ABS(h.bin_120-avgh.bin_120)+ ABS(h.bin_121-avgh.bin_121)+ ABS(h.bin_122-avgh.bin_122)+ ABS(h.bin_123-avgh.bin_123)+ ABS(h.bin_124-avgh.bin_124)+ ABS(h.bin_125-avgh.bin_125)+ ABS(h.bin_126-avgh.bin_126)+ ABS(h.bin_127-avgh.bin_127)+ ABS(h.bin_128-avgh.bin_128)+ ABS(h.bin_129-avgh.bin_129)+ ABS(h.bin_130-avgh.bin_130)+ ABS(h.bin_131-avgh.bin_131)+ ABS(h.bin_132-avgh.bin_132)+ ABS(h.bin_133-avgh.bin_133)+ ABS(h.bin_134-avgh.bin_134)+ ABS(h.bin_135-avgh.bin_135)+ ABS(h.bin_136-avgh.bin_136)+ ABS(h.bin_137-avgh.bin_137)+ ABS(h.bin_138-avgh.bin_138)+ ABS(h.bin_139-avgh.bin_139)+ ABS(h.bin_140-avgh.bin_140)+ ABS(h.bin_141-avgh.bin_141)+ ABS(h.bin_142-avgh.bin_142)+ ABS(h.bin_143-avgh.bin_143)+ ABS(h.bin_144-avgh.bin_144)+ ABS(h.bin_145-avgh.bin_145)+ ABS(h.bin_146-avgh.bin_146)+ ABS(h.bin_147-avgh.bin_147)+ ABS(h.bin_148-avgh.bin_148)+ ABS(h.bin_149-avgh.bin_149)+ ABS(h.bin_150-avgh.bin_150)+ ABS(h.bin_151-avgh.bin_151)+ ABS(h.bin_152-avgh.bin_152)+ ABS(h.bin_153-avgh.bin_153)+ ABS(h.bin_154-avgh.bin_154)+ ABS(h.bin_155-avgh.bin_155)+ ABS(h.bin_156-avgh.bin_156)+ ABS(h.bin_157-avgh.bin_157)+ ABS(h.bin_158-avgh.bin_158)+ ABS(h.bin_159-avgh.bin_159)+ ABS(h.bin_160-avgh.bin_160)+ ABS(h.bin_161-avgh.bin_161)+ ABS(h.bin_162-avgh.bin_162)+ ABS(h.bin_163-avgh.bin_163)+ ABS(h.bin_164-avgh.bin_164)+ ABS(h.bin_165-avgh.bin_165)+ ABS(h.bin_166-avgh.bin_166)+ ABS(h.bin_167-avgh.bin_167)+ ABS(h.bin_168-avgh.bin_168)+ ABS(h.bin_169-avgh.bin_169)+ ABS(h.bin_170-avgh.bin_170)+ ABS(h.bin_171-avgh.bin_171)+ ABS(h.bin_172-avgh.bin_172)+ ABS(h.bin_173-avgh.bin_173)+ ABS(h.bin_174-avgh.bin_174)+ ABS(h.bin_175-avgh.bin_175)+ ABS(h.bin_176-avgh.bin_176)+ ABS(h.bin_177-avgh.bin_177)+ ABS(h.bin_178-avgh.bin_178)+ ABS(h.bin_179-avgh.bin_179)+ ABS(h.bin_180-avgh.bin_180)+ ABS(h.bin_181-avgh.bin_181)+ ABS(h.bin_182-avgh.bin_182)+ ABS(h.bin_183-avgh.bin_183)+ ABS(h.bin_184-avgh.bin_184)+ ABS(h.bin_185-avgh.bin_185)+ ABS(h.bin_186-avgh.bin_186)+ ABS(h.bin_187-avgh.bin_187)+ ABS(h.bin_188-avgh.bin_188)+ ABS(h.bin_189-avgh.bin_189)+ ABS(h.bin_190-avgh.bin_190)+ ABS(h.bin_191-avgh.bin_191)+ ABS(h.bin_192-avgh.bin_192)+ ABS(h.bin_193-avgh.bin_193)+ ABS(h.bin_194-avgh.bin_194)+ ABS(h.bin_195-avgh.bin_195)+ ABS(h.bin_196-avgh.bin_196)+ ABS(h.bin_197-avgh.bin_197)+ ABS(h.bin_198-avgh.bin_198)+ ABS(h.bin_199-avgh.bin_199)+ ABS(h.bin_200-avgh.bin_200)+ ABS(h.bin_201-avgh.bin_201)+ ABS(h.bin_202-avgh.bin_202)+ ABS(h.bin_203-avgh.bin_203)+ ABS(h.bin_204-avgh.bin_204)+ ABS(h.bin_205-avgh.bin_205)+ ABS(h.bin_206-avgh.bin_206)+ ABS(h.bin_207-avgh.bin_207)+ ABS(h.bin_208-avgh.bin_208)+ ABS(h.bin_209-avgh.bin_209)+ ABS(h.bin_210-avgh.bin_210)+ ABS(h.bin_211-avgh.bin_211)+ ABS(h.bin_212-avgh.bin_212)+ ABS(h.bin_213-avgh.bin_213)+ ABS(h.bin_214-avgh.bin_214)+ ABS(h.bin_215-avgh.bin_215)+ ABS(h.bin_216-avgh.bin_216)+ ABS(h.bin_217-avgh.bin_217)+ ABS(h.bin_218-avgh.bin_218)+ ABS(h.bin_219-avgh.bin_219)+ ABS(h.bin_220-avgh.bin_220)+ ABS(h.bin_221-avgh.bin_221)+ ABS(h.bin_222-avgh.bin_222)+ ABS(h.bin_223-avgh.bin_223)+ ABS(h.bin_224-avgh.bin_224)+ ABS(h.bin_225-avgh.bin_225)+ ABS(h.bin_226-avgh.bin_226)+ ABS(h.bin_227-avgh.bin_227)+ ABS(h.bin_228-avgh.bin_228)+ ABS(h.bin_229-avgh.bin_229)+ ABS(h.bin_230-avgh.bin_230)+ ABS(h.bin_231-avgh.bin_231)+ ABS(h.bin_232-avgh.bin_232)+ ABS(h.bin_233-avgh.bin_233)+ ABS(h.bin_234-avgh.bin_234)+ ABS(h.bin_235-avgh.bin_235)+ ABS(h.bin_236-avgh.bin_236)+ ABS(h.bin_237-avgh.bin_237)+ ABS(h.bin_238-avgh.bin_238)+ ABS(h.bin_239-avgh.bin_239)+ ABS(h.bin_240-avgh.bin_240)+ ABS(h.bin_241-avgh.bin_241)+ ABS(h.bin_242-avgh.bin_242)+ ABS(h.bin_243-avgh.bin_243)+ ABS(h.bin_244-avgh.bin_244)+ ABS(h.bin_245-avgh.bin_245)+ ABS(h.bin_246-avgh.bin_246)+ ABS(h.bin_247-avgh.bin_247)+ ABS(h.bin_248-avgh.bin_248)+ ABS(h.bin_249-avgh.bin_249)+ ABS(h.bin_250-avgh.bin_250)+ ABS(h.bin_251-avgh.bin_251)+ ABS(h.bin_252-avgh.bin_252)+ ABS(h.bin_253-avgh.bin_253)+ ABS(h.bin_254-avgh.bin_254)+ ABS(h.bin_255-avgh.bin_255) )FROM (SELECT * FROM histogram_h WHERE imageid = (-$1)-1) avgh, histogram_h h LEFT JOIN image_characteristics c ON h.imageid = c.imageid WHERE c.is_test = true;COMMIT;"
	storeMeasuringData $timestamp "manhatten_h"
	
	echo 'Calculate Distance Metric euclidean_h'
	local timestamp=$(date +"%Y-%m-%d %H:%M:00")
	/opt/vertica/bin/vsql -At -d $databasename -U $username -w $password -c "INSERT INTO classifier_result SELECT ${paramset}, 'histogram_h' , h.imageid, $1, 'euclidean', SQRT( POWER(h.bin_0-avgh.bin_0,2.0)+ POWER(h.bin_1-avgh.bin_1,2.0)+ POWER(h.bin_2-avgh.bin_2,2.0)+ POWER(h.bin_3-avgh.bin_3,2.0)+ POWER(h.bin_4-avgh.bin_4,2.0)+ POWER(h.bin_5-avgh.bin_5,2.0)+ POWER(h.bin_6-avgh.bin_6,2.0)+ POWER(h.bin_7-avgh.bin_7,2.0)+ POWER(h.bin_8-avgh.bin_8,2.0)+ POWER(h.bin_9-avgh.bin_9,2.0)+ POWER(h.bin_10-avgh.bin_10,2.0)+ POWER(h.bin_11-avgh.bin_11,2.0)+ POWER(h.bin_12-avgh.bin_12,2.0)+ POWER(h.bin_13-avgh.bin_13,2.0)+ POWER(h.bin_14-avgh.bin_14,2.0)+ POWER(h.bin_15-avgh.bin_15,2.0)+ POWER(h.bin_16-avgh.bin_16,2.0)+ POWER(h.bin_17-avgh.bin_17,2.0)+ POWER(h.bin_18-avgh.bin_18,2.0)+ POWER(h.bin_19-avgh.bin_19,2.0)+ POWER(h.bin_20-avgh.bin_20,2.0)+ POWER(h.bin_21-avgh.bin_21,2.0)+ POWER(h.bin_22-avgh.bin_22,2.0)+ POWER(h.bin_23-avgh.bin_23,2.0)+ POWER(h.bin_24-avgh.bin_24,2.0)+ POWER(h.bin_25-avgh.bin_25,2.0)+ POWER(h.bin_26-avgh.bin_26,2.0)+ POWER(h.bin_27-avgh.bin_27,2.0)+ POWER(h.bin_28-avgh.bin_28,2.0)+ POWER(h.bin_29-avgh.bin_29,2.0)+ POWER(h.bin_30-avgh.bin_30,2.0)+ POWER(h.bin_31-avgh.bin_31,2.0)+ POWER(h.bin_32-avgh.bin_32,2.0)+ POWER(h.bin_33-avgh.bin_33,2.0)+ POWER(h.bin_34-avgh.bin_34,2.0)+ POWER(h.bin_35-avgh.bin_35,2.0)+ POWER(h.bin_36-avgh.bin_36,2.0)+ POWER(h.bin_37-avgh.bin_37,2.0)+ POWER(h.bin_38-avgh.bin_38,2.0)+ POWER(h.bin_39-avgh.bin_39,2.0)+ POWER(h.bin_40-avgh.bin_40,2.0)+ POWER(h.bin_41-avgh.bin_41,2.0)+ POWER(h.bin_42-avgh.bin_42,2.0)+ POWER(h.bin_43-avgh.bin_43,2.0)+ POWER(h.bin_44-avgh.bin_44,2.0)+ POWER(h.bin_45-avgh.bin_45,2.0)+ POWER(h.bin_46-avgh.bin_46,2.0)+ POWER(h.bin_47-avgh.bin_47,2.0)+ POWER(h.bin_48-avgh.bin_48,2.0)+ POWER(h.bin_49-avgh.bin_49,2.0)+ POWER(h.bin_50-avgh.bin_50,2.0)+ POWER(h.bin_51-avgh.bin_51,2.0)+ POWER(h.bin_52-avgh.bin_52,2.0)+ POWER(h.bin_53-avgh.bin_53,2.0)+ POWER(h.bin_54-avgh.bin_54,2.0)+ POWER(h.bin_55-avgh.bin_55,2.0)+ POWER(h.bin_56-avgh.bin_56,2.0)+ POWER(h.bin_57-avgh.bin_57,2.0)+ POWER(h.bin_58-avgh.bin_58,2.0)+ POWER(h.bin_59-avgh.bin_59,2.0)+ POWER(h.bin_60-avgh.bin_60,2.0)+ POWER(h.bin_61-avgh.bin_61,2.0)+ POWER(h.bin_62-avgh.bin_62,2.0)+ POWER(h.bin_63-avgh.bin_63,2.0)+ POWER(h.bin_64-avgh.bin_64,2.0)+ POWER(h.bin_65-avgh.bin_65,2.0)+ POWER(h.bin_66-avgh.bin_66,2.0)+ POWER(h.bin_67-avgh.bin_67,2.0)+ POWER(h.bin_68-avgh.bin_68,2.0)+ POWER(h.bin_69-avgh.bin_69,2.0)+ POWER(h.bin_70-avgh.bin_70,2.0)+ POWER(h.bin_71-avgh.bin_71,2.0)+ POWER(h.bin_72-avgh.bin_72,2.0)+ POWER(h.bin_73-avgh.bin_73,2.0)+ POWER(h.bin_74-avgh.bin_74,2.0)+ POWER(h.bin_75-avgh.bin_75,2.0)+ POWER(h.bin_76-avgh.bin_76,2.0)+ POWER(h.bin_77-avgh.bin_77,2.0)+ POWER(h.bin_78-avgh.bin_78,2.0)+ POWER(h.bin_79-avgh.bin_79,2.0)+ POWER(h.bin_80-avgh.bin_80,2.0)+ POWER(h.bin_81-avgh.bin_81,2.0)+ POWER(h.bin_82-avgh.bin_82,2.0)+ POWER(h.bin_83-avgh.bin_83,2.0)+ POWER(h.bin_84-avgh.bin_84,2.0)+ POWER(h.bin_85-avgh.bin_85,2.0)+ POWER(h.bin_86-avgh.bin_86,2.0)+ POWER(h.bin_87-avgh.bin_87,2.0)+ POWER(h.bin_88-avgh.bin_88,2.0)+ POWER(h.bin_89-avgh.bin_89,2.0)+ POWER(h.bin_90-avgh.bin_90,2.0)+ POWER(h.bin_91-avgh.bin_91,2.0)+ POWER(h.bin_92-avgh.bin_92,2.0)+ POWER(h.bin_93-avgh.bin_93,2.0)+ POWER(h.bin_94-avgh.bin_94,2.0)+ POWER(h.bin_95-avgh.bin_95,2.0)+ POWER(h.bin_96-avgh.bin_96,2.0)+ POWER(h.bin_97-avgh.bin_97,2.0)+ POWER(h.bin_98-avgh.bin_98,2.0)+ POWER(h.bin_99-avgh.bin_99,2.0)+ POWER(h.bin_100-avgh.bin_100,2.0)+ POWER(h.bin_101-avgh.bin_101,2.0)+ POWER(h.bin_102-avgh.bin_102,2.0)+ POWER(h.bin_103-avgh.bin_103,2.0)+ POWER(h.bin_104-avgh.bin_104,2.0)+ POWER(h.bin_105-avgh.bin_105,2.0)+ POWER(h.bin_106-avgh.bin_106,2.0)+ POWER(h.bin_107-avgh.bin_107,2.0)+ POWER(h.bin_108-avgh.bin_108,2.0)+ POWER(h.bin_109-avgh.bin_109,2.0)+ POWER(h.bin_110-avgh.bin_110,2.0)+ POWER(h.bin_111-avgh.bin_111,2.0)+ POWER(h.bin_112-avgh.bin_112,2.0)+ POWER(h.bin_113-avgh.bin_113,2.0)+ POWER(h.bin_114-avgh.bin_114,2.0)+ POWER(h.bin_115-avgh.bin_115,2.0)+ POWER(h.bin_116-avgh.bin_116,2.0)+ POWER(h.bin_117-avgh.bin_117,2.0)+ POWER(h.bin_118-avgh.bin_118,2.0)+ POWER(h.bin_119-avgh.bin_119,2.0)+ POWER(h.bin_120-avgh.bin_120,2.0)+ POWER(h.bin_121-avgh.bin_121,2.0)+ POWER(h.bin_122-avgh.bin_122,2.0)+ POWER(h.bin_123-avgh.bin_123,2.0)+ POWER(h.bin_124-avgh.bin_124,2.0)+ POWER(h.bin_125-avgh.bin_125,2.0)+ POWER(h.bin_126-avgh.bin_126,2.0)+ POWER(h.bin_127-avgh.bin_127,2.0)+ POWER(h.bin_128-avgh.bin_128,2.0)+ POWER(h.bin_129-avgh.bin_129,2.0)+ POWER(h.bin_130-avgh.bin_130,2.0)+ POWER(h.bin_131-avgh.bin_131,2.0)+ POWER(h.bin_132-avgh.bin_132,2.0)+ POWER(h.bin_133-avgh.bin_133,2.0)+ POWER(h.bin_134-avgh.bin_134,2.0)+ POWER(h.bin_135-avgh.bin_135,2.0)+ POWER(h.bin_136-avgh.bin_136,2.0)+ POWER(h.bin_137-avgh.bin_137,2.0)+ POWER(h.bin_138-avgh.bin_138,2.0)+ POWER(h.bin_139-avgh.bin_139,2.0)+ POWER(h.bin_140-avgh.bin_140,2.0)+ POWER(h.bin_141-avgh.bin_141,2.0)+ POWER(h.bin_142-avgh.bin_142,2.0)+ POWER(h.bin_143-avgh.bin_143,2.0)+ POWER(h.bin_144-avgh.bin_144,2.0)+ POWER(h.bin_145-avgh.bin_145,2.0)+ POWER(h.bin_146-avgh.bin_146,2.0)+ POWER(h.bin_147-avgh.bin_147,2.0)+ POWER(h.bin_148-avgh.bin_148,2.0)+ POWER(h.bin_149-avgh.bin_149,2.0)+ POWER(h.bin_150-avgh.bin_150,2.0)+ POWER(h.bin_151-avgh.bin_151,2.0)+ POWER(h.bin_152-avgh.bin_152,2.0)+ POWER(h.bin_153-avgh.bin_153,2.0)+ POWER(h.bin_154-avgh.bin_154,2.0)+ POWER(h.bin_155-avgh.bin_155,2.0)+ POWER(h.bin_156-avgh.bin_156,2.0)+ POWER(h.bin_157-avgh.bin_157,2.0)+ POWER(h.bin_158-avgh.bin_158,2.0)+ POWER(h.bin_159-avgh.bin_159,2.0)+ POWER(h.bin_160-avgh.bin_160,2.0)+ POWER(h.bin_161-avgh.bin_161,2.0)+ POWER(h.bin_162-avgh.bin_162,2.0)+ POWER(h.bin_163-avgh.bin_163,2.0)+ POWER(h.bin_164-avgh.bin_164,2.0)+ POWER(h.bin_165-avgh.bin_165,2.0)+ POWER(h.bin_166-avgh.bin_166,2.0)+ POWER(h.bin_167-avgh.bin_167,2.0)+ POWER(h.bin_168-avgh.bin_168,2.0)+ POWER(h.bin_169-avgh.bin_169,2.0)+ POWER(h.bin_170-avgh.bin_170,2.0)+ POWER(h.bin_171-avgh.bin_171,2.0)+ POWER(h.bin_172-avgh.bin_172,2.0)+ POWER(h.bin_173-avgh.bin_173,2.0)+ POWER(h.bin_174-avgh.bin_174,2.0)+ POWER(h.bin_175-avgh.bin_175,2.0)+ POWER(h.bin_176-avgh.bin_176,2.0)+ POWER(h.bin_177-avgh.bin_177,2.0)+ POWER(h.bin_178-avgh.bin_178,2.0)+ POWER(h.bin_179-avgh.bin_179,2.0)+ POWER(h.bin_180-avgh.bin_180,2.0)+ POWER(h.bin_181-avgh.bin_181,2.0)+ POWER(h.bin_182-avgh.bin_182,2.0)+ POWER(h.bin_183-avgh.bin_183,2.0)+ POWER(h.bin_184-avgh.bin_184,2.0)+ POWER(h.bin_185-avgh.bin_185,2.0)+ POWER(h.bin_186-avgh.bin_186,2.0)+ POWER(h.bin_187-avgh.bin_187,2.0)+ POWER(h.bin_188-avgh.bin_188,2.0)+ POWER(h.bin_189-avgh.bin_189,2.0)+ POWER(h.bin_190-avgh.bin_190,2.0)+ POWER(h.bin_191-avgh.bin_191,2.0)+ POWER(h.bin_192-avgh.bin_192,2.0)+ POWER(h.bin_193-avgh.bin_193,2.0)+ POWER(h.bin_194-avgh.bin_194,2.0)+ POWER(h.bin_195-avgh.bin_195,2.0)+ POWER(h.bin_196-avgh.bin_196,2.0)+ POWER(h.bin_197-avgh.bin_197,2.0)+ POWER(h.bin_198-avgh.bin_198,2.0)+ POWER(h.bin_199-avgh.bin_199,2.0)+ POWER(h.bin_200-avgh.bin_200,2.0)+ POWER(h.bin_201-avgh.bin_201,2.0)+ POWER(h.bin_202-avgh.bin_202,2.0)+ POWER(h.bin_203-avgh.bin_203,2.0)+ POWER(h.bin_204-avgh.bin_204,2.0)+ POWER(h.bin_205-avgh.bin_205,2.0)+ POWER(h.bin_206-avgh.bin_206,2.0)+ POWER(h.bin_207-avgh.bin_207,2.0)+ POWER(h.bin_208-avgh.bin_208,2.0)+ POWER(h.bin_209-avgh.bin_209,2.0)+ POWER(h.bin_210-avgh.bin_210,2.0)+ POWER(h.bin_211-avgh.bin_211,2.0)+ POWER(h.bin_212-avgh.bin_212,2.0)+ POWER(h.bin_213-avgh.bin_213,2.0)+ POWER(h.bin_214-avgh.bin_214,2.0)+ POWER(h.bin_215-avgh.bin_215,2.0)+ POWER(h.bin_216-avgh.bin_216,2.0)+ POWER(h.bin_217-avgh.bin_217,2.0)+ POWER(h.bin_218-avgh.bin_218,2.0)+ POWER(h.bin_219-avgh.bin_219,2.0)+ POWER(h.bin_220-avgh.bin_220,2.0)+ POWER(h.bin_221-avgh.bin_221,2.0)+ POWER(h.bin_222-avgh.bin_222,2.0)+ POWER(h.bin_223-avgh.bin_223,2.0)+ POWER(h.bin_224-avgh.bin_224,2.0)+ POWER(h.bin_225-avgh.bin_225,2.0)+ POWER(h.bin_226-avgh.bin_226,2.0)+ POWER(h.bin_227-avgh.bin_227,2.0)+ POWER(h.bin_228-avgh.bin_228,2.0)+ POWER(h.bin_229-avgh.bin_229,2.0)+ POWER(h.bin_230-avgh.bin_230,2.0)+ POWER(h.bin_231-avgh.bin_231,2.0)+ POWER(h.bin_232-avgh.bin_232,2.0)+ POWER(h.bin_233-avgh.bin_233,2.0)+ POWER(h.bin_234-avgh.bin_234,2.0)+ POWER(h.bin_235-avgh.bin_235,2.0)+ POWER(h.bin_236-avgh.bin_236,2.0)+ POWER(h.bin_237-avgh.bin_237,2.0)+ POWER(h.bin_238-avgh.bin_238,2.0)+ POWER(h.bin_239-avgh.bin_239,2.0)+ POWER(h.bin_240-avgh.bin_240,2.0)+ POWER(h.bin_241-avgh.bin_241,2.0)+ POWER(h.bin_242-avgh.bin_242,2.0)+ POWER(h.bin_243-avgh.bin_243,2.0)+ POWER(h.bin_244-avgh.bin_244,2.0)+ POWER(h.bin_245-avgh.bin_245,2.0)+ POWER(h.bin_246-avgh.bin_246,2.0)+ POWER(h.bin_247-avgh.bin_247,2.0)+ POWER(h.bin_248-avgh.bin_248,2.0)+ POWER(h.bin_249-avgh.bin_249,2.0)+ POWER(h.bin_250-avgh.bin_250,2.0)+ POWER(h.bin_251-avgh.bin_251,2.0)+ POWER(h.bin_252-avgh.bin_252,2.0)+ POWER(h.bin_253-avgh.bin_253,2.0)+ POWER(h.bin_254-avgh.bin_254,2.0)+ POWER(h.bin_255-avgh.bin_255,2.0) )FROM (SELECT * FROM histogram_h WHERE imageid = (-$1)-1) avgh, histogram_h h LEFT JOIN image_characteristics c ON h.imageid = c.imageid WHERE c.is_test = true;COMMIT;";
	storeMeasuringData $timestamp "euclidean_h"	
}

# runClassifier
runClassifier(){	
	calcAvgHistogram 0
	calcAvgHistogram 3

	calcDistanceMetric 0
	calcDistanceMetric 3
}

# INIT Database & Classifier (Execute first time manually)
#echo "Creating db schemas..."
#/opt/vertica/bin/vsql -d $databasename -U $username_admin -w $password -f "/data/verticaextension/classifier/install.sql"
#echo "Loading images characteristics..."
#/opt/vertica/bin/vsql -d $databasename -U $username -w $password -f "/data/verticaextension/classifier/initClassifier.sql"
#echo "Loading images..."
#/opt/vertica/bin/vsql -d $databasename -U $username -w $password -c "COPY image_rgb_grey FROM '/data/images/classifier/sunny_cloudy_4000_images.csv' WITH PARSER ImageToRGBGreyParser();"


##############################################################
# Red Channel, Full Histogram, Scale Factor 1
##############################################################

# Horizontal Rectangle Area
#paramset=0
#reset	
#calcHistogramBoundingBox 0 red 255 0 256 false 635 0 650 350
#runClassifier

# Vertical Rectangle Area
#paramset=1
#reset	
#calcHistogramBoundingBox 0 red 255 0 256 false 785 0 350 650
#runClassifier

# Square Area
#paramset=2
#reset	
#calcHistogramBoundingBox 0 red 255 0 256 false 721 130 478 478
#runClassifier

# Circle Area
#paramset=3
#reset	
#calcHistogramCircle 0 red 255 0 256 false 721 130 269
#runClassifier

##############################################################
# Red Channel, Full Histogram, Scale Factor 1/2
##############################################################

# Horizontal Rectangle Area
#paramset=4
#reset	
#calcHistogramBoundingBox 0 red 255 0 256 false 732 50 455 250
#runClassifier

# Vertical Rectangle Area
#paramset=5
#reset	
#calcHistogramBoundingBox 0 red 255 0 256 false 835 97 250 455
#runClassifier

# Square Area
#paramset=6
#reset	
#calcHistogramBoundingBox 0 red 255 0 256 false 791 200 337 337
#runClassifier

# Circle Area
#paramset=7
#reset	
#calcHistogramCircle 0 red 255 0 256 false 721 130 190
#runClassifier

##############################################################
# Red Channel, Full Histogram, Scale Factor 1/4
##############################################################

# Horizontal Rectangle Area
#paramset=8
#reset	
#calcHistogramBoundingBox 0 red 255 0 256 false 797 87 325 175
#runClassifier

# Vertical Rectangle Area
#paramset=9
#reset	
#calcHistogramBoundingBox 0 red 255 0 256 false 872 162 175 325
#runClassifier

# Square Area
#paramset=10
#reset	
#calcHistogramBoundingBox 0 red 255 0 256 false 841 250 238 238
#runClassifier

# Circle Area
#paramset=11
#reset	
#calcHistogramCircle 0 red 255 0 256 false 721 130 134
#runClassifier




##############################################################
# Blue Channel, Full Histogram, Scale Factor 1
##############################################################

# Horizontal Rectangle Area
paramset=12
reset	
calcHistogramBoundingBox 2 blue 255 0 256 false 635 0 650 350
runClassifier

# Vertical Rectangle Area
paramset=13
reset	
calcHistogramBoundingBox 2 blue 255 0 256 false 785 0 350 650
runClassifier

# Square Area
paramset=14
reset	
calcHistogramBoundingBox 2 blue 255 0 256 false 721 130 478 478
runClassifier

# Circle Area
paramset=15
reset	
calcHistogramCircle 2 blue 255 0 256 false 721 130 269
runClassifier

##############################################################
# Blue Channel, Full Histogram, Scale Factor 1/2
##############################################################

# Horizontal Rectangle Area
paramset=16
reset	
calcHistogramBoundingBox 2 blue 255 0 256 false 732 50 455 250
runClassifier

# Vertical Rectangle Area
paramset=17
reset	
calcHistogramBoundingBox 2 blue 255 0 256 false 835 97 250 455
runClassifier

# Square Area
paramset=18
reset	
calcHistogramBoundingBox 2 blue 255 0 256 false 791 200 337 337
runClassifier

# Circle Area
paramset=19
reset	
calcHistogramCircle 2 blue 255 0 256 false 721 130 190
runClassifier

##############################################################
# Blue Channel, Full Histogram, Scale Factor 1/4
##############################################################

# Horizontal Rectangle Area
paramset=20
reset	
calcHistogramBoundingBox 2 blue 255 0 256 false 797 87 325 175
runClassifier

# Vertical Rectangle Area
paramset=21
reset	
calcHistogramBoundingBox 2 blue 255 0 256 false 872 162 175 325
runClassifier

# Square Area
paramset=22
reset	
calcHistogramBoundingBox 2 blue 255 0 256 false 841 250 238 238
runClassifier

# Circle Area
paramset=23
reset	
calcHistogramCircle 2 blue 255 0 256 false 721 130 134
runClassifier

exit 0