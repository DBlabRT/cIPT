# cIPT: column-store Image Processing Toolbox

The amount of image data has been rising exponentially over the last decades due to numerous trends like social networks, smart-phones, automotive, biology, medicine and robotics. Traditionally, file systems are used as storage. Although they are easy to use and can han-
dle large data volumes, they are suboptimal for efficient sequential image processing due to the limitation of data organisation on single images.
Database systems and especially column-stores support more stuctured storage and access methods on the raw data level for entiere series.
In this paper we propose definitions of various layouts for an efficient storage of raw image data and metadata in a column store. These schemes
are designed to improve the runtime behaviour of image processing oper-ations. We present a tool called column-store Image Processing Toolbox (cIPT) allowing to easily combine the data layouts and operations for different image processing scenarios. The experimental evaluation of a classification task on a real world image dataset indicates a performance increase of up to 15x on a column store compared to a traditional row-store (PostgreSQL) while the space consumption is reduced 7x. With these results cIPT provides the basis for a future mature database feature.


https://dblab.reutlingen-university.de/paper/2016_ADBIS_cIPTShiftOfImageProcessingTechnologies.pdf
