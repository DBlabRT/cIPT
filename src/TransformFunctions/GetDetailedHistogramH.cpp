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
#include <iostream>



using namespace Vertica;
using namespace std;

class GetDetailedHistogramH : public TransformFunction
{
    virtual void processPartition(ServerInterface &srvInterface, 
                                  PartitionReader &inputReader, 
                                  PartitionWriter &outputWriter)
    {
		
	
        try {
            if (inputReader.getNumCols() != 3)
                vt_report_error(0, "Function only accepts 3 argument, but %zu provided", inputReader.getNumCols());
						
			std::vector<int> histogram (256,0);
			
			// fill up histogram with data
            do {
                const int &value = inputReader.getIntRef(2);
				histogram[value]++;		
			} while (inputReader.next());
			
			//imageid
			outputWriter.setInt(0,inputReader.getIntRef(0));
			//channel
			outputWriter.setInt(1,inputReader.getIntRef(1));
			//binnumber
			outputWriter.setInt(2,256);
			//min
			outputWriter.setInt(3,0);
			//max
			outputWriter.setInt(4,255);
			// cutminmax
			outputWriter.setBool(5,false);
			
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

class GetDetailedHistogramHFactory : public TransformFunctionFactory
{
    // Tell Vertica that we take in a row with 1 string, and return a row with 1 string
    virtual void getPrototype(ServerInterface &srvInterface, ColumnTypes &argTypes, ColumnTypes &returnType)
    {
		// imageid
        argTypes.addInt();
		// channel
		argTypes.addInt();
		// channel values
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
        // Error out if we're called with anything but 3 argument
        if (inputTypes.getColumnCount() != 3)
            vt_report_error(0, "Function only accepts 3 argument, but %zu provided", inputTypes.getColumnCount());
			
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
    { return vt_createFuncObject<GetDetailedHistogramH>(srvInterface.allocator); }

};

RegisterFactory(GetDetailedHistogramHFactory);
