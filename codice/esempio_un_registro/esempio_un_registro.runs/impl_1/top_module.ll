Revision 3
; Created by bitgen 2018.2 at Thu Jul 18 11:17:20 2019
; Bit lines have the following form:
; <offset> <frame address> <frame offset> <information>
; <information> may be zero or more <kw>=<value> pairs
; Block=<blockname     specifies the block associated with this
;                      memory cell.
;
; Latch=<name>         specifies the latch associated with this memory cell.
;
; Net=<netname>        specifies the user net associated with this
;                      memory cell.
;
; COMPARE=[YES | NO]   specifies whether or not it is appropriate
;                      to compare this bit position between a
;                      "program" and a "readback" bitstream.
;                      If not present the default is NO.
;
; Ram=<ram id>:<bit>   This is used in cases where a CLB function
; Rom=<ram id>:<bit>   generator is used as RAM (or ROM).  <Ram id>
;                      will be either 'F', 'G', or 'M', indicating
;                      that it is part of a single F or G function
;                      generator used as RAM, or as a single RAM
;                      (or ROM) built from both F and G.  <Bit> is
;                      a decimal number.
;
; Info lines have the following form:
; Info <name>=<value>  specifies a bit associated with the LCA
;                      configuration options, and the value of
;                      that bit.  The names of these bits may have
;                      special meaning to software reading the .ll file.
;
Info STARTSEL0=1
Bit 12718755 0x0040011f    835 Block=SLICE_X0Y63 Latch=AQ Net=h_c_OBUF[5]
Bit 12718883 0x0040011f    963 Block=SLICE_X0Y65 Latch=AQ Net=c_r/genblk1[30].fdre_inst/out[0]
Bit 12719011 0x0040011f   1091 Block=SLICE_X0Y67 Latch=AQ Net=h_c_OBUF[2]
Bit 12719036 0x0040011f   1116 Block=SLICE_X0Y67 Latch=BQ Net=h_c_OBUF[4]
Bit 12719139 0x0040011f   1219 Block=SLICE_X0Y69 Latch=AQ Net=c_r/genblk1[27].fdre_inst/out[0]
Bit 12719140 0x0040011f   1220 Block=SLICE_X1Y69 Latch=AQ Net=h_c_OBUF[3]
Bit 12719164 0x0040011f   1244 Block=SLICE_X0Y69 Latch=BQ Net=c_r/genblk1[28].fdre_inst/out[0]
Bit 12719169 0x0040011f   1249 Block=SLICE_X0Y69 Latch=CQ Net=c_r/genblk1[29].fdre_inst/out[0]
Bit 12719267 0x0040011f   1347 Block=SLICE_X0Y71 Latch=AQ Net=c_r/genblk1[25].fdre_inst/out[0]
Bit 12719268 0x0040011f   1348 Block=SLICE_X1Y71 Latch=AQ Net=h_c_OBUF[0]
Bit 12719292 0x0040011f   1372 Block=SLICE_X0Y71 Latch=BQ Net=c_r/genblk1[26].fdre_inst/out[0]
Bit 12719293 0x0040011f   1373 Block=SLICE_X1Y71 Latch=BQ Net=h_c_OBUF[1]
Bit 12719297 0x0040011f   1377 Block=SLICE_X0Y71 Latch=CQ Net=c_r/genblk1[31].fdre_inst/out[0]
Bit 12719298 0x0040011f   1378 Block=SLICE_X1Y71 Latch=CQ Net=h_c_OBUF[6]
