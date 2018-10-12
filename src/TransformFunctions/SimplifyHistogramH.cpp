/*
# cIPT: column-store Image Processing Toolbox
#==============================================================================
# author: Tobias Vincon
# DualStudy@HPE: http://h41387.www4.hpe.com/dualstudy/index.html
# DBLab: https://dblab.reutlingen-university.de/
#==============================================================================*/



#include "Vertica.h"
#include <string>
#include <sstream>
#include <cmath>
#include <iostream>



using namespace Vertica;
using namespace std;

class SimplifyHistogramH : public TransformFunction
{
    virtual void processPartition(ServerInterface &srvInterface, 
                                  PartitionReader &inputReader, 
                                  PartitionWriter &outputWriter)
    {
		
	
        try {
            if (inputReader.getNumCols() != 262)
                vt_report_error(0, "Function only accepts 262 argument, but %zu provided", inputReader.getNumCols());
						
			// max value is in bin(max-1)
			const int min = inputReader.getIntRef(3);
			const int max = inputReader.getIntRef(4);
			const int totalbins = inputReader.getIntRef(2);
			
			signed int binsize = (int)floor((max - min)/totalbins);
			signed int binindex = 0;
			std::vector<int> histogram (totalbins,0);
			
			if(inputReader.getBoolRef(5)){
				do {	
					for (unsigned int i = 0; i < 256; ++i){
						binindex = ((i - min) / binsize) + 1;
						
						if(binindex > 0 && binindex <= totalbins)
							histogram[binindex-1] += inputReader.getIntRef(6+i);
					}
				} while (inputReader.next());
			} else {
				do {	
					for (unsigned int i = 0; i < 256; ++i){
						binindex = ((i - min) / binsize) + 1;
						
						if(binindex <= 0){
							binindex = 1;
						}else if(binindex >= totalbins){
							binindex = totalbins;
						}
							
						histogram[binindex-1]  += inputReader.getIntRef(6+i);
					}
				} while (inputReader.next());
			}
			
			//imageid
			outputWriter.setInt(0,inputReader.getIntRef(0));
			//channel
			outputWriter.setInt(1,inputReader.getIntRef(1));
			//binnumber
			outputWriter.setInt(2,inputReader.getIntRef(2));
			//min
			outputWriter.setInt(3,inputReader.getIntRef(3));
			//max
			outputWriter.setInt(4,inputReader.getIntRef(4));	
			//cutminmax
			outputWriter.setBool(5,inputReader.getBoolRef(5));
			// set histogram as output
			for (unsigned int i=0; i<histogram.size(); i++) {
				outputWriter.setInt(6+i,histogram[i]);
			}
			outputWriter.next();
            
        } catch(exception& e) {
            // Standard exception. Quit.
            vt_report_error(0, "Exception while processing partition: [%s]", e.what());
        }
    }
};

class SimplifyHistogramHFactory : public TransformFunctionFactory
{
    // Tell Vertica that we take in a row with 1 string, and return a row with 1 string
    virtual void getPrototype(ServerInterface &srvInterface, ColumnTypes &argTypes, ColumnTypes &returnType)
    {
		// imageid
        argTypes.addInt();
		// channel
		argTypes.addInt();
		// binnumber
		argTypes.addInt();
		// min
		argTypes.addInt();
		// max
		argTypes.addInt();
		// cutminmax
		argTypes.addBool();
		for (int i = 0; i < 256; ++i)
			argTypes.addInt();
	
		// imageid
        returnType.addInt();
		// channel
		returnType.addInt();
		// binnumber
		returnType.addInt();
		// min
		returnType.addInt();
		// max
		returnType.addInt();
		// cutminmax
		returnType.addBool();
		
		for (int i = 0; i < 256; ++i)
			returnType.addInt();

    }

    // Tell Vertica what our return string length will be, given the input
    // string length
    virtual void getReturnType(ServerInterface &srvInterface, 
                               const SizedColumnTypes &inputTypes, 
                               SizedColumnTypes &outputTypes)
    {
        // Error out if we're called with anything but 262 argument
        if (inputTypes.getColumnCount() != 262)
            vt_report_error(0, "Function only accepts 262 argument, but %zu provided", inputTypes.getColumnCount());
			
		outputTypes.addInt("imageid");
		outputTypes.addInt("channel");
		outputTypes.addInt("binnumber");
		outputTypes.addInt("min");
		outputTypes.addInt("max");
		outputTypes.addBool("cutminmax");
		
		for (int i = 0; i < 256; ++i){
			std::ostringstream bin;
			bin << "bin_" << i;
			outputTypes.addInt(bin.str());
		}
    }

    virtual TransformFunction *createTransformFunction(ServerInterface &srvInterface)
    { return vt_createFuncObject<SimplifyHistogramH>(srvInterface.allocator); }

};

RegisterFactory(SimplifyHistogramHFactory);
