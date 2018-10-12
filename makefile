#
# cIPT: column-store Image Processing Toolbox
#==============================================================================
# author: Tobias Vincon
# DualStudy@HPE: http://h41387.www4.hpe.com/dualstudy/index.html
# DBLab: https://dblab.reutlingen-university.de/
#==============================================================================


############################
# Vertica Analytic Database
#
# Makefile to build user defined functions
#
# To run under valgrind:
#   make RUN_VALGRIND=1 run
#
############################

## Set to the location of the SDK installation
SDK_HOME?=/opt/vertica/sdk
SDK_JAR?=/opt/vertica/

CXX?=/usr/bin/g++44 
CXXFLAGS:=$(CXXFLAGS) -I $(SDK_HOME)/include -I src/HelperLibraries -g -Wall -shared -Wno-unused-value -fPIC 

ifdef OPTIMIZE
## UDLs should be compiled with compiler optimizations in release builds
CXXFLAGS:=$(CXXFLAGS) -O3
endif

## Set to the desired destination directory for .so output files
BUILD_DIR?=$(abspath build)

## Set to a valid temporary directory
TMPDIR?=/tmp

## Set to the path to 
BOOST_INCLUDE ?= /usr/include
CURL_INCLUDE ?= /usr/include
ZLIB_INCLUDE ?= /usr/include
BZIP_INCLUDE ?= /usr/include

export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

ifdef RUN_VALGRIND
VALGRIND=valgrind --leak-check=full
endif

.PHONEY: TransformFunctions UserDefinedLoad

all: TransformFunctions UserDefinedLoad

$(BUILD_DIR)/.exists:
	test -d $(BUILD_DIR) || mkdir -p $(BUILD_DIR)
	touch $(BUILD_DIR)/.exists
	
###
# Transform Functions
###
TransformFunctions: $(BUILD_DIR)/TransformFunctions.so

$(BUILD_DIR)/TransformFunctions.so: src/TransformFunctions/*.cpp $(SDK_HOME)/include/Vertica.cpp $(SDK_HOME)/include/BuildInfo.h $(BUILD_DIR)/.exists
	$(CXX) $(CXXFLAGS) -o $@ src/TransformFunctions/*.cpp $(SDK_HOME)/include/Vertica.cpp 

	
###
# UDL Functions
###

## Individual targets for each of the UDL examples
## Some of them are intended to be usable as-is, so they should be in
## separate libraries so they can be used individually
UserDefinedLoad: $(BUILD_DIR)/ImageParserMagick.so $(BUILD_DIR)/ImageParserCImg.so

#$(BUILD_DIR)/ImageParser.so: ParserFunctions/ImageParser.cpp $(SDK_HOME)/include/Vertica.cpp  $(SDK_HOME)/include/BuildInfo.h $(BUILD_DIR)/.exists
	#$(CXX) $(CXXFLAGS) -o $@ ParserFunctions/ImageParser.cpp $(SDK_HOME)/include/Vertica.cpp -O2 -L/usr/X11R6/lib -lm -lpthread -lX11
	
	
$(BUILD_DIR)/ImageParserMagick.so: src/ParserFunctions/Magick/*.cpp $(SDK_HOME)/include/Vertica.cpp  $(SDK_HOME)/include/BuildInfo.h $(BUILD_DIR)/.exists
	$(CXX) $(CXXFLAGS) -o $@ src/ParserFunctions/Magick/*.cpp $(SDK_HOME)/include/Vertica.cpp -O2 `Magick++-config --cppflags --cxxflags --ldflags --libs`
	
$(BUILD_DIR)/ImageParserCImg.so: src/ParserFunctions/CImg/*.cpp $(SDK_HOME)/include/Vertica.cpp  $(SDK_HOME)/include/BuildInfo.h $(BUILD_DIR)/.exists
	$(CXX) $(CXXFLAGS) -o $@ src/ParserFunctions/CImg/*.cpp $(SDK_HOME)/include/Vertica.cpp -O2 -L/usr/X11R6/lib -lm -lpthread
	
	

clean:
	rm -f $(BUILD_DIR)/*.so 
	-rmdir $(BUILD_DIR) >/dev/null 2>&1 || true
