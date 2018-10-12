#!/bin/bash
#
# cIPT: column-store Image Processing Toolbox
#==============================================================================
# author: Tobias Vincon
# DualStudy@HPE: http://h41387.www4.hpe.com/dualstudy/index.html
# DBLab: https://dblab.reutlingen-university.de/
#==============================================================================

databasename='Results'
username='dbadmin'
password='results'

/opt/vertica/bin/vsql -d $databasename -U $username -w $password -f "/opt/mount1/classifier/install_results.sql"

find `pwd` -name 'measuring_requests-*' -exec /opt/vertica/bin/vsql -a -d $databasename -U $username -w $password -c "COPY classifier_requests (paramset, type, timeid, start_time, end_time, request_duration_ms, memory_acquired_mb, request) FROM  '{}' delimiter '|' null as '';" \;
find `pwd` -name 'measuring_resources-*' -exec /opt/vertica/bin/vsql -a -d $databasename -U $username -w $password -c "COPY classifier_resources (paramset, type, timeid, start_time, end_time, average_cpu_usage_percent, average_memory_usage_percent, read_kbytes_per_sec, written_kbytes_per_sec) FROM  '{}' delimiter '|' null as '';" \;
find `pwd` -name 'measuring_storage-*' -exec /opt/vertica/bin/vsql -a -d $databasename -U $username -w $password -c "COPY classifier_storage (paramset, type, start_time, anchor_table_schema, anchor_table_name, used_compressed_gb_column, used_compressed_gb_projection) FROM  '{}' delimiter '|' null as '';" \;


/opt/vertica/bin/vsql -At -d $databasename -U $username -w $password -c "DELETE FROM classifier_requests WHERE regexp_count(request, 'PROJECTION');COMMIT;"
/opt/vertica/bin/vsql -At -d $databasename -U $username -w $password -c "DELETE FROM classifier_requests WHERE request like 'COMMIT;';COMMIT;"

exit 0