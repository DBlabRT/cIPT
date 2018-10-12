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

class RGBToGrey : public TransformFunction
{
    virtual void processPartition(ServerInterface &srvInterface, 
                                  PartitionReader &inputReader, 
                                  PartitionWriter &outputWriter)
    {
	
        try {
            if (inputReader.getNumCols() != 6)
                vt_report_error(0, "Function only accepts 6 arguments, but %zu provided", inputReader.getNumCols());

			
				
            do {
				const int &imageid = inputReader.getIntRef(0);
                const int &x = inputReader.getIntRef(1);
				const int &y = inputReader.getIntRef(2);
				const int &red = inputReader.getIntRef(3);
				const int &green = inputReader.getIntRef(4);
				const int &blue = inputReader.getIntRef(5);
				
				outputWriter.setInt(0,imageid);
				outputWriter.setInt(1,x);
				outputWriter.setInt(2,y);
				outputWriter.setInt(3,static_cast<int>(((red+green+blue)/3)+0.5));
				outputWriter.next();
				
			} while (inputReader.next());
            
        } catch(exception& e) {
            // Standard exception. Quit.
            vt_report_error(0, "Exception while processing partition: [%s]", e.what());
        }
    }
};

class RGBToGreyFactory : public TransformFunctionFactory
{
    // Tell Vertica that we take in a row with 1 string, and return a row with 1 string
    virtual void getPrototype(ServerInterface &srvInterface, ColumnTypes &argTypes, ColumnTypes &returnType)
    {
		argTypes.addInt();
		argTypes.addInt();
		argTypes.addInt();
		argTypes.addInt();
        argTypes.addInt();
		argTypes.addInt();

        returnType.addInt();
		returnType.addInt();
		returnType.addInt();
		returnType.addInt();		
    }

    // Tell Vertica what our return string length will be, given the input
    // string length
    virtual void getReturnType(ServerInterface &srvInterface, 
                               const SizedColumnTypes &inputTypes, 
                               SizedColumnTypes &outputTypes)
    {
        // Error out if we're called with anything but 6 arguments
        if (inputTypes.getColumnCount() != 6)
            vt_report_error(0, "Function only accepts 6 argument, but %zu provided", inputTypes.getColumnCount());

		outputTypes.addInt("imageid");
		outputTypes.addInt("x");
		outputTypes.addInt("y");
		outputTypes.addInt("grey");
    }

    virtual TransformFunction *createTransformFunction(ServerInterface &srvInterface)
    { return vt_createFuncObject<RGBToGrey>(srvInterface.allocator); }

};

RegisterFactory(RGBToGreyFactory);
