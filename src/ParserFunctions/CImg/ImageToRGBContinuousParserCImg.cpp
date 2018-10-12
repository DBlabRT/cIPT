/*
# cIPT: column-store Image Processing Toolbox
#==============================================================================
# author: Tobias Vincon
# DualStudy@HPE: http://h41387.www4.hpe.com/dualstudy/index.html
# DBLab: https://dblab.reutlingen-university.de/
#==============================================================================*/

#include "Vertica.h"
#include "ContinuousUDParser.h"

using namespace Vertica;

#include <string>
#include <sstream>
#include <iostream>
using namespace std;

#define cimg_display 0
#include "CImg.h"
using namespace cimg_library;

/**
 * Basic Integer parser
 * Parses a string of integers separated by non-numeric characters.
 * Uses the ContinuousUDParser API provided with the examples,
 * as a wrapper on top of the built-in Vertica SDK API.
 */
class ImageToRGBContinuousParser : public ContinuousUDParser {
private:
	// Size (in bytes) of the current record (row) that we're looking at.
    size_t currentRecordSize;
	
	// Configurable parsing parameters
    // Set by the constructor
    static const char recordTerminator = '\n';
	
	// Start off reserving this many bytes when searching for the end of a record
    // Will reserve more as needed; but from a performance perspective it's
    // nice to not have to do so.
    static const size_t BASE_RESERVE_SIZE = 256;
	
	/**
     * Make sure (via reserve()) that the full upcoming row is in memory.
     * Assumes that getDataPtr() points at the start of the upcoming row.
     * (This is guaranteed by run(), prior to calling fetchNextRow().)
     *
     * Returns true if we stopped due to a record terminator;
     * false if we stopped due to EOF.
     */
	bool fetchNextRow() {
        // Amount of data we have to work with
        size_t reserved;

        // Amount of data that we've requested to work with.
        // Equal to `reserved` after calling reserve(), except in case of end-of-file.
        size_t reservationRequest = BASE_RESERVE_SIZE;

        // Pointer into the middle of our current data buffer.
        // Must always be betweeen getDataPtr() and getDataPtr() + reserved.
        char *ptr;

        // Our current pos??ition within the stream.
        // Kept around so that we can update ptr correctly after reserve()ing more data.
        size_t position = 0;

        do {
            // Get some (more) data
            reserved = cr.reserve(reservationRequest);

            // Position counter.  Not allowed to pass getDataPtr() + reserved.
            ptr = (char*)cr.getDataPtr() + position;

            // Keep reading until we hit EOF.
            // If we find the record terminator, we'll return out of the loop.
            // Very tight loop; very performance-sensitive.
            while (*ptr != recordTerminator && position < reserved) {
                ++ptr;
                ++position;
            }

            if (*ptr == recordTerminator) {
                currentRecordSize = position;
                return true;
            }

            reservationRequest *= 2;  // Request twice as much data next time
        } while (!cr.noMoreData());  // Stop if we run out of data;
                             // correctly handles files that aren't newline terminated
                             // and when we reach eof but haven't seeked there yet

        currentRecordSize = position;
        return false;
    }
	
	void insertImage(string path){			
		int lastindexslash = path.find_last_of("/"); 
		int lastindexextensionpoint = path.find_last_of("."); 
		string imageid = path.substr(lastindexslash+1, ((lastindexextensionpoint-lastindexslash)-1));
		int imageid_i = atoi(imageid.c_str());
						
		CImg<int>* src = new CImg<int>(path.c_str());
		int width = src->width();
		int height = src->height();
		for (int y = 0; y < height; y++){
			for (int x = 0; x < width; x++){
				writer->setInt(0, imageid_i);
				writer->setInt(1, x);
				writer->setInt(2, y);
				writer->setInt(3, (*src)(x,y,0,0));
				writer->setInt(4, (*src)(x,y,0,1));
				writer->setInt(5, (*src)(x,y,0,2));
				writer->next();
			}
		} 
		
		path.clear();
		imageid.clear();
		delete src;
    }
	
public:
    virtual void run() {
		
		bool hasMoreData;

        do {

            // Fetch the next record
            hasMoreData = fetchNextRow();

            // Special case: ignore trailing newlines (record terminators) at
            // the end of files
            if (cr.isEof() && currentRecordSize == 0) {
                hasMoreData = false;
                break;
            }
			
			string str((char*)cr.getDataPtr(),  static_cast<int>(currentRecordSize));		
			insertImage(str.c_str());

        } while (hasMoreData);

    }
};

class ImageToRGBContinuousParserFactory : public ParserFactory {
public:
    virtual void plan(ServerInterface &srvInterface,
            PerColumnParamReader &perColumnParamReader,
            PlanContext &planCtxt) {
    }

    virtual UDParser* prepare(ServerInterface &srvInterface,
            PerColumnParamReader &perColumnParamReader,
            PlanContext &planCtxt,
            const SizedColumnTypes &returnType) {

        return vt_createFuncObject<ImageToRGBContinuousParser>(srvInterface.allocator);
    }

    virtual void getParserReturnType(ServerInterface &srvInterface,
            PerColumnParamReader &perColumnParamReader,
            PlanContext &planCtxt,
            const SizedColumnTypes &argTypes,
            SizedColumnTypes &returnType) {
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
RegisterFactory(ImageToRGBContinuousParserFactory);
