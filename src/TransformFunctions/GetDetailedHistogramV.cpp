/*
# cIPT: column-store Image Processing Toolbox
#==============================================================================
# author: Tobias Vincon
# DualStudy@HPE: http://h41387.www4.hpe.com/dualstudy/index.html
# DBLab: https://dblab.reutlingen-university.de/
#==============================================================================*/


#include "Vertica.h"
#include <sstream>

using namespace Vertica;
using namespace std;

class GetDetailedHistogramV : public TransformFunction
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

			// set histogram as output
			for (unsigned int i=0; i<histogram.size(); i++) {
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
				//cutminmax
				outputWriter.setBool(5,false);
				//bin
				outputWriter.setInt(6,i);
				//frequency
				outputWriter.setInt(7,histogram[i]);
				outputWriter.next();
			}
            
        } catch(exception& e) {
            // Standard exception. Quit.
            vt_report_error(0, "Exception while processing partition: [%s]", e.what());
        }
    }
};

class GetDetailedHistogramVFactory : public TransformFunctionFactory
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
		// bin
		returnType.addInt();
		// frequency
		returnType.addInt();
    }

    // Tell Vertica what our return string length will be, given the input
    // string length
    virtual void getReturnType(ServerInterface &srvInterface, 
                               const SizedColumnTypes &inputTypes, 
                               SizedColumnTypes &outputTypes)
    {
        // Error out if we're called with anything but 1 argument
        if (inputTypes.getColumnCount() != 3)
            vt_report_error(0, "Function only accepts 3 argument, but %zu provided", inputTypes.getColumnCount());
			
		outputTypes.addInt("imageid");
		outputTypes.addInt("channel");
		outputTypes.addInt("binnumber");
		outputTypes.addInt("min");
		outputTypes.addInt("max");
		outputTypes.addBool("cutminmax");
		outputTypes.addInt("bin");
		outputTypes.addInt("frequency");
    }

    virtual TransformFunction *createTransformFunction(ServerInterface &srvInterface)
    { return vt_createFuncObject<GetDetailedHistogramV>(srvInterface.allocator); }

};

RegisterFactory(GetDetailedHistogramVFactory);
