#pragma once

#include <stdio.h>
#include <setjmp.h>
#include "jpeglib.h"
#include "jerror.h"

struct jpegio_error_mgr {
  struct jpeg_error_mgr pub;
  jmp_buf setjmp_buffer;
};

typedef struct jpegio_error_mgr* jpegio_error_ptr;


EXTERN(void) jpegio_output_message(j_common_ptr cinfo);
EXTERN(void) jpegio_error_exit(j_common_ptr cinfo);