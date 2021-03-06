MODULES	:= perf test test/v3api

TARGET	:= release

CXX	:= g++
LD	:= $(CXX)

SRC_DIR		:= src
BUILD_DIR	:= build
OUT_DIR		:= output

OBJ_DIR := $(BUILD_DIR)/$(TARGET)
BIN_DIR := $(OUT_DIR)/$(TARGET)/bin

SRC_DIRS := $(addprefix $(SRC_DIR)/,$(MODULES))
OBJ_DIRS := $(addprefix $(OBJ_DIR)/,$(MODULES))

SRCS := $(foreach sdir,$(SRC_DIRS),$(wildcard $(sdir)/*.cpp))
OBJS := $(patsubst $(SRC_DIR)/%.cpp,$(OBJ_DIR)/%.o,$(SRCS))

CXX_FLAGS := -ggdb -MMD -MP -DBOOST_TEST_DYN_LINK

ifeq ($(TARGET),release)
	CXX_FLAGS += -O3
endif

vpath %.cpp $(SRC_DIRS)

define compile
$1/%.o: %.cpp
	$(CXX) -c $$(CXX_FLAGS) $$< -o $$@
endef

.PHONY: all mkdirs clean

all: mkdirs \
	$(BIN_DIR)/fbinsert \
	$(BIN_DIR)/fbtest

mkdirs: $(OBJ_DIRS) $(BIN_DIR)

$(OBJ_DIRS) $(BIN_DIR):
	@mkdir -p $@

clean:
	@rm -rf $(BUILD_DIR) $(OUT_DIR)

$(foreach bdir,$(OBJ_DIRS),$(eval $(call compile,$(bdir))))

-include $(addsuffix .d,$(basename $(OBJS)))

$(BIN_DIR)/fbinsert: $(OBJ_DIR)/perf/fbinsert.o
	$(LD) $^ -o $@ -lboost_program_options -lboost_thread -lfbclient

$(BIN_DIR)/fbtest: \
	$(OBJ_DIR)/test/FbTest.o \
	$(OBJ_DIR)/test/v3api/V3Util.o \
	$(OBJ_DIR)/test/v3api/AffectedRecordsTest.o \
	$(OBJ_DIR)/test/v3api/DescribeTest.o \
	$(OBJ_DIR)/test/v3api/DynamicMessageTest.o \
	$(OBJ_DIR)/test/v3api/StaticMessageTest.o \

	$(LD) $^ -o $@ -lboost_unit_test_framework -lfbclient
