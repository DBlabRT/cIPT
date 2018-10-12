#!/bin/bash
#
# cIPT: column-store Image Processing Toolbox
#==============================================================================
# author: Tobias Vincon
# DualStudy@HPE: http://h41387.www4.hpe.com/dualstudy/index.html
# DBLab: https://dblab.reutlingen-university.de/
#==============================================================================

# $1 = name

databasename='ExampleDB'
username='dbadmin'
password='ExampleDB'

/opt/vertica/bin/vsql -At -d $databasename -U $username -w $password -c "SELECT ToGreyscale(name,depth,x,y,red,green,blue,alpha) OVER (PARTITION BY name) FROM image;"

#!/bin/bash
/opt/vertica/bin/vsql --command 'select count(*) from my_table where condition > value;' -w 'XXX' --echo-all -h host db_name user_name
exit 0
