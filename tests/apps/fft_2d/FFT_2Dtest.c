#include<stdio.h>
#include<fftw3.h>
int main(int argc, char* argv[])
{
  int i,n0,n1;
  int num_threads;
  fftw_plan p;
  i=fftw_init_threads();
  if(i==0)
  {
    fprintf(stderr,"cannot initiate the threads");
    exit(0);
  }
  num_threads=atoi(argv[1]);
  printf("Number of threads %d \n",num_threads);
  n0=atoi(argv[2]);
  n1=atoi(argv[3]);
  fftw_plan_with_nthreads(num_threads);
  fftw_complex *in=(fftw_complex*) fftw_malloc(sizeof(fftw_complex) * n0*n1);
  fftw_complex *out=(fftw_complex*) fftw_malloc(sizeof(fftw_complex) *n0*n1);  
  printf("Size of fftw_complex data structure is %d \n",sizeof(fftw_complex));
  p=fftw_plan_dft_2d(n0,n1,in,out,FFTW_FORWARD,FFTW_ESTIMATE); 
  fftw_execute(p);    
  fftw_destroy_plan(p);  
  return 0;
}
