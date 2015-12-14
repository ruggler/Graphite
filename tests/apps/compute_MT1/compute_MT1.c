#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <stdint.h>
#define MAX_ITER 2 /*originally 100*/ 
#define MAX_num 1000
static inline void ROIBegin()
{
    __asm__ volatile ("movl %0, %%ecx\n\t"  \
            "xchg %%rcx, %%rcx\n\t" \
            : /* no output */   \
            : "ic" (1025 /* ROI_BEGIN */)   \
            : "%ecx"    \
            );
}

static inline void ROIEnd()
{
    __asm__ volatile ("movl %0, %%ecx\n\t"  \
            "xchg %%rcx, %%rcx\n\t" \
            : /* no output */   \
            : "ic" (1026 /* ROI_END */)   \
            : "%ecx"    \
            );
}

void* thread_func()
{
	register uint64_t i;
	register double t,x1,y1,z;
	register uint64_t x_val,y_val;
 	x_val=3;
	y_val=5;
	for(i=0;i<MAX_ITER;i++){
    	    z=0;
	    for(t=0;t<1;t+=0.000001){
	       x1 = pow(t,x_val-1); 
  	       y1 = pow(1-t,y_val-1);  
	       z += x1*y1;
	   }
	}
	return NULL;
}


int main(int argc, char* argv[]){
    uint64_t i,N_threads;
    pthread_t* worker_pointer;
    ROIEnd();
    N_threads=atoi(argv[1]);
    worker_pointer=malloc(N_threads*sizeof(pthread_t));
    printf("Creating threads \n");
    ROIBegin();
    for(i=0;i<N_threads;i++){
	pthread_create(worker_pointer+i,NULL, thread_func,NULL);
    }
    printf("Waiting for them to be finished \n");
    for(i=0;i<N_threads;i++){
	pthread_join(worker_pointer[i],NULL);
    }
    //Lauch the threads and wait for their completion
    ROIEnd();
    free(worker_pointer);
    printf("Done \n");
    return 0;
}
