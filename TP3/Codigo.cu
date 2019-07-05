#include <iostream>
#include <stdio.h>
#include <ctime>

using namespace std;

void initIndex(unsigned long long *index, unsigned long long n)
{
        for(unsigned long long i=0; i<n; i++)
                index[i]=i;
        for(unsigned long long i=0; i<n; i++)
        {
                unsigned long long j = rand()%n;
                swap(index[i],index[j]);
        }
}

void initArray(unsigned long long *a, unsigned long long n)
{
        if(n < (2<<10))
                for(int i = 0; i < n; i++)
                        a[i] = rand()%1001 + 1;
        else
                for(int i = 0; i < n; i++)
                        a[i] = rand()%(n+1) + 1;
}

__global__ void  somaPolinomio(unsigned long long *a, unsigned long long *b, unsigned long long n, unsigned long long *c)
{
        unsigned long long idx = blockDim.x*blockIdx.x + threadIdx.x;
        if(idx < n)
        {
                unsigned int c1=0,c2=0;
                asm("mov.u32 %0,%%clock;":"=r"(c1));
                #pragma unroll
                for(int i = 0; i < 4; i++)
                {
                        int pos = idx*4+i;
                        c[pos] = 5*(a[pos]*a[pos]*a[pos]) + 7*a[pos]*b[pos] + 8*b[pos]*b[pos] - b[pos] ;
                }
                asm("mov.u32 %0,%%clock;":"=r"(c2));

                if(idx == 0)
                        printf("soma polinomio : %u ms\n",c2-c1);
        }
        return;
}

__global__ void  somaVetor(unsigned long long *a, unsigned long long *b, unsigned long long n, unsigned long long *c)
{
        unsigned long long idx = blockDim.x*blockIdx.x + threadIdx.x;
        if(idx < n)
        {
                unsigned int c1=0,c2=0;
                asm("mov.u32 %0,%%clock;":"=r"(c1));
                for(int i = 0; i < 4; i++)
                {
                        int pos = idx*4+i;
                        c[pos] = a[pos] + b[pos];
                }
                asm("mov.u32 %0,%%clock;":"=r"(c2));

                if(idx == 0)
                        printf("soma vetor : %u ms\n",c2-c1);
        }
        return;
}

__global__ void  VetorRandom(unsigned long long *a, unsigned long long *b, unsigned long long n, unsigned long long *c, unsigned long long *index)
{
        unsigned long long idx = blockDim.x*blockIdx.x + threadIdx.x;
        if(idx < n)
        {
                //Acesso Sequencial
                unsigned int c1=0,c2=0;
                asm("mov.u32 %0,%%clock;":"=r"(c1));
                int pos = idx;
                c[pos] = a[pos] + b[pos];
                asm("mov.u32 %0,%%clock;":"=r"(c2));

                //Acesso Aleatorio
                if(idx == 0)
                        printf("Acessa Vetor Sequencial : %u ms\n",c2-c1);

                c1=0;c2=0;
                asm("mov.u32 %0,%%clock;":"=r"(c1));
                c[index[pos]] = a[index[pos]] + b[index[pos]];
                asm("mov.u32 %0,%%clock;":"=r"(c2));

                if(idx == 0)
                        printf("Acessa Vetor Random : %u ms\n",c2-c1);
        }
        return;
}


int main(int argc, char **argv)
{
	srand(time(NULL));
        //TAMANHOS PARA TESTAR : 1M, 2M, 10M, 20M, 32M
        unsigned long long n = 0;
        for(int i = 0; argv[1][i] != '\0'; i++)
                n = n*10 + (argv[1][i]-'0');

        //alocando vetores da CPU
        unsigned long long * h_a = new unsigned long long[n];
        unsigned long long * h_b = new unsigned long long[n];
        unsigned long long * h_c = new unsigned long long[n];
        unsigned long long * h_index = new unsigned long long[n];
        initArray(h_a,n);
        initArray(h_b,n);
        initIndex(h_index,n);

        //alocando vetores
        unsigned long long * d_a, *d_b, *d_c;
        cudaMalloc(&d_a,sizeof(unsigned long long)*n);
        cudaMalloc(&d_b,sizeof(unsigned long long)*n);
        cudaMalloc(&d_c,sizeof(unsigned long long)*n);
        unsigned long long * d_index;
        cudaMalloc(&d_index,sizeof(unsigned long long)*n);

	//copiando valores da CPU para a GPU
        cudaMemcpy(d_a, h_a, sizeof(unsigned long long)*n,cudaMemcpyHostToDevice);
        cudaMemcpy(d_b, h_b, sizeof(unsigned long long)*n,cudaMemcpyHostToDevice);
        cudaMemcpy(d_index, h_index, sizeof(unsigned long long)*n,cudaMemcpyHostToDevice);

        dim3 block,grid;
        //tamanho do bloco é arbitrário
        block.x = 1024;

        grid.x = ((n/4 + block.x -1)/block.x);

        //chama o somaVetor
        somaVetor<<<grid,block>>>(d_a,d_b,n,d_c);
        cudaDeviceSynchronize();

        //traz o resultado da GPU para a CPU
        cudaMemcpy(h_c, d_c, sizeof(unsigned long long)*n,cudaMemcpyDeviceToHost);

        //debug somaVetor
        /*for(int i = 0; i < n; i++)
                cout << h_a[i] << " ";
        cout << "\n";
        for(int i = 0; i < n; i++)
                cout << h_b[i] << " ";
        cout << "\n";
        for(int i = 0; i < n; i++)
                cout << h_c[i] << " ";
        cout << "\n";*/
	
	//chama o somaPolinomio
        somaPolinomio<<<grid,block>>>(d_a,d_b,n,d_c);
        cudaDeviceSynchronize();

        //chama VetorRandom
        VetorRandom<<<grid,block>>>(d_a,d_b,n,d_c,d_index);
        cudaDeviceSynchronize();


        cudaMemcpy(h_c, d_c, sizeof(unsigned long long)*n,cudaMemcpyDeviceToHost);

        //debug somaVetor
        /*for(int i = 0; i < n; i++)
                cout << h_a[i] << " ";
        cout << "\n";
        for(int i = 0; i < n; i++)
                cout << h_b[i] << " ";
        cout << "\n";
        for(int i = 0; i < n; i++)
                cout << h_c[i] << " ";
        cout << "\n";*/

        //desalocando memória
        free(h_a);
        free(h_b);
	free(h_c);
        cudaFree(d_a);
        cudaFree(d_b);
        cudaFree(d_c);
        //reseta a GPU
        cudaDeviceReset();
        return 0;
}

