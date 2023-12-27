#include <stdio.h>
#include <time.h>
#include <stdint.h>
#define rnd( x ) (x * rand() / RAND_MAX)
#define INF     2e10f

#define _bitsperpixel 32
#define _planes 1
#define _compression 0

#define _xpixelpermeter 0x13B //0x130B //2835 , 72 DPI
#define _ypixelpermeter 0x13B//0x130B //2835 , 72 DPI
#define pixel 0xFF
#pragma pack(push,1)
typedef struct{
    uint8_t signature[2];
    uint32_t filesize;
    uint32_t reserved;
    uint32_t fileoffset_to_pixelarray;
} fileheader;
typedef struct{
    uint32_t dibheadersize;
    uint32_t width;
    uint32_t height;
    uint16_t planes;
    uint16_t bitsperpixel;
    uint32_t compression;
    uint32_t imagesize;
    uint32_t ypixelpermeter;
    uint32_t xpixelpermeter;
    uint32_t numcolorspallette;
    uint32_t mostimpcolor;
} bitmapinfoheader;
typedef struct {
    fileheader fileheader;
    bitmapinfoheader bitmapinfoheader;
} bitmap;
#pragma pack(pop)
void genBpm (int height, int width, float *pixelbuffer_f) {
    uint32_t pixelbytesize = height*width*_bitsperpixel/8;
    uint32_t  _filesize =pixelbytesize+sizeof(bitmap);
    FILE *fp = fopen("test.bmp","wb");
    bitmap *pbitmap  = (bitmap*)calloc(1,sizeof(bitmap));

    int buffer_size = height*width*4;
    uint8_t *pixelbuffer = (uint8_t*)malloc(buffer_size);

    for(int i = 0; i<buffer_size;i++)
    {
     pixelbuffer[i]= (uint8_t) pixelbuffer_f[i];
    }


    //strcpy(pbitmap->fileheader.signature,"BM");
    pbitmap->fileheader.signature[0] = 'B';
    pbitmap->fileheader.signature[1] = 'M';
    pbitmap->fileheader.filesize = _filesize;
    pbitmap->fileheader.fileoffset_to_pixelarray = sizeof(bitmap);
    pbitmap->bitmapinfoheader.dibheadersize =sizeof(bitmapinfoheader);
    pbitmap->bitmapinfoheader.width = width;
    pbitmap->bitmapinfoheader.height = height;
    pbitmap->bitmapinfoheader.planes = _planes;
    pbitmap->bitmapinfoheader.bitsperpixel = _bitsperpixel;
    pbitmap->bitmapinfoheader.compression = _compression;
    pbitmap->bitmapinfoheader.imagesize = pixelbytesize;
    pbitmap->bitmapinfoheader.ypixelpermeter = _ypixelpermeter ;
    pbitmap->bitmapinfoheader.xpixelpermeter = _xpixelpermeter ;
    pbitmap->bitmapinfoheader.numcolorspallette = 0;
    fwrite (pbitmap, 1, sizeof(bitmap),fp);
    //memset(pixelbuffer,pixel,pixelbytesize);
    fwrite(pixelbuffer,1,pixelbytesize,fp);
    fclose(fp);
    free(pbitmap);
    free(pixelbuffer);
}


struct Sphere {
    float   r,b,g;
    float   radius;
    float   x,y,z;
};

void loadSpheres(Sphere *vet, int size, int dim, int radius, int sum){
   
	for (int i=0;i<size;i++){
			Sphere sphere;
            sphere.r = rnd(1);
            sphere.b = rnd(1);
            sphere.g = rnd(1);
            sphere.radius = rnd(radius) + sum;
            sphere.x = rnd(dim) - trunc(dim / 2);
            sphere.y = rnd(dim) - trunc(dim / 2);
            sphere.z = rnd(256) - 128;

            vet[i] = sphere;
            
           
        }
}

#define SPHERES 20

__global__ void kernel(int dim, Sphere * s,  float *ptr ) {
    int x = threadIdx.x + blockIdx.x * blockDim.x;
    int y = threadIdx.y + blockIdx.y * blockDim.y;
    int offset = x + y * blockDim.x * gridDim.x;
    float   ox = (x - dim/2);
    float   oy = (y - dim/2);

    float   r=0, g=0, b=0;
    float   maxz = -99999;
    for(int i=0; i<SPHERES; i++) {
        float   n;
        float   t = -99999;
        float dx = ox - s[i].x;
        float dy = oy - s[i].y;
        float dz;
        if (dx*dx + dy*dy < s[i].radius * s[i].radius) {
            dz = sqrtf( s[i].radius * s[i].radius - dx*dx - dy*dy );
            n = dz / sqrtf( s[i].radius * s[i].radius );
            t = dz + s[i].z;

        } else {
            t = -99999;
        }
        if (t > maxz) {
              float fscale = n;
              r = s[i].r * fscale;
              g = s[i].g * fscale;
              b = s[i].b * fscale;
              maxz = t;
        }

    }

    ptr[offset*4 + 0] = (r * 255);
    ptr[offset*4 + 1] = (g * 255);
    ptr[offset*4 + 2] = (b * 255);
    ptr[offset*4 + 3] = 255;
}


int main(int argc, char *argv[]){
    int dim = atoi(argv[1]);
    //int sph = atoi(argv[2]);
    
    float   *final_image;
    float   *dev_image;
    Sphere * s;

    final_image = (float*) malloc(dim * dim * sizeof(float)*4);
    Sphere *temp_s = (Sphere*)malloc( sizeof(Sphere) * SPHERES );
    
    loadSpheres(temp_s, SPHERES, dim, 160, 20);

    /*

    if(dim == 256) {
      temp_s[0] = { 0.5647144993438521, 0.17026276436658833, 0.2513199255348369, 17.309945982238226, -83.67052217169714, -119.68724631488998, 98.2803430280465 };
      temp_s[1]=  { 0.9091158787804804, 0.1487777336954863, 0.1783196508682516, 21.85598315378277, -4.082155827509382, -0.5976744895779262, 24.65309610278635 };
      temp_s[2]=  { 0.6624347666859951, 0.3954588457899716, 0.6516922513504441, 17.61146885586108, 14.65279091769159, -110.39790032654805, 4.207159642323063 };
      temp_s[3]=  { 0.413251136814478, 0.3630481887264626, 0.1980040894802698, 16.984618671224098, -2.0039674062318795, -100.77260658589435, -95.8896450697348 };
      temp_s[4]=  { 0.13864558854945525, 0.9300515762810144, 0.6028931546983245, 12.94213690603351, -104.46021912289804, 28.098513748588516, 0.8711203344828675 };
      temp_s[5]=  { 0.21469771416364025, 0.9337748344370861, 0.33420819727164525, 18.591723380230107, -28.418836024048588, 107.64000366222115, 58.74007385479294 };
      temp_s[6]=  { 0.576219977416303, 0.6904812768944365, 0.7726371044038209, 18.319498275704213, -114.95272682882168, 88.7097384563738, -65.42777794732505 };
      temp_s[7]=  { 0.9437543870357372, 0.3283181249427778, 0.8446913052766503, 6.454512161626026, 122.41389202551346, 47.942869350260935, 121.83574938200019 };
      temp_s[8]=  { 0.8970305490279855, 0.014038514358958708, 0.9583117160557878, 18.243202002014222, 15.262184514908284, 94.37397381511886, -126.56245612964263 };
      temp_s[9]=  { 0.4650105288857692, 0.21561326944792017, 0.8502761925107578, 24.533677175206762, -43.872432630390335, -119.06222724082156, 61.88860744041261 };
      temp_s[10]=  { 0.9226660969878231, 0.9497665334025086, 0.8874477370525223, 21.117435224463637, -57.17752616962187, 77.29532761619922, -92.29578539384136 };
      temp_s[11]=  { 0.03280739768669698, 0.7397076326792199, 0.9098178044984283, 15.11871700186163, 26.442213202307187, 16.871608630634483, -61.63078707235938 };
      temp_s[12]=  { 0.565660573137608, 0.3304849391155736, 0.31153294473097937, 21.61976989043855, 26.27814569536423, -40.46607867671743, -1.0898770104068092 };
      temp_s[13]=  { 0.14319284646137884, 0.2749107333597827, 0.16772972808008058, 24.909054841761527, 78.25629444257942, 10.676107058931251, 48.06006042664876 };
      temp_s[14]=  { 0.007263405255287332, 0.7207861568041017, 0.14539017914365063, 17.106692709128087, -84.42054506057924, -53.30240791039766, 114.59334086123235 };
      temp_s[15]=  { 0.391155735953856, 0.3933835871456038, 0.4371471297341838, 7.766808069093905, 123.26548051393169, 54.50556962797938, 72.99832148197882 };
      temp_s[16]=  { 0.9168065431684317, 0.9289834284493546, 0.5631885738700522, 11.508377330851161, -9.691702017273471, 59.45103305154575, -26.8797265541551 };
      temp_s[17]=  { 0.06183050019837031, 0.08331553086947234, 0.8713950010681478, 18.9005706961272, -13.230872524185912, 60.95107882930998, -63.826166570024725 };
      temp_s[18]=  { 0.2659993285927915, 0.3164159062471389, 0.46769615771965695, 15.00518814661092, -103.35081026642659, -63.951170384838406, 4.4024781029694395 };
      temp_s[19]=  { 0.5646229438154241, 0.6811426129947813, 00.023316141239661855, 14.228797265541552, 21.32486953337198, 62.71675771355328, -123.35142063661611 };
    }
    if(dim == 1024){
      temp_s[0] = { 0.5647144993438521, 0.17026276436658833, 0.2513199255348369, 69.2397839289529, -334.6820886867886, -478.7489852595599, 98.2803430280465};
      temp_s[1] = { 0.9091158787804804, 0.1487777336954863, 0.1783196508682516, 87.42393261513108, -16.32862331003753, -2.390697958311705, 24.65309610278635};
      temp_s[2] = { 0.6624347666859951, 0.3954588457899716, 0.6516922513504441, 70.44587542344432, 58.61116367076636, -441.5916013061922, 4.207159642323063};
      temp_s[3] = { 0.413251136814478, 0.3630481887264626, 0.1980040894802698, 67.93847468489639, -8.015869624927518, -403.0904263435774, -95.8896450697348};
      temp_s[4] = { 0.13864558854945525, 0.9300515762810144, 0.6028931546983245, 51.76854762413404, -417.84087649159216, 112.39405499435406, 0.8711203344828675};
      temp_s[5] = { 0.21469771416364025, 0.9337748344370861, 0.33420819727164525, 74.36689352092043, -113.67534409619435, 430.5600146488846, 58.74007385479294};
      temp_s[6] = { 0.576219977416303, 0.6904812768944365, 0.7726371044038209, 73.27799310281685, -459.8109073152867, 354.8389538254952, -65.42777794732505};
      temp_s[7] = { 0.9437543870357372, 0.3283181249427778, 0.8446913052766503, 25.818048646504103, 489.65556810205385, 191.77147740104374, 121.83574938200019};
      temp_s[8] = { 0.8970305490279855, 0.014038514358958708, 0.9583117160557878, 72.97280800805689, 61.04873805963314, 377.49589526047544, -126.56245612964263};
      temp_s[9] = { 0.4650105288857692, 0.21561326944792017, 0.8502761925107578, 98.13470870082705, -175.48973052156134, -476.2489089632862, 61.88860744041261};
      temp_s[10] = { 0.9226660969878231, 0.9497665334025086, 0.8874477370525223, 84.46974089785455, -228.71010467848748, 309.18131046479687, -92.29578539384136};
      temp_s[11] = { 0.03280739768669698, 0.7397076326792199, 0.9098178044984283, 60.47486800744652, 105.76885280922875, 67.48643452253793, -61.63078707235938};
      temp_s[12] = { 0.565660573137608, 0.3304849391155736, 0.31153294473097937, 86.4790795617542, 105.11258278145692, -161.86431470686972, -1.0898770104068092};
      temp_s[13] = { 0.14319284646137884, 0.2749107333597827, 0.16772972808008058, 99.63621936704611, 313.02517777031767, 42.704428235725004, 48.06006042664876};
      temp_s[14] = { 0.007263405255287332, 0.7207861568041017, 0.14539017914365063, 68.42677083651235, -337.682180242317, -213.20963164159065, 114.59334086123235};
      temp_s[15] = { 0.391155735953856, 0.3933835871456038, 0.4371471297341838, 31.06723227637562, 493.06192205572677, 218.02227851191753, 72.99832148197882};
      temp_s[16] = { 0.9168065431684317, 0.9289834284493546, 0.5631885738700522, 46.033509323404644, -38.766808069093884, 237.804132206183, -26.8797265541551};
      temp_s[17] = { 0.06183050019837031, 0.08331553086947234, 0.8713950010681478, 75.6022827845088, -52.92349009674365, 243.8043153172399, -63.826166570024725};
      temp_s[18] = { 0.2659993285927915, 0.3164159062471389, 0.46769615771965695, 60.02075258644368, -413.40324106570637, -255.80468153935362, 4.4024781029694395};
      temp_s[19] = { 0.5646229438154241, 0.6811426129947813, 0.023316141239661855, 56.915189062166206, 85.29947813348792, 250.8670308542131, -123.35142063661611};
    }
    if (dim == 2048 || dim == 3072 || dim ==4096 || dim == 5120 || dim == 6144 || dim == 7168){
temp_s[0]=  {0.5647144993438521	,0.17026276436658833	 ,0.2513199255348369	 , 93.85967589342937	 , -669.3641773735771	 , -957.4979705191198	 , 98.2803430280465 };
temp_s[1]=	 { 0.9091158787804804	 ,0.1487777336954863	 ,0.1783196508682516	 , 121.13589892269661	 , -32.65724662007506	 , -4.78139591662341	 , 24.65309610278635};
temp_s[2]=	 {0.6624347666859951	 ,0.3954588457899716	 ,0.6516922513504441	 , 95.66881313516647	 , 117.22232734153272	 , -883.1832026123844	 , 4.207159642323063};
temp_s[3]=	 { 0.413251136814478	 ,0.3630481887264626	 , 0.1980040894802698	 , 91.90771202734459	 , -16.031739249855036	 , -806.1808526871548	 , -95.8896450697348};
temp_s[4]=	 { 0.13864558854945525	 , 0.9300515762810144	 , 0.6028931546983245	 , 67.65282143620107	 , -835.6817529831843	 , 224.78810998870813	 , 0.8711203344828675};
temp_s[5]=	 { 0.21469771416364025	 , 0.9337748344370861	 , 0.33420819727164525	 , 101.55034028138066	 , -227.3506881923887	 , 861.1200292977692	 , 58.74007385479294};
temp_s[6]=	 { 0.576219977416303	 , 0.6904812768944365	 , 0.7726371044038209	 , 99.91698965422529	 , -919.6218146305735	 , 709.6779076509904	 , -65.42777794732505};
temp_s[7]=	 { 0.9437543870357372	 , 0.3283181249427778	 , 0.8446913052766503	 , 28.727072969756158	 , 979.3111362041077	 , 383.5429548020875	 , 121.83574938200019};
temp_s[8]=	 { 0.8970305490279855	 , 0.014038514358958708	 , 0.9583117160557878	 , 99.45921201208533	 , 122.09747611926628	 , 754.9917905209509	 , -126.56245612964263};
temp_s[9]=	 { 0.4650105288857692	 , 0.21561326944792017	 , 0.8502761925107578	 , 137.20206305124057	 , -350.9794610431227	 , -952.4978179265725	 , 61.88860744041261};
temp_s[10]=	 { 0.9226660969878231	 , 0.9497665334025086	 , 0.8874477370525223	 , 116.70461134678182	 , -457.42020935697496	 , 618.3626209295937	 , -92.29578539384136};
temp_s[11]=	 { 0.03280739768669698	 , 0.7397076326792199	 , 0.9098178044984283	 , 80.71230201116978	 , 211.5377056184575	 , 134.97286904507587	 , -61.63078707235938};
temp_s[12]=	 { 0.565660573137608	 , 0.3304849391155736	 , 0.31153294473097937	 , 119.7186193426313	 , 210.22516556291384	 , -323.72862941373944	 , -1.0898770104068092};
temp_s[13]=	 { 0.14319284646137884	 , 0.2749107333597827	 , 0.16772972808008058	 , 139.45432905056919	 , 626.0503555406353	 , 85.40885647145001	 , 48.06006042664876};
temp_s[14]=	 { 0.007263405255287332	 ,0.7207861568041017	 , 0.14539017914365063	 , 92.64015625476851	 , -675.364360484634	 , -426.4192632831813	 , 114.59334086123235};
temp_s[15]=	 { 0.391155735953856	 , 0.3933835871456038	 , 0.4371471297341838	 , 36.60084841456343	 , 986.1238441114535	 , 436.04455702383507	 , 72.99832148197882};
temp_s[16]=	 { 0.9168065431684317	 , 0.9289834284493546	 , 0.5631885738700522	 , 59.050263985106966	 , -77.53361613818777	 , 475.608264412366	 , -26.8797265541551};
temp_s[17]=	 { 0.06183050019837031	 , 0.08331553086947234	 , 0.8713950010681478	 , 103.40342417676321	 , -105.8469801934873	 , 487.6086306344798	 , -63.826166570024725};
temp_s[18]=	 { 0.2659993285927915	 , 0.3164159062471389	 , 0.46769615771965695	 , 80.03112887966552	 , -826.8064821314127	 , -511.60936307870725	 , 4.4024781029694395};
temp_s[19]=	 { 0.5646229438154241	 ,0.6811426129947813	 , 0.023316141239661855	 , 75.3727835932493	 , 170.59895626697585	 , 501.7340617084262	 , -123.35142063661611};
    
        }
  
*/

    float time;
    cudaEvent_t start, stop;   
    cudaEventCreate(&start) ;
    cudaEventCreate(&stop) ;
    cudaEventRecord(start, 0) ;

    cudaMalloc( (void**)&dev_image, dim * dim * sizeof(float)*4);
    cudaMalloc( (void**)&s, sizeof(Sphere) * SPHERES );
    
    cudaMemcpy( s, temp_s, sizeof(Sphere) * SPHERES, cudaMemcpyHostToDevice );

    dim3    grids(dim/16,dim/16);
    dim3    threads(16,16);

    kernel<<<grids,threads>>>(dim, s, dev_image);

    cudaMemcpy( final_image, dev_image, dim * dim * sizeof(float) * 4,cudaMemcpyDeviceToHost );
        
    cudaFree( dev_image);
    cudaFree( s );
    
    cudaEventRecord(stop, 0) ;
    cudaEventSynchronize(stop) ;
    cudaEventElapsedTime(&time, start, stop) ;

     printf("CUDA\t%d\t%3.1f\n", dim,time);
     genBpm(dim,dim,final_image);
    /*
    int height = dim;
    int width = dim;
    
    unsigned char* image = (unsigned char*) malloc(dim * dim *4); //[height][width][BYTES_PER_PIXEL];

    //double elapsed_time = ((double)(end_time - start_time) * 1000000.0) / CLOCKS_PER_SEC;

    char imageFileName[50];

    sprintf(imageFileName, "img-c-CUDAraytracer-%dx%d.bmp", dim, dim);
  

    int i, j;
    for (i = 0; i < height; i++) {
        for (j = 0; j < width; j++) {
            image[(i * dim + j) * 4 + 3] = final_image[(i * dim + j) * 4 + 3] ;
            image[(i * dim + j) * 4 + 0] = final_image[(i * dim + j) * 4 + 2] ;
            image[(i * dim + j) * 4 + 1] = final_image[(i * dim + j) * 4 + 1] ;
            image[(i * dim + j) * 4 + 2] = final_image[(i * dim + j) * 4 + 0] ;
        }
    }

    generateBitmapImage((unsigned char*) image, height, width, imageFileName);
    //printf("Image generated!!");

    //generateLog(elapsed_time, dim, sph, iteration);

    free(image);
    free(temp_s);
    free(final_image);
*/

}