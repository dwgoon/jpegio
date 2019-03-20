#include "jpegioerror.h"


GLOBAL(void)
jpegio_output_message(j_common_ptr cinfo)
{
    char buffer[JMSG_LENGTH_MAX];

    // Create the message
    (*cinfo->err->format_message) (cinfo, buffer);

    printf("[LIBJPEG MESSAGE] %s\n", buffer);
}


GLOBAL(void)
jpegio_error_exit(j_common_ptr cinfo)
{
    char buffer[JMSG_LENGTH_MAX];

    // cinfo->err really points to a jpegio_error_mgr struct, so coerce pointer 
    jpegio_error_ptr jpegio_err = (jpegio_error_ptr) cinfo->err;

    // create the message
    (*cinfo->err->format_message) (cinfo, buffer);
    printf("[LIBJPEG ERROR]: %s\n", buffer);

    // return control to the setjmp point
    longjmp(jpegio_err->setjmp_buffer, 1);
}
