Revision 3
; Created by bitgen 2018.2 at Thu Jul 11 12:13:46 2019
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
Bit 16120003 0x0040101f   2019 Block=SLICE_X52Y81 Latch=AQ Net=h_c_OBUF[3]
Bit 16120004 0x0040101f   2020 Block=SLICE_X53Y81 Latch=AQ Net=h_c_OBUF[0]
Bit 16120028 0x0040101f   2044 Block=SLICE_X52Y81 Latch=BQ Net=h_c_OBUF[4]
Bit 16120029 0x0040101f   2045 Block=SLICE_X53Y81 Latch=BQ Net=h_c_OBUF[1]
Bit 16120033 0x0040101f   2049 Block=SLICE_X52Y81 Latch=CQ Net=h_c_OBUF[5]
Bit 16120034 0x0040101f   2050 Block=SLICE_X53Y81 Latch=CQ Net=h_c_OBUF[2]
Bit 16120058 0x0040101f   2074 Block=SLICE_X52Y81 Latch=DQ Net=h_c_OBUF[6]
Bit 16236419 0x0040109f   2083 Block=SLICE_X54Y82 Latch=AQ Net=c_r/genblk1[28].fdre_inst/out[0]
Bit 16236420 0x0040109f   2084 Block=SLICE_X55Y82 Latch=AQ Net=c_r/genblk1[25].fdre_inst/out[0]
Bit 16236444 0x0040109f   2108 Block=SLICE_X54Y82 Latch=BQ Net=c_r/genblk1[29].fdre_inst/out[0]
Bit 16236445 0x0040109f   2109 Block=SLICE_X55Y82 Latch=BQ Net=c_r/genblk1[26].fdre_inst/out[0]
Bit 16236449 0x0040109f   2113 Block=SLICE_X54Y82 Latch=CQ Net=c_r/genblk1[30].fdre_inst/out[0]
Bit 16236450 0x0040109f   2114 Block=SLICE_X55Y82 Latch=CQ Net=c_r/genblk1[27].fdre_inst/out[0]
Bit 16236474 0x0040109f   2138 Block=SLICE_X54Y82 Latch=DQ Net=c_r/genblk1[31].fdre_inst/out[0]
