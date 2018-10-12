--
-- cIPT: column-store Image Processing Toolbox
--==============================================================================
-- author: Tobias Vincon
-- DualStudy@HPE: http://h41387.www4.hpe.com/dualstudy/index.html
-- DBLab: https://dblab.reutlingen-university.de/
--==============================================================================


DROP TABLE IF EXISTS classifier_resources CASCADE;
DROP TABLE IF EXISTS classifier_requests CASCADE;
DROP TABLE IF EXISTS classifier_storage CASCADE;

CREATE TABLE classifier_resources (paramset INTEGER, type VARCHAR(255), timeid INTEGER, start_time TIMESTAMP, end_time TIMESTAMP, average_cpu_usage_percent NUMBER, average_memory_usage_percent NUMBER, read_kbytes_per_sec NUMBER, written_kbytes_per_sec NUMBER, PRIMARY KEY (start_time, end_time), UNIQUE (start_time, end_time));
CREATE TABLE classifier_requests (paramset INTEGER, type VARCHAR(255), timeid INTEGER, start_time TIMESTAMP, end_time TIMESTAMP, request_duration_ms INTEGER, memory_acquired_mb NUMBER, request VARCHAR(255), PRIMARY KEY (start_time, end_time), UNIQUE (start_time, end_time));
CREATE TABLE classifier_storage (paramset INTEGER, type VARCHAR(255), start_time TIMESTAMP, anchor_table_schema VARCHAR(255), anchor_table_name VARCHAR(255), used_compressed_gb_column NUMBER, used_compressed_gb_projection NUMBER, PRIMARY KEY (start_time), UNIQUE (start_time));

CREATE USER result;
GRANT ALL ON ALL TABLES IN SCHEMA public TO result;