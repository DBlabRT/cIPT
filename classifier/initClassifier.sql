--
-- cIPT: column-store Image Processing Toolbox
--==============================================================================
-- author: Tobias Vincon
-- DualStudy@HPE: http://h41387.www4.hpe.com/dualstudy/index.html
-- DBLab: https://dblab.reutlingen-university.de/
--==============================================================================


-- INITIALIZE CLASSIFIER

-- store image classes
INSERT INTO image_class VALUES (0, 'sunny');
INSERT INTO image_class VALUES (1, 'rainy');
INSERT INTO image_class VALUES (2, 'foggy');
INSERT INTO image_class VALUES (3, 'cloudy');
COMMIT;

-- load the characteristics of the previously loaded images
COPY image_characteristics FROM '/data/images/classifier/sunny_cloudy_4000_images_characteristics.csv' WITH DELIMITER ';';


