TARGET = FFT_1Dapp 
SOURCES = FFT_1Dtest.c

AF ?= 2 1024
APP_FLAGS ?= ${AF} 
LD_LIBS += -lfftw3 -lfftw3f -lfftw3_threads
#APP_SPECIFIC_CXX_FLAGS ?= -I$(CURDIR)

include ../../Makefile.tests
