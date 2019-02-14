# -*- coding: utf-8 -*-


"""
http://discoverybiz.net/enu0/faq/faq_yuvdatarangebybreeze.html
"""
import numpy as np
import jpegio
from utils import dct2, idct2

SZ_DCT = 8

def estimate_dct(Dq, Q):
    D = np.zeros_like(Dq, dtype=np.float32)  # Appoximately recovered DCT coef.
    
    SZ_DCT = 8
    nr_blk = Dq.shape[0] // SZ_DCT
    nc_blk = Dq.shape[1] // SZ_DCT
    
    for i in range(nr_blk):
        for j in range(nc_blk):
            sr = slice(SZ_DCT*i, SZ_DCT*(i+1))
            sc = slice(SZ_DCT*j, SZ_DCT*(j+1))
            blk = Dq[sr, sc]
            D[sr, sc] = blk * Q
            
    return D

def inverse_dct(D):
    C = np.zeros_like(D, dtype=np.float32)
    
    nr_blk = D.shape[0] // SZ_DCT
    nc_blk = D.shape[1] // SZ_DCT
    
    for i in range(nr_blk):
        for j in range(nc_blk):
            sr = slice(SZ_DCT*i, SZ_DCT*(i+1))
            sc = slice(SZ_DCT*j, SZ_DCT*(j+1))
            blk = D[sr, sc]
            C[sr, sc] = np.clip(np.round(idct2(blk) + 128).astype(np.int16), 0, 255)
        # end of for
    # end of for
            
    return C


#Dq = jpeg.coef_arrays[0]  # Quantized DCT coef.
#Q = jpeg.quant_tables[0, :, :]  # Quantization table

jpeg = jpegio.read("testimg.jpg")

Ql = jpeg.quant_tables[0, :, :] # Quantization table for luminance
Qc = jpeg.quant_tables[1, :, :] # Quantization table for chrominance

est_dcts = list()
img_ycbcr = list()

for i in range(len(jpeg.coef_arrays)):
    Q = Ql if i == 0 else Qc     
    Dq = jpeg.coef_arrays[i]  # Quantized DCT coef.
    De = estimate_dct(Dq, Q)
    est_dcts.append(De)
    C = inverse_dct(De)  # Recovered YCbCb
    img_ycbcr.append(C)
# end of for
    
    