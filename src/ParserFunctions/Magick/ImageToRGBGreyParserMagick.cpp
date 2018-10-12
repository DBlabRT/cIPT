/*
# cIPT: column-store Image Processing Toolbox
#==============================================================================
# author: Tobias Vincon
# DualStudy@HPE: http://h41387.www4.hpe.com/dualstudy/index.html
# DBLab: https://dblab.reutlingen-university.de/
#==============================================================================*/

#include "Vertica.h"

#include <iostream>
#include <string>
#include <sstream>
using namespace std;

#include <Magick++.h> 
using namespace Magick; 

/**
 * Image Parser
 * Parses a string to retrieve paths to images....
 */
class ImageToRGBGreyParser : public Vertica::UDParser {
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
				writer->setInt(6, static_cast<int>(((255*rgb->red() + 255*rgb->green() + 255*rgb->blue())/3)+0.5));
				writer->next();
				
				delete rgb;
			}
		}
		
		delete img;	 
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

class ImageToRGBGreyParserFactory : public Vertica::ParserFactory {
public:
    virtual void plan(Vertica::ServerInterface &srvInterface,
            Vertica::PerColumnParamReader &perColumnParamReader,
            Vertica::PlanContext &planCtxt) {
    }

    virtual Vertica::UDParser* prepare(Vertica::ServerInterface &srvInterface,
            Vertica::PerColumnParamReader &perColumnParamReader,
            Vertica::PlanContext &planCtxt,
            const Vertica::SizedColumnTypes &returnType) {

        return Vertica::vt_createFuncObject<ImageToRGBGreyParser>(srvInterface.allocator);
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
		// grey
		returnType.addInt(argTypes.getColumnName(6));
    }
};
RegisterFactory(ImageToRGBGreyParserFactory);
