#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <stdint.h>
#define MAX_ITER 10000000
//This application is designed in an attempt to stress L1 data cache while maintaining high L2 miss rate
// We load a 2D image and for each pixel other than the first one it is the difference of the current and previous one


typedef struct thread_data
{
   uint64_t size;
   int* x;
   int* y;
} thread_data;

void* thread_func(thread_data* input)
{
        register uint64_t i;
        register uint64_t index;
	input->y[0]=input->x[0];
        for(i=1;i<input->size;i++){
            input->y[i]=input->x[i]-input->x[i-1];
        }
        return NULL;
}


int main(int argc, char* argv[]){
    int* x;
    int* y;
    uint64_t i;
    uint64_t size; 
    uint64_t N_threads,array_size;
    pthread_t* worker_pointer;
    thread_data* working_data;
    if (argc<3)
    {
	printf ("Usage: Image_diff_encode array_size (MBs) Number_of_threads\n");
	return -1;
    }
    srand (time(NULL)); 
    size=atoi(argv[1])*1024*1024;
    N_threads=atoi(argv[2]);
    array_size=size/N_threads;
    x=malloc(size*sizeof(int));
    y=malloc(size*sizeof(int));
    if(x==0 ||y==0)
    {
	printf("could not locate memory \n");
	return -2;
    }
     //for(i=0;i<size;i++){
     //   x[i]=rand()%size;
    //}

     worker_pointer=malloc(N_threads*sizeof(pthread_t));
    working_data=malloc(N_threads*sizeof(thread_data));
    for (i=0;i<N_threads;i++){
        working_data[i].size=array_size;
        working_data[i].x=&x[i*array_size];
        working_data[i].y=&y[i*array_size];
    }

    printf("Creating threads \n");
    for(i=0;i<N_threads;i++){
        pthread_create(worker_pointer+i,NULL, thread_func,(void *) (working_data+i));
    }
    printf("Waiting for them to be finished \n");
    for(i=0;i<N_threads;i++){
        pthread_join(worker_pointer[i],NULL);
    }
    printf("Done \n");
    free(working_data);
    free(worker_pointer);
    free(x);
    free(y);
    return 0;
}
