CC = hipcc
HIPIFY = hipify-clang
FLAGS = --shared -g '-fPIC'
PRIV_DIR = priv

all: priv/gpu_nifs.so 

priv/gpu_nifs.so: c_src/gpu_nifs.cu | $(PRIV_DIR)
	$(HIPIFY) c_src/gpu_nifs.cu -o c_src/gpu_nifs.hip
	$(CC) $(FLAGS) -o priv/gpu_nifs.so c_src/gpu_nifs.hip
	@echo "Compiled GPU NIFS successfully"

bmp: c_src/bmp_nifs.cu | $(PRIV_DIR)
	$(HIPIFY) c_src/bmp_nifs.cu -o c_src/bmp_nifs.hip
	$(CC) $(FLAGS) -o priv/bmp_nifs.so c_src/bmp_nifs.hip
	@echo "Compiled BMP NIFS successfully"

$(PRIV_DIR):
	mkdir -p $(PRIV_DIR)
	@echo "Created priv directory"

clean:
	rm -f $(PRIV_DIR)/*
