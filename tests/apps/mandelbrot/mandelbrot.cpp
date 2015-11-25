#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

#define ITERS		300

/* This program computes which iteration a given point fails the Mandelbrot set, if any.  We 
   define an NxM matrix as follows:
   
   -2,2i   ...   2,2i
     .      .     .
     .     0,0i   .
     .      .     .
   -2,-2i  ...   2,-2i

   Such that the points in between each corner are evenly spaced (i.e. step size from row to 
   row is 4/GRID_ROWS and step size from column to column is 4/GRID_COLS

   To determine when a point, c, exits the Mandelbrot set, we follow these steps
   1- Let z = c
   2- Compute |z|
   3a- If |z| >= 2, then return iteration count
   3b- If |z| < 2, then set z = z^2 + c and return to step 2
*/


void *mandelbrot( void *ptr );

struct thread_data{
     int pt_num;
     float row;
     float col;
     int fail;
     int pts_to_do;
};


int main(int argc, char *argv[])
{
     // Parse input
     if (argc != 4){
	printf("ERROR: Input args must be '<rows> <cols> <maxthreads>'\n");
     	return(0);
     }
     int GRID_ROWS = atoi(argv[1]);
     int GRID_COLS = atoi(argv[2]);
     int num_threads = atoi(argv[3]);
     
     int num_pts = GRID_ROWS * GRID_COLS;
     pthread_t thread[num_pts];
     int ret;
     int td_start_pt;
     int i,j,pt_num;
     struct thread_data td[num_pts];
     int image[GRID_ROWS][GRID_COLS];

     // Figure out number of points each thread needs to work on, assume num_pts is divisible by num_threads
     int pts_per_thread = num_pts / num_threads;     

     printf("Getting ready to spawn %d threads to compute %d points (%d points per thread)\n", num_threads, num_pts,pts_per_thread);
     // Set up points
     for( i=0; i < GRID_ROWS; i = i + 1){
	for( j=0; j < GRID_COLS; j = j + 1){
	   pt_num = GRID_COLS*i + j; /* Compute nth thread number */
	   td[pt_num].row = 2 - (float(i) / GRID_ROWS)*4;
	   td[pt_num].col = -2 + (float(j) / GRID_COLS)*4;
	   td[pt_num].pt_num = pt_num;
	   td[pt_num].pts_to_do = pts_per_thread;
	}
     }
     
     // Spawn threads
     for (i = 0; i < num_threads ; i = i + 1) {
	td_start_pt = i * pts_per_thread;
	//printf("Spawning thread %d, starting at pt %d and computing %d pts\n",i, td_start_pt, pts_per_thread);
	ret = pthread_create( &thread[i], NULL, mandelbrot, (void*)&td[td_start_pt]);
     	   if(ret){
              fprintf(stderr,"Error - pthread_create() return code: %d\n",ret);
              exit(EXIT_FAILURE);
     	   }
     }
     /* Wait till threads are complete before main continues. Unless we  */
     /* wait we run the risk of executing an exit which will terminate   */
     /* the process and all threads before the threads have completed.   */
     for( i=0; i < num_threads; i = i+1){
        pthread_join( thread[i], NULL);
     }

     // Assemble image
     for( i=0; i < GRID_ROWS; i = i + 1){
	for( j=0; j < GRID_COLS; j = j + 1){
	   pt_num = GRID_COLS*i + j; /* Compute nth thread number */
	   image[i][j] = td[pt_num].fail;
	}
     }

     // Show image
     for( i=0; i < GRID_ROWS; i = i + 1){
	for( j=0; j < GRID_COLS; j = j + 1){
	   if (image[i][j] > ITERS-1){
		printf("o");
	   }
	   else if (image[i][j] > 5){
		printf("-");
	   }
	   else{
		printf(" ");
	   }
	}
	printf("\n");
     }	   

     exit(EXIT_SUCCESS);
}

void *mandelbrot( void *ptr )
{
     struct thread_data *coords;
     int i, k, fail;
     float z_re, z_im;
     float z_re_next, z_im_next;
     float c_re, c_im;
     float mag;

     coords = (struct thread_data *) ptr;

     int pts_to_do = coords->pts_to_do;
     for (k = 0; k < pts_to_do ; k = k+1){

        /* Set c */
        c_re = coords->col;
        c_im = coords->row;

        /* Initialize z */
        z_re = 0;
        z_im = 0;
	 
        // Initialize fail to the max possible
        fail = ITERS;
        /* Run mandelbrot algorithm */
        for (i=0 ; i < ITERS ; i = i + 1){
           /* Compute the next z */
	   z_re_next = (z_re * z_re) - (z_im * z_im) + c_re;
           z_im_next = 2 * z_re * z_im + c_im;

	   /* Calc magnitude */
	   mag = z_re_next * z_re_next + z_im_next * z_im_next;	

	   /* Check if we are inside 2 */
	   if(mag >= 2){
	      fail = i;
	      break;
	   }
	   else{
	      z_re = z_re_next;
	      z_im = z_im_next;
	   }
	
        }           
        coords->fail = fail;

	// Increment to next point in struct
	coords++;
     }
}
