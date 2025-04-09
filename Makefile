CC = hipcc
HIPIFY = hipify-clang
FLAGS = --shared -g '-fPIC'
PRIV_DIR = priv
C_SRC_DIR = c_src

all: $(PRIV_DIR)/gpu_nifs.so

$(PRIV_DIR)/gpu_nifs.so: $(C_SRC_DIR)/gpu_nifs.cu | $(PRIV_DIR)
	$(HIPIFY) $(C_SRC_DIR)/gpu_nifs.cu -o $(C_SRC_DIR)/gpu_nifs.hip
	$(CC) $(FLAGS) -o priv/gpu_nifs.so $(C_SRC_DIR)/gpu_nifs.hip
	@echo "Compiled GPU NIFS successfully"

bmp: $(C_SRC_DIR)/bmp_nifs.cu | $(PRIV_DIR)
	$(HIPIFY) $(C_SRC_DIR)/bmp_nifs.cu -o $(C_SRC_DIR)/bmp_nifs.hip
	$(CC) $(FLAGS) -o priv/bmp_nifs.so $(C_SRC_DIR)/bmp_nifs.hip
	@echo "Compiled BMP NIFS successfully"

$(PRIV_DIR):
	mkdir -p $(PRIV_DIR)
	@echo "Created priv directory"

clean:
	rm -f $(PRIV_DIR)/*
	rm -f $(C_SRC_DIR)/Elixir*
	rm -f $(C_SRC_DIR)/*.hip
	rm -f erl_crash.dump