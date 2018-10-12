/*
# cIPT: column-store Image Processing Toolbox
#==============================================================================
# author: Tobias Vincon
# DualStudy@HPE: http://h41387.www4.hpe.com/dualstudy/index.html
# DBLab: https://dblab.reutlingen-university.de/
#==============================================================================*/

#include "Vertica.h"
//using namespace Vertica;

#include <iostream>
#include <string>
#include <sstream>
using namespace std;

#include <Magick++.h> 
using namespace Magick; 

//#include<opencv2/core/core.hpp>
//#include <opencv2/highgui/highgui.hpp>
//using namespace cv;

//#include "CImg.h"
//using namespace cimg_library;


/**
 * Image Parser
 * Parses a string to retrieve paths to images....
 */
class ImageToRGBParser : public Vertica::UDParser {
private:
    void insertImage(const char* start, const char* end){
		string str(start, end);
		
		Image *img = new Image(str.c_str());
		
		int lastindex = str.find_last_of("."); 
		string imageid = str.substr(0, lastindex);
		
		for (unsigned int y = 0; y < img->rows(); y++){
			for (unsigned int x = 0; x < img->columns(); x++){
				ColorRGB *rgb = new ColorRGB(img->pixelColor(x, y));			
				writer->setInt(0, atoi(imageid.c_str()));
				writer->setInt(1, x);
				writer->setInt(2, y);
				writer->setInt(3, static_cast<int>(255*rgb->red()+0.5));
				writer->setInt(4, static_cast<int>(255*rgb->green()+0.5));
				writer->setInt(5, static_cast<int>(255*rgb->blue()+0.5));
				writer->next();
				
				delete rgb;
			}
		}
		
		delete img;
		
		/* OpenCV
		
		Mat image;
		image = imread(str.c_str(), CV_LOAD_IMAGE_COLOR); 
		for (int i = 0; i < image.cols; i++) {
			for (int j = 0; j < image.rows; j++) {
				Vec3b intensity = image.at<Vec3b>(j, i);
				writer->getStringRef(0).copy(str);
				writer->setInt(1, image.cols);
				writer->setInt(2, image.rows);
				writer->setInt(3, 0);
				writer->setInt(4, image.channels());
				writer->setInt(5, i);
				writer->setInt(6, j);
				writer->setFloat(7, (float)intensity.val[0]);
				writer->setFloat(8, (float)intensity.val[1]);
				writer->setFloat(9, (float)intensity.val[2]);
				writer->setFloat(10, (float)intensity.val[3]);
				writer->next();
				//for(int k = 0; k < image.channels(); k++) {
				//	uchar col = intensity.val[k]; 
				//}   
			}
		}*/
		
		/* CImg
		
		CImg<float> src(str.c_str());
		int width = src.width();
		int height = src.height();
		for (int y = 0; y < height; y++){
			for (int x = 0; x < width; x++){
				writer->getStringRef(0).copy(str);
				writer->setInt(1, src.width());
				writer->setInt(2, src.height());
				writer->setInt(3, src.depth());
				writer->setInt(4, src.spectrum());
				writer->setInt(5, x);
				writer->setInt(6, y);
				writer->setFloat(7, (float)src(x,y,0,0));
				writer->setFloat(8, (float)src(x,y,0,1));
				writer->setFloat(9, (float)src(x,y,0,2));
				writer->setFloat(10, (float)src(x,y,0,3));
				writer->next();
			}
		}*/		 
    }

public:
    virtual Vertica::StreamState process(Vertica::ServerInterface &srvInterface, Vertica::DataBuffer &input, Vertica::InputState input_state) {
        const char* start = input.buf + input.offset;
	const char* end = input.buf + input.size;

	char* ptr = input.buf + input.offset;
	
	// move through input till either end of input buffer is reached 
	// or a newline character appears
	while (ptr < end && *ptr != '\n'){
	     ptr++;
	}

	// if current char is newline write record
	// else if no newline found and EOF reached 
	// then write last chars and return DONE
	if (*ptr == '\n'){
	    insertImage(start, ptr);
	    input.offset = ptr - start + 1;
	} else if (input_state == Vertica::END_OF_FILE){
	    insertImage(start, ptr);
	    return Vertica::DONE;
	}

	// Otherwise more data is needed
	return Vertica::INPUT_NEEDED;
    }
};

class ImageToRGBParserFactory : public Vertica::ParserFactory {
public:
    virtual void plan(Vertica::ServerInterface &srvInterface,
            Vertica::PerColumnParamReader &perColumnParamReader,
            Vertica::PlanContext &planCtxt) {
    }

    virtual Vertica::UDParser* prepare(Vertica::ServerInterface &srvInterface,
            Vertica::PerColumnParamReader &perColumnParamReader,
            Vertica::PlanContext &planCtxt,
            const Vertica::SizedColumnTypes &returnType) {

        return Vertica::vt_createFuncObject<ImageToRGBParser>(srvInterface.allocator);
    }

    virtual void getParserReturnType(Vertica::ServerInterface &srvInterface,
            Vertica::PerColumnParamReader &perColumnParamReader,
            Vertica::PlanContext &planCtxt,
            const Vertica::SizedColumnTypes &argTypes,
            Vertica::SizedColumnTypes &returnType) {
		//imageid
        returnType.addInt(argTypes.getColumnName(0));
		// x
		returnType.addInt(argTypes.getColumnName(1));
		// y
		returnType.addInt(argTypes.getColumnName(2));
		// red
		returnType.addInt(argTypes.getColumnName(3));
		// blue
		returnType.addInt(argTypes.getColumnName(4));
		// green
		returnType.addInt(argTypes.getColumnName(5));
    }
};
RegisterFactory(ImageToRGBParserFactory);
