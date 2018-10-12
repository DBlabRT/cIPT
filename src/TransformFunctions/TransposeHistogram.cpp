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

class TransposeHistogram : public TransformFunction
{
    virtual void processPartition(ServerInterface &srvInterface, 
                                  PartitionReader &inputReader, 
                                  PartitionWriter &outputWriter)
    {
		
	
        try {
            if (inputReader.getNumCols() != 8)
                vt_report_error(0, "Function only accepts 8 argument, but %zu provided", inputReader.getNumCols());
			
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
			// cutminmax
			outputWriter.setBool(5,inputReader.getBoolRef(5));
			
			do {
				outputWriter.setInt(inputReader.getIntRef(6)+6,inputReader.getIntRef(7));
			} while (inputReader.next());
			
			outputWriter.next();
            
        } catch(exception& e) {
            // Standard exception. Quit.
            vt_report_error(0, "Exception while processing partition: [%s]", e.what());
        }
    }
};

class TransposeHistogramFactory : public TransformFunctionFactory
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
		// bin
		argTypes.addInt();
		// frequency
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
        if (inputTypes.getColumnCount() != 8)
            vt_report_error(0, "Function only accepts 8 argument, but %zu provided", inputTypes.getColumnCount());
			
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
    { return vt_createFuncObject<TransposeHistogram>(srvInterface.allocator); }

};

RegisterFactory(TransposeHistogramFactory);
